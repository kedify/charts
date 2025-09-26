# keda

![Version: v2.17.2-0](https://img.shields.io/badge/Version-v2.17.2--0-informational?style=flat-square) ![AppVersion: v2.17.2-0](https://img.shields.io/badge/AppVersion-v2.17.2--0-informational?style=flat-square)

Event-based autoscaler for workloads on Kubernetes

**Homepage:** <https://github.com/kedacore/keda>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Zbynek Roubalik | <zbynek@kedify.io> |  |
| Jan Wozniak | <jan@kedify.io> |  |

## Source Code

* <https://github.com/kedacore/keda>

## Requirements

Kubernetes: `>=v1.23.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.image.registry | string | `nil` | Global image registry of KEDA components |
| global.dnsConfig | object | `{}` | DNS config for KEDA components |
| image.keda.registry | string | `"ghcr.io"` | Image registry of KEDA operator |
| image.keda.repository | string | `"kedify/keda-operator"` | Image name of KEDA operator |
| image.keda.tag | string | `"v2.17.2-0"` | Image tag of KEDA operator. Optional, given app version of Helm chart is used by default |
| image.metricsApiServer.registry | string | `"ghcr.io"` | Image registry of KEDA Metrics API Server |
| image.metricsApiServer.repository | string | `"kedify/keda-metrics-apiserver"` | Image name of KEDA Metrics API Server |
| image.metricsApiServer.tag | string | `"v2.17.2-0"` | Image tag of KEDA Metrics API Server. Optional, given app version of Helm chart is used by default |
| image.webhooks.registry | string | `"ghcr.io"` | Image registry of KEDA admission-webhooks |
| image.webhooks.repository | string | `"kedify/keda-admission-webhooks"` | Image name of KEDA admission-webhooks |
| image.webhooks.tag | string | `"v2.17.2-0"` | Image tag of KEDA admission-webhooks . Optional, given app version of Helm chart is used by default |
| image.pullPolicy | string | `"Always"` | Image pullPolicy for all KEDA components |
| clusterName | string | `"kubernetes-default"` | Kubernetes cluster name. Used in features such as emitting CloudEvents |
| clusterDomain | string | `"cluster.local"` | Kubernetes cluster domain |
| crds.install | bool | `true` | Defines whether the KEDA CRDs have to be installed or not. |
| crds.additionalAnnotations | object | `{}` | Custom annotations specifically for CRDs |
| watchNamespace | string | `""` | Defines Kubernetes namespaces to watch to scale their workloads. Default watches all namespaces |
| imagePullSecrets | list | `[]` | Name of secret to use to pull images to use to pull Docker images |
| networkPolicy.enabled | bool | `false` | Enable network policies |
| networkPolicy.flavor | string | `"cilium"` | Flavor of the network policies (cilium) |
| networkPolicy.cilium | object | `{"operator":{"extraEgressRules":[]}}` | Allow use of extra egress rules for cilium network policies |
| operator.name | string | `"keda-operator"` | Name of the KEDA operator |
| operator.revisionHistoryLimit | int | `10` | ReplicaSets for this Deployment you want to retain (Default: 10) |
| operator.replicaCount | int | `1` | Capability to configure the number of replicas for KEDA operator. While you can run more replicas of our operator, only one operator instance will be the leader and serving traffic. You can run multiple replicas, but they will not improve the performance of KEDA, it could only reduce downtime during a failover. Learn more in [our documentation](https://keda.sh/docs/latest/operate/cluster/#high-availability). |
| operator.disableCompression | bool | `true` | Disable response compression for k8s restAPI in client-go. Disabling compression simply means that turns off the process of making data smaller for K8s restAPI in client-go for faster transmission. |
| operator.dnsConfig | object | `{}` | DNS config for KEDA operator pod |
| operator.affinity | object | `{}` | [Affinity] for pod scheduling for KEDA operator. Takes precedence over the `affinity` field |
| operator.extraContainers | list | `[]` | Additional containers to run as part of the operator deployment |
| operator.extraInitContainers | list | `[]` | Additional init containers to run as part of the operator deployment |
| operator.livenessProbe | object | `{"failureThreshold":3,"initialDelaySeconds":25,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Liveness probes for operator ([docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)) |
| operator.readinessProbe | object | `{"failureThreshold":3,"initialDelaySeconds":20,"periodSeconds":3,"successThreshold":1,"timeoutSeconds":1}` | Readiness probes for operator ([docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes)) |
| metricsServer.revisionHistoryLimit | int | `10` | ReplicaSets for this Deployment you want to retain (Default: 10) |
| metricsServer.replicaCount | int | `1` | Capability to configure the number of replicas for KEDA metric server. While you can run more replicas of our metric server, only one instance will used and serve traffic. You can run multiple replicas, but they will not improve the performance of KEDA, it could only reduce downtime during a failover. Learn more in [our documentation](https://keda.sh/docs/latest/operate/cluster/#high-availability). |
| metricsServer.disableCompression | bool | `true` | Disable response compression for k8s restAPI in client-go. Disabling compression simply means that turns off the process of making data smaller for K8s restAPI in client-go for faster transmission. |
| metricsServer.dnsPolicy | string | `"ClusterFirst"` | Defined the DNS policy for the metric server |
| metricsServer.dnsConfig | object | `{}` | DNS config for KEDA metrics server pod |
| metricsServer.useHostNetwork | bool | `false` | Enable metric server to use host network |
| metricsServer.affinity | object | `{}` | [Affinity] for pod scheduling for Metrics API Server. Takes precedence over the `affinity` field |
| metricsServer.livenessProbe | object | `{"failureThreshold":3,"initialDelaySeconds":5,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Liveness probes for Metrics API Server ([docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)) |
| metricsServer.readinessProbe | object | `{"failureThreshold":3,"initialDelaySeconds":5,"periodSeconds":3,"successThreshold":1,"timeoutSeconds":1}` | Readiness probes for Metrics API Server ([docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes)) |
| webhooks.port | string | `""` | Port number to use for KEDA admission webhooks. Default is 9443. |
| webhooks.healthProbePort | int | `8081` | Port number to use for KEDA admission webhooks health probe |
| webhooks.dnsConfig | object | `{}` | DNS config for KEDA admission webhooks pod |
| webhooks.livenessProbe | object | `{"failureThreshold":3,"initialDelaySeconds":25,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Liveness probes for admission webhooks ([docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)) |
| webhooks.readinessProbe | object | `{"failureThreshold":3,"initialDelaySeconds":20,"periodSeconds":3,"successThreshold":1,"timeoutSeconds":1}` | Readiness probes for admission webhooks ([docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes)) |
| webhooks.timeoutSeconds | int | `10` | Timeout in seconds for KEDA admission webhooks |
| webhooks.useHostNetwork | bool | `false` | Enable webhook to use host network, this is required on EKS with custom CNI |
| webhooks.name | string | `"keda-admission-webhooks"` | Name of the KEDA admission webhooks |
| webhooks.revisionHistoryLimit | int | `10` | ReplicaSets for this Deployment you want to retain (Default: 10) |
| webhooks.replicaCount | int | `1` | Capability to configure the number of replicas for KEDA admission webhooks |
| webhooks.affinity | object | `{}` | [Affinity] for pod scheduling for KEDA admission webhooks. Takes precedence over the `affinity` field |
| webhooks.failurePolicy | string | `"Ignore"` | [Failure policy](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#failure-policy) to use with KEDA admission webhooks |
| upgradeStrategy.operator | object | `{}` | Capability to configure [Deployment upgrade strategy] for operator |
| upgradeStrategy.metricsApiServer | object | `{}` | Capability to configure [Deployment upgrade strategy] for Metrics Api Server |
| upgradeStrategy.webhooks | object | `{}` | Capability to configure [Deployment upgrade strategy] for Admission webhooks |
| podDisruptionBudget.operator | object | `{}` | Capability to configure [Pod Disruption Budget] |
| podDisruptionBudget.metricServer | object | `{}` | Capability to configure [Pod Disruption Budget] |
| podDisruptionBudget.webhooks | object | `{}` | Capability to configure [Pod Disruption Budget] |
| additionalLabels | object | `{}` | Custom labels to add into metadata |
| additionalAnnotations | object | `{}` | Custom annotations to add into metadata |
| podAnnotations.keda | object | `{}` | Pod annotations for KEDA operator |
| podAnnotations.metricsAdapter | object | `{}` | Pod annotations for KEDA Metrics Adapter |
| podAnnotations.webhooks | object | `{}` | Pod annotations for KEDA Admission webhooks |
| podLabels.keda | object | `{}` | Pod labels for KEDA operator |
| podLabels.metricsAdapter | object | `{}` | Pod labels for KEDA Metrics Adapter |
| podLabels.webhooks | object | `{}` | Pod labels for KEDA Admission webhooks |
| rbac.create | bool | `true` | Specifies whether RBAC should be used |
| rbac.aggregateToDefaultRoles | bool | `false` | Specifies whether RBAC for CRDs should be [aggregated](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#aggregated-clusterroles) to default roles (view, edit, admin) |
| rbac.enabledCustomScaledRefKinds | bool | `true` | Whether RBAC for configured CRDs that can have a `scale` subresource should be created |
| rbac.controlPlaneServiceAccountsNamespace | string | `"kube-system"` | Customize the namespace of k8s metrics-server deployment This could also be achieved by the Kubernetes control plane manager flag --use-service-account-credentials: [docs](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/) |
| rbac.scaledRefKinds | list | `[{"apiGroup":"*","kind":"*"}]` | List of custom resources that support the `scale` subresource and can be referenced by `scaledobject.spec.scaleTargetRef`. The feature needs to be also enabled by `enabledCustomScaledRefKinds`. If left empty, RBAC for `apiGroups: *` and `resources: *, */scale` will be created note: Deployments and StatefulSets are supported out of the box |
| serviceAccount.operator.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.operator.name | string | `"keda-operator"` | The name of the service account to use. |
| serviceAccount.operator.automountServiceAccountToken | bool | `true` | Specifies whether a service account should automount API-Credentials |
| serviceAccount.operator.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.metricServer.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.metricServer.name | string | `"keda-metrics-server"` | The name of the service account to use. |
| serviceAccount.metricServer.automountServiceAccountToken | bool | `true` | Specifies whether a service account should automount API-Credentials |
| serviceAccount.metricServer.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.webhooks.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.webhooks.name | string | `"keda-webhook"` | The name of the service account to use. |
| serviceAccount.webhooks.automountServiceAccountToken | bool | `true` | Specifies whether a service account should automount API-Credentials |
| serviceAccount.webhooks.annotations | object | `{}` | Annotations to add to the service account |
| podIdentity.azureWorkload.enabled | bool | `false` | Set to true to enable Azure Workload Identity usage. See https://keda.sh/docs/concepts/authentication/#azure-workload-identity This will be set as a label on the KEDA service account. |
| podIdentity.azureWorkload.clientId | string | `""` | Id of Azure Active Directory Client to use for authentication with Azure Workload Identity. ([docs](https://keda.sh/docs/concepts/authentication/#azure-workload-identity)) |
| podIdentity.azureWorkload.tenantId | string | `""` | Id Azure Active Directory Tenant to use for authentication with for Azure Workload Identity. ([docs](https://keda.sh/docs/concepts/authentication/#azure-workload-identity)) |
| podIdentity.azureWorkload.tokenExpiration | int | `3600` | Duration in seconds to automatically expire tokens for the service account. ([docs](https://keda.sh/docs/concepts/authentication/#azure-workload-identity)) |
| podIdentity.aws.irsa.enabled | bool | `false` | Specifies whether [AWS IAM Roles for Service Accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) is to be enabled or not. |
| podIdentity.aws.irsa.audience | string | `"sts.amazonaws.com"` | Sets the token audience for IRSA. This will be set as an annotation on the KEDA service account. |
| podIdentity.aws.irsa.roleArn | string | `""` | Set to the value of the ARN of an IAM role with a web identity provider. This will be set as an annotation on the KEDA service account. |
| podIdentity.aws.irsa.stsRegionalEndpoints | string | `"true"` | Sets the use of an STS regional endpoint instead of global. Recommended to use regional endpoint in almost all cases. This will be set as an annotation on the KEDA service account. |
| podIdentity.aws.irsa.tokenExpiration | int | `86400` | Set to the value of the service account token expiration duration. This will be set as an annotation on the KEDA service account. |
| podIdentity.gcp.enabled | bool | `false` | Set to true to enable GCP Workload Identity. See https://keda.sh/docs/2.10/authentication-providers/gcp-workload-identity/ This will be set as a annotation on the KEDA service account. |
| podIdentity.gcp.gcpIAMServiceAccount | string | `""` | GCP IAM Service Account Email which you would like to use for workload identity. |
| grpcTLSCertsSecret | string | `""` | Set this if you are using an external scaler and want to communicate over TLS (recommended). This variable holds the name of the secret that will be mounted to the /grpccerts path on the Pod |
| hashiCorpVaultTLS | string | `""` | Set this if you are using HashiCorp Vault and want to communicate over TLS (recommended). This variable holds the name of the secret that will be mounted to the /vault path on the Pod |
| logging.operator.level | string | `"info"` | Logging level for KEDA Operator. allowed values: `debug`, `info`, `error`, or an integer value greater than 0, specified as string |
| logging.operator.format | string | `"console"` | Logging format for KEDA Operator. allowed values: `json` or `console` |
| logging.operator.timeEncoding | string | `"rfc3339"` | Logging time encoding for KEDA Operator. allowed values are `epoch`, `millis`, `nano`, `iso8601`, `rfc3339` or `rfc3339nano` |
| logging.operator.stackTracesEnabled | bool | `false` | If enabled, the stack traces will be also printed |
| logging.metricServer.level | int | `0` | Logging level for Metrics Server. allowed values: `0` for info, `4` for debug, or an integer value greater than 0, specified as string |
| logging.metricServer.stderrthreshold | string | `"ERROR"` | Logging stderrthreshold for Metrics Server allowed values: 'DEBUG','INFO','WARN','ERROR','ALERT','EMERG' |
| logging.webhooks.level | string | `"info"` | Logging level for KEDA Operator. allowed values: `debug`, `info`, `error`, or an integer value greater than 0, specified as string |
| logging.webhooks.format | string | `"console"` | Logging format for KEDA Admission webhooks. allowed values: `json` or `console` |
| logging.webhooks.timeEncoding | string | `"rfc3339"` | Logging time encoding for KEDA Operator. allowed values are `epoch`, `millis`, `nano`, `iso8601`, `rfc3339` or `rfc3339nano` |
| securityContext | object | [See below](#KEDA-is-secure-by-default) | [Security context] for all containers |
| securityContext.operator | object | [See below](#KEDA-is-secure-by-default) | [Security context] of the operator container |
| securityContext.metricServer | object | [See below](#KEDA-is-secure-by-default) | [Security context] of the metricServer container |
| securityContext.webhooks | object | [See below](#KEDA-is-secure-by-default) | [Security context] of the admission webhooks container |
| podSecurityContext | object | [See below](#KEDA-is-secure-by-default) | [Pod security context] for all pods |
| podSecurityContext.operator | object | [See below](#KEDA-is-secure-by-default) | [Pod security context] of the KEDA operator pod |
| podSecurityContext.metricServer | object | [See below](#KEDA-is-secure-by-default) | [Pod security context] of the KEDA metrics apiserver pod |
| podSecurityContext.webhooks | object | [See below](#KEDA-is-secure-by-default) | [Pod security context] of the KEDA admission webhooks |
| service.type | string | `"ClusterIP"` | KEDA Metric Server service type |
| service.portHttps | int | `443` | HTTPS port for KEDA Metric Server service |
| service.portHttpsTarget | int | `6443` | HTTPS port for KEDA Metric Server container |
| service.annotations | object | `{}` | Annotations to add the KEDA Metric Server service |
| resources.operator | object | `{"limits":{"cpu":1,"memory":"1000Mi"},"requests":{"cpu":"100m","memory":"100Mi"}}` | Manage [resource request & limits] of KEDA operator pod |
| resources.metricServer | object | `{"limits":{"cpu":1,"memory":"1000Mi"},"requests":{"cpu":"100m","memory":"100Mi"}}` | Manage [resource request & limits] of KEDA metrics apiserver pod |
| resources.webhooks | object | `{"limits":{"cpu":1,"memory":"1000Mi"},"requests":{"cpu":"100m","memory":"100Mi"}}` | Manage [resource request & limits] of KEDA admission webhooks pod |
| nodeSelector | object | `{}` | Node selector for pod scheduling ([docs](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)) |
| tolerations | list | `[]` | Tolerations for pod scheduling ([docs](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)) |
| hostAliases | list | `[]` | HostAliases for pod networking ([docs](https://kubernetes.io/docs/concepts/services-networking/add-entries-to-pod-etc-hosts-with-host-aliases/)) |
| topologySpreadConstraints.operator | list | `[]` | [Pod Topology Constraints] of KEDA operator pod |
| topologySpreadConstraints.metricsServer | list | `[]` | [Pod Topology Constraints] of KEDA metrics apiserver pod |
| topologySpreadConstraints.webhooks | list | `[]` | [Pod Topology Constraints] of KEDA admission webhooks pod |
| affinity | object | `{}` | [Affinity] for pod scheduling for KEDA operator, Metrics API Server and KEDA admission webhooks. |
| priorityClassName | string | `""` | priorityClassName for all KEDA components |
| http.timeout | int | `3000` | The default HTTP timeout to use for all scalers that use raw HTTP clients (some scalers use SDKs to access target services. These have built-in HTTP clients, and the timeout does not necessarily apply to them) |
| http.keepAlive.enabled | bool | `true` | Enable HTTP connection keep alive |
| http.minTlsVersion | string | `"TLS12"` | The minimum TLS version to use for all scalers that use raw HTTP clients (some scalers use SDKs to access target services. These have built-in HTTP clients, and this value does not necessarily apply to them) |
| profiling.operator.enabled | bool | `false` | Enable profiling for KEDA operator |
| profiling.operator.port | int | `8082` | Expose profiling on a specific port |
| profiling.metricsServer.enabled | bool | `false` | Enable profiling for KEDA metrics server |
| profiling.metricsServer.port | int | `8083` | Expose profiling on a specific port |
| profiling.webhooks.enabled | bool | `false` | Enable profiling for KEDA admission webhook |
| profiling.webhooks.port | int | `8084` | Expose profiling on a specific port |
| extraArgs.keda | object | `{}` | Additional KEDA Operator container arguments |
| extraArgs.metricsAdapter | object | `{}` | Additional Metrics Adapter container arguments |
| env | list | `[]` | Additional environment variables that will be passed onto all KEDA components |
| volumes.keda.extraVolumes | list | `[]` | Extra volumes for KEDA deployment |
| volumes.keda.extraVolumeMounts | list | `[]` | Extra volume mounts for KEDA deployment |
| volumes.metricsApiServer.extraVolumes | list | `[]` | Extra volumes for metric server deployment |
| volumes.metricsApiServer.extraVolumeMounts | list | `[]` | Extra volume mounts for metric server deployment |
| volumes.webhooks.extraVolumes | list | `[]` | Extra volumes for admission webhooks deployment |
| volumes.webhooks.extraVolumeMounts | list | `[]` | Extra volume mounts for admission webhooks deployment |
| prometheus.metricServer.enabled | bool | `false` | Enable metric server Prometheus metrics expose |
| prometheus.metricServer.port | int | `8080` | HTTP port used for exposing metrics server prometheus metrics |
| prometheus.metricServer.portName | string | `"metrics"` | HTTP port name for exposing metrics server prometheus metrics |
| prometheus.metricServer.serviceMonitor | object | `{"additionalLabels":{},"enabled":false,"interval":"","jobLabel":"","metricRelabelings":[],"podTargetLabels":[],"port":"metrics","relabelings":[],"relabellings":[],"scheme":"http","scrapeTimeout":"","targetLabels":[],"targetPort":"","tlsConfig":{}}` | App Protocol for service when scraping metrics endpoint appProtocol: http |
| prometheus.metricServer.serviceMonitor.enabled | bool | `false` | Enables ServiceMonitor creation for the Prometheus Operator |
| prometheus.metricServer.serviceMonitor.jobLabel | string | `""` | JobLabel selects the label from the associated Kubernetes service which will be used as the job label for all metrics. [ServiceMonitor Spec] |
| prometheus.metricServer.serviceMonitor.targetLabels | list | `[]` | TargetLabels transfers labels from the Kubernetes `Service` onto the created metrics |
| prometheus.metricServer.serviceMonitor.podTargetLabels | list | `[]` | PodTargetLabels transfers labels on the Kubernetes `Pod` onto the created metrics |
| prometheus.metricServer.serviceMonitor.port | string | `"metrics"` | Name of the service port this endpoint refers to. Mutually exclusive with targetPort |
| prometheus.metricServer.serviceMonitor.targetPort | string | `""` | Name or number of the target port of the Pod behind the Service, the port must be specified with container port property. Mutually exclusive with port |
| prometheus.metricServer.serviceMonitor.interval | string | `""` | Interval at which metrics should be scraped If not specified Prometheus’ global scrape interval is used. |
| prometheus.metricServer.serviceMonitor.scrapeTimeout | string | `""` | Timeout after which the scrape is ended If not specified, the Prometheus global scrape timeout is used unless it is less than Interval in which the latter is used |
| prometheus.metricServer.serviceMonitor.relabellings | list | `[]` | DEPRECATED. List of expressions that define custom relabeling rules for metric server ServiceMonitor crd (prometheus operator). [RelabelConfig Spec] |
| prometheus.metricServer.serviceMonitor.relabelings | list | `[]` | List of expressions that define custom relabeling rules for metric server ServiceMonitor crd (prometheus operator). [RelabelConfig Spec] |
| prometheus.metricServer.serviceMonitor.metricRelabelings | list | `[]` | List of expressions that define custom  metric relabeling rules for metric server ServiceMonitor crd after scrape has happened (prometheus operator). [RelabelConfig Spec] |
| prometheus.metricServer.serviceMonitor.additionalLabels | object | `{}` | Additional labels to add for metric server using ServiceMonitor crd (prometheus operator) |
| prometheus.metricServer.serviceMonitor.scheme | string | `"http"` | HTTP scheme used for scraping. Defaults to `http` |
| prometheus.metricServer.serviceMonitor.tlsConfig | object | `{}` | TLS configuration for scraping metrics |
| prometheus.metricServer.podMonitor.enabled | bool | `false` | Enables PodMonitor creation for the Prometheus Operator |
| prometheus.metricServer.podMonitor.interval | string | `""` | Scraping interval for metric server using podMonitor crd (prometheus operator) |
| prometheus.metricServer.podMonitor.scrapeTimeout | string | `""` | Scraping timeout for metric server using podMonitor crd (prometheus operator) |
| prometheus.metricServer.podMonitor.namespace | string | `""` | Scraping namespace for metric server using podMonitor crd (prometheus operator) |
| prometheus.metricServer.podMonitor.additionalLabels | object | `{}` | Additional labels to add for metric server using podMonitor crd (prometheus operator) |
| prometheus.metricServer.podMonitor.relabelings | list | `[]` | List of expressions that define custom relabeling rules for metric server podMonitor crd (prometheus operator) |
| prometheus.metricServer.podMonitor.metricRelabelings | list | `[]` | List of expressions that define custom  metric relabeling rules for metric server PodMonitor crd after scrape has happened (prometheus operator). [RelabelConfig Spec] |
| prometheus.operator.enabled | bool | `false` | Enable KEDA Operator prometheus metrics expose |
| prometheus.operator.port | int | `8080` | Port used for exposing KEDA Operator prometheus metrics |
| prometheus.operator.serviceMonitor | object | `{"additionalLabels":{},"enabled":false,"interval":"","jobLabel":"","metricRelabelings":[],"podTargetLabels":[],"port":"metrics","relabelings":[],"relabellings":[],"scheme":"http","scrapeTimeout":"","targetLabels":[],"targetPort":"","tlsConfig":{}}` | App Protocol for service when scraping metrics endpoint appProtocol: http |
| prometheus.operator.serviceMonitor.enabled | bool | `false` | Enables ServiceMonitor creation for the Prometheus Operator |
| prometheus.operator.serviceMonitor.jobLabel | string | `""` | JobLabel selects the label from the associated Kubernetes service which will be used as the job label for all metrics. [ServiceMonitor Spec] |
| prometheus.operator.serviceMonitor.targetLabels | list | `[]` | TargetLabels transfers labels from the Kubernetes `Service` onto the created metrics |
| prometheus.operator.serviceMonitor.podTargetLabels | list | `[]` | PodTargetLabels transfers labels on the Kubernetes `Pod` onto the created metrics |
| prometheus.operator.serviceMonitor.port | string | `"metrics"` | Name of the service port this endpoint refers to. Mutually exclusive with targetPort |
| prometheus.operator.serviceMonitor.targetPort | string | `""` | Name or number of the target port of the Pod behind the Service, the port must be specified with container port property. Mutually exclusive with port |
| prometheus.operator.serviceMonitor.interval | string | `""` | Interval at which metrics should be scraped If not specified Prometheus’ global scrape interval is used. |
| prometheus.operator.serviceMonitor.scrapeTimeout | string | `""` | Timeout after which the scrape is ended If not specified, the Prometheus global scrape timeout is used unless it is less than Interval in which the latter is used |
| prometheus.operator.serviceMonitor.relabellings | list | `[]` | DEPRECATED. List of expressions that define custom relabeling rules for metric server ServiceMonitor crd (prometheus operator). [RelabelConfig Spec] |
| prometheus.operator.serviceMonitor.relabelings | list | `[]` | List of expressions that define custom relabeling rules for metric server ServiceMonitor crd (prometheus operator). [RelabelConfig Spec] |
| prometheus.operator.serviceMonitor.metricRelabelings | list | `[]` | List of expressions that define custom  metric relabeling rules for metric server ServiceMonitor crd after scrape has happened (prometheus operator). [RelabelConfig Spec] |
| prometheus.operator.serviceMonitor.additionalLabels | object | `{}` | Additional labels to add for metric server using ServiceMonitor crd (prometheus operator) |
| prometheus.operator.serviceMonitor.scheme | string | `"http"` | HTTP scheme used for scraping. Defaults to `http` |
| prometheus.operator.serviceMonitor.tlsConfig | object | `{}` | TLS configuration for scraping metrics |
| prometheus.operator.podMonitor.enabled | bool | `false` | Enables PodMonitor creation for the Prometheus Operator |
| prometheus.operator.podMonitor.interval | string | `""` | Scraping interval for KEDA Operator using podMonitor crd (prometheus operator) |
| prometheus.operator.podMonitor.scrapeTimeout | string | `""` | Scraping timeout for KEDA Operator using podMonitor crd (prometheus operator) |
| prometheus.operator.podMonitor.namespace | string | `""` | Scraping namespace for KEDA Operator using podMonitor crd (prometheus operator) |
| prometheus.operator.podMonitor.additionalLabels | object | `{}` | Additional labels to add for KEDA Operator using podMonitor crd (prometheus operator) |
| prometheus.operator.podMonitor.relabelings | list | `[]` | List of expressions that define custom relabeling rules for KEDA Operator podMonitor crd (prometheus operator) |
| prometheus.operator.podMonitor.metricRelabelings | list | `[]` | List of expressions that define custom  metric relabeling rules for metric server PodMonitor crd after scrape has happened (prometheus operator). [RelabelConfig Spec] |
| prometheus.operator.prometheusRules.enabled | bool | `false` | Enables PrometheusRules creation for the Prometheus Operator |
| prometheus.operator.prometheusRules.namespace | string | `""` | Scraping namespace for KEDA Operator using prometheusRules crd (prometheus operator) |
| prometheus.operator.prometheusRules.additionalLabels | object | `{}` | Additional labels to add for KEDA Operator using prometheusRules crd (prometheus operator) |
| prometheus.operator.prometheusRules.alerts | list | `[]` | Additional alerts to add for KEDA Operator using prometheusRules crd (prometheus operator) |
| prometheus.webhooks.enabled | bool | `false` | Enable KEDA admission webhooks prometheus metrics expose |
| prometheus.webhooks.port | int | `8080` | Port used for exposing KEDA admission webhooks prometheus metrics |
| prometheus.webhooks.serviceMonitor | object | `{"additionalLabels":{},"enabled":false,"interval":"","jobLabel":"","metricRelabelings":[],"podTargetLabels":[],"port":"metrics","relabelings":[],"relabellings":[],"scheme":"http","scrapeTimeout":"","targetLabels":[],"targetPort":"","tlsConfig":{}}` | App Protocol for service when scraping metrics endpoint appProtocol: http |
| prometheus.webhooks.serviceMonitor.enabled | bool | `false` | Enables ServiceMonitor creation for the Prometheus webhooks |
| prometheus.webhooks.serviceMonitor.jobLabel | string | `""` | jobLabel selects the label from the associated Kubernetes service which will be used as the job label for all metrics. [ServiceMonitor Spec] |
| prometheus.webhooks.serviceMonitor.targetLabels | list | `[]` | TargetLabels transfers labels from the Kubernetes `Service` onto the created metrics |
| prometheus.webhooks.serviceMonitor.podTargetLabels | list | `[]` | PodTargetLabels transfers labels on the Kubernetes `Pod` onto the created metrics |
| prometheus.webhooks.serviceMonitor.port | string | `"metrics"` | Name of the service port this endpoint refers to. Mutually exclusive with targetPort |
| prometheus.webhooks.serviceMonitor.targetPort | string | `""` | Name or number of the target port of the Pod behind the Service, the port must be specified with container port property. Mutually exclusive with port |
| prometheus.webhooks.serviceMonitor.interval | string | `""` | Interval at which metrics should be scraped If not specified Prometheus’ global scrape interval is used. |
| prometheus.webhooks.serviceMonitor.scrapeTimeout | string | `""` | Timeout after which the scrape is ended If not specified, the Prometheus global scrape timeout is used unless it is less than Interval in which the latter is used |
| prometheus.webhooks.serviceMonitor.relabellings | list | `[]` | DEPRECATED. List of expressions that define custom relabeling rules for metric server ServiceMonitor crd (prometheus operator). [RelabelConfig Spec] |
| prometheus.webhooks.serviceMonitor.relabelings | list | `[]` | List of expressions that define custom relabeling rules for metric server ServiceMonitor crd (prometheus operator). [RelabelConfig Spec] |
| prometheus.webhooks.serviceMonitor.metricRelabelings | list | `[]` | List of expressions that define custom  metric relabeling rules for metric server ServiceMonitor crd after scrape has happened (prometheus operator). [RelabelConfig Spec] |
| prometheus.webhooks.serviceMonitor.additionalLabels | object | `{}` | Additional labels to add for metric server using ServiceMonitor crd (prometheus operator) |
| prometheus.webhooks.serviceMonitor.scheme | string | `"http"` | HTTP scheme used for scraping. Defaults to `http` |
| prometheus.webhooks.serviceMonitor.tlsConfig | object | `{}` | TLS configuration for scraping metrics |
| prometheus.webhooks.prometheusRules.enabled | bool | `false` | Enables PrometheusRules creation for the Prometheus Operator |
| prometheus.webhooks.prometheusRules.namespace | string | `""` | Scraping namespace for KEDA admission webhooks using prometheusRules crd (prometheus operator) |
| prometheus.webhooks.prometheusRules.additionalLabels | object | `{}` | Additional labels to add for KEDA admission webhooks using prometheusRules crd (prometheus operator) |
| prometheus.webhooks.prometheusRules.alerts | list | `[]` | Additional alerts to add for KEDA admission webhooks using prometheusRules crd (prometheus operator) |
| opentelemetry.collector.uri | string | `""` | Uri of OpenTelemetry Collector to push telemetry to |
| opentelemetry.operator.enabled | bool | `false` | Enable pushing metrics to an OpenTelemetry Collector for operator |
| certificates.autoGenerated | bool | `true` | Enables the self generation for KEDA TLS certificates inside KEDA operator |
| certificates.secretName | string | `"kedaorg-certs"` | Secret name to be mounted with KEDA TLS certificates |
| certificates.mountPath | string | `"/certs"` | Path where KEDA TLS certificates are mounted |
| certificates.certManager.enabled | bool | `false` | Enables Cert-manager for certificate management |
| certificates.certManager.duration | string | `"8760h0m0s"` | Certificate duration |
| certificates.certManager.renewBefore | string | `"5840h0m0s"` | Certificate renewal time before expiration |
| certificates.certManager.generateCA | bool | `true` | Generates a self-signed CA with Cert-manager. If generateCA is false, the secret with the CA has to be annotated with `cert-manager.io/allow-direct-injection: "true"` |
| certificates.certManager.caSecretName | string | `"kedaorg-ca"` | Secret name where the CA is stored (generatedby cert-manager or user given) |
| certificates.certManager.secretTemplate | object | `{}` | Add labels/annotations to secrets created by Certificate resources [docs](https://cert-manager.io/docs/usage/certificate/#creating-certificate-resources) |
| certificates.certManager.issuer | object | `{"generate":true,"group":"cert-manager.io","kind":"ClusterIssuer","name":"foo-org-ca"}` | Reference to custom Issuer. If issuer.generate is false, then issuer.group, issuer.kind and issuer.name are required |
| certificates.certManager.issuer.generate | bool | `true` | Generates an Issuer resource with Cert-manager |
| certificates.certManager.issuer.name | string | `"foo-org-ca"` | Custom Issuer name. Required when generate: false |
| certificates.certManager.issuer.kind | string | `"ClusterIssuer"` | Custom Issuer kind. Required when generate: false |
| certificates.certManager.issuer.group | string | `"cert-manager.io"` | Custom Issuer group. Required when generate: false |
| permissions.metricServer.restrict.secret | bool | `false` | Restrict Secret Access for Metrics Server |
| permissions.operator.restrict.secret | bool | `false` | Restrict Secret Access for KEDA operator if true, KEDA operator will be able to read only secrets in {{ .Release.Namespace }} namespace |
| permissions.operator.restrict.namesAllowList | list | `[]` | Array of strings denoting what secrets the KEDA operator will be able to read, this takes into account also the configured `watchNamespace`. the default is an empty array -> no restriction on the secret name |
| permissions.operator.restrict.serviceAccountTokenCreationRoles | list | `[]` | Creates roles and rolebindings from namespaced service accounts in the array which allow the KEDA operator to request service account tokens for use with the boundServiceAccountToken trigger source. If the namespace does not exist, this will cause the helm chart installation to fail. |
| permissions.operator.restrict.allowAllServiceAccountTokenCreation | bool | `false` | Allow Keda to access all Service Token for KEDA operator |
| extraObjects | list | `[]` | Array of extra K8s manifests to deploy |
| asciiArt | bool | `true` | Capability to turn on/off ASCII art in Helm installation notes |
| customManagedBy | string | `""` | When specified, each rendered resource will have `app.kubernetes.io/managed-by: ${this}` label on it. Useful, when using only helm template with some other solution. |
| enableServiceLinks | bool | `true` | Enable service links in pods. Although enabled, mirroring k8s default, it is highly recommended to disable, due to its legacy status [Legacy container links](https://docs.docker.com/engine/network/links/) |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
