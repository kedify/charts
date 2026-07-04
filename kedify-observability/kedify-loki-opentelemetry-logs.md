# Kedify Logs with Loki and OpenTelemetry Collector

This sample deploys a small log stack for a Kedify installation:

- Loki stores and queries logs.
- OpenTelemetry Collector runs as a DaemonSet.
- The Collector `filelog` receiver tails Kubernetes container logs from the node
  filesystem, parses CRI/Docker log lines, and sends them to Loki over OTLP HTTP.

The example assumes the Kedify/KEDA control plane runs in the `keda` or `kedify`
namespace. If your release namespace is different, add a matching
`/var/log/pods/<namespace>_*/*/*.log` include pattern to the Collector values.

## Collected Logs

| Source | Filelog include pattern |
| --- | --- |
| Kedify/KEDA control plane in `keda` | `/var/log/pods/keda_*/*/*.log` |
| Kedify/KEDA control plane in `kedify` | `/var/log/pods/kedify_*/*/*.log` |
| Kedify proxy in any namespace | `/var/log/pods/*_kedify-proxy-*_*/*/*.log` |

The Collector starts at the end of each file, so it forwards new log lines only.
Set `start_at: beginning` if you intentionally want to backfill existing pod log
files.

## Install Loki

This installs a single-replica Loki for development or small internal clusters.
For production, replace the embedded MinIO storage with external object storage.

```console

# full values: https://github.com/grafana-community/helm-charts/blob/main/charts/loki/values.yaml
helm upgrade -i loki oci://ghcr.io/grafana-community/helm-charts/loki \
  --namespace loki --create-namespace --version 18.3.0 \
  -f - <<'EOF'
loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  schemaConfig:
    configs:
      - from: "2024-04-01"
        store: tsdb
        object_store: s3
        schema: v13
        index:
          prefix: loki_index_
          period: 24h
  limits_config:
    allow_structured_metadata: true
    volume_enabled: true
  pattern_ingester:
    enabled: true
  ruler:
    enable_api: true
  memcached:
    chunk_cache:
      enabled: false
    results_cache:
      enabled: false
memcached:
  enabled: false

ignoreMinioDeprecation: true
minio:
  enabled: true

deploymentMode: Monolithic
singleBinary:
  replicas: 1

backend:
  replicas: 0
read:
  replicas: 0
write:
  replicas: 0
ingester:
  replicas: 0
querier:
  replicas: 0
queryFrontend:
  replicas: 0
queryScheduler:
  replicas: 0
distributor:
  replicas: 0
compactor:
  replicas: 0
indexGateway:
  replicas: 0
bloomPlanner:
  replicas: 0
bloomBuilder:
  replicas: 0
bloomGateway:
  replicas: 0
EOF
```

Loki must allow structured metadata for OTLP log ingestion. Loki 3.0 and newer
enable this by default, but the sample keeps `allow_structured_metadata: true`
explicit.

The sample also sets `loki.auth_enabled: false`. Without that setting, Loki runs
in multi-tenant mode and rejects OTLP requests that do not include an
`X-Scope-OrgID` tenant header.

## Install the Collector

```console
helm upgrade --install kedify-logs-collector oci://ghcr.io/open-telemetry/opentelemetry-helm-charts/opentelemetry-collector \
  --namespace observability --create-namespace --version 0.159.2 \
  -f - <<'EOF'
mode: daemonset

image:
  repository: otel/opentelemetry-collector-k8s
command:
  name: otelcol-k8s

nodeSelector:
  kubernetes.io/os: linux
tolerations:
  - operator: Exists

extraVolumes:
  - name: varlogpods
    hostPath:
      path: /var/log/pods
  - name: varlibdockercontainers
    hostPath:
      path: /var/lib/docker/containers
extraVolumeMounts:
  - name: varlogpods
    mountPath: /var/log/pods
    readOnly: true
  - name: varlibdockercontainers
    mountPath: /var/lib/docker/containers
    readOnly: true

config:
  receivers:
    jaeger: null
    prometheus: null
    zipkin: null
    otlp: null
    filelog/kedify:
      include:
        - /var/log/pods/keda_*/*/*.log
        - /var/log/pods/kedify_*/*/*.log
        - /var/log/pods/*_kedify-proxy-*_*/*/*.log
      exclude:
        - /var/log/pods/*/opentelemetry-collector/*.log
      start_at: end
      include_file_path: true
      include_file_name: false
      operators:
        - type: container
          id: container-parser

  processors:
    memory_limiter:
      check_interval: 5s
      limit_percentage: 80
      spike_limit_percentage: 25
    batch: {}

  exporters:
    debug:
      sending_queue:
        enabled: false
    otlphttp/loki:
      endpoint: http://loki-gateway.loki.svc.cluster.local/otlp

  service:
    pipelines:
      traces: null
      metrics: null
      logs:
        receivers:
          - filelog/kedify
        processors:
          - memory_limiter
          - batch
        exporters:
          - otlphttp/loki

ports:
  otlp:
    enabled: false
  otlp-http:
    enabled: false
  jaeger-compact:
    enabled: false
  jaeger-thrift:
    enabled: false
  jaeger-grpc:
    enabled: false
  zipkin:
    enabled: false
EOF
```

The `container` operator reads the Kubernetes log file path and adds resource
attributes such as `k8s.namespace.name`, `k8s.pod.name`, and
`k8s.container.name`. Loki normalizes OTLP attribute names when they become
labels, so query `k8s.namespace.name` as `k8s_namespace_name`.

If you keep Loki multi-tenancy enabled instead of setting
`loki.auth_enabled: false`, add a tenant header to the `otlphttp/loki` exporter:

```yaml
exporters:
  otlphttp/loki:
    endpoint: http://loki-gateway.loki.svc.cluster.local/otlp
    headers:
      X-Scope-OrgID: kedify
```

With multi-tenancy enabled, use the same tenant header for queries:

```console
curl -H 'X-Scope-OrgID: kedify' -G -s http://localhost:3100/loki/api/v1/query \
  --data-urlencode 'query={k8s_namespace_name=~"keda|kedify"}' | jq .
```

## Verify

```console
kubectl get pods -n loki
kubectl get daemonset -n observability -l app.kubernetes.io/instance=kedify-logs-collector
kubectl logs -n observability -l app.kubernetes.io/instance=kedify-logs-collector --tail=100
```

Port-forward the Loki gateway and query the normalized OTLP labels:

```console
kubectl port-forward -n loki svc/loki-gateway 3100:80
```

```console
curl -G -s http://localhost:3100/loki/api/v1/query \
  --data-urlencode 'query={k8s_namespace_name=~"keda|kedify"}' | jq .
```

Example LogQL selectors:

```logql
{k8s_namespace_name=~"keda|kedify"}
{k8s_pod_name=~"kedify-agent.*|keda-operator.*|keda-admission-webhooks.*|kedify-proxy.*"}
{k8s_container_name="envoy"}
```

## References

- OpenTelemetry Collector filelog receiver:
  https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/filelogreceiver
- OpenTelemetry Kubernetes filelog receiver guidance:
  https://opentelemetry.io/docs/platforms/kubernetes/collector/components/#filelog-receiver
- Loki OTLP ingestion:
  https://grafana.com/docs/loki/latest/send-data/otel/
- Loki multi-tenancy:
  https://grafana.com/docs/loki/latest/operations/multi-tenancy/
- Loki authentication:
  https://grafana.com/docs/loki/latest/operations/authentication/
- Loki monolithic Helm install:
  https://grafana.com/docs/loki/latest/setup/install/helm/install-monolithic/
