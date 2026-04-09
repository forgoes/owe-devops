{{- define "owe.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "owe.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "owe.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "owe.uiName" -}}
{{- printf "%s-ui" (include "owe.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "owe.serviceName" -}}
{{- printf "%s-service" (include "owe.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
