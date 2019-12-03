{{- define "deployment.container" -}}
        name: {{ .name }}
        {{- if hasKey . "args" }}
        args:
        {{ toYaml .args | indent 12 }}
        {{- end }}
        image: "{{ .image.repository }}:{{ .image.tag }}"
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
        {{- if hasKey . "ports" }}
        ports:
        {{- range .ports }}
        - name: {{ .name }}
          containerPort: {{ .port }}
        {{- end }}
        {{- end }}
        {{- if hasKey . "livenessProbe" }}
        livenessProbe: {{- toYaml .livenessProbe | nindent 10 }}
        {{- end }}
        {{- if hasKey . "readinessProbe" }}
        readinessProbe: {{- toYaml .readinessProbe | nindent 10 }}
        {{- end }}
        {{- if hasKey . "volumes" }}
        volumeMounts:
          {{- range $key, $vol := $.volumes }}
          - name: {{ $vol.name }}
            mountPath: {{ $vol.path }}
          {{- end }}
        {{- end }}
        {{- if hasKey . "resources" }}
        resources: {{- toYaml .resources | nindent 10 }}
        {{- end }}
{{- end -}}