{{- define "cronjob._exit_handler_newrelic" -}}
{{- $image := .Values.newRelic.image | default dict -}}
      - name: notice-newrelic-failed
        container:
          image:  '{{ required "newRelic.image.repository must be provided" $image.repository }}:{{ required "newRelic.image.tag must be provided" $image.tag }}'
          env: 
            - name: NEWRELIC_APP_NAME
              value: "{{ required "newRelic.appName must be provided" .Values.newRelic.appName }}"        
            - name: FUNCTION_NAME
              value: "{{ .Values.name }}"        
            - name: NEWRELIC_LICENSE_KEY
              value: "{{ required "newRelic.licenseKey must be provided" .Values.newRelic.licenseKey }}"        
            - name: ARGO_WORKFLOW_ERROR
              value: "{{ "{{" }}workflow.failures{{ "}}" }}"              
            - name: ARGO_WORKFLOW_NAME
              value: "{{ "{{" }}workflow.name{{ "}}" }}"
            - name: ARGO_WORKFLOW_STATUS
              value: "{{ "{{" }}workflow.status{{ "}}" }}"        
            - name: ARGO_WORKFLOW_DURATION
              value: "{{ "{{" }}workflow.duration{{ "}}" }}"                                                          
{{- end -}}