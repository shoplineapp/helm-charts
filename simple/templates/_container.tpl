{{- define "deployment.container" -}}
        name: {{ .name }}
        {{- if hasKey . "command" }}
        command: {{ .command }}
        {{- end }}
        {{- if hasKey . "args" }}
        args: {{ toYaml .args | nindent 8 }}
        {{- end }}
        image: "{{ .image.repository }}:{{ .image.tag }}"
        {{- if hasKey . "securityContext" }}
        securityContext: {{ toYaml .securityContext | nindent 10 }}
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
        {{- if hasKey . "envFromConfigmap" }}
        envFrom:
        - configMapRef:
            name: {{ .envFromConfigmap.name }}
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
            mountPath: {{ $vol.path | quote }}
            readOnly: {{ $vol.readOnly | default "true" }}
            {{- if hasKey $vol "subPath" }}
            subPath: {{ $vol.subPath }}
            {{- end }}
          {{- end }}
        {{- end }}
        {{- if hasKey . "resources" }}
        resources: {{- toYaml .resources | nindent 10 }}
        {{- end }}
{{- end -}}
