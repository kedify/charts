{{/* Validates the api key format */}}
{{- define "validateApiKey" -}}
{{- if not . }}
{{- fail "'agent.apiKey' is not set" }}
{{- end }}
{{- if not (regexMatch "^kfy_[0-9a-zA-Z]{32}$" (. | toString)) }}
{{- fail (printf "'agent.apiKey' is not valid.\n - It must be in the format: 'kfy_***' (got: '%s')\n - You can get this value from https://dashboard.kedify.io/api-keys" (. | toString)) }}
{{- end }}
{{- end -}}

{{/* Validates the org id format */}}
{{- define "validateOrgId" -}}
{{- if not . }}
{{- fail "'agent.orgId' is not set" }}
{{- end }}
{{- if not (regexMatch "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$" (. | toString)) }}
{{- fail (printf "'agent.orgId' is not valid.\n - It must be in the format (uuid v4): 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx' where x is 0-f and y is 8-b (got: '%s')\n - You can get this value from https://dashboard.kedify.io/organization-details" (. | toString)) }}
{{- end }}
{{- end -}}

{{/* Validates the cloud account id format */}}
{{- define "validateCloudAccountId" -}}
{{- if . }}
{{- if not (regexMatch "^(aws:|gcp:|kfy:)[a-zA-Z0-9][a-zA-Z0-9-]*$" (. | toString)) }}
{{- fail (printf "'agent.cloudAccountID' is not valid.\n - It must be in the format: 'aws:***', 'gcp:***', or 'kfy:***' (got: '%s')" (. | toString)) }}
{{- end }}
{{- end }}
{{- end -}}
