{{- define "workflow-lib._exit_handler_slack_app" -}}
{{- $slackApp := .Values.exitNotifications.slackApp | default dict -}}
{{- $sendOnSuccess := list nil true "true" | has $slackApp.sendOnSuccess -}}
{{- $sendOnFailure := list nil true "true" | has $slackApp.sendOnFailure -}}
{{- if eq $sendOnSuccess true }}
- name: notice-slack-app-succeeded
  container:
    image: 332947256684.dkr.ecr.ap-southeast-1.amazonaws.com/curlimages/curl:8.4.0
    command: [sh, -c]
    args:
      - >
        cat << ---EOF--- | curl -X POST --tlsv1.2 --retry 3 --retry-all-errors --fail -H 'Content-type: application/json' --data @- {{ required "exitNotifications.slackApp.webhookUrl must be provided" $slackApp.webhookUrl }}

        {
          "attachments": [
            {
            "fallback": "Workflow Succeeded - {{ "{{" }}workflow.name{{ "}}" }}",
            "color": "#18be52",
            "blocks": [
              {
                "type": "header",
                "text": {
                  "type": "plain_text",
                  "text": "Workflow Succeeded - {{ "{{" }}workflow.name{{ "}}" }}",
                  "emoji": true
                }
              },
              {
                "type": "divider"
              },
              {
                "type": "section",
                "fields": [
                  {
                    "type": "mrkdwn",
                    "text": "*Cluster*\n{{ .Values.clusterName | default "unknown"}}"
                  },
                  {
                    "type": "mrkdwn",
                    "text": "*Namespace*\n{{ "{{" }}workflow.namespace{{ "}}" }}"
                  },
                  {
                    "type": "mrkdwn",
                    "text": "*Scheduled Time*\n{{ "{{" }}workflow.scheduledTime{{ "}}" }}"
                  },
                  {
                    "type": "mrkdwn",
                    "text": "*Duration*\n{{ "{{" }}workflow.duration{{ "}}" }} sec"
                  }
                ]
              }
              {{- if $slackApp.mention }}
              {{- if $slackApp.mention.onSuccess }}
              ,{
                "type": "section",
                "text": {
                  "type": "mrkdwn",
                  "text": "{{ range $slackApp.mention.onSuccess -}}{{ if (hasPrefix "S" .) }}<!subteam^{{.}}>{{ else }}<@{{.}}> {{ end }}{{ end }}"
                }
              }
              {{- end }}
              {{- end }}
              ,
              {
                "type": "actions",
                "elements": [
                  {
                    "type": "button",
                    "text": {
                      "type": "plain_text",
                      "text": "Argo Dashboard"
                    },
                    "url": "{{required "exitNotifications.slackApp.portalDomain must be provided" $slackApp.portalDomain}}/workflows/{{ "{{" }}workflow.namespace{{ "}}" }}/{{ "{{" }}workflow.name{{ "}}" }}?tab=workflow"
                  }
                {{- if $slackApp.customUrls }}
                {{- range $index, $value := $slackApp.customUrls }}
                {{- with $value }}
                  ,{
                    "type": "button",
                    "text": {
                      "type": "plain_text",
                      "text": {{.title | quote}}
                    },
                    "url": {{.url | quote}}
                  }
                {{- end }}
                {{- end }}
                {{- end }}
                ]
              }
            ]
            }
          ]
        }

        ---EOF---
{{- end -}}
{{- if eq $sendOnFailure true }}
- name: notice-slack-app-failed
  container:
    image: 332947256684.dkr.ecr.ap-southeast-1.amazonaws.com/curlimages/curl:8.4.0
    command: [sh, -c]
    args:
      - >
        cat << ---EOF--- | curl -X POST --tlsv1.2 --retry 3 --retry-all-errors --fail -H 'Content-type: application/json' --data @- {{ required "exitNotifications.slackApp.webhookUrl must be provided" $slackApp.webhookUrl }}

        {
          "attachments": [
            {
            "fallback": "Workflow Failed - {{ "{{" }}workflow.name{{ "}}" }}",
            "color": "#E01E5A",
            "blocks": [
              {
                "type": "header",
                "text": {
                  "type": "plain_text",
                  "text": "Workflow Failed - {{ "{{" }}workflow.name{{ "}}" }}",
                  "emoji": true
                }
              },
              {
                "type": "divider"
              },
              {
                "type": "section",
                "fields": [
                  {
                    "type": "mrkdwn",
                    "text": "*Cluster*\n{{ .Values.clusterName | default "unknown"}}"
                  },
                  {
                    "type": "mrkdwn",
                    "text": "*Namespace*\n{{ "{{" }}workflow.namespace{{ "}}" }}"
                  },
                  {
                    "type": "mrkdwn",
                    "text": "*Scheduled Time*\n{{ "{{" }}workflow.scheduledTime{{ "}}" }}"
                  },
                  {
                    "type": "mrkdwn",
                    "text": "*Duration*\n{{ "{{" }}workflow.duration{{ "}}" }} sec"
                  }
                ]
              }
              {{- if $slackApp.mention }}
              {{- if $slackApp.mention.onFailure }}
              ,{
                "type": "section",
                "text": {
                  "type": "mrkdwn",
                  "text": "{{ range $slackApp.mention.onFailure -}}{{ if (hasPrefix "S" .) }}<!subteam^{{.}}>{{ else }}<@{{.}}> {{ end }}{{ end }}"
                }
              }
              {{- end }}
              {{- end }}
              {{- if $slackApp.runbook }}
              ,{
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    {{- $joined := join "\n" $slackApp.runbook }}
                    "text": {{ printf "*Runbook*\n%s" $joined | quote }}
                }
              }
              {{- end }}
              ,{
                "type": "actions",
                "elements": [
                  {
                    "type": "button",
                    "text": {
                      "type": "plain_text",
                      "text": "Argo Dashboard"
                    },
                    "url": "{{required "exitNotifications.slackApp.portalDomain must be provided" $slackApp.portalDomain}}/workflows/{{ "{{" }}workflow.namespace{{ "}}" }}/{{ "{{" }}workflow.name{{ "}}" }}?tab=workflow"
                  }
                {{- if $slackApp.customUrls }}
                {{- range $index, $value := $slackApp.customUrls }}
                {{- with $value }}
                  ,{
                    "type": "button",
                    "text": {
                      "type": "plain_text",
                      "text": {{.title | quote}}
                    },
                    "url": {{.url | quote}}
                  }
                {{- end }}
                {{- end }}
                {{- end }}
                ]
              }
            ]
            }
          ]
        }

        ---EOF---
{{- end -}}
{{- end -}}
