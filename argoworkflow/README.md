## Sample usage
```yaml
name: simple-cron-workflow
schedule: '*/3 * * * *'
image:
  repository: xxxxx
  tag: latest
rake_command: routes
resources:
  limits:
    memory: "3Gi"
  requests:
    cpu: "300m"
    memory: "2Gi"
envFrom:
  configMapRef:
    - some-env
  secretRef:
    - some-env
```