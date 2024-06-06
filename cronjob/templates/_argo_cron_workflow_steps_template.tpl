{{- define "cronjob.argo_cron_workflow.steps_template" -}}
name: {{ .name }}
{{- with .inputs }}
inputs: {{ toYaml . | nindent 2 }}
{{- end }}
{{- with .outputs }}
outputs: {{ toYaml . | nindent 2 }}
{{- end }}
steps: {{ toYaml .steps | nindent 2 }}
{{- if (.job).retries }}
retryStrategy:
  # Limit of retries if the job is fail   
  limit: {{ .job.retries }}
  {{- with .job.retryPolicy }}
  # Valid Value:  "Always" | "OnFailure" | "OnError" | "OnTransientError", Default: "OnFailure"
  retryPolicy: {{ . }} 
  {{- end }}
{{- end }}
{{- end -}}
