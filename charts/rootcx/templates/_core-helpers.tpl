{{/* Core keeps its historical resource names after being merged into this chart. */}}
{{- define "rootcx-core.name" -}}
{{- default "core" .Values.core.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "rootcx-core.platform" -}}
{{- include "rootcx-portal.platform" . -}}
{{- end }}

{{- define "rootcx-core.deploymentMode" -}}
{{- include "rootcx-portal.deploymentMode" . -}}
{{- end }}

{{- define "rootcx-core.oidcIssuer" -}}
{{- $portalHost := dig "hosts" "portal" "" .Values.global.rootcx -}}
{{- if .Values.core.oidc.issuer -}}
{{- .Values.core.oidc.issuer -}}
{{- else if $portalHost -}}
{{- printf "https://%s" $portalHost -}}
{{- else -}}
{{- .Values.global.rootcx.oidcIssuer -}}
{{- end -}}
{{- end }}

{{- define "rootcx-core.oidcClientId" -}}
{{- default .Values.global.rootcx.oidcClientId .Values.core.oidc.clientId -}}
{{- end }}

{{- define "rootcx-core.oidcClientSecret" -}}
{{- $configured := default .Values.global.rootcx.oidcClientSecret .Values.core.oidc.clientSecret -}}
{{- if $configured -}}
{{- $configured -}}
{{- else if eq (include "rootcx-core.deploymentMode" .) "quickstart" -}}
rootcx-local
{{- end -}}
{{- end }}

{{- define "rootcx-core.publicUrl" -}}
{{- $coreHost := dig "hosts" "core" "" .Values.global.rootcx -}}
{{- if .Values.core.publicUrl -}}
{{- .Values.core.publicUrl -}}
{{- else if $coreHost -}}
{{- printf "https://%s" $coreHost -}}
{{- else -}}
{{- .Values.global.rootcx.corePublicUrl -}}
{{- end -}}
{{- end }}

{{- define "rootcx-core.routeHost" -}}
{{- default .Values.core.route.host (dig "hosts" "core" "" .Values.global.rootcx) -}}
{{- end }}

{{- define "rootcx-core.tlsSecretName" -}}
{{- default (dig "tls" "secretName" "" .Values.global.rootcx) .Values.core.route.tls.externalCertificateSecretName -}}
{{- end }}

{{- define "rootcx-core.secretName" -}}
{{- default (include "rootcx-core.fullname" .) .Values.core.existingSecret -}}
{{- end }}

{{- define "rootcx-core.fullname" -}}
{{- if .Values.core.fullnameOverride }}
{{- .Values.core.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "core" .Values.core.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "rootcx-core.labels" -}}
helm.sh/chart: {{ include "rootcx-portal.chart" . }}
{{ include "rootcx-core.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.core.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "rootcx-core.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rootcx-core.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "rootcx-core.serviceAccountName" -}}
{{- if .Values.core.serviceAccount.create }}
{{- default (include "rootcx-core.fullname" .) .Values.core.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.core.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "rootcx-core.postgresql.fullname" -}}
{{- printf "%s-postgresql" (include "rootcx-core.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
