{{- define "helper.containType" -}}
  {{- $list := index . 0 -}}
  {{- $search := index . 1 -}}
  {{- if eq (first $list).type $search -}}
    yes
  {{- else if lt 1 (len $list) -}}
    {{- include "helper.containType" (list (rest $list) $search) -}}
  {{- end -}}
{{- end -}}