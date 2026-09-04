#!/usr/bin/env bash

set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
default_render="$(mktemp)"
bundled_render="$(mktemp)"
canonical_render="$(mktemp)"
external_render="$(mktemp)"
trap 'rm -f "${default_render}" "${bundled_render}" "${canonical_render}" "${external_render}"' EXIT

render() {
  helm template test "${chart_dir}" \
    --namespace keda \
    --values "${chart_dir}/test/test-values.yaml" \
    "$@"
}

render >"${default_render}"
render --set kube-state-metrics.enabled=true >"${bundled_render}"
render --set agent.resourceMetrics.legacy.enabled=false >"${canonical_render}"
render --set agent.resourceMetrics.kubeStateMetrics.url=http://existing-ksm.monitoring.svc:8080/metrics >"${external_render}"

grep -A1 -F 'name: LEGACY_CONTAINER_RESOURCE_METRICS_ENABLED' "${default_render}" | grep -q 'value: "true"'
grep -A1 -F 'name: KUBE_STATE_METRICS_URL' "${bundled_render}" | grep -q 'value: "http://kedify-agent-kube-state-metrics.keda.svc:8080/metrics"'
grep -q 'name: kedify-agent-kube-state-metrics' "${bundled_render}"
grep -q -- '--resources=pods,replicasets' "${bundled_render}"
grep -q -- '--metric-allowlist=kube_pod_container_resource_requests,kube_pod_container_resource_limits,kube_pod_container_status_restarts_total,kube_pod_container_status_last_terminated_reason,kube_pod_owner,kube_replicaset_owner' "${bundled_render}"
grep -A1 -F 'name: LEGACY_CONTAINER_RESOURCE_METRICS_ENABLED' "${canonical_render}" | grep -q 'value: "false"'
if grep -q '^  - metrics.k8s.io$' "${canonical_render}"; then
  echo "Canonical-only rendering must not grant metrics.k8s.io access" >&2
  exit 1
fi
grep -A1 -F 'name: KUBE_STATE_METRICS_URL' "${external_render}" | grep -q 'value: "http://existing-ksm.monitoring.svc:8080/metrics"'
grep -q '^  - nodes/proxy$' "${canonical_render}"
