{{- define "cronjob._exit_handler_slack_app" -}}
{{- $slackApp := .Values.exitNotifications.slackApp | default dict -}}
      - name: notice-slack-app-succeeded
        container:
          image: curlimages/curl
          command: [sh, -c]
          args: [
            "curl -X POST -H 'Content-type: application/json' --data '{\"attachments\": [
              {
                \"color\": \"#18be52\",
                \"blocks\": [
                  {
                    \"type\": \"header\",
                    \"text\": {
                      \"type\": \"plain_text\",
                      \"text\": \"Workflow Succeededed - {{ "{{" }}workflow.name{{ "}}" }}\",
                      \"emoji\": true
                    }
                  },
                  {
                    \"type\": \"divider\"
                  },
                  {
                    \"type\": \"section\",
                    \"fields\": [
                      {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Cluster*\\n{{ .Values.clusterName | default "unknown"}}\"
                      },
                      {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Namespace*\\n{{ "{{" }}workflow.namespace{{ "}}" }}\"
                      },
                      {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Duration*\\n{{ "{{" }}workflow.duration{{ "}}" }} sec\"
                      },
                      {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Link*\\n<{{required "exitNotifications.slackApp.portalDomain must be provided" $slackApp.portalDomain}}/workflows/{{ "{{" }}workflow.namespace{{ "}}" }}/{{ "{{" }}workflow.name{{ "}}" }}?tab=workflow|View>\"
                      }
                    ]
                  }
                ]
              }
            ]}'
           {{ required "exitNotifications.slackApp.webhookUrl must be provided" $slackApp.webhookUrl }}"
          ]
      - name: notice-slack-app-failed
        container:
          image: curlimages/curl
          command: [sh, -c]
          args: [
            "curl -X POST -H 'Content-type: application/json' --data '{\"attachments\": [
              {
                \"color\": \"#E01E5A\",
                \"blocks\": [
                  {
                    \"type\": \"header\",
                    \"text\": {
                      \"type\": \"plain_text\",
                      \"text\": \"Workflow Failed - {{ "{{" }}workflow.name{{ "}}" }}\",
                      \"emoji\": true
                    }
                  },
                  {
                    \"type\": \"divider\"
                  },
                  {
                    \"type\": \"section\",
                    \"fields\": [
                      {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Cluster*\\n{{ .Values.clusterName | default "unknown"}}\"
                      },
                      {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Namespace*\\n{{ "{{" }}workflow.namespace{{ "}}" }}\"
                      },
                      {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Duration*\\n{{ "{{" }}workflow.duration{{ "}}" }} sec\"
                      },
                      {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Link*\\n<{{required "exitNotifications.slackApp.portalDomain must be provided" $slackApp.portalDomain}}/workflows/{{ "{{" }}workflow.namespace{{ "}}" }}/{{ "{{" }}workflow.name{{ "}}" }}?tab=workflow|View>\"
                      }
                    ]
                  }
                ]
              }
            ]}'
            {{ required "exitNotifications.slackApp.webhookUrl must be provided" $slackApp.webhookUrl }}"
          ]
{{- end -}}