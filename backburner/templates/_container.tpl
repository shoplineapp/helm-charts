{{- define "deployment.container" -}}
        name: {{ .queue }}
        {{- if hasKey . "command" }}
        command: {{ toYaml .command | nindent 8 }}
        {{- else }}
        command:
          - sh
          - -c
        {{- end }}
        {{- if hasKey . "args" }}
        args: {{ toYaml .args | nindent 8 }}
        {{- else }}
        args:
          - bundle exec backburner -e $RAILS_ENV -q {{ .queue }}
        {{- end }}
        image: "{{ .image.repository }}:{{ .image.tag }}"
        imagePullPolicy: "IfNotPresent"
        env:
        - name: CONTAINER_NAME
          value: {{ .queue }}
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
        envFrom:
        {{- range .envFromConfigmap }}
        - configMapRef:
            name: {{ .name }}
        {{- end }}
        {{- range .envFromSecret }}
        - secretRef:
            name: {{ .name }}
        {{- end }}
        {{- if hasKey . "resources" }}
        resources: {{- toYaml .resources | nindent 10 }}
        {{- else }}
        resources:
          limits:
            cpu: "1"
            memory: "1Gi"
          requests:
            cpu: "1"
            memory: "1Gi"
        {{- end }}
        {{- if hasKey . "lifecycle" }}
        lifecycle: {{- toYaml .lifecycle | nindent 10 }}
        {{- else }}
        lifecycle:
          preStop:
            exec:
              command: ["sleep", "15"]
        {{- end }}
{{- end -}}