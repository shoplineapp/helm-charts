{{- define "cronjob.argo_cron_workflow" -}}
  workflowSpec:
    {{ include "workflow-library.argo_workflow_workflow.template" . }}
{{- end -}}