{{- define "cronjob._exit_handler_health_check" -}}
      - name: notice-health-check-succeeded                                    # For cronjob health check, as the schedule may different therefore each cronjob will have different uuid
        container:
          image: curlimages/curl
          command: [ "sh", "-c" ]
          args:
            - curl https://hc-ping.com/{{ required "healthCheck.successUUID must be provided" .Values.healthCheck.SuccessUUID }}
      - name: notice-health-check-failed
        container:
          image: curlimages/curl
          command: [ "sh", "-c" ]
          args:
            - curl https://hc-ping.com/{{ required "healthCheck.failUUID must be provided" .Values.healthCheck.FailUUID }}/fail
{{- end -}}