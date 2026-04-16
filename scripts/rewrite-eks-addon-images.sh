#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 \
    --chart-dir <path> \
    --ecr-registry <host> \
    --ecr-image-repository-prefix <prefix> \
    [--src-images-out <path>] \
    [--image-map-out <path>] \
    [--dst-images-out <path>] \
    [--skip-unpack]

Example:
  $0 \
    --chart-dir kedify-agent \
    --ecr-registry 709825985650.dkr.ecr.us-east-1.amazonaws.com \
    --ecr-image-repository-prefix kedify/kedify-eks-addon
USAGE
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

is_nonempty() {
  local v="${1:-}"
  [[ -n "$v" && "$v" != "null" ]]
}

normalize_image() {
  local src="$1"
  src="${src%@*}"
  local tag="${src##*:}"
  local repo="${src%:*}"

  # Skip invalid references that don't include explicit tag
  if [[ "$repo" == "$tag" ]]; then
    return 1
  fi

  local image_name="${repo##*/}"
  local dst="${ECR_FULL_REPO_PREFIX}/${image_name}:${tag}"

  printf '%s\t%s\n' "$src" "$dst"
  return 0
}

CHART_DIR=""
ECR_REGISTRY=""
ECR_IMAGE_REPOSITORY_PREFIX=""
SRC_IMAGES_OUT="/tmp/src-images.txt"
IMAGE_MAP_OUT="/tmp/image-map.tsv"
DST_IMAGES_OUT="/tmp/dst-images.txt"
UNPACK_DEPS="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --chart-dir)
      CHART_DIR="$2"
      shift 2
      ;;
    --ecr-registry)
      ECR_REGISTRY="$2"
      shift 2
      ;;
    --ecr-image-repository-prefix)
      ECR_IMAGE_REPOSITORY_PREFIX="$2"
      shift 2
      ;;
    --src-images-out)
      SRC_IMAGES_OUT="$2"
      shift 2
      ;;
    --image-map-out)
      IMAGE_MAP_OUT="$2"
      shift 2
      ;;
    --dst-images-out)
      DST_IMAGES_OUT="$2"
      shift 2
      ;;
    --skip-unpack)
      UNPACK_DEPS="false"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$CHART_DIR" || -z "$ECR_REGISTRY" || -z "$ECR_IMAGE_REPOSITORY_PREFIX" ]]; then
  usage
  exit 1
fi

if [[ ! -d "$CHART_DIR" ]]; then
  echo "Chart directory not found: $CHART_DIR" >&2
  exit 1
fi

require_cmd yq
require_cmd sort
require_cmd grep
require_cmd tar

ECR_FULL_REPO_PREFIX="${ECR_REGISTRY}/${ECR_IMAGE_REPOSITORY_PREFIX}"
export ECR_REGISTRY ECR_IMAGE_REPOSITORY_PREFIX ECR_FULL_REPO_PREFIX

if [[ "$UNPACK_DEPS" == "true" ]]; then
  shopt -s nullglob
  for pkg in "$CHART_DIR"/charts/*.tgz; do
    tar -xzf "$pkg" -C "$CHART_DIR"/charts
    rm -f "$pkg"
  done
fi

: > "$SRC_IMAGES_OUT"
: > "$IMAGE_MAP_OUT"

collect_repo_tag_images() {
  local values_file="$1"
  yq -r '
    ..
    | select(type == "!!map" and has("repository") and has("tag"))
    | [(.registry // ""), (.repository | tostring), (.tag | tostring)]
    | @tsv
  ' "$values_file" | while IFS=$'\t' read -r registry repository tag; do
    if ! is_nonempty "$repository" || ! is_nonempty "$tag"; then
      continue
    fi

    local src
    if [[ "$repository" =~ ^[A-Za-z0-9.-]+(:[0-9]+)?/ ]]; then
      src="${repository}:${tag}"
    elif is_nonempty "$registry"; then
      src="${registry}/${repository}:${tag}"
    else
      src="${repository}:${tag}"
    fi

    echo "$src"
  done
}

collect_http_images() {
  local values_file="$1"
  yq -r '
    ..
    | select(type == "!!map" and has("tag") and has("operator") and has("interceptor") and has("scaler"))
    | [(.operator | tostring), (.interceptor | tostring), (.scaler | tostring), (.tag | tostring)]
    | @tsv
  ' "$values_file" | while IFS=$'\t' read -r operator interceptor scaler tag; do
    if ! is_nonempty "$tag"; then
      continue
    fi
    if is_nonempty "$operator"; then echo "${operator}:${tag}"; fi
    if is_nonempty "$interceptor"; then echo "${interceptor}:${tag}"; fi
    if is_nonempty "$scaler"; then echo "${scaler}:${tag}"; fi
  done
}

collect_name_tag_images() {
  local values_file="$1"
  yq -r '
    ..
    | select(type == "!!map" and has("name") and has("tag"))
    | [(.name | tostring), (.tag | tostring)]
    | @tsv
  ' "$values_file" | while IFS=$'\t' read -r name tag; do
    if ! is_nonempty "$name" || ! is_nonempty "$tag"; then
      continue
    fi
    if [[ "$name" == */* ]]; then
      echo "${name}:${tag}"
    fi
  done
}

rewrite_values_to_ecr() {
  local values_file="$1"

  yq -i '
    (
      ..
      | select(
          type == "!!map"
          and has("repository")
          and has("tag")
          and has("registry")
          and .repository != null and .repository != ""
          and .tag != null and (.tag | tostring) != ""
        )
      | .registry
    ) = strenv(ECR_REGISTRY)
  ' "$values_file"

  yq -i '
    (
      ..
      | select(
          type == "!!map"
          and has("repository")
          and has("tag")
          and .repository != null and .repository != ""
          and .tag != null and (.tag | tostring) != ""
        )
      | .repository
    ) |= strenv(ECR_FULL_REPO_PREFIX) + "/" + (split("/")[-1])
  ' "$values_file"

  yq -i '
    (
      ..
      | select(
          type == "!!map"
          and has("name")
          and has("tag")
          and .name != null and .name != ""
          and .tag != null and (.tag | tostring) != ""
          and (.name | test("/"))
        )
      | .name
    ) |= strenv(ECR_FULL_REPO_PREFIX) + "/" + (split("/")[-1])
  ' "$values_file"

  yq -i '
    (
      ..
      | select(
          type == "!!map"
          and has("tag")
          and has("operator")
          and .operator != null and .operator != ""
          and .tag != null and (.tag | tostring) != ""
        )
      | .operator
    ) |= strenv(ECR_FULL_REPO_PREFIX) + "/" + (split("/")[-1])
  ' "$values_file"

  yq -i '
    (
      ..
      | select(
          type == "!!map"
          and has("tag")
          and has("interceptor")
          and .interceptor != null and .interceptor != ""
          and .tag != null and (.tag | tostring) != ""
        )
      | .interceptor
    ) |= strenv(ECR_FULL_REPO_PREFIX) + "/" + (split("/")[-1])
  ' "$values_file"

  yq -i '
    (
      ..
      | select(
          type == "!!map"
          and has("tag")
          and has("scaler")
          and .scaler != null and .scaler != ""
          and .tag != null and (.tag | tostring) != ""
        )
      | .scaler
    ) |= strenv(ECR_FULL_REPO_PREFIX) + "/" + (split("/")[-1])
  ' "$values_file"
}

while IFS= read -r values_file; do
  collect_repo_tag_images "$values_file" >> "$SRC_IMAGES_OUT"
  collect_http_images "$values_file" >> "$SRC_IMAGES_OUT"
  collect_name_tag_images "$values_file" >> "$SRC_IMAGES_OUT"

  rewrite_values_to_ecr "$values_file"
done < <(find "$CHART_DIR" -type f -name values.yaml | sort)

sort -u "$SRC_IMAGES_OUT" -o "$SRC_IMAGES_OUT"
: > "$IMAGE_MAP_OUT"

while IFS= read -r src; do
  [[ -z "$src" ]] && continue
  if normalize_image "$src" >> "$IMAGE_MAP_OUT"; then
    :
  fi
done < "$SRC_IMAGES_OUT"

sort -u "$IMAGE_MAP_OUT" -o "$IMAGE_MAP_OUT"
cut -f2 "$IMAGE_MAP_OUT" | sort -u > "$DST_IMAGES_OUT"

echo "Rewritten values and prepared image mapping files:"
echo "  src images: $SRC_IMAGES_OUT"
echo "  map file  : $IMAGE_MAP_OUT"
echo "  dst images: $DST_IMAGES_OUT"
