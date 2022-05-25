{{- define "compute_checksum" -}}
{{- $subpaths := splitList "/" .path }}
{{- $data := .Values }}
{{- range $key, $subpath := $subpaths }}
{{- $data = index $data $subpath }}
{{- end }}
{{- $data | sha256sum }}
{{- end -}}
