{{/*
Expand the name of the chart.
*/}}
{{- define "rootcx-core.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Resolve auto to OpenShift only when the Route API is available. */}}
{{- define "rootcx-core.platform" -}}
{{- if eq .Values.global.platform "auto" -}}
{{- if .Capabilities.APIVersions.Has "route.openshift.io/v1/Route" -}}openshift{{- else -}}kubernetes{{- end -}}
{{- else -}}
{{- .Values.global.platform -}}
{{- end -}}
{{- end }}

{{- define "rootcx-core.deploymentMode" -}}
{{- dig "deploymentMode" "quickstart" .Values.global.rootcx -}}
{{- end }}

{{/* OIDC values may be supplied by an umbrella chart through global.rootcx. */}}
{{- define "rootcx-core.oidcIssuer" -}}
{{- $portalHost := dig "hosts" "portal" "" .Values.global.rootcx -}}
{{- if .Values.oidc.issuer -}}
{{- .Values.oidc.issuer -}}
{{- else if $portalHost -}}
{{- printf "https://%s" $portalHost -}}
{{- else -}}
{{- .Values.global.rootcx.oidcIssuer -}}
{{- end -}}
{{- end }}

{{- define "rootcx-core.oidcClientId" -}}
{{- default .Values.global.rootcx.oidcClientId .Values.oidc.clientId -}}
{{- end }}

{{- define "rootcx-core.oidcClientSecret" -}}
{{- $configured := default .Values.global.rootcx.oidcClientSecret .Values.oidc.clientSecret -}}
{{- if $configured -}}
{{- $configured -}}
{{- else if eq (include "rootcx-core.deploymentMode" .) "quickstart" -}}
rootcx-local
{{- end -}}
{{- end }}

{{- define "rootcx-core.publicUrl" -}}
{{- $coreHost := dig "hosts" "core" "" .Values.global.rootcx -}}
{{- if .Values.publicUrl -}}
{{- .Values.publicUrl -}}
{{- else if $coreHost -}}
{{- printf "https://%s" $coreHost -}}
{{- else -}}
{{- .Values.global.rootcx.corePublicUrl -}}
{{- end -}}
{{- end }}

{{- define "rootcx-core.routeHost" -}}
{{- default .Values.route.host (dig "hosts" "core" "" .Values.global.rootcx) -}}
{{- end }}

{{- define "rootcx-core.tlsSecretName" -}}
{{- default (dig "tls" "secretName" "" .Values.global.rootcx) .Values.route.tls.externalCertificateSecretName -}}
{{- end }}

{{- define "rootcx-core.secretName" -}}
{{- default (include "rootcx-core.fullname" .) .Values.existingSecret -}}
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
