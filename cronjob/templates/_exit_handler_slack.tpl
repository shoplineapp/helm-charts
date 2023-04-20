{{- define "cronjob._exit_handler_slack" -}}
      - name: notice-slack-succeeded
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
                        \"text\": \"*Cluster*\\nec-eks-staging\"
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
                        \"text\": \"*Link*\\n<https://argo-workflows.shoplinestg.com/workflows/{{ "{{" }}workflow.namespace{{ "}}" }}/{{ "{{" }}workflow.name{{ "}}" }}?tab=workflow|View>\"
                      }
                    ]
                  }
                ]
              }
            ]}'
           {{ required "slack.ChannelURL must be provided" .Values.slack.ChannelURL }}"
          ]
      - name: notice-slack-failed
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
                        \"text\": \"*Cluster*\\nec-eks-staging\"
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
                        \"text\": \"*Link*\\n<https://argo-workflows.shoplinestg.com/workflows/{{ "{{" }}workflow.namespace{{ "}}" }}/{{ "{{" }}workflow.name{{ "}}" }}?tab=workflow|View>\"
                      }
                    ]
                  }
                ]
              }
            ]}'
            {{ required "slack.ChannelURL must be provided" .Values.slack.ChannelURL }}"
          ]
{{- end -}}