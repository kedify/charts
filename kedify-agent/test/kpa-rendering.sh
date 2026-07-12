#!/usr/bin/env bash

set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
default_render="$(mktemp)"
enabled_render="$(mktemp)"
restricted_render="$(mktemp)"
trap 'rm -f "${default_render}" "${enabled_render}" "${restricted_render}"' EXIT

helm template test "${chart_dir}" \
  --namespace keda \
  --values "${chart_dir}/test/test-values.yaml" \
  --show-only templates/agent-deployment.yaml \
  --show-only templates/agent-rbac.yaml >"${default_render}"

helm template test "${chart_dir}" \
  --namespace keda \
  --values "${chart_dir}/test/test-values.yaml" \
  --set agent.features.kedifyPodAutoscalerEnabled=true \
  --show-only templates/agent-deployment.yaml \
  --show-only templates/agent-rbac.yaml >"${enabled_render}"

helm template test "${chart_dir}" \
  --namespace keda \
  --values "${chart_dir}/test/test-values.yaml" \
  --set agent.features.kedifyPodAutoscalerEnabled=true \
  --set agent.rbac.readServices=false \
  --set agent.rbac.ingressAutoWire=false \
  --show-only templates/agent-deployment.yaml \
  --show-only templates/agent-rbac.yaml >"${restricted_render}"

if grep -q 'autoscaling.kedify.io' "${default_render}"; then
  echo "KPA RBAC must not be rendered by default" >&2
  exit 1
fi

if ! grep -A1 -F 'name: RBAC_READ_KPAS' "${default_render}" | grep -q 'value: "false"'; then
  echo "RBAC_READ_KPAS must be false by default" >&2
  exit 1
fi

if ! grep -A1 -F 'name: RBAC_READ_KPAS' "${enabled_render}" | grep -q 'value: "true"'; then
  echo "RBAC_READ_KPAS must be true when KPA support is enabled" >&2
  exit 1
fi

if ! grep -q 'autoscaling.kedify.io' "${enabled_render}" || \
   ! grep -q 'kedifypodautoscalers' "${enabled_render}"; then
  echo "KPA read RBAC must be rendered when KPA support is enabled" >&2
  exit 1
fi

if ! grep -A1 -F 'name: RBAC_READ_SERVICES' "${enabled_render}" | grep -q 'value: "true"' || \
   ! grep -q '^  - services$' "${enabled_render}"; then
  echo "Service discovery RBAC must remain available when KPA support is enabled" >&2
  exit 1
fi

if ! grep -A1 -F 'name: RBAC_READ_SERVICES' "${restricted_render}" | grep -q 'value: "false"'; then
  echo "KPA support must not advertise broad Service access when it only has list permission" >&2
  exit 1
fi

if ! grep -A1 -F 'name: RBAC_READ_KPAS' "${restricted_render}" | grep -q 'value: "true"'; then
  echo "KPA support must retain its dedicated capability when broad Service reads are disabled" >&2
  exit 1
fi

restricted_service_rule="$(grep -A4 '^  - services$' "${restricted_render}")"
if ! grep -q '^  - list$' <<<"${restricted_service_rule}" || \
   grep -Eq '^  - (create|patch|update|watch)$' <<<"${restricted_service_rule}"; then
  echo "KPA-only Service discovery must receive list-only RBAC" >&2
  exit 1
fi
