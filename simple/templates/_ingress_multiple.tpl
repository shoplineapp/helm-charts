{{- define "ingress.ingress_multiple" -}}
{{- if eq .Values.EnableMutilpleIngress true }}
{{- range $ingress_name, $ref := .Values.ingress }}
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: {{ $ingress_name }}
  annotations:
{{ toYaml $ref.annotations | indent 4 }}
spec:
  {{- if $ref.tls }}
  tls:
    - hosts:
    {{- range $ref.tls.hosts }}
        - "{{ .host }}"
    {{- end }}
      secretName: {{ $ref.tls.secretName }}
  {{- end }}
  rules:
    {{- range $ref.rules }}
    -
      {{- if .host}}
      host: "{{ .host }}"
      {{- end }}
      http:
        paths:
        {{- range .http.paths }}
        - backend:
            serviceName: {{ .backend.serviceName }}
            servicePort: {{ .backend.servicePort }}
          path: {{ .path | default "/*"}}
        {{- end }}
    {{- end }}
{{- end }}
{{- else }}
{{ template "ingress.ingress_single" . }}
{{- end }}
{{- end -}}