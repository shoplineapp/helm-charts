# kubernetes oomkill exporter

[Source Code](https://github.com/sapcc/kubernetes-oomkill-exporter)

*Notice The repository using difference git tag to separate two container runtime*
docker runtime: 0.4.0
containerd runtime: >= 0.5.0

## How to install

docker runtime
```shell
helm3 upgrade -i oomkill-exporter-docker -n prometheus-operator shopline-charts/oomkill-exporter --set-string containerRuntime=docker
```

containerd runtime
```shell
helm3 upgrade -i oomkill-exporter-containerd -n prometheus-operator shopline-charts/oomkill-exporter --set-string containerRuntime=containerd
```