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
    {{- if and (.Values.job) (.Values.job.timeout) (ne (.Values.job.timeout | int) -1) }}
    activeDeadlineSeconds: {{.Values.job.timeout }}
    {{- else if and (.Values.job) (.Values.job.timeout) (eq (.Values.job.timeout | int) -1) }} 
    activeDeadlineSeconds: null # if timeout equal to -1, the pod will not dead until the task is completed
    {{- end }}         
    metrics:
      prometheus:
        - name: cron_workflow_exec_duration_gauge # Metric name (will be prepended with "argo_workflows_")
          labels: # Labels are optional. Avoid cardinality explosion.
            - key: name
              value: "{{ "{{" }}workflow.labels.name{{ "}}" }}"
            - key: namespace
              value: "{{ "{{" }}workflow.namespace{{ "}}" }}"              
            - key: kind
              value: "cron-workflow"
          help: "Duration gauge by name" # A help doc describing your metric. This is required.
          gauge:  # The metric type. Available are "gauge", "histogram", and "counter".
            value: "{{ "{{" }}workflow.duration{{ "}}" }}"  # The value of your metric. It could be an Argo variable (see variables doc) or a literal value
        - name: cron_workflow_fail_count
          labels:
            - key: name
              value: "{{ "{{" }}workflow.labels.name{{ "}}" }}"
            - key: namespace
              value: "{{ "{{" }}workflow.namespace{{ "}}" }}"
            - key: kind
              value: "cron-workflow"
          help: "Count of execution by fail status"                  
          when: "{{ "{{" }}status{{ "}}" }} != Succeededed" # Emit the metric conditionally. Works the same as normal "when"
          counter:
            value: "1"  # This increments the counter by 1
        - name: cron_workflow_success_count
          labels:
            - key: name
              value: "{{ "{{" }}workflow.labels.name{{ "}}" }}"
            - key: namespace
              value: "{{ "{{" }}workflow.namespace{{ "}}" }}"
            - key: kind
              value: "cron-workflow"
          help: "Count of execution by success status"                            
          when: "{{ "{{" }}status{{ "}}" }} == Succeededed" # Emit the metric conditionally. Works the same as normal "when"
          counter:
            value: "1"  # This increments the counter by 1
    entrypoint: entry
    {{- if .Values.exitNotifications }}    
    onExit: exit-handler
    {{- end }}  
    templates:
      - name: entry
        steps:
          - - name: step1
              template: template
        {{- if and  (.Values.job) (.Values.job.retries)}}      
        retryStrategy:  # will cause a container to retry until completion if it is empty 
          limit: {{ .Values.job.retries }}
          {{- if .Values.job.retryPolicy }} 
          retryPolicy: {{ .Values.job.retryPolicy }}  # Valid Value:  "Always" | "OnFailure" | "OnError" | "OnTransientError", Default: "OnFailure"
          {{- end }}  
        {{- end }}        
      - name: template
        metadata:
          namespace: {{ .Release.Namespace }}
        container:
          image: '{{ required "image.repository must be provided" .Values.image.repository }}:{{ required "image.tag must be provided" .Values.image.tag }}'
          {{- if .Values.command }}
          command:  {{- toYaml ( .Values.command) | nindent 11 }}
          {{- end }}
          {{- if .Values.args }}
          args: {{- toYaml ( .Values.args) | nindent 11 }}
          {{- end }}
          {{- if .Values.resources }}
          resources: {{- toYaml ( .Values.resources) | nindent 11 }}
          {{- else }} # default settings on resources
          resources:  
            limits:
              memory: "2Gi"
              cpu: "1"
            requests:
              cpu: "300M"
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
      {{- if .Values.exitNotifications }}    
      - name: exit-handler
        steps:
        - - name: Success
            template: success-handler
            when: "{{ "{{" }}workflow.status{{ "}}" }} == Succeeded" 
          - name: Failure
            template: failure-handler
            when: "{{ "{{" }}workflow.status{{ "}}" }} != Succeeded"
      - name: success-handler # template for the success case
        steps:
        -
          {{- if .Values.exitNotifications.slackApp }}  
          - name: Notice-SlackApp-Succeeded
            template: notice-slack-app-succeeded 
          {{- end }}     
          {{- if .Values.exitNotifications.healthcheckIo }}  
          - name: Notice-HealthcheckIo-Succeeded
            template: notice-healthcheck-io-succeeded 
          {{- end }}                             
      - name: failure-handler  # template for the failed case
        steps: 
        -
          {{- if .Values.exitNotifications.slackApp }}  
          - name: Notice-SlackApp-Failed
            template: notice-slack-app-failed 
          {{- end }}
         {{- if .Values.exitNotifications.newRelic }}          
          - name: Notice-NewRelic-Failed
            template: notice-newrelic-failed            
         {{- end }}
         {{- if  .Values.exitNotifications.healthcheckIo }}  
          - name: Notice-HealthcheckIo-Failed
            template: notice-healthcheck-io-failed
         {{- end }}                                
      {{- if .Values.exitNotifications.slackApp }}                                        
      {{ template "cronjob._exit_handler_slack_app" . }}
      {{- end }}
      {{- if .Values.exitNotifications.newRelic }}                                        
      {{ template "cronjob._exit_handler_newrelic" . }}
      {{- end }}
      {{- if .Values.exitNotifications.healthcheckIo }}                                        
      {{ template "cronjob._exit_handler_healthcheck_io" . }}
      {{- end }}                                     
      {{- end }}                           
    {{- if and (.Values.ttlStrategy) (.Values.ttlStrategy.secondsAfterCompletion) }} 
    ttlStrategy:  # Can keep the pod after finish during development
      secondsAfterCompletion: {{.Values.ttlStrategy.secondsAfterCompletion}}
    {{- end }}
    podGC:
      strategy: {{ $podGC.strategy | default "OnPodCompletion"}}
{{- end -}}
