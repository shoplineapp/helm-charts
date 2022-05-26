{{- define "service.service_single" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.name }}
  annotations: {{ toYaml .Values.service.annotations | nindent 4 }}
  labels: {{ toYaml .Values.service.labels | nindent 4 }}
spec:
  {{- if hasKey .Values.service "type" }}
    {{- if eq .Values.service.type "ExternalName" }}
  type: ExternalName
  externalName: {{ .Values.service.externalName }}
    {{- else }}
  ports:
    {{- range .Values.service.ports }}
  - name: {{ .name | default .port | quote }}
    port: {{ .port }}
    targetPort: {{ .target | default .port }}
    protocol: {{ .protocol | default "TCP" }}
    {{- end }}
  type: {{ .Values.service.type }}
  selector:
    app: {{ .Values.name }}
    {{- end }}
  {{- else}}
  ports:
    {{- range .Values.service.ports }}
  - name: {{ .name | default .port | quote }}
    port: {{ .port }}
    targetPort: {{ .target | default .port }}
    protocol: {{ .protocol | default "TCP" }}
    {{- end}}
  type: ClusterIP
  selector:
    app: {{ .Values.name }}
  {{- end }}
{{- end }}