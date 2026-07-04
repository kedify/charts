# kube-state-metrics Custom Resource State

This repo defines CRDs in `keda/templates/crds`, `http-add-on/templates/crds`, and
`kedify-agent/files/crds`. The companion values file
`kube-state-metrics-custom-resource-state-values.yaml` enables kube-state-metrics
Custom Resource State metrics for all of them.

## Covered CRDs

| Group | Version | Kind |
| --- | --- | --- |
| `keda.sh` | `v1alpha1` | `ScaledObject` |
| `keda.sh` | `v1alpha1` | `ScaledJob` |
| `keda.sh` | `v1alpha1` | `TriggerAuthentication` |
| `keda.sh` | `v1alpha1` | `ClusterTriggerAuthentication` |
| `eventing.keda.sh` | `v1alpha1` | `CloudEventSource` |
| `eventing.keda.sh` | `v1alpha1` | `ClusterCloudEventSource` |
| `http.keda.sh` | `v1alpha1` | `HTTPScaledObject` |
| `http.keda.sh` | `v1beta1` | `InterceptorRoute` |
| `keda.kedify.io` | `v1alpha1` | `ScalingGroup` |
| `keda.kedify.io` | `v1alpha1` | `DistributedScaledJob` |
| `keda.kedify.io` | `v1alpha1` | `DistributedScaledObject` |
| `keda.kedify.io` | `v1alpha1` | `PodResourceAutoscaler` |
| `keda.kedify.io` | `v1alpha1` | `PodResourceProfile` |
| `keda.kedify.io` | `v1alpha1` | `ScalingPolicy` |
| `install.kedify.io` | `v1alpha1` | `KedifyConfiguration` |

## Install

```console
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install kube-state-metrics prometheus-community/kube-state-metrics \
  --namespace monitoring --create-namespace \
  -f samples/kube-state-metrics-custom-resource-state-values.yaml
```

For `kube-prometheus-stack`, put the values file content under the
`kube-state-metrics:` key.

## Example Metrics

The config uses resource-specific metric prefixes, for example:

```
kubectl run -it --image=badouralix/curl-jq:alpine --rm --restart=Never --command metrics -- curl http://kube-state-metrics.monitoring.svc:8080/metrics | grep "kube_\(kedify\|keda\)_"
```

```promql
kube_keda_scaledobject_status_condition{condition="Ready"}
kube_keda_scaledjob_status_condition{condition="Active"}
kube_keda_http_scaledobject_spec_min_replicas
kube_kedify_scalinggroup_status_residual_capacity
kube_kedify_distributedscaledobject_status_members_healthy_count
kube_kedify_podresourceprofile_status_triggered
kube_kedify_configuration_component_phase_info
```

Condition metrics follow the kube-state-metrics custom resource condition pattern:
`True` is exported as `1`; `False` and `Unknown` are exported as `0`.
