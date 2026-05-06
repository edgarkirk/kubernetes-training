{{/*
Common labels with date and version
*/}}
{{- define "kuber-training-chart.labels" -}}
date: {{ now | date "2006-01-02" | quote }}
version: {{ .Chart.AppVersion | quote }}
{{- end }}