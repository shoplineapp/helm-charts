{{- define "ingress.ingress_single" -}}
apiVersion: networking.k8s.io/v1
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
            service:
              name: {{ .backend.serviceName }}
              port:
              {{- if .backend.useAnnotation }}
                name: use-annotation
              {{- else if regexMatch "^[1-9][0-9]+$" (toString .backend.servicePort) }}
                number: {{ .backend.servicePort }}
              {{- else }}
                name: {{ .backend.servicePort }}
              {{- end }}
          path: {{ .path | default "/*" }}
          pathType: {{ .pathType | default "ImplementationSpecific" }}
        {{- end }}
    {{- end }}
{{- end -}}