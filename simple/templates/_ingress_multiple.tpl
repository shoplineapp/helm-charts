{{- define "ingress.ingress_multiple" -}}
{{- if eq .Values.EnableMutilpleIngress true }}
{{- $businessid := .Values.businessid }}
{{- range $ingress_name, $ref := .Values.ingress }}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $ingress_name }}
  labels:
    businessid: {{ $businessid | quote }}
    {{- range $key, $value := $ref.labels }}
    {{ $key }}: {{ $value }}
    {{- end }}
  annotations:
{{ toYaml $ref.annotations | indent 4 }}
    {{- if and (not (index $ref.annotations "alb.ingress.kubernetes.io/ssl-policy")) (index $ref.annotations "alb.ingress.kubernetes.io/load-balancer-name") }}
    alb.ingress.kubernetes.io/ssl-policy: "ELBSecurityPolicy-TLS13-1-2-2021-06"
    {{- end }}
    {{- if eq (index $ref.annotations "kubernetes.io/ingress.class") "alb" }}
    {{- if not (index $ref.annotations "alb.ingress.kubernetes.io/tags") }}
    alb.ingress.kubernetes.io/tags: {{ printf "businessid=%s" $businessid | quote }}
    {{- end }}
    {{- end }}
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
              {{- if regexMatch "^[1-9][0-9]+$" (toString .backend.servicePort) }}
                number: {{ .backend.servicePort }}
              {{- else }}
                name: {{ .backend.servicePort }}
              {{- end }}
          path: {{ .path | default "/*" }}
          pathType: {{ .pathType | default "ImplementationSpecific" }}
        {{- end }}
    {{- end }}
{{- end }}
{{- else }}
{{ template "ingress.ingress_single" . }}
{{- end }}
{{- end -}}