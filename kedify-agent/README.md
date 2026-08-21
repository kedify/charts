# kedify-agent

![Version: v0.6.8](https://img.shields.io/badge/Version-v0.6.8-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.6.8](https://img.shields.io/badge/AppVersion-v0.6.8-informational?style=flat-square)

Kedify agent - Helm Chart

**Homepage:** <https://github.com/kedify/charts>

## Source Code

* <https://github.com/kedify/agent>
* <https://github.com/kedify/charts>

## Requirements

Kubernetes: `>=v1.23.0-0`

| Repository | Name | Version |
|------------|------|---------|
| https://kedify.github.io/charts | keda | v2.20.2-0 |
| https://kedify.github.io/charts | keda-add-ons-http | v0.11.1-6 |
| oci://ghcr.io/kedify/charts | autoscaling-checks | 0.0.2 |
| oci://ghcr.io/kedify/charts | kedify-observability | 0.0.4 |
| oci://ghcr.io/kedify/charts | kedify-predictor | 0.1.6 |
| oci://ghcr.io/kedify/charts | otel-add-on | 0.1.4 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.features.distributedScalingEnabled | bool | `false` | Enable KEDA raw metrics gRPC for distributed scaling. |
| agent.features.scaleAdaptersEnabled | bool | `false` | Enable the ScaleAdapter controller that bridges HPA/KEDA to resources with an incomplete /scale subresource (e.g. Agones Fleet), or without one at all (spec.desiredReplicasPath). The agent additionally needs RBAC via agent.extraRbacRules: get + update on the target kinds' /scale subresource, or get, list, watch + update on the whole resource for targets adapted through replica field paths. |
| agent.features.kedifyPodAutoscalerEnabled | bool | `false` | Enable resource metrics collection and Prometheus endpoint discovery for Kedify Pod Autoscaler (KPA). KPA can be installed separately; leave disabled when its CRD/controller is not present |
| agent.multicluster.localCluster.enabled | bool | `false` | Register the KEDA cluster itself as a multi-cluster member. This grants the agent permissions to scale local Deployments and manage local Jobs. |
| agent.multicluster.localCluster.name | string | `"multicluster-local"` | Member-cluster alias. This is also the name of the generated kubeconfig Secret. |

