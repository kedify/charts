# keda-add-ons-http

![Version: v0.11.0-3](https://img.shields.io/badge/Version-v0.11.0--3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.11.0-3](https://img.shields.io/badge/AppVersion-v0.11.0--3-informational?style=flat-square)

Event-based autoscaler for HTTP workloads on Kubernetes

**Homepage:** <https://github.com/kedacore/http-add-on>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Jorge Turrado | <jorge_turrado@hotmail.es> |  |
| Zbynek Roubalik | <zbynek@kedify.io> |  |
| Jan Wozniak | <jan@kedify.io> |  |

## Source Code

* <https://github.com/kedacore/http-add-on>

## Requirements

Kubernetes: `>=v1.23.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| additionalLabels | object | `{}` | Additional labels to be applied to installed resources. Note that not all resources will receive these labels. |
| crds.install | bool | `true` | Whether to install the `HTTPScaledObject` [`CustomResourceDefinition`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) |
| logging.operator.level | string | `"info"` | Logging level for KEDA http-add-on operator. allowed values: `debug`, `info`, `error`, or an integer value greater than 0, specified as string |
| logging.operator.format | string | `"console"` | Logging format for KEDA http-add-on operator. allowed values: `json` or `console` |
| logging.operator.timeEncoding | string | `"rfc3339"` | Logging time encoding for KEDA http-add-on operator. allowed values are `epoch`, `millis`, `nano`, `iso8601`, `rfc3339` or `rfc3339nano` |
| logging.operator.stackTracesEnabled | bool | `false` | Display stack traces in the logs |
| logging.operator.kubeRbacProxy.level | int | `10` | Logging level for KEDA http-add-on operator rbac proxy allowed values: `0` for info, `4` for debug, or an integer value greater than 0 |
| logging.scaler.level | string | `"info"` | Logging level for KEDA http-add-on Scaler. allowed values: `debug`, `info`, `error`, or an integer value greater than 0, specified as string |
| logging.scaler.format | string | `"console"` | Logging format for KEDA http-add-on Scaler. allowed values: `json` or `console` |
| logging.scaler.timeEncoding | string | `"rfc3339"` | Logging time encoding for KEDA http-add-on Scaler. allowed values are `epoch`, `millis`, `nano`, `iso8601`, `rfc3339` or `rfc3339nano` |
| logging.scaler.stackTracesEnabled | bool | `false` | Display stack traces in the logs |
| logging.interceptor.level | string | `"info"` | Logging level for KEDA http-add-on Interceptor. allowed values: `debug`, `info`, `error`, or an integer value greater than 0, specified as string |
| logging.interceptor.format | string | `"console"` | Logging format for KEDA http-add-on Interceptor. allowed values: `json` or `console` |
| logging.interceptor.timeEncoding | string | `"rfc3339"` | Logging time encoding for KEDA http-add-on Interceptor. allowed values are `epoch`, `millis`, `nano`, `iso8601`, `rfc3339` or `rfc3339nano` |
| logging.interceptor.stackTracesEnabled | bool | `false` | Display stack traces in the logs |
| operator.replicas | int | `0` | Number of replicas, oerator k8s resources will not be installed if this is set to 0 |
| operator.imagePullSecrets | list | `[]` | The image pull secrets for the operator component |
| operator.watchNamespace | string | `""` | The namespace to watch for new `HTTPScaledObject`s. Leave this blank (i.e. `""`) to tell the operator to watch all namespaces. |
| operator.pullPolicy | string | `"Always"` | The image pull policy for the operator component |
| operator.resources.limits | object | `{"cpu":0.5,"memory":"64Mi"}` | The CPU/memory resource limit for the operator component |
| operator.resources.requests | object | `{"cpu":"250m","memory":"20Mi"}` | The CPU/memory resource request for the operator component |
| operator.port | int | `8443` | The port for the operator main server to run on |
| operator.nodeSelector | object | `{}` | Node selector for pod scheduling ([docs](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)) |
| operator.tolerations | list | `[]` | Tolerations for pod scheduling ([docs](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)) |
| operator.affinity | object | `{}` | Affinity for pod scheduling ([docs](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/)) |
| operator.podAnnotations | object | `{}` | Annotations to be added to the operator pods |
| operator.kubeRbacProxy.resources.limits | object | `{"cpu":"300m","memory":"200Mi"}` | The CPU/memory resource limit for the operator component's kube rbac proxy |
| operator.kubeRbacProxy.resources.requests | object | `{"cpu":"10m","memory":"20Mi"}` | The CPU/memory resource request for the operator component's kube rbac proxy |
| scaler.replicas | int | `1` | Number of replicas |
| scaler.imagePullSecrets | list | `[]` | The image pull secrets for the scaler component |
| scaler.service | string | `"external-scaler"` | The name of the Kubernetes `Service` for the scaler component |
| scaler.pullPolicy | string | `"Always"` | The image pull policy for the scaler component |
| scaler.grpcPort | int | `9090` | The port for the scaler's gRPC server. This is the server that KEDA will send scaling requests to. |
| scaler.pendingRequestsInterceptor | int | `200` | The number of "target requests" that the external scaler will report to KEDA for the interceptor's scaling metrics. See the [KEDA external scaler documentation](https://keda.sh/docs/2.4/concepts/external-scalers/) for details on target requests. |
| scaler.streamInterval | int | `200` | Interval in ms for communicating IsActive to KEDA |
| scaler.nodeSelector | object | `{}` | Node selector for pod scheduling ([docs](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)) |
| scaler.tolerations | list | `[]` | Tolerations for pod scheduling ([docs](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)) |
| scaler.affinity | object | `{}` | Affinity for pod scheduling ([docs](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/)) |
| scaler.podAnnotations | object | `{}` | Annotations to be added to the scaler pods |
| scaler.metrics | object | `{"port":2223}` | prometheus metrics endpoint |
| interceptor.clusterDomain | string | `"cluster.local"` | The cluster domain used for in cluster routing with envoy fleet |
| interceptor.imagePullSecrets | list | `[]` | The image pull secrets for the interceptor component |
| interceptor.pullPolicy | string | `"Always"` | The image pull policy for the interceptor component |
| interceptor.admin.service | string | `"interceptor-admin"` | The name of the Kubernetes `Service` for the interceptor's admin service |
| interceptor.admin.port | int | `9090` | The port for the interceptor's admin server to run on |
| interceptor.proxy.service | string | `"interceptor-proxy"` | The name of the Kubernetes `Service` for the interceptor's proxy service. This is the service that accepts live HTTP traffic. |
| interceptor.proxy.port | int | `8080` | The port on which the interceptor's proxy service will listen for live HTTP traffic |
| interceptor.metrics.service | string | `"interceptor-metrics"` | The name of the Kubernetes `Service` for the metrics. |
| interceptor.metrics.port | int | `2223` | The port to host metrics. |
| interceptor.replicas.min | int | `1` | The minimum number of interceptor replicas that should ever be running |
| interceptor.replicas.max | int | `3` | The maximum number of interceptor replicas that should ever be running |
| interceptor.replicas.waitTimeout | string | `"20m"` | The maximum time the interceptor should wait during cold start for an HTTP request to reach a backend before it is considered a failure |
| interceptor.strictEndpointSliceReadiness | object | `{"enabled":false}` | Whether the interceptor should wait for endpoints in the EndpointSlice to be strictly ready before starting to serve traffic |
| interceptor.scaledObject.pollingInterval | string | `nil` | The interval (in seconds) that KEDA should poll the external scaler to fetch scaling metrics about the interceptor |
| interceptor.scaledObject.waitForCrd | bool | `false` | when enabled, the scaled object will be installed as post-install hook which waits for the ScaledObject CRD to exist |
| interceptor.scaledObject.pendingRequestsTrigger | object | `{"enabled":false}` | Use the interceptor's `pendingRequests` metric to scale the interceptor When using kedify-proxy, this metric is not a good indicator of the load on the interceptor, so it is disabled by default. |
| interceptor.scaledObject.cpuTrigger | object | `{"enabled":true,"target":75}` | The CPU utilization threshold that KEDA should use to scale the interceptor |
| interceptor.scaledObject.memoryTrigger | object | `{"enabled":true,"target":90}` | The memory utilization threshold that KEDA should use to scale the interceptor |
| interceptor.tcpConnectTimeout | string | `"5m"` | https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/intro/terminology |
| interceptor.keepAlive | string | `"1s"` | The interceptor's connection keep alive timeout |
| interceptor.responseHeaderTimeout | string | `"30s"` | How long the interceptor will wait between forwarding a request to a backend and receiving response headers back before failing the request |
| interceptor.endpointsCachePollingIntervalMS | int | `20000` | How often (in milliseconds) the interceptor does a full refresh of its endpoints cache. The interceptor will also use Kubernetes events to stay up-to-date with the endpoints cache changes. This duration is the maximum time it will take to see changes to the endpoints. |
| interceptor.forceHTTP2 | bool | `true` | Whether or not the interceptor should force requests to use HTTP/2 |
| interceptor.maxIdleConns | int | `100` | The maximum number of idle connections allowed in the interceptor's in-memory connection pool. Set to 0 to indicate no limit |
| interceptor.idleConnTimeout | string | `"10m"` | The timeout after which any idle connection is closed and removed from the interceptor's in-memory connection pool. |
| interceptor.tlsHandshakeTimeout | string | `"10s"` | The maximum amount of time the interceptor will wait for a TLS handshake. Set to zero to indicate no timeout. |
| interceptor.expectContinueTimeout | string | `"1s"` | Special handling for responses with "Expect: 100-continue" response headers. see https://pkg.go.dev/net/http#Transport under the 'ExpectContinueTimeout' field for more details |
| interceptor.nodeSelector | object | `{}` | Node selector for pod scheduling ([docs](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)) |
| interceptor.tolerations | list | `[]` | Tolerations for pod scheduling ([docs](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)) |
| interceptor.affinity | object | `{}` | Affinity for pod scheduling ([docs](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/)) |
| interceptor.topologySpreadConstraints | list | `[]` | Topology spread constraints ([docs](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)) |
| interceptor.resources.limits | object | `{"cpu":0.5,"memory":"512Mi"}` | The CPU/memory resource limit for the operator component |
| interceptor.resources.requests | object | `{"cpu":"250m","memory":"20Mi"}` | The CPU/memory resource request for the operator component |
| interceptor.podAnnotations | object | `{}` | Annotations to be added to the interceptor pods |
| interceptor.tls.enabled | bool | `true` | Whether a TLS server should be started on the interceptor proxy |
| interceptor.tls.cert_path | string | `""` | Mount path of the certificate file to use with the interceptor proxy TLS server |
| interceptor.tls.key_path | string | `""` | Mount path of the certificate key file to use with the interceptor proxy TLS server |
| interceptor.tls.cert_secret | string | `""` | Name of the Kubernetes secret that contains the certificates to be used with the interceptor proxy TLS server |
| interceptor.tls.port | int | `8443` | Port that the interceptor proxy TLS server should be started on |
| interceptor.tls.allowCertsFromSecrets | bool | `true` | Allowing RBAC for Secrets for dynamic TLS certificates |
| interceptor.pdb.enabled | bool | `false` | Whether to install the `PodDisruptionBudget` for the interceptor |
| interceptor.pdb.minAvailable | int | `0` | The minimum number of replicas that should be available for the interceptor |
| interceptor.pdb.maxUnavailable | int | `1` | The maximum number of replicas that can be unavailable for the interceptor |
| interceptor.maintenancePage | object | `{"body":"Service is temporarily under maintenance. Please try again later.","responseStatusCode":503}` | Maintenance page configuration for the interceptor |
| interceptor.maintenancePage.body | string | `"Service is temporarily under maintenance. Please try again later."` | The HTML body displayed when maintenance mode for a certain application is enabled, limited to 256 KiB |
| interceptor.maintenancePage.responseStatusCode | int | `503` | The HTTP status code to return when maintenance mode for a certain application is enabled |
| interceptor.coldStartWaitingPage | object | `{"body":"Service is starting. Please try again later.","responseStatusCode":503,"retryAfter":"60s"}` | Cold start waiting page configuration defaults for the interceptor |
| interceptor.coldStartWaitingPage.body | string | `"Service is starting. Please try again later."` | The HTML body displayed when the application has cold-start waiting page enabled, limited to 256 KiB |
| interceptor.coldStartWaitingPage.responseStatusCode | int | `503` | The HTTP status code to return when the application has cold-start waiting page enabled |
| interceptor.coldStartWaitingPage.retryAfter | string | `"60s"` | Value in the `Retry-After` header to return when the application has cold-start waiting page enabled |
| interceptor.xds | object | `{"keepalive":{"enforcementPolicyMinTime":"30s","time":"30s","timeout":"5s"},"maxConcurrentStreams":1000000}` | Configuration options for the envoy xDS control-plane |
| images.tag | string | `"v0.11.0-3"` | Image tag for the http add on. This tag is applied to the images listed in `images.operator`, `images.interceptor`, and `images.scaler`. Optional, given app version of Helm chart is used by default |
| images.operator | string | `"ghcr.io/kedify/http-add-on-operator"` | Image name for the operator image component |
| images.interceptor | string | `"ghcr.io/kedify/http-add-on-interceptor"` | Image name for the interceptor image component |
| images.scaler | string | `"ghcr.io/kedify/http-add-on-scaler"` | Image name for the scaler image component |
| images.kubeRbacProxy.name | string | `"gcr.io/kubebuilder/kube-rbac-proxy"` | Image name for the Kube RBAC Proxy image component |
| images.kubeRbacProxy.tag | string | `"v0.16.0"` | Image tag for the Kube RBAC Proxy image component |
| rbac.aggregateToDefaultRoles | bool | `false` | Install aggregate roles for edit and view |
| securityContext | object | [See below](#KEDA-is-secure-by-default) | [Security context] for all containers |
| profiling.operator.enabled | bool | `false` | Enable profiling for KEDA http-add-on Operator |
| profiling.operator.port | int | `8085` | Expose profiling on a specific port |
| profiling.interceptor.enabled | bool | `false` | Enable profiling for KEDA http-add-on Interceptor |
| profiling.interceptor.port | int | `8086` | Expose profiling on a specific port |
| profiling.scaler.enabled | bool | `false` | Enable profiling for KEDA http-add-on Scaler |
| profiling.scaler.port | int | `8087` | Expose profiling on a specific port |
| grpcBridge | object | `{"enabled":false,"metricPushPeriod":"1s","port":50051}` | gRPC bridge between external-scaler and interceptor serves as a replacement of the legacy REST /queue endpoint |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
