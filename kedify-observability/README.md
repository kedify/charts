# Observability Stack for Kedify Components
Hierarchical helm chart that installs:
- Prometheus
- Kube state metrics w/ altered configuration to report metrics about our CRDs
- Grafana & dashboard
- Loki for logs
- one OTel collector for collecting the logs and pushing them to Loki
- (optional) Kedify CRDs and example apps

### Usage
```
helm upgrade kedify-obs oci://ghcr.io/kedify/charts/kedify-observability -i -nobs --create-namespace
kubectl port-forward -nobs svc/grafana 3000:80
open http://localhost:3000/dashboards
```

### Logging Infrastructure
consult [Kedify Logs with Loki and OpenTelemetry Collector](./kedify-loki-opentelemetry-logs.md)

### DEBUG
To get all the logs kedify component logs:

```
kubectl port-forward -n obs svc/loki 3100
curl -G -s http://localhost:3100/loki/api/v1/query_range --data-urlencode 'query={k8s_namespace_name=~"keda|kedify"}'
```

To show the metrics from KSM:

```
kubectl run -it -nobs --image=badouralix/curl-jq:alpine --rm --restart=Never --command metrics -- sh -c 'sleep 5 ; curl -s http://kube-state-metrics:8080/metrics'
```

