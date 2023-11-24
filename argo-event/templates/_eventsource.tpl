{{- define "source_webhook" }}
    {{- .eventName | required "Missing eventName" }}:
      endpoint: {{ .endpoint | required (printf "Missing endpoint for source: %s" .eventName) | printf "/webhook%s" }}
      method: {{ .method | required (printf "Missing method for source: %s " .eventName) }}
      port: "12051"
{{- end }}