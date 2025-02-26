{{- define "pvc_name_checker" -}}
{{- if and (.Values.persistence.enabled) (eq .Values.persistence.name "") }}
  {{ fail "Error: persistence.name is required when persistence.enabled is true" }}
{{- end }}
{{- end -}}
