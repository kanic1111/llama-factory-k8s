{{/*
Expand the name of the chart.
*/}}
{{- define "llama4-helm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "llama4-helm.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "llama4-helm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "llama4-helm.labels" -}}
helm.sh/chart: {{ include "llama4-helm.chart" . }}
{{ include "llama4-helm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "llama4-helm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "llama4-helm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "llama4-helm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "llama4-helm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
  Helper that returns the fully‑qualified name for a given app.
  Usage: {{ include "multi-app-chart.fullname" . $app }}
*/}}
{{- define "multi-app-chart.fullname" -}}
{{- $root := . -}}
{{- $app  := index . 1 -}}
{{- printf "%s-%s" $root.Release.Name $app.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
  Helper that merges app‑specific values with global defaults.
  Returns a dict with the merged result.
*/}}
{{- define "multi-app-chart.mergedValues" -}}
{{- $root := . -}}
{{- $app  := index . 1 -}}
{{-  $merged := deepCopy .Values.global -}}
{{- /* Override with app‑specific top‑level keys */ -}}
{{- range $k, $v := $app -}}
  {{- if not (hasKey (list "name" "service") $k) -}}
    {{- $_ := set $merged $k $v -}}
  {{- end -}}
{{- end -}}
{{- $_ := set $merged "name" $app.name -}}
{{- $_ := set $merged "service" $app.service -}}
{{- printf $merged -}}
{{- end -}}

{{- define "vllm.vllmServeCommand" -}}
vllm serve {{ .Values.vllm.model }} \
{{- $args := .Values.vllm.extraArgs }}
{{- if $args }}
  {{- $argList := dict }}
  {{- range $k, $v := $args }}
    {{- $_ := set $argList $k $v }}
  {{- end }}
  {{- $keys := keys $argList | sortAlpha }}
  {{- range $i, $k := $keys }}
    {{- $v := index $argList $k }}
    {{- $isLast := eq (add1 $i) (len $keys) }}
    {{- if eq (kindOf $v) "bool" }}
      {{- if $v }}
{{ $k | replace "_" "-" }}{{ if not $isLast }} \{{ end }}
      {{- end }}
    {{- else }}
{{ $k | replace "_" "-" }} {{ $v }}{{ if not $isLast }} \{{ end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
