## Sample usage
```yaml
name: simple-cron-workflow  # required
kind: CronWorkflow          # required, use to define which template to use
schedule: '*/3 * * * *'     # required
image:
  repository: xxxxx         # required
  tag: latest               # required
command:                    # optional
  - bundle
args:                       # optional
  - exec 
  - rails
  - routes
resources:                  # optional, having default value
  limits:
    memory: "3Gi"
  requests:
    cpu: "300m"
    memory: "2Gi"
job:
  history:
    success: 1              # optional, having default value 3
    failed: 1               # optional, having default value 1
  concurrency: "Forbid"     # optional, having default value Allow
  retries: 5                # optional
  retryPolicy: "Forbid"     # optional
  timeout: 0                # optional
startingDeadlineSeconds: 6  # optional
annotations:                # optional, a map for storing self-define variable
  TEST_VARIABLE: TESTVALUE
healthCheck:                
  SuccessUUID: "xxxxxxxxxxxxxxxxxxxxxxxxxxx"  # required
  FailUUID: "xxxxxxxxxxxxxxxxxxxxxxxxxxx"     # required
newRelic:                                     # optional
  enabled: true                               # optional
  functionName: "Test Cron Job"               # required if "enabled" is true
  licenseKey: "xxxxxxxxxxx"                   # required if "enabled" is true
ttlStrategy:
  secondsAfterCompletion: 600                 # optional
env:                                          # optional
  TEST_VARIABLE: TESTVALUE
envSecrets:
  some-env: some-value
envFrom:
  configMapRef:
    - some-env
  secretRef:
    - some-env
```