#!/usr/bin/env bash
set -euo pipefail

chart_dir="$(cd "$(dirname "$0")/.." && pwd)"
render() {
  helm template test "$chart_dir" --values "$chart_dir/test/test-values.yaml" \
    --show-only templates/agent-deployment.yaml --show-only templates/agent-rbac.yaml \
    --set global.features.podResourceProfilesEnabled=false --set agent.features.podResourceProfilesEnabled=false "$@"
}

disabled=$(render)
enabled=$(render --set agent.metricsCPUThrottlingEnabled=true)
restricted=$(render --set agent.metricsCPUThrottlingEnabled=true --set agent.rbac.readNodes=false)
profiles=$(render --set agent.features.podResourceProfilesEnabled=true)
[[ "$disabled" != *METRICS_CPU_THROTTLING_ENABLED* && "$disabled" != *nodes/proxy* ]]
[[ "$enabled" == *METRICS_CPU_THROTTLING_ENABLED* && "$enabled" == *nodes/proxy* && "$enabled" != *pods/resize* ]]
[[ "$restricted" != *nodes/proxy* ]]
[[ "$profiles" == *nodes/proxy* && "$profiles" == *pods/resize* ]]
