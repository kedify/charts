#!/usr/bin/env bash
set -euo pipefail
chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
render_dir="$(mktemp -d)"
trap 'rm -rf "$render_dir"' EXIT
render() {
  helm template discovery "$chart_dir" --namespace scaling-system --kube-version 1.35.5 \
    -f "$chart_dir/test/test-values.yaml" \
    --set keda.enabled=true --set kpa.enabled=true \
    --set global.features.multicluster.enabled=true \
    --set global.features.multicluster.type=dedicated "$@"
}
render --set global.features.multicluster.vClusterSecretDiscoveryEnabled=true > "$render_dir/global.yaml"
render --set agent.features.multicluster.vClusterSecretDiscoveryEnabled=true \
  --set keda.permissions.operator.restrict.secret=true \
  --set keda.rbac.enabledCustomScaledRefKinds=false > "$render_dir/agent.yaml"
for mode in global agent; do
  python3 - "$render_dir/$mode.yaml" <<'PYTEST'
import sys
import yaml

docs = [d for d in yaml.safe_load_all(open(sys.argv[1])) if d]
deployment = next(d for d in docs if d["kind"] == "Deployment" and d["metadata"]["name"] == "kedify-agent")
env = {e["name"]: e.get("value") for e in deployment["spec"]["template"]["spec"]["containers"][0]["env"]}
assert env["MULTICLUSTER_VCLUSTER_SECRET_DISCOVERY_ENABLED"] == "true", "discovery flag missing"
assert env.get("MULTICLUSTER_VCLUSTER_DISCOVERY_ENABLED") != "true", "native discovery enabled"
assert env["DSO_ENABLED"] == "false" and env["DSJ_ENABLED"] == "false", "distributed mode enabled"
# Audit every ClusterRole, including both autoscaler dependencies.
for role in (d for d in docs if d["kind"] == "ClusterRole"):
    for rule in role.get("rules", []):
        if not set(rule["apiGroups"]) & {"", "*"} or not set(rule["resources"]) & {"secrets", "*"}:
            continue
        assert not set(rule["verbs"]) & {"list", "watch", "*"}, "cluster-wide Secret read in " + role["metadata"]["name"]
        assert "get" not in rule["verbs"] or rule.get("resourceNames"), "unrestricted Secret get in " + role["metadata"]["name"]
role = next(d for d in docs if d["kind"] == "Role" and d["metadata"]["name"] == "kedify-manager-role")
registration = next(r for r in role["rules"] if "clusterregistrations" in r["resources"])
assert set(registration["verbs"]) >= {"create", "update", "patch", "delete"}, "registration write permissions missing"
secrets = next(r for r in role["rules"] if "secrets" in r["resources"])
assert "create" not in secrets["verbs"], "unexpected Secret creation permission"
PYTEST

done
for override in \
  global.features.multicluster.type=distributed \
  global.features.multicluster.vClusterDiscoveryEnabled=true \
  agent.multicluster.localCluster.enabled=true; do
  if render --set global.features.multicluster.vClusterSecretDiscoveryEnabled=true --set "$override" > "$render_dir/error.yaml" 2>&1; then
    echo "unsafe combination accepted: $override" >&2
    exit 1
  fi
done
echo 'Namespaced vCluster discovery rendering and RBAC checks passed'
