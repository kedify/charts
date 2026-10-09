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
| oci://ghcr.io/kedify/charts | kpa | 0.2.0 |

## Optional KPA installation

Set `kpa.enabled=true` to install the Kedify Pod Autoscaler controller and CRD
with the Agent chart on Kubernetes 1.33–1.35. Enable
`global.features.kedifyPodAutoscalerEnabled=true` for Agent support and
`keda.kedify.kpa.enabled=true` when using the bundled KEDA dependency. These
settings are disabled by default. Existing separate KPA installations can keep
`kpa.enabled=false`.

KPA defaults to the KEDA operator in the `keda` namespace. Override
`kpa.keda.metricsAddress` and `kpa.keda.metricsAuthority` when installing in
another namespace or using a different operator Service. Inspect the other
controller settings with `helm show values oci://ghcr.io/kedify/charts/kpa`.

Dedicated multicluster scaling requires both bundled controllers. Set
`global.features.multicluster.enabled=true`,
`global.features.multicluster.type=dedicated`, `keda.enabled=true`, and
`kpa.enabled=true`. This mode enables KEDA/KPA remote reconciliation and
selects KPA as KEDA's default autoscaling class. The default distributed mode
uses the Agent's DistributedScaledObject/DistributedScaledJob controllers and
suppresses the bundled KPA resources. With multicluster scaling disabled,
`kpa.enabled=true` installs KPA for single-cluster use.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kpa.enabled | bool | `false` | Install the optional Kedify Pod Autoscaler controller and CRD. Requires Kubernetes 1.33–1.35. Enable Agent and KEDA KPA support separately. |
| global.features.argoRolloutsEnabled | bool | `false` | Enable Argo Rollout targets for Pod Resource Profiles and Pod Resource Autoscalers by granting read-only Rollout RBAC. |
| global.features.multicluster | object | `{"enabled":false,"type":"distributed","vClusterDiscoveryEnabled":false}` | Enable multicluster scaling. The default distributed type preserves the existing Agent DSO/DSJ workflow; dedicated delegates each registered cluster to KEDA/KPA with its own replica target. |
| global.features.multicluster.type | string | `"distributed"` | Scaling model. distributed spreads global DSO/DSJ demand across clusters; dedicated scales each registered cluster separately through KEDA/KPA. |
| global.features.multicluster.vClusterDiscoveryEnabled | bool | `false` | Discover shared-node vClusters, install the live KEDA/KPA CRDs, and materialize ClusterRegistrations from native kubeconfig Secrets. Grants cluster-wide read access to Secrets and Services and read-only access to the required source CRDs. |
| global.features.distributedScaledObjectsEnabled | bool | `false` | Deprecated: use multicluster.enabled. Enables only the DistributedScaledObject controller during the compatibility period. |
| global.features.distributedScaledJobsEnabled | bool | `false` | Deprecated: use multicluster.enabled. Enables only the DistributedScaledJob controller and KEDA raw metrics gRPC during the compatibility period. |
| global.features.kedifyPodAutoscalerEnabled | bool | `false` | Enable resource metrics collection and Prometheus endpoint discovery for Kedify Pod Autoscaler (KPA). KPA can be installed separately; leave disabled when its CRD/controller is not present |
| agent.sharding | object | `{"pools":[]}` | Label-shard pools assigned by this Agent. Requires multitenant KEDA and KPA features. Each tenantRef names a separately installed, selector-capable tenant KEDA/KPA pair; the bundled KEDA dependency remains the ordinary, unsharded default installation. Pools are additions-only after enrollment; create them before adding SO/SJ resources. |
| agent.features.argoRolloutsEnabled | bool | `false` | Enable Argo Rollout targets for Pod Resource Profiles and Pod Resource Autoscalers by granting read-only Rollout RBAC. |
| agent.features.multicluster | object | `{"enabled":false,"vClusterDiscoveryEnabled":false}` | Enable the existing Agent DistributedScaledObject and DistributedScaledJob controllers. This does not enable KEDA's dedicated remote ScaledObject/ScaledJob runtime. |
| agent.features.multicluster.vClusterDiscoveryEnabled | bool | `false` | Discover shared-node vClusters, install the live KEDA/KPA CRDs, and materialize ClusterRegistrations from native kubeconfig Secrets. This is independent of the Agent DSO/DSJ controllers. Grants cluster-wide read access to Secrets and Services and read-only access to the required source CRDs. |
| agent.features.distributedScaledObjectsEnabled | bool | `false` | Deprecated: use multicluster.enabled. Enables only the DistributedScaledObject controller during the compatibility period. |
| agent.features.distributedScaledJobsEnabled | bool | `false` | Deprecated: use multicluster.enabled. Enables only the DistributedScaledJob controller during the compatibility period. |
| agent.features.scaleAdaptersEnabled | bool | `false` | Enable the ScaleAdapter controller that bridges HPA/KEDA to resources with an incomplete /scale subresource (e.g. Agones Fleet), or without one at all (spec.desiredReplicasPath). The agent additionally needs RBAC via agent.extraRbacRules: get + update on the target kinds' /scale subresource, or get, list, watch + update on the whole resource for targets adapted through replica field paths. |
| agent.features.kedifyPodAutoscalerEnabled | bool | `false` | Enable resource metrics collection and Prometheus endpoint discovery for Kedify Pod Autoscaler (KPA). KPA can be installed separately; leave disabled when its CRD/controller is not present |
| agent.sharding.pools | list | `[]` | Label-shard pools rendered in the Agent namespace as `kedify-agent-sharding` with a `pools.yaml` entry. Each pool has a name, explicit disjoint namespaces, optional `Rendezvous` or `LoadAware` strategy and `keyLabel`, and shards with unique `id` and `tenantRef` (`namespace/release`). Requires multi-tenant KEDA and KPA features. Each tenantRef names a separately installed, selector-capable tenant KEDA/KPA pair; the bundled KEDA dependency remains the ordinary, unsharded default installation. Create pools before adding SO/SJ resources; the Agent owns the enrollment annotation. |
| agent.multicluster.localCluster.enabled | bool | `false` | Register the management cluster through a ClusterRegistration. The Agent materializes and rotates its self-contained kubeconfig Secret. The registration can be consumed by dedicated KEDA/KPA mode or the existing Agent DSO/DSJ workflow and grants the Agent identity the required local scaling permissions. |
| agent.multicluster.localCluster.name | string | `"multicluster-local"` | Human-readable member-cluster identity. This is also the name of the generated ClusterRegistration and kubeconfig Secret. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
