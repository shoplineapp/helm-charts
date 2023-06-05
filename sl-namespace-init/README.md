# sl-namespace-init

## Prerequisite
 - ArgoEvent
 - ArgoWorkflows

## Introduction
This Helm Chart helps us install ArgoSensor with EventBus and EventResource.
Argo Sensor will create a Argo Workflow to help us install Helm chart(shopline-chart/eks) while EventSource is defined as namespace is created or deleted.

## How to use chart
### Add helm repo

```
helm repo add shopline-charts https://shoplineapp.github.io/helm-charts
```

### Update chart repository

```
helm repo update
```

### Helm install command example

```
helm install sl-namespace-init shopline-charts/sl-namespace-init -f values.yaml --version 0.1.0
```

### Helm upgrade command example

```
helm diff upgrade sl-namespace-init shopline-charts/sl-namespace-init -f values.yaml --version 0.1.0
helm upgrade sl-namespace-init shopline-charts/sl-namespace-init -f values.yaml --version 0.1.0
```