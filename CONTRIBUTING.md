# Contributing to Shopline Chart

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

## How to add new chart to shopline charts

step1. update .github/workflows/update-chart.yaml

example add new chart: eks
```shell
vi .github/workflows/update-chart.yaml
- name: Package helm chart file and create index.yaml
...
+ helm package eks -d eks
...
```