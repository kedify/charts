#!/usr/bin/env bash

set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
default_render="$(mktemp)"
agent_enabled_render="$(mktemp)"
global_enabled_render="$(mktemp)"
trap 'rm -f "${default_render}" "${agent_enabled_render}" "${global_enabled_render}"' EXIT

render() {
  helm template test "${chart_dir}" \
    --namespace keda \
    --values "${chart_dir}/test/test-values.yaml" \
    --show-only templates/agent-rbac.yaml \
    "$@"
}

render >"${default_render}"
render --set agent.features.argoRolloutsEnabled=true >"${agent_enabled_render}"
render --set global.features.argoRolloutsEnabled=true >"${global_enabled_render}"

if grep -q '^  - argoproj.io$' "${default_render}" || grep -q '^  - rollouts$' "${default_render}"; then
  echo "Argo Rollout RBAC must not be rendered by default" >&2
  exit 1
fi

assert_rollout_access() {
  local rendered="$1"
  if ! grep -q '^  - argoproj.io$' "${rendered}" || ! grep -q '^  - rollouts$' "${rendered}"; then
    echo "Argo Rollout RBAC must be rendered when support is enabled" >&2
    exit 1
  fi

  local rollout_rule
  rollout_rule="$(grep -A6 '^  - rollouts$' "${rendered}")"
  for verb in get list watch; do
    if ! grep -q -- "- ${verb}" <<<"${rollout_rule}"; then
      echo "Argo Rollout RBAC is missing ${verb}" >&2
      exit 1
    fi
  done
}

assert_rollout_access "${agent_enabled_render}"
assert_rollout_access "${global_enabled_render}"
