{{- define "cronjob._exit_handler_slack_app" -}}
{{- $slackApp := .Values.exitNotifications.slackApp | default dict -}}
      - name: notice-slack-app-succeeded
        container:
          image: 332947256684.dkr.ecr.ap-southeast-1.amazonaws.com/curlimages/curl:8.4.0
          command: [sh, -c]
          args: [
            "curl -X POST -H 'Content-type: application/json' --data '{\"attachments\": [
              {
                \"fallback\": \"Workflow Succeeded - {{ "{{" }}workflow.name{{ "}}" }}\",
                \"color\": \"#18be52\",
                \"blocks\": [
                  {
                    \"type\": \"header\",
                    \"text\": {
                      \"type\": \"plain_text\",
                      \"text\": \"Workflow Succeeded - {{ "{{" }}workflow.name{{ "}}" }}\",
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
                        \"text\": \"*Scheduled Time*\\n{{ "{{" }}workflow.scheduledTime{{ "}}" }}\"
                      },
                      {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Duration*\\n{{ "{{" }}workflow.duration{{ "}}" }} sec\"
                      },
                      {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Argo Dashboard*\\n<{{required "exitNotifications.slackApp.portalDomain must be provided" $slackApp.portalDomain}}/workflows/{{ "{{" }}workflow.namespace{{ "}}" }}/{{ "{{" }}workflow.name{{ "}}" }}?tab=workflow|View>\"
                      }
                      {{- if $slackApp.customUrls }}
                      ,{
                        \"type\": \"mrkdwn\",
                        {{ $max := add (len $slackApp.customUrls) -1 }}
                        \"text\": \"*Extra Links*\\n{{- range $index, $value := $slackApp.customUrls }}
                        {{- with $value }}
                            <{{ .url }}|{{ .title }}>
                            {{- if gt $max $index }},{{- end}}
                        {{- end }}
                        {{- end }}\"
                      }
                      {{- end }}
                    ]
                  }
                  {{- if $slackApp.mention }}
                  {{- if $slackApp.mention.onSuccess }}
                  ,{
                    \"type\": \"section\",
                    \"text\": {
                      \"type\": \"mrkdwn\",
                      \"text\": \"{{ range $slackApp.mention.onSuccess -}}{{ if (hasPrefix "S" .) }}<!subteam^{{.}}>{{ else }}<@{{.}}> {{ end }}{{ end }}\"
                    }
                  }
                  {{- end }} 
                  {{- end }}
                ]
              }
            ]}'
           {{ required "exitNotifications.slackApp.webhookUrl must be provided" $slackApp.webhookUrl }}"
          ]
      - name: notice-slack-app-failed
        container:
          image: 332947256684.dkr.ecr.ap-southeast-1.amazonaws.com/curlimages/curl:8.4.0
          command: [sh, -c]
          args: [
            "curl -X POST -H 'Content-type: application/json' --data '{\"attachments\": [
              {
                \"fallback\": \"Workflow Failed - {{ "{{" }}workflow.name{{ "}}" }}\",
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
                        \"text\": \"*Scheduled Time*\\n{{ "{{" }}workflow.scheduledTime{{ "}}" }}\"
                      },
                      {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Duration*\\n{{ "{{" }}workflow.duration{{ "}}" }} sec\"
                      },
                      {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Argo Dashboard*\\n<{{required "exitNotifications.slackApp.portalDomain must be provided" $slackApp.portalDomain}}/workflows/{{ "{{" }}workflow.namespace{{ "}}" }}/{{ "{{" }}workflow.name{{ "}}" }}?tab=workflow|View>\"
                      }
                      {{- if $slackApp.customUrls }}
                      ,{
                        \"type\": \"mrkdwn\",
                        {{ $max := add (len $slackApp.customUrls) -1 }}
                        \"text\": \"*Extra Links*\\n{{- range $index, $value := $slackApp.customUrls }}
                        {{- with $value }}
                            <{{ .url }}|{{ .title }}>
                            {{- if gt $max $index }},{{- end}}
                        {{- end }}
                        {{- end }}\"
                      }
                      {{- end }}
                    ]
                  }
                  {{- if $slackApp.mention }}
                  {{- if $slackApp.mention.onFailure }}
                  ,{
                    \"type\": \"section\",
                    \"text\": {
                      \"type\": \"mrkdwn\",
                      \"text\": \"{{ range $slackApp.mention.onFailure -}}{{ if (hasPrefix "S" .) }}<!subteam^{{.}}>{{ else }}<@{{.}}> {{ end }}{{ end }}\"
                    }
                  }
                  {{- end }}
                  {{- end }}
                  {{- if $slackApp.runbook }}
                  ,{
                    \"type\": \"section\",
                    \"text\": {
                        \"type\": \"mrkdwn\",
                        \"text\": \"*Runbook*{{- range $line := $slackApp.runbook }}\\n{{$line}}{{- end}}\"
                    }
                  }
                  {{- end }}
                ]
              }
            ]}'
            {{ required "exitNotifications.slackApp.webhookUrl must be provided" $slackApp.webhookUrl }}"
          ]
{{- end -}}
