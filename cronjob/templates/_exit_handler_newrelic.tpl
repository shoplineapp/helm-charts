{{- define "cronjob._exit_handler_newrelic" -}}
      - name: notice-newrelic-failed
        container:
          image: johnku001/newrelic-notice-error-agent
          env:
            - name: NEWRELIC_APP_NAME
              value: "Argo Workflow Cronjob (Staging)"        
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