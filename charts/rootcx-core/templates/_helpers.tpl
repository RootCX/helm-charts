{{/*
Expand the name of the chart.
*/}}
{{- define "rootcx-core.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "rootcx-core.fullname" -}}
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
{{- define "rootcx-core.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rootcx-core.labels" -}}
helm.sh/chart: {{ include "rootcx-core.chart" . }}
{{ include "rootcx-core.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rootcx-core.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rootcx-core.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service account name
*/}}
{{- define "rootcx-core.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rootcx-core.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL fully qualified name
*/}}
{{- define "rootcx-core.postgresql.fullname" -}}
{{- printf "%s-postgresql" (include "rootcx-core.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Database URL — use provided value or build from embedded postgresql
*/}}
{{- define "rootcx-core.databaseUrl" -}}
{{- if .Values.databaseUrl }}
{{- .Values.databaseUrl }}
{{- else if .Values.postgresql.enabled }}
{{- if not .Values.postgresql.auth.password }}
{{- fail "postgresql.auth.password is required when postgresql.enabled=true" }}
{{- end }}
{{- printf "postgres://%s:%s@%s:5432/%s" .Values.postgresql.auth.username .Values.postgresql.auth.password (include "rootcx-core.postgresql.fullname" .) .Values.postgresql.auth.database }}
{{- else }}
{{- fail "Either databaseUrl or postgresql.enabled must be set" }}
{{- end }}
{{- end }}
