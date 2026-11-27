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

OTel scaler metrics are discovered from Services labelled
`app.kubernetes.io/name: otel-add-on` on their `internal-metrics` port. This
includes `kedify-otel-scaler` from the Agent chart and standalone add-on
installations with custom service names. The scrape job and `release` label stay
`keda-otel-scaler` for existing dashboard filters.

### Logging Infrastructure
consult [Kedify Logs with Loki and OpenTelemetry Collector](./kedify-loki-opentelemetry-logs.md)

OTel scaler log collection recognizes both `keda-otel-scaler-*` and
`kedify-otel-scaler-*` pods in the `keda` namespace and assigns their logs the
`kedify_otel_scaler` component.

Collector containers are excluded from every log receiver. This also prevents
an Agent-prefixed collector pod from matching the Agent log rule and ingesting
its own parsing errors.

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

