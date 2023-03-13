{{- define "deployment.container" -}}
        name: {{ .resourceName }}
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
          {{- $standAlone := .standAlone }}
          {{- $queueLen := len .queue | int }}
          {{- if (default $standAlone false ) }}
            {{- if gt $queueLen 1}} 
              {{ fail "queue more than one failed when the standalone mode."}}
            {{- end}}
          {{- end}}

          {{- $queueList := list}}
          {{- range $i, $items := .queue }}
            {{- $queueName := get $items "queueName" }}
            {{- $listener := get $items "listener" | int }}
            {{- if (default $standAlone false ) }}
              {{- if gt $listener 1 }} 
              {{ fail "listener more than one failed when the standalone mode."}}
              {{- end}}
              {{- $listener = 1 }}
            {{- else }} 
              {{- if lt $listener 2 }}
                {{- $listener = 2 }}
              {{- end}}
            {{- end}}
            {{- $tmpItem := printf "%v:%v" $queueName $listener }}
            {{- $queueList = append $queueList $tmpItem }}
          {{- end }}
          {{- $queueName := (join "," $queueList) }}
          - bundle exec backburner -e $RAILS_ENV -q {{ $queueName }}
        {{- end }}
        image: "{{ .image.repository }}:{{ .image.tag }}"
        imagePullPolicy: "IfNotPresent"
        env:
        - name: CONTAINER_NAME
          value: {{ .resourceName }}
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