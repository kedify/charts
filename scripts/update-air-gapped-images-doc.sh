#!/usr/bin/env bash
set -euo pipefail

DOC_PATH="${1:-}"
IMAGES_FILE="${2:-}"

if [[ -z "$DOC_PATH" || -z "$IMAGES_FILE" ]]; then
  echo "Usage: $0 <doc-path> <images-file>" >&2
  exit 1
fi

if [[ ! -f "$DOC_PATH" ]]; then
  echo "Doc file not found: $DOC_PATH" >&2
  exit 1
fi

if [[ ! -f "$IMAGES_FILE" ]]; then
  echo "Images file not found: $IMAGES_FILE" >&2
  exit 1
fi

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

awk -v images_file="$IMAGES_FILE" '
  BEGIN {
    in_required_images = 0
    replaced = 0
  }

  /^## Required Images$/ {
    in_required_images = 1
    print
    next
  }

  in_required_images == 1 && /^```text$/ && replaced == 0 {
    print
    while ((getline line < images_file) > 0) {
      print line
    }
    close(images_file)

    while (getline > 0) {
      if ($0 ~ /^```$/) {
        print
        replaced = 1
        break
      }
    }
    next
  }

  /^## / && $0 != "## Required Images" {
    in_required_images = 0
  }

  {
    print
  }

  END {
    if (replaced == 0) {
      exit 2
    }
  }
' "$DOC_PATH" > "$TMP_FILE"

mv "$TMP_FILE" "$DOC_PATH"
