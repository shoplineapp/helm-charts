{{- define "deployment.container_legacy" -}}
          name: {{ .name }}
          {{- if hasKey .container "args" }}
          args:
          {{ toYaml .container.args | indent 12 }}
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

          {{- if hasKey .service "ports" }}
          ports:
          {{- range .service.ports }}
          - name: {{ .name }}
            containerPort: {{ .targetPort }}
            protocol: {{ .protocol }}
          {{- end }}
          {{- end }}

          {{- if hasKey .deployment "livenessProbe" }}
          livenessProbe:
            {{ toYaml .deployment.livenessProbe | nindent 12 }}
          {{- end }}
          {{- if hasKey .deployment  "readinessProbe" }}
          readinessProbe:
            {{ toYaml .deployment.readinessProbe | nindent 12 }}
          {{- end }}
          {{- if hasKey .deployment  "volumes" }}
          volumeMounts:
            {{- range $key, $vol := $.deployment.volumes }}
            - name: {{ $vol.name }}
              mountPath: {{ $vol.path }}
            {{- end }}
          {{- end }}
          resources:
          {{- if hasKey .deployment  "resources" }}
            {{ toYaml .deployment.resources | indent 12 }}
          {{- end }}
{{- end -}}