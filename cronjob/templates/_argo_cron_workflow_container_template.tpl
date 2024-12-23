{{- define "cronjob.argo_cron_workflow.container_template" -}}
{{- $input := index . 0 -}}
{{- $namespace := index . 1 -}}
{{- $workflowName := index . 2 -}}
{{- $businessid := index . 3 -}}
name: {{ $input.name }}
metadata:
  namespace: {{ $namespace }}
  labels:
    businessid: {{ $businessid | quote }}
{{- with $input.podSpecPatch }}
podSpecPatch: {{ quote . }}
{{- end }}
{{- with $input.inputs }}
inputs: {{ toYaml . | nindent 2 }}
{{- end }}
{{- with $input.outputs }}
outputs: {{ toYaml . | nindent 2 }}
{{- end }}
container:
  image: {{ template "cronjob.argo_cron_workflow.image" $input.image }}
  {{- with $input.command }}
  command: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $input.args }}
  args: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if $input.resources }}
  # The resource will be apply if "resource is set" 
  resources: {{- toYaml $input.resources | nindent 4 }}
  {{- else }}
  # default settings on resources
  resources: {{- include "cronjob.argo_cron_workflow.default_resource" . | nindent 4 }}
  {{- end }}
  {{- with $input.securityContext }}
  securityContext: {{ toYaml . | nindent 4 }}
  {{- end }}
  env:
    - name: POD_NAME
      value: {{ $workflowName }}
    {{- range $key, $value := $input.env }}
    - name: {{ $key }}
      value: {{ $value | quote }}
    {{- end }}
    {{- range $key, $name := $input.envSecrets }}
    - name: {{ $key }}
      valueFrom:
        secretKeyRef:
          name: {{ $name }}
          key: {{ $key | quote }}
    {{- end }}
  # Apply .envFrom if it is set
  {{- if $input.envFrom }}
  envFrom:
    {{- range $input.envFrom.configMapRef }}
    - configMapRef:
        name: {{ . }}
    {{- end }}
    {{- range $input.envFrom.secretRef }}
    - secretRef:
        name: {{ . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "cronjob.argo_cron_workflow.default_resource" -}}
limits:
  memory: "2Gi"
  cpu: "1"
requests:
  cpu: "300m"
  memory: "1Gi"
{{- end -}}

{{- define "cronjob.argo_cron_workflow.image" -}}
'{{ required "image.repository must be provided" .repository }}:{{ required "image.tag must be provided" .tag }}'
{{- end -}}