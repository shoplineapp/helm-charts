{{- define "workflow-library.argo_workflow_workflow.template" -}}
{{- /*
  Set trigger_healthcheck to true if the workflow does not contain the trigger_healthcheck parameter
*/ -}}
{{- $new := list -}}
{{- $arguments_parameters := .Values.arguments.parameters | default list -}}
{{- $contain_trigger_healthcheck_io_params := include "workflow-library.argo_workflow_workflow.arguments.contain_specify_parameters" (dict "list" $arguments_parameters "target" "trigger_healthcheck_io") -}}
arguments: 
  parameters:
  {{- range $arguments_parameters }}
  - name: {{ .name | quote }}
    value: {{ .value | quote }}
  {{- end }}
  {{- if and (.Values.exitNotifications) (.Values.exitNotifications.healthcheckIo) (eq $contain_trigger_healthcheck_io_params "false") }}
  - name: "trigger_healthcheck_io"
    value: "true"
  {{- end }}
podMetadata:
  labels:
    name: {{ .Values.name }}
    businessid: {{ .Values.businessid | quote }}
  annotations:
    {{- range $key, $value := .Values.annotations }}
    {{ $key | quote }} : {{ $value | quote }}
    {{- end }}
workflowMetadata:
  labels:
    name: {{ .Values.name }}
    businessid: {{ .Values.businessid | quote }}
  annotations:
    {{- range $key, $value := .Values.annotations }}
    {{ $key | quote }} : {{ $value | quote }}
    {{- end }}
{{- if .Values.serviceaccount }}
serviceAccountName: {{ .Values.serviceaccount.name | default (printf "%s-pod-service-account" .Values.name) }}
{{- else }}
serviceAccountName: {{ .Values.name }}-pod-service-account
{{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
# If .Values.job.timeout equal to null, the pod will be kill ONLY the job is done. Otherwise, the pod will kill after the value you set
{{- if and (.Values.job) (.Values.job.timeout) }}
activeDeadlineSeconds: {{.Values.job.timeout }}
{{- end }}
{{- with .Values.securityContextForPod }}
securityContext: {{ toYaml . | nindent 2 }}
{{- end }}
{{- if .Values.dnsConfig }}
dnsConfig:
  {{- toYaml .Values.dnsConfig | nindent 2 }}
{{- else }}
dnsConfig:
  options:
    - name: ndots
      value: "2"
{{- end }}
{{- if hasKey .Values "affinity" }}
affinity:
  {{- if hasKey .Values.affinity "nodeAffinity" }}
  nodeAffinity: {{- toYaml .Values.affinity.nodeAffinity | nindent 6 }}
  {{- end }}
  {{- if hasKey .Values.affinity "podAffinity" }}
  podAffinity: {{- toYaml .Values.affinity.podAffinity | nindent 6 }}
  {{- end }}
{{- end }}
metrics:
  prometheus:
    # Metric name (will be prepended with "argo_workflows_")
    - name: cron_workflow_exec_duration_gauge
    # Labels are optional. Avoid cardinality explosion. 
      labels:
        - key: name
          value: "{{ "{{" }}workflow.labels.name{{ "}}" }}"
        - key: namespace
          value: "{{ "{{" }}workflow.namespace{{ "}}" }}"
      # A help doc describing your metric. This is required.    
      help: "Duration gauge by name"
      # The metric type. Available are "gauge", "histogram", and "counter".
      gauge:
      # The value of your metric. It could be an Argo variable (see variables doc) or a literal value 
        value: "{{ "{{" }}workflow.duration{{ "}}" }}"  
        realtime: true
    - name: cron_workflow_fail_count
      labels:
        - key: name
          value: "{{ "{{" }}workflow.labels.name{{ "}}" }}"
        - key: namespace
          value: "{{ "{{" }}workflow.namespace{{ "}}" }}"
      help: "Count of execution by fail status"
      # Emit the metric conditionally. Works the same as normal "when"
      when: "{{ "{{" }}status{{ "}}" }} != Succeeded" 
      counter:
        # This increments the counter by 1
        value: "1"
    - name: cron_workflow_success_count
      labels:
        - key: name
          value: "{{ "{{" }}workflow.labels.name{{ "}}" }}"
        - key: namespace
          value: "{{ "{{" }}workflow.namespace{{ "}}" }}"
      help: "Count of execution by success status"
      # Emit the metric conditionally. Works the same as normal "when"
      when: "{{ "{{" }}status{{ "}}" }} == Succeeded" 
      counter:
        # This increments the counter by 1
        value: "1"
entrypoint: {{ .Values.entrypoint }}
# If not exitNotifications config is set, the default exit-handler of the argo server will be used 
{{- if .Values.exitNotifications }}
onExit: exit-handler 
{{- end }}
{{- if .Values.pdb }}
{{- if eq .Values.pdb.enable true }}
podDisruptionBudget:
  {{- if .Values.pdb.maxUnavailable }}
  maxUnavailable: {{ .Values.pdb.maxUnavailable }}
  {{- else }}
  # Documentation: https://argoproj.github.io/argo-workflows/fields/#poddisruptionbudgetspec
  # Provide arbitrary big number if you don't know how many pods workflow creates
  minAvailable: {{ .Values.pdb.minAvailable | default 9999 }}
  {{- end }}
{{- end }}
{{- end }}
templates:

  {{- if .Values.steps }}
  {{- range .Values.steps }}
  - {{- include "workflow-library.argo_workflow_step.template" . | nindent 4}}
  {{- end }}
  {{- else }}
  {{- /* if no steps, use single step */}}
  {{- $defaultValue := merge (fromJson "{\"name\":\"entry\",\"steps\":[[{\"name\":\"step1\",\"template\":\"template\"}]]}") .Values }}
  - {{- include "workflow-library.argo_workflow_step.template" $defaultValue | nindent 4 }}
  {{- end }}

  {{- if .Values.containers }}
  {{- range .Values.containers }}
  {{ $value := list (.) ($.Release.Namespace) ($.Values.name) }}
  - {{- include "workflow-library.argo_workflow_container.template" $value | nindent 4 }}
  {{- end }}
  {{- else }}
  {{- $defaultValue := merge (fromJson "{\"name\":\"template\"}") .Values }}
  {{- $value := list $defaultValue $.Release.Namespace $.Values.name }}
  - {{- include "workflow-library.argo_workflow_container.template" $value | nindent 4 }}
  {{- end }}

  # The template of exist-handler if any .Values.exitNotifications config is set
  {{- if .Values.exitNotifications }}
  - name: exit-handler
    steps:
    - - name: Success
        template: success-handler
        when: "{{ "{{" }}workflow.status{{ "}}" }} == Succeeded"
      - name: Failure
        template: failure-handler
        when: "{{ "{{" }}workflow.status{{ "}}" }} != Succeeded"
  # The template of steps will go through if the job is done successfully
  - name: success-handler 
    steps:
    -
      # If .Values.exitNotifications.slackApp is set, slackApp will be notify if the job is done 
      {{- if .Values.exitNotifications.slackApp }}
      {{- if list nil true "true" | has .Values.exitNotifications.slackApp.sendOnSuccess }}
      - name: Notice-SlackApp-Succeeded
        template: notice-slack-app-succeeded 
      {{- end }}
      {{- end }}
      # If .Values.exitNotifications.healthcheckIo is set, Healthcheck IO will be notify if the job is done
      {{- if .Values.exitNotifications.healthcheckIo }}
      - name: Notice-HealthcheckIo-Succeeded
        template: notice-healthcheck-io-succeeded
        when: "{{ "{{" }}workflow.parameters.trigger_healthcheck_io{{ "}}" }} == true"
      {{- end }}
  # The template of steps will go through if the job is failed      
  - name: failure-handler
    steps:
    -
      # If .Values.exitNotifications.slackApp is set, slackApp will be notify if the job is failed
      {{- if .Values.exitNotifications.slackApp }}
      {{- if list nil true "true" | has .Values.exitNotifications.slackApp.sendOnFailure }}
      - name: Notice-SlackApp-Failed
        template: notice-slack-app-failed 
      {{- end }}
      {{- end }}
      # If .Values.exitNotifications.newRelic is set, New Relic will be notify if the job is failed
      {{- if .Values.exitNotifications.newRelic }}
      - name: Notice-NewRelic-Failed
        template: notice-newrelic-failed
      {{- end }}
      # If .Values.exitNotifications.newRelic is set, New Relic will be notify if the job is failed
      {{- if  .Values.exitNotifications.healthcheckIo }}
      - name: Notice-HealthcheckIo-Failed
        template: notice-healthcheck-io-failed
        when: "{{ "{{" }}workflow.parameters.trigger_healthcheck_io{{ "}}" }} == true"
      {{- end }}
  # If .Values.exitNotifications.slackApp is set, Slack app notification template will be loaded
  {{- if .Values.exitNotifications.slackApp }}
  {{- include "workflow-library._exit_handler_slack_app" . | nindent 2 }}
  {{- end }}
  # If .Values.exitNotifications.newRelic is set, New Relic notification template will be loaded
  {{- if .Values.exitNotifications.newRelic }}
  {{- include "workflow-library._exit_handler_newrelic" . | nindent 2 }}
  {{- end }}
  # If .Values.exitNotifications.healthcheckIo is set, Healthcheck IO notification template will be loaded
  {{- if .Values.exitNotifications.healthcheckIo }}
  {{- include "workflow-library._exit_handler_healthcheck_io" . | nindent 2 }}
  {{- end }}
  {{- end }}

  {{- with .Values.suspends }}
  {{- range . }}
  - name: {{ .name }}
    suspend:
      duration: {{ .duration }}
  {{- end}}
  {{- end }}

{{- $ttl := .Values.ttlStrategy }}
{{- if $ttl }}
ttlStrategy:
{{- if $ttl.secondsAfterCompletion }}
  # The second of the pod can be alive after the job is done
  secondsAfterCompletion: {{ $ttl.secondsAfterCompletion }}
{{- end }}
{{- if $ttl.secondsAfterFailure }}
  # The second of the pod can be alive after the job is failed
  secondsAfterFailure: {{ $ttl.secondsAfterFailure }}
{{- end }}
{{- if $ttl.secondsAfterSuccess }}
  # The second of the pod can be alive after the job is succeeded
  secondsAfterSuccess: {{ $ttl.secondsAfterSuccess }}
{{- end }}
{{- end }}

# The mechanism for garbage collecting completed pods. There is default value "OnPodCompletion"
podGC:
  {{- if and (.Values.podGC) (.Values.podGC.strategy) }}
  strategy: {{ .Values.podGC.strategy }}
  {{- else}}
  strategy: OnPodCompletion
  {{- end }}
{{- end -}}

{{- define "workflow-library.argo_workflow_workflow.arguments.contain_specify_parameters" -}}
{{- $result := false -}}
{{- $target := .target -}}
{{- range .list -}}
{{- if eq .name $target -}}
{{- $result = true -}}
{{- end -}}
{{- end -}}
{{- $result -}}
{{- end -}}