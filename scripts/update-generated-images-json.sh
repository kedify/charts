#!/usr/bin/env bash
set -euo pipefail

JSON_PATH="${1:-}"
IMAGES_FILE="${2:-}"
KEDIFY_AGENT_VERSION="${3:-}"
UPDATED_AT="${4:-}"

if [[ -z "$JSON_PATH" || -z "$IMAGES_FILE" || -z "$KEDIFY_AGENT_VERSION" || -z "$UPDATED_AT" ]]; then
  echo "Usage: $0 <json-path> <images-file> <kedify-agent-version> <updated-at-YYYY-MM-DD>" >&2
  exit 1
fi

if [[ ! -f "$IMAGES_FILE" ]]; then
  echo "Images file not found: $IMAGES_FILE" >&2
  exit 1
fi

jq -Rs \
  --arg version "$KEDIFY_AGENT_VERSION" \
  --arg updatedAt "$UPDATED_AT" \
  '{kedifyAgentVersion: $version, updatedAt: $updatedAt, images: (split("\n") | map(select(length > 0)))}' \
  "$IMAGES_FILE" > "$JSON_PATH"
