# kedify-proxy

![Version: v0.0.1](https://img.shields.io/badge/Version-v0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v1.33.0](https://img.shields.io/badge/AppVersion-v1.33.0-informational?style=flat-square)

A Helm chart for Kedify proxy

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | [details](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) |
| autoscaling | object | `{"enabled":false,"horizontalPodAutoscalerConfig":{},"maxReplicaCount":3,"minReplicaCount":1,"scaledObjectName":""}` | mutually exclusive with `.deployment.replicas` |
| autoscaling.enabled | bool | `false` | Should the KEDA's `ScaledObject` be also rendered with the helm chart? |
| autoscaling.scaledObjectName | string | `""` | Name of the `ScaledObject` custom resource. If empty, release name is used. |
| config.clusterDomain | string | `"cluster.local"` |  |
| config.kedaNamespace | string | `"keda"` | namespace where Kedify HTTP addon is deployed |
| config.kedifyEnvoyCP | string | `"keda-add-ons-http-interceptor-kedify-proxy-metric-sink"` | service name of Kedify interceptor that serves as a control plane for configuration xDS and metrics |
| config.kedifyEnvoyCPPort | int | `5678` | port on kedify interceptor (`.config.kedifyEnvoyCP` host) from which the xDS config should be pulled |
| config.kedifyMetricsSinkPort | int | `9901` | port on kedify interceptor (`.config.kedifyEnvoyCP` host) where metrics from envoy data planes will be sent |
| config.nodeId | string | `"kedify-proxy"` |  |
| deployment.replicas | int | `1` | Fixed amount of replicas for the deployment. Use either `.autoscaling` section or this field. |
| deployment.rollingUpdate | object | `{}` | [docs](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/) |
| extraObjects | list | `[]` | Array of extra K8s manifests to deploy |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy, consult [docs](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| image.repository | string | `"envoyproxy/envoy"` | Image to use for the Deployment |
| image.tag | string | `""` | Image version to use for the Deployment, if not specified, it defaults to `.Chart.AppVersion` |
| imagePullSecrets | list | `[]` | Required for private image registries, consult [docs](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| logging.format | string | `"plaintext"` | Use: `plaintext` or `json` |
| nameOverride | string | `""` |  |
| noBanner | bool | `false` | should the ascii logo be printed when this helm chart is installed |
| nodeSelector | object | `{}` | [details](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) |
| pod.annotations | object | `{}` | custom annotations that should be added to the Kedify proxy pod |
| pod.containerSecurityContext | object | `{"runAsUser":101}` | container-lvl securityContext [docs](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) |
| pod.labels | object | `{}` | custom labels that should be added to the Kedify proxy pod |
| pod.livenessProbe | object | `{}` | custom timeouts and thresholds for liveness probe |
| pod.priorityClassName | string | `""` | [docs](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) |
| pod.readinessProbe | object | `{}` | custom timeouts and thresholds for readiness probe |
| pod.securityContext | object | `{}` | pod-lvl securityContext [docs](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) |
| podDisruptionBudget | object | `{"enabled":false,"spec":{}}` | [details](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) (not rendered by default) |
| resources | object | `{}` | resource definitions for envoy container, see [docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| service.adminPort | int | `9901` | port for admin interface of envoy |
| service.adminSvcNameOverride | string | `"kedify-proxy-admin"` | Name of the service that exposes admin port for envoy. If empty, `${releaseName}-admin` is used. |
| service.adminSvcType | string | `"ClusterIP"` | [docs](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| service.annotations | object | `{}` | custom annotations that should be added to both services |
| service.enabled | bool | `true` | Should the services be rendered with the helm chart? |
| service.exposeAdminInterface | bool | `true` | Should the admin service be also rendered with the helm chart? |
| service.httpPort | int | `8080` | port for plain text HTTP traffic |
| service.labels | object | `{}` | custom labels that should be added to both services |
| service.nameOverride | string | `"kedify-proxy"` | Name of the service that exposes HTTP and TLS ports. If empty, release name is used. |
| service.tlsPort | int | `8443` | port for TLS HTTP traffic |
| service.type | string | `"ClusterIP"` | [docs](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| tolerations | list | `[]` | [details](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) |
| topologySpreadConstraints | list | `[]` | [details](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/) |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[]` | Additional volumes on the output Deployment definition. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
