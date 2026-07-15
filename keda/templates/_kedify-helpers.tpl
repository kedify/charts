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

{{/*
Return one validated autoscaling default for every KEDA process. The legacy
extraArgs form remains accepted only when operator and webhook values match;
this prevents admission and reconciliation from silently choosing different
classes. New installations should use kedify.kpa.defaultClass.
*/}}
{{- define "keda.kedifyKpaDefaultClass" -}}
{{- $configured := default "hpa" .Values.kedify.kpa.defaultClass -}}
{{- $operatorArgs := default (dict) .Values.extraArgs.keda -}}
{{- $webhookArgs := default (dict) .Values.extraArgs.webhooks -}}
{{- $operatorHasLegacy := hasKey $operatorArgs "autoscaling-default-class" -}}
{{- $webhookHasLegacy := hasKey $webhookArgs "autoscaling-default-class" -}}
{{- if or $operatorHasLegacy $webhookHasLegacy -}}
  {{- if not (and $operatorHasLegacy $webhookHasLegacy) -}}
    {{- fail "extraArgs.keda and extraArgs.webhooks must set autoscaling-default-class together; prefer kedify.kpa.defaultClass" -}}
  {{- end -}}
  {{- $operatorLegacy := toString (index $operatorArgs "autoscaling-default-class") -}}
  {{- $webhookLegacy := toString (index $webhookArgs "autoscaling-default-class") -}}
  {{- if ne $operatorLegacy $webhookLegacy -}}
    {{- fail "extraArgs.keda and extraArgs.webhooks autoscaling-default-class values must match; prefer kedify.kpa.defaultClass" -}}
  {{- end -}}
  {{- if and (ne $configured "hpa") (ne $configured $operatorLegacy) -}}
    {{- fail "kedify.kpa.defaultClass conflicts with the legacy autoscaling-default-class extraArgs" -}}
  {{- end -}}
  {{- $configured = $operatorLegacy -}}
{{- end -}}
{{- if not (has $configured (list "hpa" "kpa")) -}}
  {{- fail "kedify.kpa.defaultClass must be hpa or kpa" -}}
{{- end -}}
{{- if and (eq $configured "kpa") (not .Values.kedify.kpa.enabled) -}}
  {{- fail "kedify.kpa.defaultClass=kpa requires kedify.kpa.enabled=true" -}}
{{- end -}}
{{- $configured -}}
{{- end -}}
