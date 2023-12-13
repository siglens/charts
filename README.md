# SigLens Helm Chart

SigLens Helm Chart provides a simple deployment for a highly performant, low overhead observability solution that supports automatic Kubernetes events & container logs exporting

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

Important configs in `values.yaml`
| Values      | Description |
| ----------- | ----------- |
| siglens.configs      | Server configs for siglens       |
| siglens.storage   | Defines storage class to use for siglens StatefulSet        |
| siglens.storage.size | Storage size for persistent volume claim. Recommended to be half of license limit |
| siglens.ingest.service | Configurations to expose an ingest service |
| siglens.ingest.service | Configurations to expose a query service |
| k8sExporter.enabled   | Enable automatic exporting of k8s events using [an exporting tool](https://github.com/opsgenie/kubernetes-event-exporter)      |
| k8sExporter.configs.index   | Output index name for kubernetes events      |
| logsExporter.enabled   | Enable automatic exporting of logs using a Daemonset [fluentd](https://docs.fluentd.org/container-deployment/kubernetes)      |
| logsExporter.configs.indexPrefix   | Prefix of index name used by logStash. Suffix will be namespace of log source      |

If k8sExporter or logsExporter is enabled, then a ClusterRole will be created to get/watch/list all resources in all apigroups. Which resources and apiGroups can be edited in serviceAccount.yaml

## Storage options

Currently, only `awsEBS` and `local` storage classes provisioners can be configured by setting `storage.defaultClass: false` and setting the required configs. To add more types of storage classes, add the necessary provisioner info to [`storage.yaml`](charts/siglens/templates/storage.yaml). 

It it recommended to use a storage class that supports volume expansion. 

Example configuration to use an EBS storage class.
```
storage:
    defaultClass: false
    size: 20Gi
    awsEBS:
      parameters: 
        type: "gp2"
        fsType: "ext4"
```

Example configuration to use a local storage class.
```
storage:
    defaultClass: false
    size: 20Gi
    local:
        hostname: minikube
        capacity: 5Gi 
        path: /data # must be present on local machine
```

## Credentials

To add AWS credentials, add the following configuration:
```
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: <<arn-of-role-to-use>>
```

If issues with AWS credentials are encountered, refer to [this guide](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).


To use `abc.txt` as a license, add the following configmap:
```
kubectl create configmap siglens-license --from-file=license.txt=abc.txt
```

Set the following config:
```
siglens:
  configs:
    license: abc.txt
```