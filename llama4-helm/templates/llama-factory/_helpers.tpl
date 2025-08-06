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

# get llama-factory vllm arg
{{- define "llamafactory.getArgs" -}}
  {{- $args := list }}
  {{- range $i, $arg := .extraArgs }}
    {{- $tokens := split " " $arg }}
    {{- range $t := $tokens }}
      {{- if hasPrefix $t "llamafactory-cli" }}
        {{- $args = append $args $t }}
      {{- else if hasPrefix $t "/" }}
        {{- $args = append $args $t }}
      {{- else if hasPrefix $t "-" }}
        {{- $args = append $args $t }}
      {{- else if contains "=" $t }}
        {{- $args = append $args (printf "--%s" $t) }}
      {{- else }}
        {{- $args = append $args $t }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- range $a := $args }}
  - {{ $a | quote }}
  {{- end }}
{{- end }}

{{- define "llama_factory.renderBashCommand" -}}
    {{- $base := printf "llamafactory-cli %s %s" .Values.llama_factory.cli_args.mode .Values.llama_factory.templatepath }}
    {{- $args := list (printf "%s " $base) }}
    {{- $args = append $args (printf "infer_backend=%s" .Values.llama_factory.cli_args.infer_backend) }}
    {{- if eq .Values.llama_factory.cli_args.infer_backend "vllm" }}
        {{- if .Values.llama_factory.cli_args.vllm }}
            {{- $extra := .Values.llama_factory.cli_args.vllm.extraArgs }}
            {{- $keys := keys $extra | sortAlpha }}
            {{- range $i, $k := $keys }}
                {{- $val := index $extra $k }}
                {{- $item := printf "%s=%v" $k $val }}
                {{- $args = append $args $item }}
            {{- end }}
        {{- end }}
    {{- end }}

    {{- $lastIndex := sub (len $args) 1 }}
    {{- range $i, $line := $args }}
        {{- if lt $i $lastIndex }}
            {{ $line }} \
        {{- else }}
            {{ $line }}
        {{- end }}
    {{- end }}
{{- end }}