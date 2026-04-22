## JSON Schema for Kedify CRDs

Assuming you've installed [kubeconform](https://github.com/yannh/kubeconform), to verify a CR against the schema use:

```bash
kubeconform -schema-location 'https://raw.githubusercontent.com/kedify/charts/main/crd-schemas/{{.ResourceKind}}{{.KindSuffix}}.json' -summary -output json ../agent/config/samples/keda_v1alpha1_podresourceprofile.yaml
{
  "resources": [],
  "summary": {
    "valid": 1,
    "invalid": 0,
    "errors": 0,
    "skipped": 0
  }
}
```

or using a container image:

```bash
docker run -i --rm ghcr.io/yannh/kubeconform:v0.7.0 -summary -debug -schema-location default -schema-location 'https://raw.githubusercontent.com/kedify/charts/refs/heads/crd-schema-url-templating/crd-schemas/{{.ResourceKind}}{{.KindSuffix}}.json' < ../agent/config/samples/keda_v1alpha1_podresourceprofile.yaml
Summary: 1 resource found parsing stdin - Valid: 1, Invalid: 0, Errors: 0, Skipped: 0
```

Invalid resources should fail:

```bash
cat <<PRP | docker run -i --rm ghcr.io/yannh/kubeconform:v0.7.0 -output json -summary -debug -schema-location default -schema-location 'https://raw.githubusercontent.com/kedify/charts/refs/heads/crd-schema-url-templating/crd-schemas/{{.ResourceKind}}{{.KindSuffix}}.json' -
apiVersion: keda.kedify.io/v1alpha1
kind: PodResourceProfile
metadata:
  name: podresourceprofile-sample
spec:
  selector: # use either selector or spec.target
    matchLabels:
      app: nginx
  containerName: nginx # required - container name to update
  paused: f4lse # << ERROR here
  priority: 0 # optional, defaults to 0
  trigger:
    after: containerReady # optional, defaults to containerReady (allowed values: containerReady, containerStarted, podReady, podScheduled, podRunning)
    delay: 30s # required, examples: 20s, 1m, 90s, 2m30s, 2h
  newResources: # required - new requests and/or limits
    requests:
      memory: 50M
PRP
{
  "resources": [
    {
      "filename": "stdin",
      "kind": "PodResourceProfile",
      "name": "podresourceprofile-sample",
      "version": "keda.kedify.io/v1alpha1",
      "status": "statusInvalid",
      "msg": "problem validating schema. Check JSON formatting: jsonschema validation failed with 'https://raw.githubusercontent.com/kedify/charts/refs/heads/crd-schema-url-templating/crd-schemas/podresourceprofile-keda-v1alpha1.json#' - at '/spec/paused': got string, want boolean",
      "validationErrors": [
        {
          "path": "/spec/paused",
          "msg": "got string, want boolean"
        }
      ]
    }
  ],
  "summary": {
    "valid": 0,
    "invalid": 1,
    "errors": 0,
    "skipped": 0
  }
}
```
