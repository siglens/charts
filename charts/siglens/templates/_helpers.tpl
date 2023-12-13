{{/*
Expand the name of the chart.
*/}}
{{- define "siglens.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "siglens.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "siglens.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "siglens.labels" -}}
helm.sh/chart: {{ include "siglens.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "siglens-server.labels" -}}
helm.sh/chart: {{ include "siglens.chart" . }}
{{ include "siglens-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "siglens-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "siglens.name" . }}-core
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "siglens.serviceAccountName" -}}
{{- default (include "siglens.fullname" .) .Values.serviceAccount.name }}
{{- end }}

{{/*
Return the storage class name to use
*/}}
{{ define "siglens.storageClass" }}
{{ if .Values.siglens.storage.defaultClass }}
{{ else }}
storageClassName: {{ .Chart.Name }}-storage-class
{{ end }}
{{ end }}

{{/*
Events Exporter Common labels
*/}}
{{- define "siglens-events-exporter.labels" -}}
helm.sh/chart: {{ include "siglens.chart" . }}
{{ include "siglens-events-exporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
Logs Exporter Common labels
*/}}
{{- define "siglens-fluentd.labels" -}}
helm.sh/chart: {{ include "siglens.chart" . }}
{{ include "siglens-fluentd.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
SigLens UI Common labels
*/}}
{{- define "siglens-ui.labels" -}}
helm.sh/chart: {{ include "siglens.chart" . }}
{{ include "siglens-ui.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Log Exporter Selector labels
*/}}
{{- define "siglens-fluentd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "siglens.name" . }}-fluentd
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Events Exporter Selector labels
*/}}
{{- define "siglens-events-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "siglens.name" . }}-events-exporter
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
SigLens UI Selector labels
*/}}
{{- define "siglens-ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "siglens.name" . }}-ui
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
SigLens PVC storage size
*/}}
{{- define "siglens-pvc.size" -}}
{{ if .Values.siglens }}
{{ if .Values.siglens.storage }}
{{ if .Values.siglens.storage.size }}
storage: {{ .Values.siglens.storage.size }}
{{ else }}
storage: 10Gi
{{ end }}
{{ end }}
{{ end }}
{{- end }}