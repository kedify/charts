# kedify-agent

![Version: v0.8.0](https://img.shields.io/badge/Version-v0.8.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.8.0](https://img.shields.io/badge/AppVersion-v0.8.0-informational?style=flat-square)

Kedify agent - Helm Chart

**Homepage:** <https://github.com/kedify/charts>

## Source Code

* <https://github.com/kedify/agent>
* <https://github.com/kedify/charts>

## Requirements

Kubernetes: `>=v1.23.0-0`

| Repository | Name | Version |
|------------|------|---------|
| https://kedify.github.io/charts | keda | v2.21.0-0 |
| https://kedify.github.io/charts | keda-add-ons-http | v0.11.1-6 |
| oci://ghcr.io/kedify/charts | autoscaling-checks | 0.0.2 |
| oci://ghcr.io/kedify/charts | kedify-observability | 0.0.4 |
| oci://ghcr.io/kedify/charts | kedify-predictor | 0.1.6 |
| oci://ghcr.io/kedify/charts | otel-add-on | 0.1.4 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.features.argoRolloutsEnabled | bool | `false` | Enable Argo Rollout targets for Pod Resource Profiles and Pod Resource Autoscalers by granting read-only Rollout RBAC. |
| global.features.multicluster | object | `{"enabled":false,"vClusterDiscoveryEnabled":false}` | Enable DistributedScaledObject and DistributedScaledJob controllers and bundled KEDA raw metrics gRPC. |
| global.features.multicluster.vClusterDiscoveryEnabled | bool | `false` | Discover shared-node vClusters from native kubeconfig Secrets. Grants cluster-wide read access to Secrets and Services. |
| global.features.distributedScaledObjectsEnabled | bool | `false` | Deprecated: use multicluster.enabled. Enables only the DistributedScaledObject controller during the compatibility period. |
| global.features.distributedScaledJobsEnabled | bool | `false` | Deprecated: use multicluster.enabled. Enables only the DistributedScaledJob controller and KEDA raw metrics gRPC during the compatibility period. |
| global.features.kedifyPodAutoscalerEnabled | bool | `false` | Enable resource metrics collection and Prometheus endpoint discovery for Kedify Pod Autoscaler (KPA). KPA can be installed separately; leave disabled when its CRD/controller is not present |
| agent.features.argoRolloutsEnabled | bool | `false` | Enable Argo Rollout targets for Pod Resource Profiles and Pod Resource Autoscalers by granting read-only Rollout RBAC. |
| agent.features.multicluster | object | `{"enabled":false,"vClusterDiscoveryEnabled":false}` | Enable DistributedScaledObject and DistributedScaledJob controllers. Use the global setting when this chart installs KEDA. |
| agent.features.multicluster.vClusterDiscoveryEnabled | bool | `false` | Discover shared-node vClusters from native kubeconfig Secrets. Grants cluster-wide read access to Secrets and Services. |
| agent.features.distributedScaledObjectsEnabled | bool | `false` | Deprecated: use multicluster.enabled. Enables only the DistributedScaledObject controller during the compatibility period. |
| agent.features.distributedScaledJobsEnabled | bool | `false` | Deprecated: use multicluster.enabled. Enables only the DistributedScaledJob controller during the compatibility period. |
| agent.features.scaleAdaptersEnabled | bool | `false` | Enable the ScaleAdapter controller that bridges HPA/KEDA to resources with an incomplete /scale subresource (e.g. Agones Fleet), or without one at all (spec.desiredReplicasPath). The agent additionally needs RBAC via agent.extraRbacRules: get + update on the target kinds' /scale subresource, or get, list, watch + update on the whole resource for targets adapted through replica field paths. |
| agent.features.kedifyPodAutoscalerEnabled | bool | `false` | Enable resource metrics collection and Prometheus endpoint discovery for Kedify Pod Autoscaler (KPA). KPA can be installed separately; leave disabled when its CRD/controller is not present |
| agent.sharding.pools | list | `[]` | Label-shard pools rendered in the Agent namespace as `kedify-agent-sharding` with a `pools.yaml` entry. Each pool has a name, explicit disjoint namespaces, optional `Rendezvous` or `LoadAware` strategy and `keyLabel`, and shards with unique `id` and `tenantRef` (`namespace/release`). Requires multi-tenant KEDA and KPA features. Each tenantRef names a separately installed, selector-capable tenant KEDA/KPA pair; the bundled KEDA dependency remains the ordinary, unsharded default installation. Create pools before adding SO/SJ resources; the Agent owns the enrollment annotation. |
| agent.multicluster.localCluster.enabled | bool | `false` | Register the KEDA cluster itself as a multi-cluster member. This grants the agent permissions to scale local Deployments and manage local Jobs. |
| agent.multicluster.localCluster.name | string | `"multicluster-local"` | Member-cluster alias. This is also the name of the generated kubeconfig Secret. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
