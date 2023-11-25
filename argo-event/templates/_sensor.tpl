{{- define "trigger_http" }}
          http:
            url: {{ .url }}
            method: {{ .method | default "POST"}}
            headers:
              content-type: application/json
            {{- with .payload }}
            payload:
              {{- toYaml . | nindent 14 }}
            {{- end -}}
{{- end }}