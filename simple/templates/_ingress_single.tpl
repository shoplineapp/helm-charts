{{- define "ingress.ingress_single" -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.name }}
  labels:
    businessid: {{ .Values.businessid | quote }}
    {{- range $key, $value := .Values.ingress.labels }}
    {{ $key }}: {{ $value }}
    {{- end }}
  annotations:
{{ toYaml .Values.ingress.annotations | indent 4 }}
    {{- if and (not (index .Values.ingress.annotations "alb.ingress.kubernetes.io/ssl-policy")) (index .Values.ingress.annotations "alb.ingress.kubernetes.io/load-balancer-name") }}
    alb.ingress.kubernetes.io/ssl-policy: "ELBSecurityPolicy-TLS13-1-2-2021-06"
    {{- end }}
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