{{- define "rootcx-portal.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Resolve auto to OpenShift only when the Route API is available. */}}
{{- define "rootcx-portal.platform" -}}
{{- if eq .Values.global.platform "auto" -}}
{{- if .Capabilities.APIVersions.Has "route.openshift.io/v1/Route" -}}openshift{{- else -}}kubernetes{{- end -}}
{{- else -}}
{{- .Values.global.platform -}}
{{- end -}}
{{- end }}

{{- define "rootcx-portal.deploymentMode" -}}
{{- dig "deploymentMode" "quickstart" .Values.global.rootcx -}}
{{- end }}

{{- define "rootcx-portal.oidcClientSecret" -}}
{{- if .Values.global.rootcx.oidcClientSecret -}}
{{- .Values.global.rootcx.oidcClientSecret -}}
{{- else if eq (include "rootcx-portal.deploymentMode" .) "quickstart" -}}
rootcx-local
{{- end -}}
{{- end }}

{{- define "rootcx-portal.coreServiceName" -}}
{{- printf "%s-core" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "rootcx-portal.coreSecretName" -}}
{{- default (include "rootcx-portal.coreServiceName" .) .Values.core.existingSecret -}}
{{- end }}

{{- define "rootcx-portal.corePostgresqlServiceName" -}}
{{- printf "%s-postgresql" (include "rootcx-portal.coreServiceName" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "rootcx-portal.coreInternalUrl" -}}
{{- printf "http://%s:9100" (include "rootcx-portal.coreServiceName" .) }}
{{- end }}

{{- define "rootcx-portal.portalHost" -}}
{{- default .Values.route.host (dig "hosts" "portal" "" .Values.global.rootcx) -}}
{{- end }}

{{- define "rootcx-portal.portalPublicUrl" -}}
{{- $host := dig "hosts" "portal" "" .Values.global.rootcx -}}
{{- if $host -}}
{{- printf "https://%s" $host -}}
{{- else -}}
{{- .Values.global.rootcx.portalPublicUrl -}}
{{- end -}}
{{- end }}

{{- define "rootcx-portal.corePublicUrl" -}}
{{- $host := dig "hosts" "core" "" .Values.global.rootcx -}}
{{- if $host -}}
{{- printf "https://%s" $host -}}
{{- else -}}
{{- .Values.global.rootcx.corePublicUrl -}}
{{- end -}}
{{- end }}

{{- define "rootcx-portal.oidcIssuer" -}}
{{- $host := dig "hosts" "portal" "" .Values.global.rootcx -}}
{{- if $host -}}
{{- printf "https://%s" $host -}}
{{- else -}}
{{- .Values.global.rootcx.oidcIssuer -}}
{{- end -}}
{{- end }}

{{- define "rootcx-portal.tlsSecretName" -}}
{{- dig "tls" "secretName" "" .Values.global.rootcx -}}
{{- end }}

{{- define "rootcx-portal.secretName" -}}
{{- default (include "rootcx-portal.fullname" .) .Values.existingSecret -}}
{{- end }}

{{- define "rootcx-portal.fullname" -}}
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

{{- define "rootcx-portal.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "rootcx-portal.labels" -}}
helm.sh/chart: {{ include "rootcx-portal.chart" . }}
{{ include "rootcx-portal.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "rootcx-portal.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rootcx-portal.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "rootcx-portal.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rootcx-portal.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
