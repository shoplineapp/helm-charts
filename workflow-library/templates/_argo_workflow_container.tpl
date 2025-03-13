{{- define "workflow-library.argo_workflow_container.template" -}}
{{- $input := index . 0 -}}
{{- $namespace := index . 1 -}}
{{- $workflowName := index . 2 -}}
name: {{ $input.name }}
metadata:
  namespace: {{ $namespace }}
  labels:
    businessid: {{ $input.businessid | quote }}
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
  image: {{ template "workflow-library.argo_workflow_container.image_name" $input.image }}
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
  resources: {{- include "workflow-library.argo_workflow_container.default_resource" . | nindent 4 }}
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

{{- define "workflow-library.argo_workflow_container.image_name" -}}
'{{ required "image.repository must be provided" .repository }}:{{ required "image.tag must be provided" .tag }}'
{{- end -}}

{{- define "workflow-library.argo_workflow_container.default_resource" -}}
limits:
  memory: "2Gi"
  cpu: "1"
requests:
  cpu: "300m"
  memory: "1Gi"
{{- end -}}