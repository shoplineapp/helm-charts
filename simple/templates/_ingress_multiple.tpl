{{- define "ingress.ingress_multiple" -}}
{{- if eq .Values.EnableMutilpleIngress true }}
{{- range $ingress_name, $ref := .Values.ingress }}
---
apiVersion: networking.k8s.io/v1
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
            service:
              name: {{ .backend.serviceName }}
              port: 
                number: {{ .backend.servicePort }}
          path: {{ .path | default "/*" }}
          pathType: {{ .pathType | default "ImplementationSpecific" }}
        {{- end }}
    {{- end }}
{{- end }}
{{- else }}
{{ template "ingress.ingress_single" . }}
{{- end }}
{{- end -}}