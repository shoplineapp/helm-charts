{{- define "cronjob._exit_handler_newrelic" -}}
{{- $newRelic := .Values.exitNotifications.newRelic | default dict -}}
{{- $image := $newRelic.image | default dict -}}
      - name: notice-newrelic-failed
        container:
          image: '{{ required "exitNotifications.newRelic.image.repository must be provided" $image.repository }}:{{ required "exitNotifications.newRelic.image.tag must be provided" $image.tag }}'
          env: 
            - name: NEWRELIC_APP_NAME
              value: "{{ required "exitNotifications.newRelic.appName must be provided" $newRelic.appName }}"
            - name: FUNCTION_NAME
              value: "{{ .Values.name }}"
            - name: NEWRELIC_LICENSE_KEY
              value: "{{ required "exitNotifications.newRelic.licenseKey must be provided" $newRelic.licenseKey }}"
            - name: ARGO_WORKFLOW_ERROR
              value: "{{ "{{" }}workflow.failures{{ "}}" }}"
            - name: ARGO_WORKFLOW_NAME
              value: "{{ "{{" }}workflow.name{{ "}}" }}"
            - name: ARGO_WORKFLOW_STATUS
              value: "{{ "{{" }}workflow.status{{ "}}" }}"
            - name: ARGO_WORKFLOW_DURATION
              value: "{{ "{{" }}workflow.duration{{ "}}" }}"
{{- end -}}