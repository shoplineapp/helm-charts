{{- define "cronjob.argo_cron_workflow" -}}
{{- $podGC := .Values.podGC | default dict -}}
    workflowSpec:
    workflowMetadata:
      labels:
        name: {{ .Values.name }}
      {{- range $key, $value := .Values.annotations }}
      {{ $key | quote }} : {{ $value | quote }}
      {{- end }}
    {{- if .Values.serviceaccount }}
    serviceAccountName: {{ .Values.serviceaccount.name | default (printf "%s-pod-service-account" .Values.name) }}
    {{- else if .Values.serviceAccount }}
    serviceAccountName: {{ .Values.name }}-pod-service-account
    {{- end }}
    # Reason why use "-1" to unset "activeDeadlineSeconds" instead of the checking the existance of ".Values.job.timeout" is because there is default value "1800" for ".Values.job.timeout" and we would like to kind this behavour
    {{- if and (.Values.job) (.Values.job.timeout) (ne (.Values.job.timeout | int) -1) }}
    # if timeout not equal to -1, the pod will be kill after certain seconds
    activeDeadlineSeconds: {{.Values.job.timeout }}
    {{- else if and (.Values.job) (.Values.job.timeout) (eq (.Values.job.timeout | int) -1) }}
    # if timeout equal to -1, the pod will not dead until the task is completed
    activeDeadlineSeconds: null 
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
    entrypoint: entry
    # If not exitNotifications config is set, the default exit-handler of the argo server will be used 
    {{- if .Values.exitNotifications }}
    onExit: exit-handler 
    {{- end }}
    templates:
      - name: entry
        steps:
          - - name: step1
              template: template
        {{- if and  (.Values.job) (.Values.job.retries)}}
        retryStrategy:
          # Limit of retries if the job is fail   
          limit: {{ .Values.job.retries }}
          {{- if .Values.job.retryPolicy }}
          # Valid Value:  "Always" | "OnFailure" | "OnError" | "OnTransientError", Default: "OnFailure"
          retryPolicy: {{ .Values.job.retryPolicy }}  
          {{- end }}
        {{- end }}
      - name: template
        metadata:
          namespace: {{ .Release.Namespace }}
        container:
          image: '{{ required "image.repository must be provided" .Values.image.repository }}:{{ required "image.tag must be provided" .Values.image.tag }}'
          {{- if .Values.command }}
          # The command to call the function of the image
          command:  {{- toYaml ( .Values.command) | nindent 11 }}
          {{- end }}
          {{- if .Values.args }}
          # The args need to pass for the function
          args: {{- toYaml ( .Values.args) | nindent 11 }}
          {{- end }}
          {{- if .Values.resources }}
          # The resource will be apply if "resource is set" 
          resources: {{- toYaml ( .Values.resources) | nindent 11 }}
          {{- else }}
          # default settings on resources
          resources:
            limits:
              memory: "2Gi"
              cpu: "1"
            requests:
              cpu: "300m"
              memory: "1Gi"
          {{- end }}
          env:
            - name: POD_NAME
              value: {{ .Values.name }}
            {{- range $key, $value := .Values.env }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
            {{- range $key, $name := .Values.envSecrets }}
            - name: {{ $key }}
              valueFrom:
                secretKeyRef:
                  name: {{ $name }}
                  key: {{ $key | quote }}
            {{- end }}
          # Apply .Values.envFrom if it is set
          {{- if .Values.envFrom }}
          envFrom:
            {{- range .Values.envFrom.configMapRef }}
            - configMapRef:
                name: {{ . }}
            {{- end }}
            {{- range .Values.envFrom.secretRef }}
            - secretRef:
                name: {{ . }}
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
    {{- if and (.Values.ttlStrategy) (.Values.ttlStrategy.secondsAfterCompletion) }}
    ttlStrategy:
      # The second of the pod can be alive after the job is done
      secondsAfterCompletion: {{.Values.ttlStrategy.secondsAfterCompletion}}
    {{- end }}
    podGC:
      strategy: {{ $podGC.strategy | default "OnPodCompletion"}}
{{- end -}}