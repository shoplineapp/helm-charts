## Sample usage
```yaml
name: simple-cron-workflow  # required
kind: CronWorkflow          # required, use to define which template to use
schedule: '*/3 * * * *'     # required
# For the details logic of fields "serviceaccount" and "serviceAccount", please have a look on ./cronjob/templates/serviceaccount.yaml
serviceaccount:             # optional
  name: "xxxxxxxx"          # optional
serviceAccount:
  annotations: "xxxxxxxx"   # optional 
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
  requests:
    cpu: "300m"
    memory: "2Gi"
job:
  history:
    success: 1              # optional, having default value 3
    failed: 1               # optional, having default value 1
  concurrency: "Forbid"     # optional, having default value "Allow"
  retries: 5                # optional, having default value 1
  retryPolicy: "OnFailure"  # optional, having default value "OnFailure"
  timeout: 0                # optional
startingDeadlineSeconds: 6  # optional
annotations:                # optional, a map for storing self-define variable
  TEST_VARIABLE: TESTVALUE
# if "exitNotifications" is not exist, then the workflow will apply default exit handle made in Infra.
exitNotifications:
  slackApp:
    portalDomain: "xxxxxxxxxxxxxxxxxxxxxxxxxxx" # required if "slackApp" is exist
    webhookUrl: "xxxxxxxxxxxxxxxxxxxxxxxxxxx"   # required if "slackApp" is exist
  newRelic:                                     # optional, recommend pass through all the variable of "newRelic" section by pipeline
    licenseKey: "xxxxxxxxxxx"                   # required if "newRelic" is exist
    appName: "xxxxxxxxxxx"                      # required if "newRelic" is exist 
  healthcheckIo:
    uuid: "xxxxxxxxxxxxx"                       # required if "healthcheckIo" is exist 

ttlStrategy:
  secondsAfterCompletion: 600                 # optional
podGC:
  strategy: "OnPodCompletion"                 # optional, having default value OnPodCompletion
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