{{- define "cronjob.argo_cron_workflow" -}}
    workflowSpec:
    podMetadata:
      labels:
        name: {{ .Values.name }}
      annotations:
        {{- range $key, $value := .Values.annotations }}
        {{ $key | quote }} : {{ $value | quote }}
        {{- end }}
    workflowMetadata:
      labels:
        name: {{ .Values.name }}
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
      - name: {{ .name }}
        {{- with .inputs }}
        inputs: {{ toYaml . | nindent 10 }}
        {{- end }}
        {{- with .outputs }}
        outputs: {{ toYaml . | nindent 10 }}
        {{- end }}
        steps: {{ toYaml .steps | nindent 10}}
        {{- if or (and ($.Values.job) ($.Values.job.retries)) (.job) }}
        retryStrategy:
          # Limit of retries if the job is fail   
          {{- if and (.job) (.job.limit) }}
          limit: {{ .job.limit }}
          {{- else }}
          limit: {{ $.Values.job.retries }}
          {{- end }}
          {{- if and (.job) (.job.retryPolicy) }}
          # Valid Value:  "Always" | "OnFailure" | "OnError" | "OnTransientError", Default: "OnFailure"
          retryPolicy: {{ .job.retryPolicy }} 
          {{- else if $.Values.job.retryPolicy }}
          # Valid Value:  "Always" | "OnFailure" | "OnError" | "OnTransientError", Default: "OnFailure"
          retryPolicy: {{ $.Values.job.retryPolicy }}  
          {{- end }}
        {{- end }}
      {{- end }}
      {{- end }}

      {{- if .Values.containers }}
      {{- range .Values.containers }}
      - name: {{ .name }}
        metadata:
          namespace: {{ $.Release.Namespace }}
        {{- if or ($.Values.podSpecPatch) (.podSpecPatch) }}
        podSpecPatch: {{ (default $.Values.podSpecPatch .podSpecPatch) | quote }}
        {{- end }}
        {{- with .inputs }}
        inputs: {{ toYaml . | nindent 12 }}
        {{- end }}
        {{- with .outputs }}
        outputs: {{ toYaml . | nindent 12 }}
        {{- end }}
        container:
          image: {{ template "cronjob.argo_cron_workflow.image" (default $.Values.image .image) }}
          {{- if or ($.Values.command) (.command) }}
          command: {{- toYaml (default $.Values.command .command) | nindent 12 }}
          {{- end }}
          {{- if or ($.Values.args) (.args) }}
          args: {{- toYaml (default $.Values.args .args) | nindent 12 }}
          {{- end }}
          {{- if or ($.Values.resources) (.resources) }}
          # The resource will be apply if "resource is set" 
          resources: {{- toYaml (default $.Values.resources .resources) | nindent 12 }}
          {{- else }}
          # default settings on resources
          resources: {{- include "cronjob.argo_cron_workflow.default_resource" . | nindent 12 }}
          {{- end }}
          {{- if or ($.Values.securityContext) (.securityContext) }}
          securityContext: {{ toYaml (default $.Values.securityContext .securityContext) | nindent 12 }}
          {{- end }}
          env:
            - name: POD_NAME
              value: {{ $.Values.name }}
            {{- range $key, $value := $.Values.env }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
            {{- range $key, $name := $.Values.envSecrets }}
            - name: {{ $key }}
              valueFrom:
                secretKeyRef:
                  name: {{ $name }}
                  key: {{ $key | quote }}
            {{- end }}
          # Apply .Values.envFrom if it is set
          {{- if $.Values.envFrom }}
          envFrom:
            {{- range $.Values.envFrom.configMapRef }}
            - configMapRef:
                name: {{ . }}
            {{- end }}
            {{- range $.Values.envFrom.secretRef }}
            - secretRef:
                name: {{ . }}
            {{- end }}
          {{- end }}
      {{- end }}
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
          - name: Notice-SlackApp-Succeeded
            template: notice-slack-app-succeeded 
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
          - name: Notice-SlackApp-Failed
            template: notice-slack-app-failed 
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

{{- define "cronjob.argo_cron_workflow.image" -}}
'{{ required "image.repository must be provided" .repository }}:{{ required "image.tag must be provided" .tag }}'
{{- end -}}

{{- define "cronjob.argo_cron_workflow.default_resource" -}}
limits:
  memory: "2Gi"
  cpu: "1"
requests:
  cpu: "300m"
  memory: "1Gi"
{{- end -}}
