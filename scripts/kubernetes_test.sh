#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
pr="$(bash kubernetes.sh matrix pull_request)"
push="$(bash kubernetes.sh matrix push)"
jq -e --argjson pr "$pr" 'length == 3 and .[:1] == $pr' <<<"$push" >/dev/null
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
cp kubernetes.sh "$fixture/"
for filter in '.[1] = .[0]' '.[0] |= sub("@.*"; "")' 'reverse'; do
  jq "$filter" kubernetes-versions.json > "$fixture/kubernetes-versions.json"
  if bash "$fixture/kubernetes.sh" matrix push >/dev/null 2>&1; then
    echo "accepted invalid Kubernetes selection: $filter" >&2
    exit 1
  fi
done
cat > "$fixture/kubectl" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  version) printf '{"serverVersion":{"gitVersion":"%s"}}' "$SERVER_VERSION" ;;
  get) printf '{"items":%s}' "$NODES" ;;
esac
STUB
chmod +x "$fixture/kubectl"
export PATH="$fixture:$PATH"
export SERVER_VERSION=v1.37.0 NODES='[{"status":{"nodeInfo":{"kubeletVersion":"v1.37.0"}}}]'
bash kubernetes.sh verify v1.37.0 >/dev/null
if bash kubernetes.sh verify v1.36.0 >/dev/null; then exit 1; fi
if NODES='[]' bash kubernetes.sh verify v1.37.0 >/dev/null; then exit 1; fi
if NODES='[{"status":{"nodeInfo":{"kubeletVersion":"v1.36.0"}}}]' bash kubernetes.sh verify v1.37.0 >/dev/null; then exit 1; fi
echo 'Kubernetes configuration checks passed'
