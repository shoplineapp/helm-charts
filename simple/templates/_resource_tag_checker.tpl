{{- define "resource_tag_checker" -}}
{{- if not .Values.businessid }}
{{ fail "businessid is a required field. Please provide a value in your values.yaml." }}
{{- end }}
{{- end -}}