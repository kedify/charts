# kedify-proxy

![Version: v0.0.1](https://img.shields.io/badge/Version-v0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v1.33.0](https://img.shields.io/badge/AppVersion-v1.33.0-informational?style=flat-square)

A Helm chart for Kedify proxy

```
     _         _ _ ___       _            _ __  _ __ _____  ___   _
    | |_ ___ _| |_|  _|_ _  |_|___       | '_ \| '__/ _ \ \/ / | | |
    | '_| -_| . | |  _| | |_| | . |      | |_) | | | (_) >  <| |_| |
    |_,_|___|___|_|_| |_  |_|_|___|      | .__/|_|  \___/_/\_\\__, |
                      |___|              |_|                  |___/
```

## Usage

Check available version in OCI repo:
```
crane ls ghcr.io/kedify/charts/kedify-proxy | grep -E '^v?[0-9]'
```

Install specific version:
```
helm upgrade -i oci://ghcr.io/kedify/charts/kedify-proxy --version=v0.0.1
```

## Dependencies

This Helm Chart spawns a Kedify proxy which itself tries to connect to another envoy control plane. In order to see the pod with proxy up and running,
you need to first install the helm chart for KEDA and KEDA HTTP Addon:

```
helm repo add kedify https://kedify.github.io/charts
helm repo update kedify
helm upgrade -i keda kedifykeda/keda -nkeda --create-namespace --version ${kedaVersion}
helm upgrade -i keda-add-ons-http kedifykeda/keda-add-ons-http --nkeda --version ${httpAddonVersion}
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.repository | string | `"envoyproxy/envoy"` | Image to use for the Deployment |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy, consult [docs](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| image.tag | string | `""` | Image version to use for the Deployment, if not specified, it defaults to `.Chart.AppVersion` |
| imagePullSecrets | list | `[]` | Required for private image registries, consult [docs](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| logging.format | string | `"plaintext"` | Use: `plaintext` or `json` |
| config.kedaNamespace | string | `"keda"` | namespace where Kedify HTTP addon is deployed |
| config.kedifyEnvoyCP | string | `"keda-add-ons-http-interceptor-kedify-proxy-metric-sink"` | service name of Kedify interceptor that serves as a control plane for configuration xDS and metrics |
| config.kedifyEnvoyCPPort | int | `5678` | port on kedify interceptor (`.config.kedifyEnvoyCP` host) from which the xDS config should be pulled |
| config.kedifyMetricsSinkPort | int | `9901` | port on kedify interceptor (`.config.kedifyEnvoyCP` host) where metrics from envoy data planes will be sent |
| pod.annotations | object | `{}` | custom annotations that should be added to the Kedify proxy pod |
| pod.labels | object | `{}` | custom labels that should be added to the Kedify proxy pod |
| pod.securityContext | object | `{}` | pod-lvl securityContext [docs](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) |
| pod.containerSecurityContext | object | `{"runAsUser":101}` | container-lvl securityContext [docs](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) |
| pod.priorityClassName | string | `""` | [docs](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) |
| pod.livenessProbe | object | `{}` | custom timeouts and thresholds for liveness probe |
| pod.readinessProbe | object | `{}` | custom timeouts and thresholds for readiness probe |
| deployment.replicas | int | `1` | Fixed amount of replicas for the deployment. Use either `.autoscaling` section or this field. |
| deployment.rollingUpdate | object | `{}` | [docs](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/) |
| service.enabled | bool | `true` | Should the services be rendered with the helm chart? |
| service.nameOverride | string | `"kedify-proxy"` | Name of the service that exposes HTTP and TLS ports. If empty, release name is used. |
| service.type | string | `"ClusterIP"` | [docs](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| service.annotations | object | `{}` | custom annotations that should be added to both services |
| service.labels | object | `{}` | custom labels that should be added to both services |
| service.httpPort | int | `8080` | port for plain text HTTP traffic |
| service.tlsPort | int | `8443` | port for TLS HTTP traffic |
| service.exposeAdminInterface | bool | `true` | Should the admin service be also rendered with the helm chart? |
| service.adminSvcNameOverride | string | `"kedify-proxy-admin"` | Name of the service that exposes admin port for envoy. If empty, `${releaseName}-admin` is used. |
| service.adminSvcType | string | `"ClusterIP"` | [docs](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| service.adminPort | int | `9901` | port for admin interface of envoy |
| resources | object | `{}` | resource definitions for envoy container, see [docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| autoscaling | object | `{"enabled":false,"horizontalPodAutoscalerConfig":{},"maxReplicaCount":3,"minReplicaCount":1,"scaledObjectName":""}` | mutually exclusive with `.deployment.replicas` |
| autoscaling.enabled | bool | `false` | Should the KEDA's `ScaledObject` be also rendered with the helm chart? |
| autoscaling.scaledObjectName | string | `""` | Name of the `ScaledObject` custom resource. If empty, release name is used. |
| volumes | list | `[]` | Additional volumes on the output Deployment definition. |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| nodeSelector | object | `{}` | [details](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) |
| tolerations | list | `[]` | [details](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) |
| topologySpreadConstraints | list | `[]` | [details](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/) |
| affinity | object | `{}` | [details](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) |
| podDisruptionBudget | object | `{"enabled":false,"spec":{}}` | [details](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) (not rendered by default) |
| noBanner | bool | `false` | should the ascii logo be printed when this helm chart is installed |
| extraObjects | list | `[]` | Array of extra K8s manifests to deploy |

## Releasing

Run the action on this repo called Helm Publish (OCI) - [link](https://github.com/kedify/charts/actions/workflows/gh-release-oci-chart.yml).
You can provide the desired version of the helm chart as an input to the action or (if not provided) it will create a patch release.
It will also:
- create a tag in the repo
- modifies the `Chart.yaml` with increased version
- updates the docs in this `README.md` file.
