# Rotating vCluster ServiceAccount exports

This opt-in integration discovers a restricted vCluster kubeconfig in the central
installation namespace. The Agent creates a ClusterRegistration referencing the
Secret's `config` key directly. KEDA and KPA consume that registration and follow
credential updates without copying the Secret.

Requires a vCluster chart and runtime implementing
[loft-sh/vcluster#4227](https://github.com/loft-sh/vcluster/pull/4227), and an Agent
build with `MULTICLUSTER_VCLUSTER_SECRET_DISCOVERY_ENABLED`. The upstream feature
is not yet released. Select compatible images for both charts when testing.

## Install

Set `KUBECONFIG` to the host cluster and run from this directory. Supply your own
private Kedify installation values and the compatible Agent image tag:

```bash
helm upgrade --install kedify-agent /path/to/kedify-agent-chart \
  --namespace keda --create-namespace \
  --values /path/to/private-kedify-values.yaml --values central-values.yaml \
  --set agent.image.tag="$AGENT_TAG" --wait --timeout 6m
helm upgrade --install tenant-a /path/to/vcluster-chart \
  --namespace vcluster-tenant-a --create-namespace --values vcluster-values.yaml \
  --set controlPlane.statefulSet.image.repository="$VCLUSTER_IMAGE_REPOSITORY" \
  --set controlPlane.statefulSet.image.tag="$VCLUSTER_IMAGE_TAG" \
  --set-file experimental.deploy.vcluster.manifests=tenant-runtime.yaml \
  --wait --timeout 6m
```

Keep the vCluster image registry consistent with `VCLUSTER_IMAGE_REPOSITORY`.
The values use the normal administrative export plus one additional export.
`vcluster connect` retains its administrative credentials. The additional export
uses a separate virtual ServiceAccount bound to `kedify-runtime`.

The vCluster chart creates the destination Secret, discovery label and writer
Role/RoleBinding. No bootstrap chart or separate host RBAC is needed. The writer
can only `get/list/watch/patch` that exact Secret; list/watch use a matching
`metadata.name` selector. It cannot create Secrets in the central namespace.
The destination namespace must already exist.

`expiration: 10m` requests a ten-minute token. Rotation uses the expiry actually
granted by the API server. `renewBeforePercentage: 33` renews with approximately
one-third of that lifetime remaining, with jitter that advances renewal. Omit
the percentage to use the upstream default. Omitting `tokenRotation`, or setting
it to `{}`, retains startup-only exports and legacy token lifetimes.

## Provision tenant APIs

`tenant-runtime.yaml` defines the runtime ClusterRole inside the vCluster. The
exporter's native `serviceAccount` fields create its ServiceAccount and binding.
The runtime role supports KEDA/KPA scaling, reading scaler authentication inputs,
and creating Jobs. Read-only native HPA access is also required by the controllers
even when scaling through KPA. Restrict it further to the features your tenants use. It
cannot change RBAC, install CRDs, or request ServiceAccount tokens.

Install the five KEDA/KPA CRDs separately with the administrative provisioning
identity. Obtain that kubeconfig with `vcluster connect`, then run:

```bash
export TENANT_KUBECONFIG=/path/to/tenant-admin.kubeconfig
bash provision-tenant-crds.sh
python3 validate-export.py
```

The validator requires Python 3 with PyYAML. It checks host authorization,
ServiceAccount token lifetime, direct registration readiness and renewal before
expiry. It prints no credentials and may run for several minutes. Also exercise
a tenant ScaledObject before and after renewal to verify actual scaling.

## Ownership and GitOps

Helm owns the destination Secret and scoped writer RBAC. Removing rotation or
uninstalling the vCluster release removes those resources. When enabling rotation
for a previously controller-created Secret, adopt it into the Helm release first,
for example with `helm upgrade --take-ownership` where supported.

vCluster owns credential data; GitOps should manage metadata. Configure Argo CD
`ignoreDifferences` for `/data` and `RespectIgnoreDifferences=true`, scoped to this
Secret's exact name and namespace. If the Secret is deleted, Helm/GitOps must
recreate it. vCluster watches for that recreation and repopulates its data. The
Agent then restores the registration. Source deletion, label removal or unsafe
credentials withdraw the generated registration; deleting a registration never
deletes its source Secret.

The central readers have namespace-wide Secret access. Put stronger credentials,
including native administrative exports, outside their installation namespace.
Labels select integrations; they do not restrict authorization to read Secrets.
Do not combine this mode with native host-wide vCluster discovery. Existing
`"true"` discovery labels using `data.kubeconfig` retain their distributed workflow;
use a separate Secret rather than relabeling an existing integration.
