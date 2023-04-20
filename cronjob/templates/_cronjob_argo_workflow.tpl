{{- define "cronjob.cronjob_argo_workflow" -}}
{{- $podGC := .Values.podGC | default dict -}}
    workflowSpec:
    workflowMetadata:
      labels:
        name: {{ .Values.name }}
      {{- range $key, $value := .Values.annotations }}
      {{ $key | quote }} : {{ $value | quote }}
      {{- end }}  
    {{- if .Values.serviceaccount }}
    serviceAccountName: {{ .Values.serviceaccount.name | default (printf "%s-argo-workflows-admin-service-account" .Release.Namespace) }}
    {{- else if .Values.serviceAccount }}
    serviceAccountName: {{ .Release.Namespace  }}-argo-workflows-admin-service-account
    {{- end }}  
    {{- if and (.Values.job) (.Values.job.timeout) (ne (.Values.job.timeout | int) -1) }}
    activeDeadlineSeconds: {{.Values.job.timeout }}
    {{- else if and (.Values.job) (.Values.job.timeout) (eq (.Values.job.timeout | int) -1) }} 
    activeDeadlineSeconds: null # if timeout equal to -1, the pod will not dead until the task is completed
    {{- end }}         
    metrics:
      prometheus:
        - name: exec_duration_gauge # Metric name (will be prepended with "argo_workflows_")
          labels: # Labels are optional. Avoid cardinality explosion.
            - key: name
              value: "{{ "{{" }}workflow.labels.name{{ "}}" }}"
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
    {{- if or (.Values.healthCheck) (.Values.slack) (.Values.newRelic) }}  
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
          retryPolicy: {{ .Values.job.retryPolicy }}  # Valid Value:  "Allow" | "Forbid" | "Replace" 
          {{- end }}  
        {{- end }}        
      - name: template
        metadata:
          namespace: {{ .Release.Namespace }}
          kind: "cron-workflow"    
        container:
          image: '{{ required "image.repository must be provided" .Values.image.repository }}:{{ required "image.tag must be provided" .Values.image.tag }}'
          {{- if .Values.command }}
          command:  {{- toYaml ( .Values.command) | nindent 11 }}
          {{- end }}
          {{- if .Values.command }}
          args: {{- toYaml ( .Values.args) | nindent 11 }}
          {{- end }}
          {{- if .Values.resources }}
          resources: {{- toYaml ( .Values.resources) | nindent 11 }}
          {{- else }} # default settings on resources
          resources:  
            limits:
              memory: "4Gi"
            requests:
              cpu: "0.5"
              memory: "3Gi"
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
      {{- if or (.Values.healthCheck) (.Values.slack) (.Values.newRelic) }}    
      - name: exit-handler
        steps:
        - - name: Success
            template: success-handler
            when: "{{ "{{" }}workflow.status{{ "}}" }} == Succeeded" 
          - name: Failed
            template: failed-handler
            when: "{{ "{{" }}workflow.status{{ "}}" }} != Succeeded"
      - name: success-handler # template for the success case
        steps:
        -
          {{- if .Values.healthCheck }}  
          - name: Notice-Health-Check-Succeeded
            template: notice-health-check-succeeded 
          {{- end }}
          {{- if .Values.slack }}  
          - name: Notice-Slack-Succeeded
            template: notice-slack-succeeded 
          {{- end }}                          
      - name: failed-handler  # template for the failed case
        steps: 
        -
         {{- if .Values.newRelic }}          
          - name: Notice-NewRelic-Failed
            template: notice-newrelic-failed            
         {{- end }}
         {{- if  .Values.healthCheck }}  
          - name: Notice-Health-Check-Failed
            template: notice-health-check-failed
         {{- end }}  
          {{- if .Values.slack }}  
          - name: Notice-Slack-Failed
            template: notice-slack-failed 
          {{- end }}                      
      {{- if .Values.newRelic }}                                        
      {{ template "cronjob._exit_handler_newrelic" . }}
      {{- end }}
      {{- if .Values.healthCheck }}                                        
      {{ template "cronjob._exit_handler_health_check" . }}
      {{- end }} 
      {{- if .Values.slack }}                                        
      {{ template "cronjob._exit_handler_slack" . }}
      {{- end }}                           
      {{- end }}                           
    {{- if and (.Values.ttlStrategy) (.Values.ttlStrategy.secondsAfterCompletion) }} 
    ttlStrategy:  # Can keep the pod after finish during development
      secondsAfterCompletion: {{.Values.ttlStrategy.secondsAfterCompletion}}
    {{- end }}
    podGC:
      strategy: {{ $podGC.strategy | default "OnPodCompletion"}}
{{- end -}}
