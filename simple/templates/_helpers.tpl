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

{{/* Compute checksum for configuration data */}}
{{- define "simple.computeChecksum" -}}
{{- $subpaths := splitList "/" .path }}
{{- $data := .Values }}
{{- range $key, $subpath := $subpaths }}
  {{- $data = index $data $subpath }}
{{- end }}
{{- $data | sha256sum }}
{{- end -}}


{{/* Validate < 1.0.0 version  */}}
{{- define "simple.v1BreakingChange" -}}
{{ if or (.Values.nodeSelector.labelName) (.Values.nodeSelector.labelValue) }}
{{- fail "Error: nodeSelector.labelName and nodeSelector.labelValue is depreacted, please use nodeSelector[]" }}
{{- end }}

{{ if .Values.hpav2 }}
{{- fail "Error: hpav2 is depreacted, please use hpa(Default hpa uses autoscaling/v2 API version)" }}
{{- end }}

{{- end -}}