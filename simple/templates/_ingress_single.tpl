{{- define "ingress.ingress_single" -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.name }}
  labels:
    businessid: {{ .Values.businessid | quote }}
{{- with .Values.ingress.labels }}
{{- $labelsYaml := toYaml . | quote }}
{{- $labelsYaml | trim | nindent 4 }}
{{- end }}
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
              {{- if regexMatch "^[1-9][0-9]+$" (toString .backend.servicePort) }}
                number: {{ .backend.servicePort }}
              {{- else }}
                name: {{ .backend.servicePort }}
              {{- end }}
          path: {{ .path | default "/*" }}
          pathType: {{ .pathType | default "ImplementationSpecific" }}
        {{- end }}
    {{- end }}
{{- end -}}