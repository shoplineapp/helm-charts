{{- define "deployment.container" -}}
- name: {{ .name }}
  {{- if hasKey . "command" }}
  command: {{ toYaml .command | nindent 4 }}
  {{- end }}
  {{- if hasKey . "args" }}
  args: {{ toYaml .args | nindent 4 }}
  {{- end }}
  image: "{{ .image.repository }}:{{ .image.tag }}"
  {{- if hasKey . "securityContext" }}
  securityContext: {{ toYaml .securityContext | nindent 4 }}
  {{- end }}
  imagePullPolicy: {{ .imagePullPolicy | default "IfNotPresent" }}
  env:
  - name: CONTAINER_NAME
    value: {{ .name }}
  {{- range $key, $value := .env }}
  - name: {{ $key }}
    value: {{ $value | quote }}
  {{- end }}
  {{- range $key, $ref := .envSecrets }}
  - name: {{ $key }}
    valueFrom:
      secretKeyRef:
        name: {{ $ref.name }}
        key: {{ $ref.key | quote }}
  {{- end }}
  {{- range .envFromFieldRefs }}
  - name: {{ .name }}
    valueFrom:
      fieldRef:
        fieldPath: {{ .fieldPath }}
  {{- end }}
  envFrom:
  {{- range .envFromConfigmap }}
  - configMapRef:
      name: {{ .name }}
  {{- end }}
  {{- range .envFromSecret }}
  - secretRef:
      name: {{ .name }}
  {{- end }}
  {{- if hasKey . "ports" }}
  ports:
  {{- range .ports }}
  - name: {{ .name }}
    containerPort: {{ .port }}
    protocol: {{ .protocol | default "TCP" }}
  {{- end }}
  {{- end }}
  {{- if hasKey . "livenessProbe" }}
  livenessProbe: {{- toYaml .livenessProbe | nindent 4 }}
  {{- end }}
  {{- if hasKey . "readinessProbe" }}
  readinessProbe: {{- toYaml .readinessProbe | nindent 4 }}
  {{- end }}
  {{- if hasKey . "startupProbe" }}
  startupProbe: {{- toYaml .startupProbe | nindent 4 }}
  {{- end }}
  {{- if hasKey . "volumeMounts" }}
  volumeMounts:
    {{- toYaml .volumeMounts | nindent 4 }}
  {{- end }}
  {{- if hasKey . "resources" }}
  resources: {{- toYaml .resources | nindent 4 }}
  {{- end }}
  {{- if hasKey . "lifecycle" }}
  lifecycle: {{- toYaml .lifecycle | nindent 4 }}
  {{- else }}
  lifecycle:
    preStop:
      exec:
        command: ["sleep", "60"]
  {{- end }}
{{- end -}}