#!/usr/bin/env bash

set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
default_render="$(mktemp)"
enabled_render="$(mktemp)"
tenant_render="$(mktemp)"
trap 'rm -f "${default_render}" "${enabled_render}" "${tenant_render}"' EXIT

helm template test "${chart_dir}" --namespace keda >"${default_render}"
helm template test "${chart_dir}" --namespace keda \
  --set kedify.kpa.enabled=true >"${enabled_render}"
helm template test "${chart_dir}" --namespace keda \
  --set kedify.kpa.enabled=true \
  --set kedify.multitenant.mode=tenant \
  --set watchNamespace=tenant-a >"${tenant_render}"

if grep -q -- 'autoscaling.kedify.io' "${default_render}" || grep -q -- '--enable-kpa' "${default_render}"; then
  echo "KPA RBAC and arguments must not be rendered by default" >&2
  exit 1
fi

if [[ "$(grep -c -- '- autoscaling.kedify.io' "${enabled_render}")" -ne 2 ]] ||
   [[ "$(grep -c -- '--enable-kpa' "${enabled_render}")" -ne 2 ]]; then
  echo "KPA-enabled default mode must configure the operator and webhook" >&2
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

if [[ "$(grep -c -- '--enable-kpa' "${tenant_render}")" -ne 1 ]]; then
  echo "KPA-enabled tenant mode must configure only its operator" >&2
  exit 1
fi
