{{- define "deployment.container_legacy" -}}
        name: {{ .name }}
        {{- if hasKey .container "args" }}
        args: {{ toYaml .container.args | nindent 10 }}
        {{- end }}
        image: "{{ .container.image.repository }}:{{ .container.image.tag }}"
        imagePullPolicy: {{ .global.imagePullPolicy }}
        env:
        - name: POD_NAME
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

        {{- if hasKey . "service"}}
        {{- if hasKey .service "ports" }}
        ports:
        {{- range .service.ports }}
        - name: {{ .name }}
          containerPort: {{ .targetPort }}
          protocol: {{ .protocol }}
        {{- end }}
        {{- end }}
        {{- end }}

        {{- if hasKey .deployment "livenessProbe" }}
        livenessProbe: {{ toYaml .deployment.livenessProbe | nindent 10 }}
        {{- end }}
        {{- if hasKey .deployment  "readinessProbe" }}
        readinessProbe: {{ toYaml .deployment.readinessProbe | nindent 10 }}
        {{- end }}
        {{- if hasKey .deployment  "volumes" }}
        volumeMounts:
          {{- range $key, $vol := $.deployment.volumes }}
          - name: {{ $vol.name }}
            mountPath: {{ $vol.path }}
          {{- end }}
        {{- end }}
        {{- if hasKey .deployment  "resources" }}
        resources: {{ toYaml .deployment.resources | nindent 10 }}
        {{- end }}
        {{- if hasKey .deployment  "lifecycle" }}
        lifecycle: {{ toYaml .deployment.lifecycle | nindent 10 }}
        {{- else }}
        lifecycle:
          preStop:
            exec:
              command: ["sleep", "15"]
        {{- end }}
{{- end -}}
