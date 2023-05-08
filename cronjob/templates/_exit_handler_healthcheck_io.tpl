{{- define "cronjob._exit_handler_healthcheck_io" -}}
{{- $healthcheckIo := .Values.exitNotifications.healthcheckIo | default dict -}}
      - name: notice-healthcheck-io-succeeded # For cronjob health check, as the schedule may different therefore each cronjob will have different uuid
        container:
          image: curlimages/curl
          command: [ "sh", "-c" ]
          args:
            - curl https://hc-ping.com/{{ required "exitNotifications.healthcheckIo.uuid must be provided" $healthcheckIo.uuid }}
      - name: notice-healthcheck-io-failed
        container:
          image: curlimages/curl
          command: [ "sh", "-c" ]
          args:
            - curl https://hc-ping.com/{{ required "exitNotifications.healthcheckIo.uuid must be provided" $healthcheckIo.uuid }}/fail
{{- end -}}