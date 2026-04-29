#!/usr/bin/env bash
set -euo pipefail

CHART_DIR="${CHART_DIR:-kedify-agent}"
RELEASE_NAME="${RELEASE_NAME:-image-scan}"
NAMESPACE="${NAMESPACE:-default}"

TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

build_helm_set_args_for_dependencies() {
  local chart_yaml="$1"
  local out_file="$2"

  : > "$out_file"

  yq -r '.dependencies[]?.condition // ""' "$chart_yaml" | while IFS= read -r condition_list; do
    if [[ -z "$condition_list" ]]; then
      continue
    fi

    IFS=',' read -r -a condition_keys <<< "$condition_list"
    for key in "${condition_keys[@]}"; do
      key="$(echo "$key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
      [[ -z "$key" ]] && continue
      printf '%s\n' "$key=true" >> "$out_file"
    done
  done
}

print_images_by_helm_template() {
  local chart_dir="$1"
  local set_values_file="$TMP_DIR/template-set-values.txt"
  local rendered_file="$TMP_DIR/rendered.yaml"

  helm dependency build "$chart_dir" >/dev/null

  build_helm_set_args_for_dependencies "$chart_dir/Chart.yaml" "$set_values_file"

  local -a helm_args=(
    template
    "$RELEASE_NAME"
    "$chart_dir"
    --namespace "$NAMESPACE"
    --include-crds
    --set "disableSchemaValidation=true"
    --set "keda.enabled=true"
    --set "keda-add-ons-http.enabled=true"
    --set "otel-add-on.enabled=true"
    --set "kedify-predictor.enabled=true"
  )

  if [[ -s "$set_values_file" ]]; then
    while IFS= read -r keyval; do
      helm_args+=(--set "$keyval")
    done < "$set_values_file"
  fi

  helm "${helm_args[@]}" > "$rendered_file"

  yq -Nr '
    ..
    | select(type == "!!map" and has("image"))
    | .image
    | select(type == "!!str" and . != "")
  ' "$rendered_file" | grep -v busybox | sort -u
}

print_kedify_proxy_images() {
  local repo_root envoy_tag

  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  envoy_tag="$(yq -r '.appVersion // ""' "$repo_root/kedify-proxy/Chart.yaml")"

  if [[ -z "$envoy_tag" || "$envoy_tag" == "null" ]]; then
    echo "Failed to read appVersion from $repo_root/kedify-proxy/Chart.yaml" >&2
    return 1
  fi

  printf 'envoyproxy/envoy:%s\n' "$envoy_tag"
}

resolve_amd64_digest() {
  local image="$1"
  local inspect_json digest

  inspect_json="$(docker buildx imagetools inspect --format '{{ json . }}' "$image")"
  digest="$(printf '%s' "$inspect_json" | yq -r '.manifest.manifests[]? | select(.platform.os == "linux" and .platform.architecture == "amd64") | .digest' | head -n1)"

  if [[ -z "$digest" || "$digest" == "null" ]]; then
    digest="$(printf '%s' "$inspect_json" | yq -r '.manifest.digest // ""')"
  fi

  if [[ -z "$digest" || "$digest" == "null" ]]; then
    echo "Failed to resolve digest for $image" >&2
    return 1
  fi

  printf '%s@%s\n' "$image" "$digest"
}

main() {
  local image
  while IFS= read -r image; do
    resolve_amd64_digest "$image"
  done < <(
    {
      print_images_by_helm_template "$CHART_DIR"
      print_kedify_proxy_images
    } | sort -u
  )
}

main
