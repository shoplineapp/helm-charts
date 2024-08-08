{{- define "cronjob.k8s_cronjob" -}}
  jobTemplate:
    metadata:
      annotations:
        cronjob_name: {{ .Values.name }}
    spec:
      backoffLimit: {{ .Values.job.retries }}
      activeDeadlineSeconds: {{ .Values.job.timeout }}
      template:
        metadata:
          annotations:
            cronjob_name: {{ .Values.name }}
            {{- range $key, $value := .Values.annotations }}
            {{ $key | quote }} : {{ $value | quote }}
            {{- end }}
        spec:
          {{- if .Values.serviceaccount }}
          serviceAccountName: {{ .Values.serviceaccount.name | default (printf "%s-pod-service-account" .Values.name) }}
          {{- else if .Values.serviceAccount }}
          serviceAccountName: {{ .Values.name }}-pod-service-account
          {{- end }}
          restartPolicy: Never
          containers:
            -
              name: app
              image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
              {{- if .Values.command }}
              command: {{- toYaml .Values.command | nindent 16 }}
              {{- end }}
              {{- if hasKey .Values "resources" }}
              resources: {{ toYaml .Values.resources | nindent 16 }}
              {{- end }}
              env:
                - name: POD_NAME
                  value: {{ .Values.name }}
                {{- range $key, $value := .Values.env }}
                - name: {{ $key }}
                  value: {{ $value | quote }}
                {{- end }}
                {{- range $key, $name := .Values.envSecrets }}
                - name: {{ $key }}
                  valueFrom:
                    secretKeyRef:
                      name: {{ $name }}
                      key: {{ $key | quote }}
                {{- end }}
              {{- if .Values.envFrom }}
              envFrom:
                {{- range .Values.envFrom.configMapRef }}
                - configMapRef:
                    name: {{ . }}
                {{- end }}
                {{- range .Values.envFrom.secretRef }}
                - secretRef:
                    name: {{ . }}
                {{- end }}
              {{- end }}
{{- end -}}
