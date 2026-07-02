{{/*
Returns a random ghcr.io/kedify/sample-minute-metrics schedule.
The schedule has buckets 0 through 9, each with a value from 0 through 6.
*/}}
{{- define "kedify-observability.randomMinuteMetricsSchedule" -}}
{{- $schedule := list -}}
{{- range $bucket := until 10 -}}
{{- $schedule = append $schedule (printf "%d:%d" $bucket (randInt 0 7)) -}}
{{- end -}}
{{- join "," $schedule -}}
{{- end -}}
