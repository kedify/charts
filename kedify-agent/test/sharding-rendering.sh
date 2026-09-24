#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "${test_dir}"' EXIT

# The Agent umbrella has remote dependencies. Render its own templates in a
# temporary copy so this focused test is independent of chart repositories.
cp -R "${repo_dir}/kedify-agent" "${test_dir}/agent"
rm -rf "${test_dir}/agent/charts"
sed -i.bak '/^dependencies:/,$d' "${test_dir}/agent/Chart.yaml"
rm "${test_dir}/agent/Chart.yaml.bak"

helm template test "${test_dir}/agent" --namespace keda \
  --set agent.createApiKeySecret=false >"${test_dir}/default-agent.yaml"
if grep -qF 'name: kedify-agent-sharding' "${test_dir}/default-agent.yaml" || \
   grep -qF -- '--sharding-configmap-name=' "${test_dir}/default-agent.yaml"; then
  echo 'Default Agent installation must remain unsharded' >&2
  exit 1
fi

cat >"${test_dir}/agent-values.yaml" <<'EOF'
agent:
  createApiKeySecret: false
  sharding:
    pools:
      - name: applications
        namespaces: [app-a, app-b]
        shards:
          - id: s0
            tenantRef: operators/keda-s0
          - id: s1
            tenantRef: operators/keda-s1
global:
  features:
    multitenantKEDAEnabled: true
    kedifyPodAutoscalerEnabled: true
EOF

helm template test "${test_dir}/agent" --namespace keda \
  -f "${test_dir}/agent-values.yaml" >"${test_dir}/agent-render.yaml"
for field in shardPool shardId watchLabelSelector; do
  if ! grep -q -- "^                    ${field}:$" "${repo_dir}/kedify-agent/files/crds/kedify-configuration.yaml"; then
    echo "The Helm-installed KedifyConfiguration CRD must preserve status.discoveredTenants[].${field}" >&2
    exit 1
  fi
done
for expected in 'name: kedify-agent-sharding' 'pools.yaml: |' 'name: applications' \
  'strategy: Rendezvous' 'tenantRef: operators/keda-s0' \
  '--sharding-configmap-name=kedify-agent-sharding' \
  '--sharding-configmap-namespace=keda'; do
  grep -qF -- "${expected}" "${test_dir}/agent-render.yaml"
done
if grep -qF 'kedify.io/shard-enrollment' "${test_dir}/agent-render.yaml"; then
  echo 'The Agent, not Helm, owns the enrollment annotation' >&2
  exit 1
fi

helm template test "${test_dir}/agent" --namespace keda \
  -f "${test_dir}/agent-values.yaml" \
  --set agent.rbac.readMetrics=false \
  --set agent.rbac.readDeploymentsClusterwide=false \
  --set agent.rbac.selfUpdates=false \
  --set agent.features.recommendationsForLabeledNamespaces=false \
  --set global.features.recommendationsForLabeledNamespaces=false \
  --show-only templates/agent-rbac.yaml >"${test_dir}/shard-rbac.yaml"
for resource in namespaces deployments; do
  if ! awk -v target="${resource}" '
    function check_rule() {
      if (resource && get && list && watch && !scoped) found = 1
    }
    /^- apiGroups:/ { check_rule(); resource = get = list = watch = scoped = 0 }
    $0 == "  - " target { resource = 1 }
    $0 == "  - get" { get = 1 }
    $0 == "  - list" { list = 1 }
    $0 == "  - watch" { watch = 1 }
    /^  resourceNames:/ { scoped = 1 }
    END { check_rule(); exit !found }
  ' "${test_dir}/shard-rbac.yaml"; then
    echo "Shard RBAC needs unscoped get/list/watch on ${resource} without telemetry reads" >&2
    exit 1
  fi
done

if helm template test "${test_dir}/agent" --namespace keda \
  -f "${test_dir}/agent-values.yaml" \
  --set global.features.kedifyPodAutoscalerEnabled=false >/dev/null 2>&1; then
  echo 'Agent pools require KPA feature enablement' >&2
  exit 1
fi
if helm template test "${test_dir}/agent" --namespace keda \
  -f "${test_dir}/agent-values.yaml" \
  --set 'agent.sharding.pools[0].namespaces[1]=app-a' >/dev/null 2>&1; then
  echo 'Pool namespaces must be unique' >&2
  exit 1
fi
if helm template test "${test_dir}/agent" --namespace keda \
  -f "${test_dir}/agent-values.yaml" \
  --set agent.extraArgs.sharding-configmap-name=other >/dev/null 2>&1; then
  echo 'Agent extraArgs must not override the rendered pool ConfigMap' >&2
  exit 1
fi

cat >"${test_dir}/keda-values.yaml" <<'EOF'
watchNamespace: app-a,app-b
kedify:
  multitenant:
    mode: tenant
  kpa:
    enabled: true
    defaultClass: kpa
    deploymentName: kpa-s0
  sharding:
    pool: applications
    id: s0
EOF

helm template shard "${repo_dir}/keda" --namespace operators \
  -f "${test_dir}/keda-values.yaml" \
  --show-only templates/kedify-tenant-registration-configmap.yaml \
  --show-only templates/manager/deployment.yaml >"${test_dir}/keda-render.yaml"
for expected in 'shardPool: "applications"' 'shardId: "s0"' \
  'watchLabelSelector: "kedify.io/shard-pool=applications,kedify.io/shard=s0"' \
  'name: WATCH_LABEL_SELECTOR' \
  'value: "kedify.io/shard-pool=applications,kedify.io/shard=s0"'; do
  grep -qF -- "${expected}" "${test_dir}/keda-render.yaml"
done
if grep -qF -- '--watch-label-selector=' "${test_dir}/keda-render.yaml"; then
  echo 'Shard KEDA must use WATCH_LABEL_SELECTOR without an unsupported selector flag' >&2
  exit 1
fi

for override in \
  '--set kedify.multitenant.mode=default' \
  '--set watchNamespace=' \
  '--set kedify.kpa.defaultClass=hpa' \
  '--set kedify.kpa.enabled=false' \
  '--set kedify.kpa.deploymentName=' \
  '--set extraArgs.keda.watch-label-selector=other' \
  '--set extraArgs.keda.enable-kpa=false' \
  '--set env[0].name=WATCH_LABEL_SELECTOR' \
  '--set env[0].name=KEDIFY_SCALINGGROUPS_ENABLED --set env[0].valueFrom.secretKeyRef.name=flags --set env[0].valueFrom.secretKeyRef.key=enabled' \
  '--set env[0].name=KEDIFY_SCALINGGROUPS_ENABLED --set env[0].value=true'; do
  read -r -a args <<<"${override}"
  if helm template shard "${repo_dir}/keda" --namespace operators \
    -f "${test_dir}/keda-values.yaml" "${args[@]}" >/dev/null 2>&1; then
    echo "Unsafe shard setting was accepted: ${override}" >&2
    exit 1
  fi
done

helm template default "${repo_dir}/keda" --namespace operators \
  --show-only templates/manager/deployment.yaml >"${test_dir}/default-keda.yaml"
if grep -qF -- 'name: WATCH_LABEL_SELECTOR' "${test_dir}/default-keda.yaml"; then
  echo 'Default KEDA must not receive a shard selector' >&2
  exit 1
fi
