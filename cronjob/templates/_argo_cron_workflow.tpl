{{- define "cronjob.argo_cron_workflow" -}}
{{- if .Values.createWithWorkflowTemplate }}
  workflowSpec:
    workflowTemplateRef:
      name: "{{ .Values.name }}-workflow-template"
{{- else -}}
  workflowSpec: {{- include "workflow-library.argo_workflow_workflow.template" . | nindent 4 }}
{{- end -}}
{{- end -}}