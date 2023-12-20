{{- define "source.webhook" }}
    {{- $item := index . 0 -}}
    {{- $globalVal := index . 1 -}}
    {{- $item.eventName | required "Missing eventName" }}:
      endpoint: {{ $item.endpoint | required (printf "Missing endpoint for source: %s" $item.eventName) | printf "/webhook%s" }}
      method: {{ $item.method | required (printf "Missing method for source: %s " $item.eventName) }}
      port: {{ $globalVal.eventsource.config.webhookPort | quote}}
{{- end }}