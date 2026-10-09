#!/usr/bin/env bash

set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
default_render="$(mktemp)"
enabled_render="$(mktemp)"
kpa_default_render="$(mktemp)"
legacy_render="$(mktemp)"
tenant_render="$(mktemp)"
multicluster_render="$(mktemp)"
dedicated_render="$(mktemp)"
distributed_render="$(mktemp)"
trap 'rm -f "${default_render}" "${enabled_render}" "${kpa_default_render}" "${legacy_render}" "${tenant_render}" "${multicluster_render}" "${dedicated_render}" "${distributed_render}"' EXIT

helm template test "${chart_dir}" --namespace keda >"${default_render}"
helm template test "${chart_dir}" --namespace keda \
  --set kedify.kpa.enabled=true >"${enabled_render}"
helm template test "${chart_dir}" --namespace keda \
  --set kedify.kpa.enabled=true \
  --set kedify.kpa.defaultClass=kpa >"${kpa_default_render}"
helm template test "${chart_dir}" --namespace keda \
  --set kedify.kpa.enabled=true \
  --set-string extraArgs.keda.autoscaling-default-class=kpa \
  --set-string extraArgs.webhooks.autoscaling-default-class=kpa >"${legacy_render}"
helm template test "${chart_dir}" --namespace keda \
  --set kedify.kpa.enabled=true \
  --set kedify.kpa.defaultClass=kpa \
  --set kedify.kpa.deploymentName=kpa-tenant-a \
  --set kedify.multitenant.mode=tenant \
  --set watchNamespace=tenant-a >"${tenant_render}"
helm template test "${chart_dir}" --namespace keda \
  --set multicluster.enabled=true >"${multicluster_render}"
helm template test "${chart_dir}" --namespace keda \
  --set global.features.multicluster.enabled=true \
  --set global.features.multicluster.type=dedicated >"${dedicated_render}"
helm template test "${chart_dir}" --namespace keda \
  --set global.features.multicluster.enabled=true >"${distributed_render}"

if grep -q -- 'autoscaling.kedify.io' "${default_render}" || grep -q -- '--enable-kpa' "${default_render}"; then
  echo "KPA RBAC and arguments must not be rendered by default" >&2
  exit 1
fi

if [[ "$(grep -c -- '- autoscaling.kedify.io' "${enabled_render}")" -ne 2 ]] ||
   [[ "$(grep -c -- '--enable-kpa=true' "${enabled_render}")" -ne 2 ]] ||
   [[ "$(grep -c -- '--autoscaling-default-class=hpa' "${enabled_render}")" -ne 2 ]]; then
  echo "KPA-enabled default mode must configure the operator and webhook" >&2
  exit 1
fi

if [[ "$(grep -c -- '--autoscaling-default-class=kpa' "${kpa_default_render}")" -ne 2 ]] ||
   [[ "$(grep -c -- '--autoscaling-default-class=kpa' "${legacy_render}")" -ne 2 ]]; then
  echo "KPA default class must be identical for the operator and webhook" >&2
  exit 1
fi

if helm template test "${chart_dir}" --namespace keda \
  --set kedify.kpa.defaultClass=kpa >/dev/null 2>&1; then
  echo "KPA default class must require KPA support" >&2
  exit 1
fi

# Existing unsharded tenants did not configure a KPA Deployment name.
for mode in default tenant; do
  helm template test "${chart_dir}" --namespace keda \
    --set kedify.kpa.enabled=true \
    --set "kedify.multitenant.mode=${mode}" >"${legacy_render}"
  if grep -q -- 'kpaDeploymentName:' "${legacy_render}"; then
    echo "unconfigured KPA Deployment names must be omitted for unsharded tenants" >&2
    exit 1
  fi
done

# Helm --reuse-values can omit the newly added field entirely.
helm template test "${chart_dir}" --namespace keda \
  --set kedify.kpa.deploymentName=null >"${legacy_render}"
helm template test "${chart_dir}" --namespace keda \
  --set kedify.kpa.enabled=true \
  --set kedify.multitenant.mode=tenant \
  --set kedify.kpa.deploymentName=null >"${legacy_render}"

render_error="$(helm template test "${chart_dir}" --namespace keda \
  --set kedify.kpa.enabled=true \
  --set kedify.kpa.defaultClass=kpa \
  --set kedify.multitenant.mode=tenant \
  --set watchNamespace=tenant-a \
  --set kedify.sharding.pool=applications \
  --set kedify.sharding.id=s0 2>&1 || true)"
if [[ "${render_error}" != *"kedify.sharding requires enabled KPA, defaultClass=kpa and exact KPA deploymentName"* ]]; then
  echo "KPA shards must retain the mainline exact KPA Deployment requirement" >&2
  exit 1
fi

if helm template test "${chart_dir}" --namespace keda \
  --set kedify.kpa.enabled=true \
  --set-string extraArgs.keda.autoscaling-default-class=kpa >/dev/null 2>&1; then
  echo "one-sided legacy default class must be rejected" >&2
  exit 1
fi

if helm template test "${chart_dir}" --namespace keda \
  --set kedify.kpa.enabled=true \
  --set-string extraArgs.keda.autoscaling-default-class=kpa \
  --set-string extraArgs.webhooks.autoscaling-default-class=hpa >/dev/null 2>&1; then
  echo "conflicting legacy default classes must be rejected" >&2
  exit 1
fi

ruby -ryaml -e '
  docs = YAML.load_stream(File.read(ARGV.fetch(0))).compact
  operator_role = docs.find { |doc| doc["kind"] == "ClusterRole" && doc.dig("metadata", "name") == "keda-operator-test" }
  abort "tenant operator KPA role is missing" unless operator_role&.fetch("rules", [])&.any? { |rule| rule.fetch("apiGroups", []).include?("autoscaling.kedify.io") }
  bindings = docs.select { |doc| doc["kind"] == "RoleBinding" && doc.dig("roleRef", "name") == "keda-operator-test" }
  abort "tenant operator must be bound only in release and watched namespaces" unless bindings.map { |binding| binding.dig("metadata", "namespace") }.sort == ["keda", "tenant-a"]
  abort "tenant operator must not receive a cluster-wide binding" if docs.any? { |doc| doc["kind"] == "ClusterRoleBinding" && doc.dig("roleRef", "name") == "keda-operator-test" }
  abort "tenant mode must not deploy the admission webhook" if docs.any? { |doc| doc.dig("spec", "template", "spec", "containers")&.any? { |container| container.fetch("command", []).include?("/keda-admission-webhooks") } }
' "${tenant_render}"

if [[ "$(grep -c -- '--enable-kpa=true' "${tenant_render}")" -ne 1 ]] ||
   [[ "$(grep -c -- '--autoscaling-default-class=kpa' "${tenant_render}")" -ne 1 ]]; then
  echo "KPA-enabled tenant mode must configure only its operator" >&2
  exit 1
fi

if ! grep -q -- 'kpaDeploymentName: "kpa-tenant-a"' "${tenant_render}"; then
  echo "tenant registration must include the exact KPA Deployment name" >&2
  exit 1
fi

if [[ "$(grep -c -- '--multicluster=true' "${multicluster_render}")" -ne 1 ]] ||
   [[ "$(grep -c -- '--multicluster-registration-namespace=keda' "${multicluster_render}")" -ne 1 ]] ||
   [[ "$(grep -c -- '--enable-kpa=true' "${multicluster_render}")" -ne 2 ]] ||
   [[ "$(grep -c -- '--autoscaling-default-class=kpa' "${multicluster_render}")" -ne 2 ]]; then
  echo "multicluster mode must configure the remote ScaledObject/ScaledJob operator" >&2
  exit 1
fi

if [[ "$(grep -c -- '--multicluster=true' "${dedicated_render}")" -ne 1 ]] ||
   [[ "$(grep -c -- '--multicluster-registration-namespace=keda' "${dedicated_render}")" -ne 1 ]] ||
   [[ "$(grep -c -- '--enable-kpa=true' "${dedicated_render}")" -ne 2 ]] ||
   [[ "$(grep -c -- '--autoscaling-default-class=kpa' "${dedicated_render}")" -ne 2 ]]; then
  echo "dedicated global mode must configure KEDA remote reconciliation" >&2
  exit 1
fi
if grep -q -- '--multicluster=true' "${distributed_render}" ||
   grep -q -- '--enable-kpa=true' "${distributed_render}"; then
  echo "distributed global mode must not enable KEDA remote reconciliation" >&2
  exit 1
fi
grep -A1 'name: RAW_METRICS_GRPC_PROTOCOL' "${distributed_render}" | grep -q 'value: enabled'

render_error="$(helm template test "${chart_dir}" --namespace keda \
  --set global.features.multicluster.enabled=true \
  --set global.features.multicluster.type=dedicated \
  --set kedify.multitenant.mode=tenant 2>&1 || true)"
if [[ "${render_error}" != *"kedify.kpa.deploymentName is required when dedicated multicluster reconciliation and multitenant mode are enabled"* ]]; then
  echo "dedicated multicluster tenants must require the KPA Deployment name with a mode-specific error" >&2
  exit 1
fi

render_error="$(helm template test "${chart_dir}" --namespace keda \
  --set global.features.multicluster.enabled=true \
  --set global.features.multicluster.type=dedicated \
  --set kedify.multitenant.mode=tenant \
  --set watchNamespace=tenant-a \
  --set kedify.kpa.enabled=true \
  --set kedify.kpa.defaultClass=kpa \
  --set kedify.kpa.deploymentName=kpa-tenant-a \
  --set kedify.sharding.pool=applications \
  --set kedify.sharding.id=s0 2>&1 || true)"
if [[ "${render_error}" != *"kedify.sharding cannot be combined with dedicated multicluster reconciliation in the same KEDA release"* ]]; then
  echo "KEDA sharding and dedicated multicluster reconciliation must be rejected explicitly" >&2
  exit 1
fi

render_error="$(helm template test "${chart_dir}" --namespace keda \
  --set global.features.multicluster.enabled=true \
  --set global.features.multicluster.type=distributed \
  --set multicluster.enabled=true 2>&1 || true)"
if [[ "${render_error}" != *"multicluster.enabled=true enables dedicated KEDA reconciliation and cannot be combined with global.features.multicluster.type=distributed"* ]]; then
  echo "standalone dedicated KEDA reconciliation and distributed mode must not be combined" >&2
  exit 1
fi

ruby -ryaml -e '
  docs = YAML.load_stream(File.read(ARGV.fetch(0))).compact
  role = docs.find { |doc| doc["kind"] == "Role" && doc.dig("metadata", "name") == "keda-operator-clusterregistrations" }
  abort "multicluster ClusterRegistration Role is missing" unless role
  rules = role.fetch("rules", [])
  abort "ClusterRegistration watch permission is missing" unless rules.any? { |rule| rule.fetch("apiGroups", []).include?("multicluster.kedify.io") && rule.fetch("resources", []).include?("clusterregistrations") }
  abort "registration Secret watch permission is missing" unless rules.any? { |rule| rule.fetch("apiGroups", []).include?("") && rule.fetch("resources", []).include?("secrets") }
' "${multicluster_render}"
