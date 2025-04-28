> [!CAUTION]
> This project has been archived and is no longer being maintained. Please migrate to the Bitbucket internal-repository Helm chart.

# helm-charts

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

### How to use subChart
You can find example code at example subChart folder

```bash
helm dependency build ./example/subChart
helm install ./example/subChart --name andytest
helm upgrade andytest ./example/subChart
```

#### Update subChart version

```bash
vi ./example/subChart/requirements.yaml
```

```
- version: "0.0.1"
+ version: "0.0.2"
  repository: "https://shoplineapp.github.io/helm-charts"
  alias: second-subChart
```

```bash
helm dependency update ./helm/preview
```

<!-- how to unit test -->
### Unit test development ###
https://github.com/helm-unittest/helm-unittest/blob/main/DOCUMENT.md
### How to run unit tests

```bash
helm unittest <chart-name>
```