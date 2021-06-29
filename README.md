# helm-charts

# setting github pages
source: github-pages
path: root

# package helm file
```
helm package simple -d simple
helm package fluentd-cloudwatch -d fluentd-cloudwatch
helm package cronjob -d cronjob
```
# create helm index.yaml
```
helm repo index simple --url https://shoplineapp.github.io/helm-chart/simple
helm repo index fluentd-cloudwatch --url https://shoplineapp.github.io/helm-chart/fluentd-cloudwatch
helm repo index cronjob --url https://shoplineapp.github.io/helm-chart/cronjob
```
# upload index.yaml and helm chart file
```
git add .
git commit -m 'update chart'
ggpush
```
# add helm repo
```
helm repo add shopline-simple https://shoplineapp.github.io/helm-charts/simple
```