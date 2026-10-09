#!/usr/bin/env bash
set -euo pipefail
chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
render_dir="$(mktemp -d)"
trap 'rm -rf "$render_dir"' EXIT
render() {
  helm template discovery "$chart_dir" --namespace scaling-system --kube-version 1.35.5 \
    --values "$chart_dir/test/test-values.yaml" \
    --show-only templates/agent-deployment.yaml \
    --show-only templates/agent-rbac.yaml "$@"
}
role_rule_verbs() {
  ruby -ryaml -e '
    documents = YAML.load_stream(File.read(ARGV[0])).compact
    role = documents.find do |document|
      document["kind"] == "Role" && document.dig("metadata", "name") == "kedify-manager-role"
    end
    rule = role.fetch("rules").find do |candidate|
      candidate.fetch("apiGroups", []).include?(ARGV[1]) &&
        candidate.fetch("resources", []).include?(ARGV[2])
    end
    puts rule.fetch("verbs").sort.join(" ")
  ' "$1" "$2" "$3"
}
cluster_role_rule_verbs() {
  ruby -ryaml -e '
    documents = YAML.load_stream(File.read(ARGV[0])).compact
    role = documents.find do |document|
      document["kind"] == "ClusterRole" && document.dig("metadata", "name") == "kedify-manager-role"
    end
    rule = role.fetch("rules").find do |candidate|
      candidate.fetch("apiGroups", []).include?(ARGV[1]) &&
        candidate.fetch("resources", []).include?(ARGV[2])
    end
    puts rule.fetch("verbs").sort.join(" ")
  ' "$1" "$2" "$3"
}
render > "$render_dir/default.yaml"
render --set agent.features.multicluster.enabled=true > "$render_dir/legacy-agent.yaml"
render --set global.features.multicluster.enabled=true > "$render_dir/legacy-global.yaml"
render --set keda.enabled=true --set kpa.enabled=true \
  --set global.features.multicluster.enabled=true \
  --set global.features.multicluster.type=dedicated > "$render_dir/dedicated-agent.yaml"
for mode in agent global; do
  render --set "$mode.features.multicluster.vClusterDiscoveryEnabled=true" \
    --set agent.rbac.readServices=false > "$render_dir/$mode.yaml"
done
for mode in default legacy-agent legacy-global; do
  if grep -q 'MULTICLUSTER_VCLUSTER_DISCOVERY_ENABLED\|Discover native vCluster exports' "$render_dir/$mode.yaml"; then
    echo 'Discovery credentials/watch permissions must be opt-in' >&2
    exit 1
  fi
done
for mode in legacy-agent legacy-global; do
  grep -A1 'name: DSO_ENABLED' "$render_dir/$mode.yaml" | grep -q 'value: "true"'
  grep -A1 'name: DSJ_ENABLED' "$render_dir/$mode.yaml" | grep -q 'value: "true"'
done
grep -A1 'name: DSO_ENABLED' "$render_dir/dedicated-agent.yaml" | grep -q 'value: "false"'
grep -A1 'name: DSJ_ENABLED' "$render_dir/dedicated-agent.yaml" | grep -q 'value: "false"'
for mode in agent global; do
  grep -A1 'name: DSO_ENABLED' "$render_dir/$mode.yaml" | grep -q 'value: "false"'
  grep -A1 'name: DSJ_ENABLED' "$render_dir/$mode.yaml" | grep -q 'value: "false"'
  grep -A1 'name: MULTICLUSTER_VCLUSTER_DISCOVERY_ENABLED' "$render_dir/$mode.yaml" | grep -q 'value: "true"'
  grep -A3 '# Discover native vCluster exports' "$render_dir/$mode.yaml" | grep -q '"get", "list", "watch"'
  grep -A12 '# Copy the exact KEDA and KPA CRD schemas' "$render_dir/$mode.yaml" | grep -q 'kedifypodautoscalers.autoscaling.kedify.io'
  awk '/^kind: Role$/{role=1} role{print} /^---$/{role=0}' "$render_dir/$mode.yaml" > "$render_dir/$mode-roles.yaml"
  test "$(role_rule_verbs "$render_dir/$mode.yaml" multicluster.kedify.io clusterregistrations)" = 'create delete get list patch update watch'
  test "$(role_rule_verbs "$render_dir/$mode.yaml" '' secrets)" = 'create delete get list patch update watch'
done
# Agent-local and global discovery switches must render identical namespaced
# permissions. Discovery may add writes only for its generated registration and
# kubeconfig resources.
diff -u "$render_dir/agent-roles.yaml" "$render_dir/global-roles.yaml"
test "$(role_rule_verbs "$render_dir/legacy-agent.yaml" multicluster.kedify.io clusterregistrations)" = 'get list watch'
test "$(role_rule_verbs "$render_dir/legacy-agent.yaml" '' secrets)" = 'delete get list update watch'

# Deprecated flat values retain their independent DSO/DSJ behavior for one release.
render --set agent.features.distributedScaledObjectsEnabled=true > "$render_dir/legacy-dso.yaml"
grep -A1 'name: DSO_ENABLED' "$render_dir/legacy-dso.yaml" | grep -q 'value: "true"'
grep -A1 'name: DSJ_ENABLED' "$render_dir/legacy-dso.yaml" | grep -q 'value: "false"'
render --set global.features.distributedScaledJobsEnabled=true > "$render_dir/legacy-dsj.yaml"
grep -A1 'name: DSO_ENABLED' "$render_dir/legacy-dsj.yaml" | grep -q 'value: "false"'
grep -A1 'name: DSJ_ENABLED' "$render_dir/legacy-dsj.yaml" | grep -q 'value: "true"'
if grep -q 'MULTICLUSTER_VCLUSTER_DISCOVERY_ENABLED\|Discover native vCluster exports' "$render_dir/legacy-dsj.yaml"; then
  echo 'Legacy DSJ must not enable vCluster discovery' >&2
  exit 1
fi

# The shared global switch reaches the KEDA chart and enables DSJ raw metrics.
helm template keda "$chart_dir/../keda" --namespace scaling-system \
  --set global.features.multicluster.enabled=true \
  --show-only templates/manager/deployment.yaml > "$render_dir/keda.yaml"
grep -A1 'name: RAW_METRICS_GRPC_PROTOCOL' "$render_dir/keda.yaml" | grep -q 'value: enabled'
if grep -qE -- '--multicluster=true|--multicluster-registration-namespace=' "$render_dir/keda.yaml"; then
  echo 'The shared Agent DSO/DSJ switch must not enable KEDA remote reconciliation' >&2
  exit 1
fi

# KEDA's dedicated runtime is a separate switch. It must not be enabled by the
# Agent DSO/DSJ umbrella, and enabling it selects KPA without changing Agent
# controller environment variables.
helm template keda "$chart_dir/../keda" --namespace scaling-system \
  --set global.features.multicluster.enabled=true \
  --set global.features.multicluster.type=dedicated \
  --show-only templates/manager/deployment.yaml > "$render_dir/keda-dedicated.yaml"
grep -q -- '--multicluster=true' "$render_dir/keda-dedicated.yaml"
grep -q -- '--enable-kpa=true' "$render_dir/keda-dedicated.yaml"
grep -q -- '--autoscaling-default-class=kpa' "$render_dir/keda-dedicated.yaml"

for legacy_switch in \
  agent.features.multicluster.enabled \
  global.features.distributedScaledObjectsEnabled \
  agent.features.distributedScaledJobsEnabled; do
  if render --set keda.enabled=true --set kpa.enabled=true \
    --set global.features.multicluster.enabled=true \
    --set global.features.multicluster.type=dedicated \
    --set "$legacy_switch=true" > "$render_dir/conflict.yaml" 2> "$render_dir/error"; then
    echo "dedicated scaling must reject legacy Agent controller switch $legacy_switch" >&2
    exit 1
  fi
  grep -q 'dedicated multicluster scaling is mutually exclusive with the Agent DistributedScaledObject/DistributedScaledJob controllers' "$render_dir/error"
done
render --set keda.enabled=true --set kpa.enabled=true \
  --set global.features.multicluster.enabled=true \
  --set global.features.multicluster.type=dedicated \
  --set agent.multicluster.localCluster.enabled=true > "$render_dir/dedicated-local-agent.yaml"
grep -A1 'name: DSO_ENABLED' "$render_dir/dedicated-local-agent.yaml" | grep -q 'value: "false"'
grep -A1 'name: DSJ_ENABLED' "$render_dir/dedicated-local-agent.yaml" | grep -q 'value: "false"'
test "$(role_rule_verbs "$render_dir/dedicated-local-agent.yaml" '' secrets)" = 'create delete get list patch update watch'
test "$(cluster_role_rule_verbs "$render_dir/dedicated-local-agent.yaml" keda.sh scaledobjects)" = 'get list patch update watch'
test "$(cluster_role_rule_verbs "$render_dir/dedicated-local-agent.yaml" autoscaling.kedify.io kedifypodautoscalers)" = 'create delete get list patch update watch'
test "$(cluster_role_rule_verbs "$render_dir/dedicated-local-agent.yaml" '' secrets)" = 'get list watch'
test "$(cluster_role_rule_verbs "$render_dir/dedicated-local-agent.yaml" metrics.k8s.io pods)" = 'get list'

if render --set global.features.multicluster.type=invalid > /dev/null 2> "$render_dir/error"; then
  echo 'invalid multicluster type must be rejected' >&2
  exit 1
fi
grep -q 'global.features.multicluster.type must be distributed or dedicated' "$render_dir/error"
if render --set global.features.multicluster.enabled=true \
  --set global.features.multicluster.type=dedicated > /dev/null 2> "$render_dir/error"; then
  echo 'dedicated multicluster mode must require bundled KEDA' >&2
  exit 1
fi
grep -q 'dedicated multicluster scaling requires keda.enabled=true' "$render_dir/error"

if render --set keda.enabled=true \
  --set global.features.multicluster.enabled=true \
  --set global.features.multicluster.type=dedicated > /dev/null 2> "$render_dir/error"; then
  echo 'dedicated multicluster mode must require bundled KPA' >&2
  exit 1
fi
grep -q 'dedicated multicluster scaling requires kpa.enabled=true' "$render_dir/error"

# The parent chart wires dedicated mode into both bundled consumers. The
# default distributed type must retain DSO/DSJ and suppress KPA resources.
helm template discovery "$chart_dir" --namespace scaling-system \
  --kube-version 1.35.5 \
  --values "$chart_dir/test/test-values.yaml" \
  --set keda.enabled=true --set kpa.enabled=true \
  --set global.features.multicluster.enabled=true \
  --set global.features.multicluster.type=dedicated > "$render_dir/dedicated-full.yaml"
test "$(grep -c -- '--multicluster=true' "$render_dir/dedicated-full.yaml")" = '2'
grep -q 'app.kubernetes.io/part-of: kedify-pod-autoscaler' "$render_dir/dedicated-full.yaml"
grep -q -- '--keda-metrics-address=keda-operator.scaling-system.svc:9666' "$render_dir/dedicated-full.yaml"

helm template discovery "$chart_dir" --namespace scaling-system \
  --kube-version 1.35.5 \
  --values "$chart_dir/test/test-values.yaml" \
  --set keda.enabled=true --set kpa.enabled=true \
  --set global.features.multicluster.enabled=true > "$render_dir/distributed-full.yaml"
grep -A1 'name: DSO_ENABLED' "$render_dir/distributed-full.yaml" | grep -q 'value: "true"'
grep -A1 'name: DSJ_ENABLED' "$render_dir/distributed-full.yaml" | grep -q 'value: "true"'
if grep -q 'app.kubernetes.io/part-of: kedify-pod-autoscaler' "$render_dir/distributed-full.yaml"; then
  echo 'distributed mode must not render the KPA dependency' >&2
  exit 1
fi

helm template discovery "$chart_dir" --namespace scaling-system \
  --values "$chart_dir/test/test-values.yaml" \
  --set agent.multicluster.localCluster.enabled=true \
  --set agent.multicluster.localCluster.name=management \
  --show-only templates/local-cluster-registration.yaml > "$render_dir/local-registration.yaml"
grep -q '^kind: ClusterRegistration$' "$render_dir/local-registration.yaml"
grep -q 'multicluster.kedify.io/local-cluster: "true"' "$render_dir/local-registration.yaml"
grep -q 'clusterName: "management"' "$render_dir/local-registration.yaml"
grep -q 'context: "kedify-agent@management"' "$render_dir/local-registration.yaml"
grep -A2 'kubeconfigSecretRef:' "$render_dir/local-registration.yaml" | grep -q 'name: management'
if grep -q '^kind: Secret$' "$render_dir/local-registration.yaml"; then
  echo 'the local connection Secret must be materialized by the Agent, not contain file references rendered by Helm' >&2
  exit 1
fi
echo 'vCluster discovery rendering passed'
