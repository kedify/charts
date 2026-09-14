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
render --set agent.features.distributedScaledObjectsEnabled=true \
  --set agent.features.vclusterDiscoveryEnabled=false > "$render_dir/disabled.yaml"
for mode in agent global; do
  render --set "$mode.features.distributedScaledObjectsEnabled=true" \
    --set "$mode.features.vclusterDiscoveryEnabled=true" \
    --set agent.rbac.readServices=false > "$render_dir/$mode.yaml"
done
for mode in default disabled; do
  if grep -q 'VCLUSTER_DISCOVERY_ENABLED\|Discover native vCluster exports' "$render_dir/$mode.yaml"; then
    echo 'Discovery credentials/watch permissions must be opt-in' >&2
    exit 1
  fi
done
for mode in agent global; do
  grep -A1 'name: VCLUSTER_DISCOVERY_ENABLED' "$render_dir/$mode.yaml" | grep -q 'value: "true"'
  grep -A3 '# Discover native vCluster exports' "$render_dir/$mode.yaml" | grep -q '"get", "list", "watch"'
  grep -A3 '# Maintain automatically discovered member registrations' "$render_dir/$mode.yaml" | grep -q '"create", "patch"'
done
if render --set agent.features.vclusterDiscoveryEnabled=true > "$render_dir/invalid.yaml" 2> "$render_dir/error"; then
  echo 'Discovery without DSO/DSJ must be rejected' >&2
  exit 1
fi
grep -q 'requires distributedScaledObjectsEnabled or distributedScaledJobsEnabled' "$render_dir/error"
render --set agent.features.distributedScaledJobsEnabled=true \
  --set agent.features.vclusterDiscoveryEnabled=true > "$render_dir/dsj.yaml"
echo 'vCluster discovery rendering passed'
