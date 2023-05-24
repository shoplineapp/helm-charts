# sl-namespace-init

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

## Prerequisite

- ArgoEvents
- ArgoWorkflows