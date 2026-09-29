#!/usr/bin/env bash

set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rendered="$(mktemp)"
trap 'rm -f "${rendered}"' EXIT

helm template kedify-agent "${chart_dir}" \
  --namespace keda \
  --set disableSchemaValidation=true \
  --set-string agent.extraArgs.quickstart=ignored \
  --set-string agent.quickstart=http >"${rendered}"

grep -q -- '- "--quickstart=ignored"' "${rendered}"
grep -q -- '- "--quickstart=http"' "${rendered}"
if grep -q 'name: KEDIFY_AGENT_ID\|name: KEDIFY_ORGANIZATION_ID\|name: KEDIFY_API_KEY' "${rendered}"; then
  echo "quickstart rendering contains credential environment variables" >&2
  exit 1
fi
if grep -q '^# Source: kedify-agent/templates/api-key-secret.yaml$' "${rendered}"; then
  echo "quickstart rendering contains the API key Secret" >&2
  exit 1
fi
grep -q -- 'resourceNames:' "${rendered}"
grep -q -- '  - kedify-agent' "${rendered}"
