{{- /*
Rbac necessary for creating the custom objects by post/pre-instal hook
*/}}
{{- define "postInstallRbac" -}}
{{- $stuff := dict "preOrPost" "post" "ns" .Release.Namespace "objects" .Values.agent.extraPostInstallObjects }}
{{ include "prePostInstallRbac" $stuff }}
{{- end }}

{{- define "preInstallRbac" -}}
{{- $stuff := dict "preOrPost" "pre" "ns" .Release.Namespace "objects" .Values.agent.extraPreInstallObjects }}
{{ include "prePostInstallRbac" $stuff }}
{{- end }}

{{- define "prePostInstallRbac" -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ printf "create-manifests-%s" .preOrPost }}
  namespace: {{ .ns }}
  annotations:
    helm.sh/hook: {{ printf "%s-install,%s-upgrade" .preOrPost .preOrPost }}
    helm.sh/hook-delete-policy: "before-hook-creation,hook-succeeded"
    helm.sh/hook-weight: "-2"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ printf "create-manifests-%s" .preOrPost }}
  annotations:
    helm.sh/hook: {{ printf "%s-install,%s-upgrade" .preOrPost .preOrPost }}
    helm.sh/hook-delete-policy: "before-hook-creation,hook-succeeded"
    helm.sh/hook-weight: "-2"
rules:
{{- range .objects }}
- apiGroups:
  - {{ .apiVersion }}
  resources:
  - {{ lower .kind }}s
  verbs:
  - patch
  - create
  - get
{{- end}}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ printf "create-manifests-%s" .preOrPost }}
  annotations:
    helm.sh/hook: {{ printf "%s-install,%s-upgrade" .preOrPost .preOrPost }}
    helm.sh/hook-delete-policy: "before-hook-creation,hook-succeeded"
    helm.sh/hook-weight: "-2"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ printf "create-manifests-%s" .preOrPost }}
subjects:
- kind: ServiceAccount
  name: {{ printf "create-manifests-%s" .preOrPost }}
  namespace: {{ .ns }}
---
{{- end }}



{{- /*
Job necessary for creating the custom objects by post/pre-instal hook
*/}}
{{- define "postInstallJob" -}}
{{- $stuff := dict "preOrPost" "post" "ns" .Release.Namespace "objects" .Values.agent.extraPostInstallObjects "agent" .Values.agent }}
{{ include "prePostInstallJob" $stuff }}
{{- end }}

{{- define "preInstallJob" -}}
{{- $stuff := dict "preOrPost" "pre" "ns" .Release.Namespace "objects" .Values.agent.extraPreInstallObjects "agent" .Values.agent }}
{{ include "prePostInstallJob" $stuff }}
{{- end }}

{{- define "prePostInstallJob" -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ printf "create-manifests-%s" .preOrPost }}
  namespace: {{ .ns }}
  labels:
    app: {{ printf "create-manifests-%s" .preOrPost }}
  annotations:
    helm.sh/hook: {{ printf "%s-install,%s-upgrade" .preOrPost .preOrPost }}
    helm.sh/hook-weight: "-1"
    helm.sh/hook-delete-policy: "before-hook-creation,hook-succeeded"
spec:
  ttlSecondsAfterFinished: 43200 # 12h
  backoffLimit: 4
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "false"
      labels:
        app: {{ printf "create-manifests-%s" .preOrPost }}
    spec:
      restartPolicy: Never
      serviceAccountName: {{ printf "create-manifests-%s" .preOrPost }}
      {{- with .agent.imagePullSecrets }}
      imagePullSecrets:
      {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .agent.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      volumes:
{{- range $i, $o := .objects }}
      - name: {{ printf "extra-resource-%d" $i }}
        configMap:
          name: {{ printf "extra-resource-%d" $i }}
          items:
          - key: content
            path: {{ printf "extra-resource-%d.yaml" $i }}
{{- end }}
      containers:
      - name: {{ printf "create-manifests-%s" .preOrPost }}
        image: "{{ .agent.kubectlImage.repository }}:{{ .agent.kubectlImage.tag }}"
        imagePullPolicy: {{ .agent.kubectlImage.pullPolicy }}
        {{- with .agent.securityContext }}
        securityContext:
          {{- toYaml . | nindent 10 }}
        {{- end }}
{{- range $i, $o := .objects }}
        volumeMounts:
        - name: {{ printf "extra-resource-%d" $i }}
          mountPath: {{ printf "/data/extra-resource-%d.yaml" $i }}
          subPath: {{ printf "extra-resource-%d.yaml" $i }}
{{- end }}
        command:
        - sh
        args:
        - -c
        - |
          set -o nounset
          for i in $(seq 20)
          do
            kubectl apply -f /data/ 2>&1 && exit 0
            _sec=$(echo "1.5^$i" | bc)
            echo "Waiting ${_sec} seconds.."
            sleep ${_sec}
          done
          exit 1
      {{- with .agent.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .agent.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .agent.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}

{{- /*
ConfigMap necessary for creating the custom objects by post/pre-instal hook. It actually holds the content,
of the extra objects till their CRDs are available in the k8s cluster.
*/}}
{{- define "postInstallConfigmap" -}}
{{- $stuff := dict "preOrPost" "post" "ns" .Release.Namespace "objects" .Values.agent.extraPostInstallObjects "rootScope" . }}
{{ include "prePostInstallConfigmap" $stuff }}
{{- end }}

{{- define "preInstallConfigmap" -}}
{{- $stuff := dict "preOrPost" "pre" "ns" .Release.Namespace "objects" .Values.agent.extraPreInstallObjects "rootScope" . }}
{{ include "prePostInstallConfigmap" $stuff }}
{{- end }}

{{- define "prePostInstallConfigmap" -}}
{{- range $i, $o := .objects }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "extra-resource-%d" $i }}
  namespace: {{ .ns }}
  annotations:
    helm.sh/hook: {{ printf "%s-install,%s-upgrade" $.preOrPost $.preOrPost }}
    helm.sh/hook-delete-policy: "before-hook-creation,hook-succeeded"
    helm.sh/hook-weight: "-2"
data:
  content: |
{{ tpl ($o | toYaml) $.rootScope | indent 4 }}
---
{{- end }}
{{- end }}
