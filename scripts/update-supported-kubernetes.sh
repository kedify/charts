#!/usr/bin/env bash
# Run only after the released Agent chart passes every Kubernetes smoke test.
set -euo pipefail
cd "${1:?Marketing checkout required}"
: "${SUPPORTED_KUBERNETES_VERSIONS:?Validated minor versions required}"
: "${CHART_VERSION:?Released chart version required}"
: "${SOURCE_SHA:?Charts release commit required}"
: "${RUN_URL:?Successful release workflow URL required}"
repo=kedify/marketing
manifest=packages/docs/src/data/supported-kubernetes-versions.json
branch=automation/supported-kubernetes-versions
base=main

validate() {
  jq -ce '
    if type != "array" or length != 3 or any(.[]; type != "string" or (test("^1\\.[0-9]+$") | not))
    then error("expected three Kubernetes minor versions") else . end |
    map(split(".")[1] | tonumber) as $minors |
    if $minors != [$minors[0], $minors[0]-1, $minors[0]-2]
    then error("expected latest-first consecutive minors") else . end
  '
}
summary() { echo "$*" | tee -a "$GITHUB_STEP_SUMMARY"; }
candidate="$(validate <<< "$SUPPORTED_KUBERNETES_VERSIONS")"
current="$(validate < "$manifest")"
latest="$(jq -r '.[0] | split(".")[1] | tonumber' <<< "$candidate")"
current_latest="$(jq -r '.[0] | split(".")[1] | tonumber' <<< "$current")"
summary "Agent chart $CHART_VERSION passed HTTP and CPU smoke tests on Kubernetes $(jq -r 'join(", ")' <<< "$candidate"). [Release checks]($RUN_URL)."
if (( latest <= current_latest )); then
  summary 'The published support list is already current; no PR needed.'
  exit 0
fi

old_sha="$(git ls-remote --heads origin "refs/heads/$branch" | cut -f1)"
if [[ -n "$old_sha" ]]; then
  git fetch origin "$branch"
  branch_files="$(git diff --name-only "HEAD...$old_sha")"
  if git log --format='%ae%n%ce' "HEAD..$old_sha" | grep -Fvx 'kedifybot@kedify.io' >/dev/null ||
     [[ -n "$branch_files" && "$branch_files" != "$manifest" ]]; then
    echo 'The docs automation branch has other edits; review it before rerunning.' >&2
    exit 1
  fi
  pending="$(git show "$old_sha:$manifest" | validate)"
  pending_latest="$(jq -r '.[0] | split(".")[1] | tonumber' <<< "$pending")"
  if (( latest < pending_latest )); then
    summary 'A newer Kubernetes support update is already pending; keeping that PR.'
    exit 0
  fi
fi

printf '%s\n' "$candidate" | jq . > "$manifest"
if [[ -z "$old_sha" ]] || ! git merge-base --is-ancestor HEAD "$old_sha" ||
   ! git show "$old_sha:$manifest" | cmp -s - "$manifest"; then
  git switch -c "$branch"
  git config user.name 'Kedify Bot'
  git config user.email kedifybot@kedify.io
  git add -- "$manifest"
  git commit -s -m 'docs: update supported Kubernetes versions'
  git push --force-with-lease="refs/heads/$branch:$old_sha" origin "HEAD:refs/heads/$branch"
fi

labels="$(gh label list --repo "$repo" --limit 1000 --json name --jq '.[].name')"
if ! grep -Fxq version-bump <<< "$labels"; then
  gh label create version-bump --repo "$repo" --color 1d76db --description 'Automated version updates'
fi
body="$RUNNER_TEMP/supported-kubernetes-versions.md"
cat > "$body" <<EOF
Update the supported Kubernetes minor versions to $(jq -r 'join(", ")' <<< "$candidate").

Validated by the HTTP and CPU smoke checks for [Agent chart $CHART_VERSION](https://github.com/kedify/charts/releases/tag/kedify-agent/$CHART_VERSION).

- [Release checks]($RUN_URL)
- [Tested Kubernetes pins](https://github.com/kedify/charts/blob/$SOURCE_SHA/scripts/kubernetes-versions.json)
EOF
pr="$(gh pr list --repo "$repo" --head "$branch" --base "$base" --state open --json url --jq '.[0].url // empty')"
if [[ -n "$pr" ]]; then
  gh pr edit "$pr" --repo "$repo" --body-file "$body" --add-label version-bump
else
  pr="$(gh pr create --repo "$repo" --head "$branch" --base "$base" \
    --title 'docs: update supported Kubernetes versions' --body-file "$body" --label version-bump)"
fi
summary "Kubernetes support update: $pr"
