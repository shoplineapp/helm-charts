## Sample usage
```yaml
argoCronWorkflows:
  sample-script:
    spec:
      schedule: '*/3 * * * *'
      workflowSpec:
        entrypoint: sample-script
        templates:
          - name: sample-script
            container:
              image: <your image>
              command: [ bundle ]
              args: [ exec, rake, routes ]
              resources:
                limits:
                  cpu: "300m"
                  memory: "3Gi"
                requests:
                  cpu: "300m"
                  memory: "2Gi"
              envFrom:
                - configMapRef:
                    name: api-env
        ttlStrategy:
          secondsAfterCompletion: 300
  sample-script2:
    spec:
      schedule: '*/3 * * * *'
      workflowSpec:
        entrypoint: sample-script
        templates:
          - name: sample-script
            container:
              image: <your image>
              command: [ bundle ]
              args: [ exec, rake, routes ]
              resources:
                limits:
                  cpu: "300m"
                  memory: "3Gi"
                requests:
                  cpu: "300m"
                  memory: "2Gi"
              envFrom:
                - configMapRef:
                    name: api-env
        ttlStrategy:
          secondsAfterCompletion: 300
```