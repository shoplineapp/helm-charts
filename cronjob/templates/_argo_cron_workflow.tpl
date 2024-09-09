{{- define "cronjob.argo_cron_workflow" -}}
  workflowSpec:
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
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.tolerations }}
    tolerations:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    # If .Values.job.timeout equal to null, the pod will be kill ONLY the job is done. Otherwise, the pod will kill after the value you set
    {{- if and (.Values.job) (.Values.job.timeout) }}
    activeDeadlineSeconds: {{.Values.job.timeout }}
    {{- end }}
    {{- with .Values.securityContextForPod }}
    securityContext: {{ toYaml . | nindent 6 }}
    {{- end }}
    {{- if .Values.dnsConfig }}
    dnsConfig:
      {{- toYaml .Values.dnsConfig | nindent 6 }}
    {{- else }}
    dnsConfig:
      options:
        - name: ndots
          value: "2"
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
      - {{- include "cronjob.argo_cron_workflow.step_template" . | nindent 8 }}
      {{- end }}
      {{- else }}
      {{- /* if no steps, use single step */}}
      {{- $defaultValue := merge (fromJson "{\"name\":\"entry\",\"steps\":[[{\"name\":\"step1\",\"template\":\"template\"}]]}") $.Values }}
      - {{- include "cronjob.argo_cron_workflow.step_template" $defaultValue | nindent 8 }}
      {{- end }}

      {{- if .Values.containers }}
      {{- range .Values.containers }}
      {{ $value := list . $.Release.Namespace $.Values.name }}
      - {{- include "cronjob.argo_cron_workflow.container_template" $value | nindent 8}}
      {{- end }}
      {{- else }}
      {{- $defaultValue := merge (fromJson "{\"name\":\"template\"}") $.Values }}
      {{- $value := list $defaultValue $.Release.Namespace $.Values.name }}
      - {{- include "cronjob.argo_cron_workflow.container_template" $value | nindent 8 }}
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
         {{- end }}
      # If .Values.exitNotifications.slackApp is set, Slack app notification template will be loaded
      {{- if .Values.exitNotifications.slackApp }}
      {{ template "cronjob._exit_handler_slack_app" . }}
      {{- end }}
      # If .Values.exitNotifications.newRelic is set, New Relic notification template will be loaded
      {{- if .Values.exitNotifications.newRelic }}
      {{ template "cronjob._exit_handler_newrelic" . }}
      {{- end }}
      # If .Values.exitNotifications.healthcheckIo is set, Healthcheck IO notification template will be loaded
      {{- if .Values.exitNotifications.healthcheckIo }}
      {{ template "cronjob._exit_handler_healthcheck_io" . }}
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
