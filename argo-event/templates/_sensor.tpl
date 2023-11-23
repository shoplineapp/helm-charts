{{- define "trigger_http" }}
          http:
            url: {{ .url }}
            method: {{ .method | default "POST"}}
            {{- with .payload }}
            payload:
              {{- toYaml . | nindent 14 }}
            {{- end -}}
{{- end }}