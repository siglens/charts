# SigLens Helm Chart

SigLens Helm Chart provides a simple deployment for a highly performant, low overhead log managment system that supports automatic Kubernetes events & container logs exporting

# TLDR Installation:

```
helm repo add siglens-repo https://siglens.github.io/charts
helm install siglens siglens-repo/siglens
```

# Installation

Please ensure that `helm` is installed.


To install SigLens from source:
```bash
git clone
cd charts/siglens
helm install siglens .
```

Important configs in `values.yaml`:

| Values      | Description |
| ----------- | ----------- |
| siglens.configs      | Server configs for siglens       |
| siglens.storage   | Defines storage class to use for siglens StatefulSet        |
| k8sExporter.enabled   | Enable automatic exporting of k8s events using [an exporting tool](https://github.com/opsgenie/kubernetes-event-exporter)      |
| k8sExporter.configs.index   | Output index name for kubernetes events      |
| logsExporter.enabled   | Enable automatic exporting of logs using a Daemonset [fluentd](https://docs.fluentd.org/container-deployment/kubernetes)      |
| logsExporter.configs.indexPrefix   | Prefix of index name used by logStash. Suffix will be namespace of log source      |
| service.alternateServiceType | by default, a headless service is always created for siglens. Another service can be created using configs below |

If k8sExporter or logsExporter is enabled, then a ClusterRole will be created to get/watch/list all resources in all apigroups. Which resources and apiGroups can be edited in serviceAccount.yaml
