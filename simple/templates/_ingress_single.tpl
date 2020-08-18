{{- define "ingress.ingress_single" -}}
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: {{ .Values.name }}
  annotations:
{{ toYaml .Values.ingress.annotations | indent 4 }}
spec:
  {{- if .Values.ingress.tls }}
  tls:
    - hosts:
    {{- range .Values.ingress.tls.hosts }}
        - "{{ .host }}"
    {{- end }}
      secretName: {{ .Values.ingress.tls.secretName }}
  {{- end }}
  rules:
    {{- range .Values.ingress.rules }}
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
{{- end -}}