{{/* vim: set filetype=mustache: */}}

{{/*
Kedify-specific template helpers. Kept in a separate file from the upstream
_helpers.tpl so rebases against kedacore/charts do not conflict here.
*/}}

{{/*
Effective KEDA operator name: the configured operator.name, suffixed with the Helm
release name in multitenant "tenant" mode so multiple tenants sharing a namespace get
unique, non-colliding resource names. Unchanged in default / non-multitenant mode.
*/}}
{{- define "keda.operator.name" -}}
{{- if eq (default "" (.Values.kedify.multitenant).mode) "tenant" -}}
{{- printf "%s-%s" .Values.operator.name .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Values.operator.name -}}
{{- end -}}
{{- end -}}

{{/*
Effective KEDA operator ServiceAccount name: the configured serviceAccount.operator.name
(falling back to serviceAccount.name), suffixed with the Helm release name in multitenant
"tenant" mode the same way as the operator name so the ServiceAccount stays unique per tenant.
*/}}
{{- define "keda.operator.serviceAccountName" -}}
{{- $base := (.Values.serviceAccount.operator).name | default .Values.serviceAccount.name -}}
{{- if eq (default "" (.Values.kedify.multitenant).mode) "tenant" -}}
{{- printf "%s-%s" $base .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $base -}}
{{- end -}}
{{- end -}}

{{/*
Effective name of the Secret holding the operator's TLS certificates: the configured
certificates.secretName, suffixed with the Helm release name in multitenant "tenant" mode
so tenants sharing a namespace do not overwrite each other's certificates.
*/}}
{{- define "keda.certificates.secretName" -}}
{{- if eq (default "" (.Values.kedify.multitenant).mode) "tenant" -}}
{{- printf "%s-%s" .Values.certificates.secretName .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Values.certificates.secretName -}}
{{- end -}}
{{- end -}}
