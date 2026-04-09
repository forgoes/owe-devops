{{- define "postgres.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "postgres.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Values.postgres.nameOverride | default (include "postgres.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "postgres.headlessServiceName" -}}
{{- printf "%s-headless" (include "postgres.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "postgres.readWriteServiceName" -}}
{{- printf "%s-rw" (include "postgres.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
