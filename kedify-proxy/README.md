# kedify-proxy

![Version: v0.0.7](https://img.shields.io/badge/Version-v0.0.7-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v1.35.1](https://img.shields.io/badge/AppVersion-v1.35.1-informational?style=flat-square)

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

<table>
     <thead>
          <th>Key</th>
          <th>Description</th>
          <th>Default</th>
     </thead>
     <tbody>
          <tr>
               <td id="image--repository">
               <a href="./values.yaml#L3">image.repository</a><br/>
               (string)
               </td>
               <td>
               Image to use for the Deployment
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
"envoyproxy/envoy"
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="image--pullPolicy">
               <a href="./values.yaml#L5">image.pullPolicy</a><br/>
               (string)
               </td>
               <td>
               Image pull policy, consult <a href="https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy">docs</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
"IfNotPresent"
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="image--tag">
               <a href="./values.yaml#L7">image.tag</a><br/>
               (string)
               </td>
               <td>
               Image version to use for the Deployment, if not specified, it defaults to <code>.Chart.AppVersion</code>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
""
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="imagePullSecrets">
               <a href="./values.yaml#L10">imagePullSecrets</a><br/>
               (list)
               </td>
               <td>
               Required for private image registries, consult <a href="https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/">docs</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
[]
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="logging--format">
               <a href="./values.yaml#L16">logging.format</a><br/>
               (string)
               </td>
               <td>
               Use: <code>plaintext</code> or <code>json</code>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
"plaintext"
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="extraArgs">
               <a href="./values.yaml#L19">extraArgs</a><br/>
               (object)
               </td>
               <td>
               Extra program arguments that should be passed to Envoy, consult <a href="https://www.envoyproxy.io/docs/envoy/latest/operations/cli">docs</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="config--kedaNamespace">
               <a href="./values.yaml#L26">config.kedaNamespace</a><br/>
               (string)
               </td>
               <td>
               namespace where Kedify HTTP addon is deployed
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
"keda"
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="config--kedifyEnvoyCP">
               <a href="./values.yaml#L30">config.kedifyEnvoyCP</a><br/>
               (string)
               </td>
               <td>
               service name of Kedify interceptor that serves as a control plane for configuration xDS and metrics
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
"keda-add-ons-http-interceptor-kedify-proxy-metric-sink"
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="config--kedifyEnvoyCPPort">
               <a href="./values.yaml#L32">config.kedifyEnvoyCPPort</a><br/>
               (int)
               </td>
               <td>
               port on kedify interceptor (<code>.config.kedifyEnvoyCP</code> host) from which the xDS config should be pulled
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
5678
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="config--kedifyMetricsSinkPort">
               <a href="./values.yaml#L34">config.kedifyMetricsSinkPort</a><br/>
               (int)
               </td>
               <td>
               port on kedify interceptor (<code>.config.kedifyEnvoyCP</code> host) where metrics from envoy data planes will be sent
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
9901
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="config--overloadManager">
               <a href="./values.yaml#L38">config.overloadManager</a><br/>
               (object)
               </td>
               <td>
               overloadManager static configuration by default, the overload manager is disabled which means that there is no limit on active downstream connections NOTE: changing any values here restarts all kedify-proxy instances
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{
  "enabled": false,
  "maxActiveDownstreamConnections": 10000,
  "refreshInterval": "0.25s"
}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="config--overloadManager--enabled">
               <a href="./values.yaml#L40">config.overloadManager.enabled</a><br/>
               (bool)
               </td>
               <td>
               enabled toggle to enable/disable overload manager
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
false
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="config--overloadManager--refreshInterval">
               <a href="./values.yaml#L42">config.overloadManager.refreshInterval</a><br/>
               (string)
               </td>
               <td>
               refresh interval for the overload manager
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
"0.25s"
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="config--overloadManager--maxActiveDownstreamConnections">
               <a href="./values.yaml#L44">config.overloadManager.maxActiveDownstreamConnections</a><br/>
               (int)
               </td>
               <td>
               max active downstream connections
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
10000
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="config--xds">
               <a href="./values.yaml#L46">config.xds</a><br/>
               (object)
               </td>
               <td>
               gRPC xDS specific configuration
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{
  "connectTimeout": "2s",
  "keepaliveInterval": "30s",
  "keepaliveTimeout": "5s"
}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="config--xds--keepaliveInterval">
               <a href="./values.yaml#L48">config.xds.keepaliveInterval</a><br/>
               (string)
               </td>
               <td>
               keepalive settings for gRPC xDS connection to Kedify control plane
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
"30s"
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="config--xds--connectTimeout">
               <a href="./values.yaml#L51">config.xds.connectTimeout</a><br/>
               (string)
               </td>
               <td>
               timeout for initial connection to the Kedify control plane
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
"2s"
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="pod--annotations">
               <a href="./values.yaml#L55">pod.annotations</a><br/>
               (object)
               </td>
               <td>
               custom annotations that should be added to the Kedify proxy pod
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="pod--labels">
               <a href="./values.yaml#L57">pod.labels</a><br/>
               (object)
               </td>
               <td>
               custom labels that should be added to the Kedify proxy pod
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="pod--securityContext">
               <a href="./values.yaml#L59">pod.securityContext</a><br/>
               (object)
               </td>
               <td>
               pod-lvl securityContext <a href="https://kubernetes.io/docs/tasks/configure-pod-container/security-context/">docs</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="pod--containerSecurityContext">
               <a href="./values.yaml#L61">pod.containerSecurityContext</a><br/>
               (object)
               </td>
               <td>
               container-lvl securityContext <a href="https://kubernetes.io/docs/tasks/configure-pod-container/security-context/">docs</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{
  "allowPrivilegeEscalation": false,
  "capabilities": {
    "drop": [
      "ALL"
    ]
  },
  "readOnlyRootFilesystem": true,
  "runAsNonRoot": true,
  "runAsUser": 101,
  "seccompProfile": {
    "type": "RuntimeDefault"
  }
}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="pod--priorityClassName">
               <a href="./values.yaml#L72">pod.priorityClassName</a><br/>
               (string)
               </td>
               <td>
               <a href="https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/">docs</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
""
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="pod--livenessProbe">
               <a href="./values.yaml#L74">pod.livenessProbe</a><br/>
               (object)
               </td>
               <td>
               custom timeouts and thresholds for liveness probe
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{
  "failureThreshold": 5,
  "httpGet": {
    "path": "/ready",
    "port": "admin"
  },
  "initialDelaySeconds": 5,
  "periodSeconds": 2
}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="pod--readinessProbe">
               <a href="./values.yaml#L82">pod.readinessProbe</a><br/>
               (object)
               </td>
               <td>
               custom timeouts and thresholds for readiness probe
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{
  "failureThreshold": 2,
  "httpGet": {
    "path": "/ready",
    "port": "admin"
  },
  "initialDelaySeconds": 1,
  "periodSeconds": 1
}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="pod--preStopHookWaitSeconds">
               <a href="./values.yaml#L90">pod.preStopHookWaitSeconds</a><br/>
               (int)
               </td>
               <td>
               custom timeout for graceful shutdown, should be smaller or equal to terminationGracePeriodSeconds
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
5
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="pod--terminationGracePeriodSeconds">
               <a href="./values.yaml#L92">pod.terminationGracePeriodSeconds</a><br/>
               (int)
               </td>
               <td>
               custom timeout for pod termination, should be larger or equal to preStopHookWaitSeconds
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
30
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="deployment--replicas">
               <a href="./values.yaml#L96">deployment.replicas</a><br/>
               (int)
               </td>
               <td>
               Fixed amount of replicas for the deployment. Use either <code>.autoscaling</code> section or this field.
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
1
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="deployment--rollingUpdate">
               <a href="./values.yaml#L98">deployment.rollingUpdate</a><br/>
               (object)
               </td>
               <td>
               <a href="https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/">docs</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="service--enabled">
               <a href="./values.yaml#L105">service.enabled</a><br/>
               (bool)
               </td>
               <td>
               Should the services be rendered with the helm chart?
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
true
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="service--type">
               <a href="./values.yaml#L107">service.type</a><br/>
               (string)
               </td>
               <td>
               <a href="https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types">docs</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
"ClusterIP"
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="service--annotations">
               <a href="./values.yaml#L109">service.annotations</a><br/>
               (object)
               </td>
               <td>
               custom annotations that should be added to both services
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="service--labels">
               <a href="./values.yaml#L111">service.labels</a><br/>
               (object)
               </td>
               <td>
               custom labels that should be added to both services
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="service--httpPort">
               <a href="./values.yaml#L113">service.httpPort</a><br/>
               (int)
               </td>
               <td>
               port for plain text HTTP traffic
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
8080
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="service--tlsPort">
               <a href="./values.yaml#L115">service.tlsPort</a><br/>
               (int)
               </td>
               <td>
               port for TLS HTTP traffic
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
8443
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="service--exposeAdminInterface">
               <a href="./values.yaml#L117">service.exposeAdminInterface</a><br/>
               (bool)
               </td>
               <td>
               Should the admin service be also rendered with the helm chart?
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
true
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="service--adminSvcType">
               <a href="./values.yaml#L119">service.adminSvcType</a><br/>
               (string)
               </td>
               <td>
               <a href="https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types">docs</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
"ClusterIP"
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="service--adminPort">
               <a href="./values.yaml#L121">service.adminPort</a><br/>
               (int)
               </td>
               <td>
               port for admin interface of envoy
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
9901
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="resources">
               <a href="./values.yaml#L124">resources</a><br/>
               (object)
               </td>
               <td>
               resource definitions for envoy container, see <a href="https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/">docs</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{
  "limits": {
    "cpu": "500m",
    "memory": "256Mi"
  },
  "requests": {
    "cpu": "250m",
    "memory": "128Mi"
  }
}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="autoscaling">
               <a href="./values.yaml#L134">autoscaling</a><br/>
               (object)
               </td>
               <td>
               mutually exclusive with <code>.deployment.replicas</code> configure the <code>.resources</code> appropriately, because the SO uses cpu and memory scalers
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{
  "enabled": false,
  "horizontalPodAutoscalerConfig": {},
  "maxReplicaCount": 3,
  "minReplicaCount": 1,
  "scaledObjectName": ""
}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="autoscaling--enabled">
               <a href="./values.yaml#L136">autoscaling.enabled</a><br/>
               (bool)
               </td>
               <td>
               Should the KEDA's <code>ScaledObject</code> be also rendered with the helm chart?
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
false
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="autoscaling--scaledObjectName">
               <a href="./values.yaml#L138">autoscaling.scaledObjectName</a><br/>
               (string)
               </td>
               <td>
               Name of the <code>ScaledObject</code> custom resource. If empty, release name is used.
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
""
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="volumes">
               <a href="./values.yaml#L153">volumes</a><br/>
               (list)
               </td>
               <td>
               Additional volumes on the output Deployment definition.
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
[]
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="volumeMounts">
               <a href="./values.yaml#L160">volumeMounts</a><br/>
               (list)
               </td>
               <td>
               Additional volumeMounts on the output Deployment definition.
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
[]
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="nodeSelector">
               <a href="./values.yaml#L166">nodeSelector</a><br/>
               (object)
               </td>
               <td>
               <a href="https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector">details</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="tolerations">
               <a href="./values.yaml#L168">tolerations</a><br/>
               (list)
               </td>
               <td>
               <a href="https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/">details</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
[]
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="topologySpreadConstraints">
               <a href="./values.yaml#L170">topologySpreadConstraints</a><br/>
               (list)
               </td>
               <td>
               <a href="https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/">details</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
[]
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="affinity">
               <a href="./values.yaml#L172">affinity</a><br/>
               (object)
               </td>
               <td>
               <a href="https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity">details</a>
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="podDisruptionBudget">
               <a href="./values.yaml#L175">podDisruptionBudget</a><br/>
               (object)
               </td>
               <td>
               <a href="https://kubernetes.io/docs/tasks/run-application/configure-pdb/">details</a> (not rendered by default)
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
{
  "enabled": false,
  "spec": {}
}
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="noBanner">
               <a href="./values.yaml#L186">noBanner</a><br/>
               (bool)
               </td>
               <td>
               should the ascii logo be printed when this helm chart is installed
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
false
</pre>
</div>
               </td>
          </tr>
          <tr>
               <td id="extraObjects">
               <a href="./values.yaml#L189">extraObjects</a><br/>
               (list)
               </td>
               <td>
               Array of extra K8s manifests to deploy
               </td>
               <td>
                    <div style="max-width: 200px;">
<pre lang="json">
[]
</pre>
</div>
               </td>
          </tr>
     </tbody>
</table>

<!-- uncomment this for markdown style (use either valuesTableHtml or valuesSection)
(( template "chart.valuesSection" . )) -->

## Releasing

Run the action on this repo called Helm Publish (OCI) - [link](https://github.com/kedify/charts/actions/workflows/gh-release-oci-chart.yml).
You can provide the desired version of the helm chart as an input to the action or (if not provided) it will create a patch release.
It will also:
- create a tag in the repo
- modifies the `Chart.yaml` with increased version
- updates the docs in this `README.md` file.
