{{- define "cronjob.cronjob_argo_workflow" -}}
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
    {{- if and (.Values.job) (.Values.job.timeout) }}
    activeDeadlineSeconds	: {{.Values.job.timeout }}
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
            value: "{{ "{{" }}workflow.duration{{ "}}" }}"            # The value of your metric. It could be an Argo variable (see variables doc) or a literal value
        - name: cron_workflow_fail_count
          labels:
            - key: name
              value: "{{ "{{" }}workflow.labels.name{{ "}}" }}"
            - key: namespace
              value: "{{ "{{" }}workflow.namespace{{ "}}" }}"
            - key: kind
              value: "cron-workflow"
          help: "Count of execution by fail status"                  
          when: "{{ "{{" }}status{{ "}}" }} != Succeeded"             # Emit the metric conditionally. Works the same as normal "when"
          counter:
            value: "1"                                                # This increments the counter by 1
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
          {{- else }}   # default settings on resources
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
    {{- if and (.Values.ttlStrategy) (.Values.ttlStrategy.secondsAfterCompletion) }}                               # Can keep the pod after finish during development
    ttlStrategy:
      secondsAfterCompletion: {{.Values.ttlStrategy.secondsAfterCompletion}}
    podGC:
      labelSelector:
        matchLabels:
          should-be-deleted: "true"
    {{- end }}
{{- end -}}
