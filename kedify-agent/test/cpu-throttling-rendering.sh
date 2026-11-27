#!/usr/bin/env bash
set -euo pipefail
trap 'echo "CPU throttling render check failed at line $LINENO" >&2' ERR

chart_dir="$(cd "$(dirname "$0")/.." && pwd)"
render() {
  helm template test "$chart_dir" --values "$chart_dir/test/test-values.yaml" \
    --show-only templates/agent-deployment.yaml --show-only templates/agent-rbac.yaml "$@"
}

collector_value() {
  awk '/name: METRICS_CPU_THROTTLING_ENABLED$/ { getline; print $2 }'
}

standard=$(render)
[[ "$(collector_value <<< "$standard")" == '"true"' && "$standard" == *nodes/proxy* ]]
disabled=$(render --set agent.insights.cpuThrottling.enabled=false)
[[ "$(collector_value <<< "$disabled")" == '"false"' ]]
preview_opt_out=$(render --set agent.metricsCPUThrottlingEnabled=false)
[[ "$(collector_value <<< "$preview_opt_out")" == '"false"' ]]

# The collector reuses kubelet access. An upgrade must not regrant access
# when administrators disable both features that previously supplied it.
restricted=$(render --set global.features.podResourceProfilesEnabled=false --set agent.features.podResourceProfilesEnabled=false)
[[ "$(collector_value <<< "$restricted")" == '"true"' ]]
[[ "$restricted" != *nodes/proxy* && "$restricted" != *pods/resize* ]]
# Turning off collection must preserve the existing profile permissions.
[[ "$disabled" == *nodes/proxy* && "$disabled" == *pods/resize* ]]
