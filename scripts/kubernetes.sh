#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  matrix)
    jq -ce --arg event "${2:?event name required}" '
      map(capture("^kindest/node:v1\\.(?<minor>[0-9]+)\\.[0-9]+@sha256:[a-f0-9]{64}$").minor | tonumber) as $minors |
      if length != 3 or ($minors | length != 3 or . != [.[0], .[0]-1, .[0]-2])
      then error("expected three digest-pinned images in latest-first consecutive minor order") else . end |
      (if $event == "pull_request" then .[:1] else . end) |
      map(. as $image | capture("^kindest/node:(?<version>v1\\.(?<minor>[0-9]+)\\.[0-9]+)@") |
        {kindImage: $image, kubectlVersion: .version, kubernetesVersion: ("v1." + .minor)})
    ' "$(dirname "${BASH_SOURCE[0]}")/kubernetes-versions.json"
    ;;
  verify)
    expected="${2:?expected version required}"
    kubectl version -o json | jq -e --arg expected "$expected" '.serverVersion.gitVersion == $expected'
    kubectl get nodes -o json | jq -e --arg expected "$expected" \
      '(.items | length) > 0 and all(.items[]; .status.nodeInfo.kubeletVersion == $expected)'
    ;;
  *) echo 'expected matrix <event> or verify <version>' >&2; exit 1 ;;
esac
