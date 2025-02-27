{{- define "service.service_single" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.name }}
  annotations: {{ toYaml .Values.service.annotations | nindent 4 }}
  labels:
    businessid: {{ .Values.businessid | quote }}
    {{- range $key, $value := .Values.service.labels }}
    {{ $key }}: {{ $value }}
    {{- end }}
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
    {{- if hasKey .Values.service "clusterIP" }}
  clusterIP: {{ .Values.service.clusterIP }}
    {{- end }}
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
    {{- end }}
  type: ClusterIP
    {{- if hasKey .Values.service "clusterIP" }}
  clusterIP: {{ .Values.service.clusterIP }}
    {{- end }}
  selector:
    app: {{ .Values.name }}
  {{- end }}
{{- end }}