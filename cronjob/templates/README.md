## Sample usage
```yaml
name: simple-cron-workflow  # required
kind: CronWorkflow          # required, use to define which template to use
schedule: '*/3 * * * *'     # required
image:
  repository: xxxxx         # required, 
  tag: latest               # required, recommend pass through the updated tag by pipeline
command:                    # optional
  - bundle                  # e.g ONLY
args:                       # optional
  - exec                    # e.g ONLY
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
# if "healthCheck", "newRelic", and "slack" is not exist, then the workflow will apply default exit handle made in Infra.
healthCheck:                
  SuccessUUID: "xxxxxxxxxxxxxxxxxxxxxxxxxxx"  # required if "healthCheck" is exist
  FailUUID: "xxxxxxxxxxxxxxxxxxxxxxxxxxx"     # required if "healthCheck" is exist
newRelic:                                     # optional, recommend pass through by pipeline
  licenseKey: "xxxxxxxxxxx"                   # required if "newRelic" is exist
slack: # optional, recommend pass through by pipeline
  ChannelURL: "xxxxxxxxxxxxxxxxxxxxxxxxxxx"   # required if "slack" is exist
ttlStrategy:
  secondsAfterCompletion: 600                 # optional
podGC:
  strategy: "OnPodCompletion"               # optional, having default value OnPodCompletion
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