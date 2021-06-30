# helm-charts


## Initial chart server

### Create github pages branch ( checkout from master branch)
```
git checkout -b 'github-pages'
```
### Package helm file
```
helm package simple -d simple
helm package fluentd-cloudwatch -d fluentd-cloudwatch
helm package cronjob -d cronjob
```
### Create helm index.yaml
```
helm repo index . --url https://shoplineapp.github.io/helm-charts
```
### Upload index.yaml and helm chart file
```
git add .
git commit -m 'update chart'
ggpush
```
### Setting github pages

- source: github-pages
- path: /

---
## How to use chart sever

### Add helm repo
```
helm repo add shopline-charts https://shoplineapp.github.io/helm-charts
```

### Update chart repository
```
helm repo update
```

### Helm upgrade command example
*(option)You can use --version in your command to lock specify chart version*

```
helm upgrade example-simple shopline-charts/simple -f helm/simple.yaml
helm upgrade example-cronjob shopline-charts/cronjob -f helm/cronjob.yaml --version 0.0.1
```


---
## Update chart version example

step1: update Chart.yaml version
```
vi simple/Chart.yaml 

- version: 0.0.1
+ version: 0.0.2
```

step2: package chart file
```
helm package simple -d simple
```

step3: update index.yaml
```
helm repo index . --url https://shoplineapp.github.io/helm-charts
```

step4: push new chart version to chart server
```
git add .
git commit -m 'update chart'
ggpush
```