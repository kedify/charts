#!/usr/bin/env bash

set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
default_render="$(mktemp)"
disabled_render="$(mktemp)"
enabled_render="$(mktemp)"
trap 'rm -f "${default_render}" "${disabled_render}" "${enabled_render}"' EXIT

render() {
  helm template test "${chart_dir}" \
    --namespace keda \
    --values "${chart_dir}/test/test-values.yaml" \
    "$@"
}

render >"${default_render}"
render --set agent.rbac.readMetrics=false --set agent.rbac.readDaemonSets=false \
  --set agent.rbac.readLogs=false --set agent.rbac.readDeploymentsClusterwide=false >"${disabled_render}"
render --set agent.rbac.readMetrics=false --set agent.rbac.readDaemonSets=true \
  --set agent.rbac.readLogs=false --set agent.rbac.readDeploymentsClusterwide=false >"${enabled_render}"

assert_daemonset_access() {
  local render="$1"
  if ! grep -A1 -F 'name: RBAC_READ_DAEMON_SETS' "${render}" | grep -q 'value: "true"'; then
    echo "DaemonSet reads must be advertised when enabled" >&2
    exit 1
  fi
  if ! grep -q '^  - daemonsets$' "${render}"; then
    echo "DaemonSet read RBAC must be rendered when enabled" >&2
    exit 1
  fi
}

assert_daemonset_access "${default_render}"
assert_daemonset_access "${enabled_render}"

if ! grep -q '^  - replicasets$' "${default_render}"; then
  echo "Deployment metrics must include ReplicaSet read RBAC" >&2
  exit 1
fi

if ! grep -A1 -F 'name: RBAC_READ_DAEMON_SETS' "${disabled_render}" | grep -q 'value: "false"'; then
  echo "DaemonSet reads must be disabled when neither metrics nor explicit access is enabled" >&2
  exit 1
fi
if grep -q '^  - daemonsets$' "${disabled_render}"; then
  echo "DaemonSet RBAC must not be rendered when access is disabled" >&2
  exit 1
fi
if grep -q '^  - replicasets$' "${disabled_render}"; then
  echo "ReplicaSet RBAC must not be rendered when metrics access is disabled" >&2
  exit 1
fi
