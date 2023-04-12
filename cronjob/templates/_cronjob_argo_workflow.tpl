{{- define "cronjob.cronjob_argo_workflow" -}}
{{- $healthCheck := .Values.healthCheck | default dict -}}
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
        - name: exec_duration_gauge                                   # Metric name (will be prepended with "argo_workflows_")
          labels:                                                     # Labels are optional. Avoid cardinality explosion.
            - key: name
              value: "{{ "{{" }}workflow.labels.name{{ "}}" }}"
            - key: kind
              value: "cron-workflow"
          help: "Duration gauge by name"                              # A help doc describing your metric. This is required.
          gauge:                                                      # The metric type. Available are "gauge", "histogram", and "counter".
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
          when: "{{ "{{" }}status{{ "}}" }} != Succeeded" # Emit the metric conditionally. Works the same as normal "when"
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
          when: "{{ "{{" }}status{{ "}}" }} == Succeeded"             # Emit the metric conditionally. Works the same as normal "when"
          counter:
            value: "1"                                                # This increments the counter by 1
    entrypoint: entry
    onExit: exit-handler
    templates:
      - name: entry
        steps:
          - - name: step1
              template: template
        {{- if and  (.Values.job) (.Values.job.retries)}}      
        retryStrategy:                                                # will cause a container to retry until completion if it is empty 
          limit: {{ .Values.job.retries }}
          {{- if .Values.job.retryPolicy }} 
          retryPolicy: {{ .Values.job.retryPolicy }}                  # Valid Value:  "Allow" | "Forbid" | "Replace" 
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
      - name: exit-handler
        steps:
        - - name: Success
            template: success-handler
            when: "{{ "{{" }}workflow.status{{ "}}" }} == Succeeded" 
          - name: Failed
            template: failed-handler
            when: "{{ "{{" }}workflow.status{{ "}}" }} != Succeeded"
      - name: success-handler                                                 # template for the success case
        steps: 
        - - name: Notice-Health-Check-Succeed
            template: notice-health-check-succeed            
      - name: failed-handler                                                  # template for the failed case
        steps: 
        - - name: Notice-Health-Check-Failed
            template: notice-health-check-failed 
         {{- if and (.Values.newRelic)  (.Values.newRelic.enabled) }}          
          - name: Notice-NewRelic-Failed
            template: notice-newrelic-failed            
          {{- end }}    
      - name: notice-health-check-succeed                                    # For cronjob health check, as the schedule may different therefore each cronjob will have different uuid
        container:
          image: curlimages/curl
          command: [ "sh", "-c" ]
          args:
            - curl https://hc-ping.com/{{ required "healthCheck.successUUID must be provided" $healthCheck.SuccessUUID }}
      - name: notice-health-check-failed
        container:
          image: curlimages/curl
          command: [ "sh", "-c" ]
          args:
            - curl https://hc-ping.com/{{ required "healthCheck.failUUID must be provided" $healthCheck.FailUUID }}/fail
      {{- if and (.Values.newRelic)  (.Values.newRelic.enabled) }}                                        
      - name: notice-newrelic-failed
        container:
          image: johnku001/newrelic-notice-error-agent
          env:
            - name: NEWRELIC_APP_NAME
              value: "Argo Workflow Cronjob (Staging)"        
            - name: FUNCTION_NAME
              value: "{{ required "newRelic.functionName must be provided" .Values.newRelic.functionName }}"        
            - name: NEWRELIC_LICENSE_KEY
              value: "{{ required "newRelic.licenseKey must be provided" .Values.newRelic.licenseKey }}"                                      
          args:
            - error={{ "{{" }}workflow.failures{{ "}}" }} 
            - workflow_name="{{ "{{" }}workflow.name{{ "}}" }}" 
            - workflow_status="{{ "{{" }}workflow.status{{ "}}" }}" 
            - workflow_duration="{{ "{{" }}workflow.duration{{ "}}" }}"
      {{- end }}            
    {{- if and (.Values.ttlStrategy) (.Values.ttlStrategy.secondsAfterCompletion) }}  # Can keep the pod after finish during development
    ttlStrategy:
      secondsAfterCompletion: {{.Values.ttlStrategy.secondsAfterCompletion}}
    {{- end }}
    podGC:
      strategy: {{ $podGC.strategy | default "OnPodCompletion"}}
{{- end -}}
