#!/usr/bin/env bash
set -euo pipefail
: "${KUBECONFIG:?Set KUBECONFIG to the local host cluster}"
: "${TENANT_KUBECONFIG:?Set TENANT_KUBECONFIG to the provisioning identity inside the tenant}"
crds=(scaledobjects.keda.sh scaledjobs.keda.sh triggerauthentications.keda.sh \
  clustertriggerauthentications.keda.sh kedifypodautoscalers.autoscaling.kedify.io)
# Copy only the CRD specification. Runtime credentials do not receive CRD writes.
kubectl get crd "${crds[@]}" -o json |
  python3 -c 'import json,sys; source=json.load(sys.stdin); print(json.dumps({"apiVersion":"v1","kind":"List","items":[{"apiVersion":r["apiVersion"],"kind":r["kind"],"metadata":{"name":r["metadata"]["name"]},"spec":r["spec"]} for r in source["items"]]}))' |
  kubectl --kubeconfig "$TENANT_KUBECONFIG" apply --server-side --field-manager=vcluster-provisioner -f -
kubectl --kubeconfig "$TENANT_KUBECONFIG" wait --for=condition=Established --timeout=90s \
  "${crds[@]/#/crd/}"
