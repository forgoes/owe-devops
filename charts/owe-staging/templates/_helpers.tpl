{{- define "owe-staging.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "owe-staging.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "owe-staging.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "owe-staging.uiName" -}}
{{- printf "%s-ui" (include "owe-staging.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "owe-staging.serviceName" -}}
{{- printf "%s-service" (include "owe-staging.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
