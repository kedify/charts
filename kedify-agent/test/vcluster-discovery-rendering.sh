#!/usr/bin/env bash
set -euo pipefail
chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
render_dir="$(mktemp -d)"
trap 'rm -rf "$render_dir"' EXIT
render() {
  helm template discovery "$chart_dir" --namespace scaling-system \
    --values "$chart_dir/test/test-values.yaml" \
    --show-only templates/agent-deployment.yaml \
    --show-only templates/agent-rbac.yaml "$@"
}
render > "$render_dir/default.yaml"
render --set agent.features.multicluster.enabled=true > "$render_dir/enabled-agent.yaml"
render --set global.features.multicluster.enabled=true > "$render_dir/enabled-global.yaml"
for mode in agent global; do
  render --set "$mode.features.multicluster.enabled=true" \
    --set "$mode.features.multicluster.vClusterDiscoveryEnabled=true" \
    --set agent.rbac.readServices=false > "$render_dir/$mode.yaml"
done
for mode in default enabled-agent enabled-global; do
  if grep -q 'MULTICLUSTER_VCLUSTER_DISCOVERY_ENABLED\|Discover native vCluster exports' "$render_dir/$mode.yaml"; then
    echo 'Discovery credentials/watch permissions must be opt-in' >&2
    exit 1
  fi
done
for mode in enabled-agent enabled-global; do
  grep -A1 'name: DSO_ENABLED' "$render_dir/$mode.yaml" | grep -q 'value: "true"'
  grep -A1 'name: DSJ_ENABLED' "$render_dir/$mode.yaml" | grep -q 'value: "true"'
done
for mode in agent global; do
  grep -A1 'name: MULTICLUSTER_VCLUSTER_DISCOVERY_ENABLED' "$render_dir/$mode.yaml" | grep -q 'value: "true"'
  grep -A3 '# Discover native vCluster exports' "$render_dir/$mode.yaml" | grep -q '"get", "list", "watch"'
  # Discovery must not add any namespaced permissions or Secret writes.
  awk '/^kind: Role$/{role=1} role{print} /^---$/{role=0}' "$render_dir/$mode.yaml" > "$render_dir/$mode-roles.yaml"
  awk '/^kind: Role$/{role=1} role{print} /^---$/{role=0}' "$render_dir/enabled-agent.yaml" > "$render_dir/enabled-roles.yaml"
  diff -u "$render_dir/enabled-roles.yaml" "$render_dir/$mode-roles.yaml"
done
if render --set agent.features.multicluster.vClusterDiscoveryEnabled=true > "$render_dir/invalid.yaml" 2> "$render_dir/error"; then
  echo 'Discovery without multi-cluster scaling must be rejected' >&2
  exit 1
fi
grep -q 'vCluster discovery requires multicluster.enabled' "$render_dir/error"

# Deprecated flat values retain their independent DSO/DSJ behavior for one release.
render --set agent.features.distributedScaledObjectsEnabled=true > "$render_dir/legacy-dso.yaml"
grep -A1 'name: DSO_ENABLED' "$render_dir/legacy-dso.yaml" | grep -q 'value: "true"'
grep -A1 'name: DSJ_ENABLED' "$render_dir/legacy-dso.yaml" | grep -q 'value: "false"'
render --set global.features.distributedScaledJobsEnabled=true \
  --set global.features.multiclusterVclusterDiscoveryEnabled=true > "$render_dir/legacy-dsj.yaml"
grep -A1 'name: DSO_ENABLED' "$render_dir/legacy-dsj.yaml" | grep -q 'value: "false"'
grep -A1 'name: DSJ_ENABLED' "$render_dir/legacy-dsj.yaml" | grep -q 'value: "true"'
grep -q 'MULTICLUSTER_VCLUSTER_DISCOVERY_ENABLED' "$render_dir/legacy-dsj.yaml"

# The shared global switch reaches the KEDA chart and enables DSJ raw metrics.
helm template keda "$chart_dir/../keda" --namespace scaling-system \
  --set global.features.multicluster.enabled=true \
  --show-only templates/manager/deployment.yaml > "$render_dir/keda.yaml"
grep -A1 'name: RAW_METRICS_GRPC_PROTOCOL' "$render_dir/keda.yaml" | grep -q 'value: enabled'
echo 'vCluster discovery rendering passed'
