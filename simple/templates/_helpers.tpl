{{/* Common labels */}}
{{- define "simple.labels" -}}
app: {{ .Values.name }}
businessid: {{ .Values.businessid | quote }}
{{- if .Values.additionalLabels }}
{{- toYaml .Values.additionalLabels | nindent 0 }}
{{- end }}
{{- end }}

{{/* Common metadata */}}
{{- define "simple.metadata" -}}
name: {{ .Values.name }}
namespace: {{ .Release.Namespace }}
labels:
  {{- include "simple.labels" . | nindent 2 }}
{{- end }}

{{/* Validate required values */}}
{{- define "simple.validateRequired" -}}
{{- if (eq .Values.name "") -}}
{{- fail "name is required" -}}
{{- end -}}
{{- if (eq .Values.businessid "") -}}
{{- fail "businessid is required" -}}
{{- end -}}
{{- end }}

{{/* Validate PVC configuration */}}
{{- define "simple.validatePVC" -}}
{{- if and (.Values.persistence.enabled) (eq .Values.persistence.name "") }}
{{- fail "Error: persistence.name is required when persistence.enabled is true" }}
{{- end }}
{{- end -}}