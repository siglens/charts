# SigLens Helm Chart

SigLens Helm Chart provides a simple deployment for a highly performant, low overhead observability solution that supports automatic Kubernetes events & container logs exporting

# TL;DR Installation:

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
| Values | Description |
| ----------- | ----------- |
| siglens.configs | Server configs for siglens |
| siglens.storage | Defines storage class to use for siglens StatefulSet |
| siglens.storage.size | Storage size for persistent volume claim. Recommended to be half of license limit |
| siglens.ingest.service | Configurations to expose an ingest service |
| siglens.ingest.service | Configurations to expose a query service |
| k8sExporter.enabled | Enable automatic exporting of k8s events using [an exporting tool](https://github.com/opsgenie/kubernetes-event-exporter) |
| k8sExporter.configs.index | Output index name for kubernetes events |
| logsExporter.enabled | Enable automatic exporting of logs using a Daemonset [fluentd](https://docs.fluentd.org/container-deployment/kubernetes) |
| logsExporter.configs.indexPrefix | Prefix of index name used by logStash. Suffix will be namespace of log source |
| affinity | Affinity rules for pod scheduling. |
| tolerations | Tolerations for pod scheduling. |
| ingress.enabled | Enable or disable ingress for the service. |
| ingress.className | Ingress class to use. |
| ingress.annotations | Annotations for the ingress resource. |
| ingress.hosts | List of hosts for the ingress. |
| ingress.tls | TLS configuration for the ingress. |

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

# Siglensent

## Installation

1. **Prepare Configuration**:

   1. Begin by creating a `custom-values.yaml` file, where you'll provide your license key and other necessary configurations
   2. Please look at this [sample `values.yaml` file](https://raw.githubusercontent.com/siglens/charts/main/charts/siglensent/values.yaml) for all the available config
   3. By default, the Helm chart installs in the `siglensent` namespace. If needed, you can change this in your `custom-values.yaml`, or manually create the namespace with the command:
      ```bash
      kubectl create namespace siglensent
      ```

2. **Add Helm Repository**:
   Add the Siglens Helm repository with the following command:

   ```bash
   helm repo add siglens-repo https://siglens.github.io/charts
   ```

3. **Update License and TLS Settings**:

   1. Update your `licenseBase64` with your Base64-encoded license key. For license key, please reach out at support@sigscalr.io
   2. If TLS is enabled, ensure you also update `acme.registrationEmail`, `ingestHost`, and `queryHost` in your configuration

4. **Apply Cert-Manager (If TLS is enabled)**:
   If TLS is enabled, apply the Cert-Manager CRDs using the following command:

   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.crds.yaml
   ```

5. **Update the Resources Config**:

   1. Update the CPU and memory resources for both raft and worker nodes:
      1. `raft.deployment.cpu.request`
      2. `raft.deployment.memory.request`
      3. `worker.deployment.cpu.request`
      4. `worker.deployment.cpu.request`
      5. Update the corresponding limits
   2. Set the required storage size for the PVC of the worker node: `pvc.size` and storage class type: `storageClass.diskType`

5.5. **(Optional) Customize Storage Classes**:

By default, Siglensent uses GCP Persistent Disk (`pd.csi.storage.gke.io`) as the provisioner and defines two `StorageClass` objects:

- `gcp-pd-rwo` — used for worker node volumes (`pd-ssd` by default)
- `gcp-pd-standard-rwo` — used for raft node volumes (`pd-standard` by default)

If you're running on a different cloud provider (e.g., AWS), or want to change disk types or provisioner settings, you can override the `storageClass` configuration in `custom-values.yaml`.

### Example: GCP (default)

```yaml
storageClass:
  worker:
    name: gcp-pd-rwo
    provisioner: pd.csi.storage.gke.io
    diskType: pd-ssd

  raft:
    name: gcp-pd-standard-rwo
    provisioner: pd.csi.storage.gke.io
    diskType: pd-standard
```

### Example: AWS (override in custom-values.yaml)

```yaml
storageClass:
  worker:
    name: aws-ebs-gp3
    provisioner: ebs.csi.aws.com
    diskType: gp3

  raft:
    name: aws-ebs-gp2
    provisioner: ebs.csi.aws.com
    diskType: gp2
```

These values control how persistent volumes are provisioned by Kubernetes for both raft and worker nodes.

> ⚠️ **Important:** Avoid changing the `name` of an existing `StorageClass` in a running cluster unless you know what you're doing. Doing so may cause issues with existing PersistentVolumeClaims.


6. **Update the RBAC Database Config (If SaaS is Enabled)**:

   ```
   config:
      rbac:
         # Postgres configuration for RBAC
         dbname: db1
         host: "pstgresDbHost"
         port: 5432
         user: "username"
         password: "password"
   ```

7. **(Optional) Enable Blob Storage**:

   1. **Use S3**:

      1. **Update Config**:
         Update the config section in `values.yaml`:

         ```
         config:
            ... # other config params

            blobStoreMode: "S3"
            s3:
               enabled: true
               bucketName: "bucketName"
               bucketPrefix: "subdir"
               regionName: "us-east-1"

            ... # other config params
         ```

      2. **Create AWS secret**:
         Create a secret with IAM keys that have access to S3 using the below command:
         ```bash
         kubectl create secret generic aws-keys \
         --from-literal=aws_access_key_id=<accessKey> \
         --from-literal=aws_secret_access_key=<secretKey> \
         --namespace=siglensent
         ```

   2. **Use GCS**:

      1. **Update Config**:
         Update the `config` section in the `values.yaml`:

         ```
         config:
             ... # other config params

             blobStoreMode: "GCS"
             s3:
               enabled: true
             gcs:
                 bucketName: "bucketName"
                 bucketPrefix: "subdir"
                 regionName: "us-east1"

             ... # other config params
         ```

      2. **Create GCS secret**:
         1. Create a service account with these permissions:
            - Storage Admin
            - Storage Object Admin
         2. Create a key for the service account and download the JSON file
         3. Create a secret with the key using the below command (use the absolute path):
            ```bash
            kubectl create secret generic gcs-key \
            --from-file=key.json=/path/to/your-key.json \
            --namespace=siglensent
            ```
         4. Add the service account to the `serviceAccountAnnotations` section in `values.yaml`

8. **Install Siglensent**:
   Install Siglensent using Helm with your custom configuration file:

   ```bash
   helm install siglensent siglens-repo/siglensent -f custom-values.yaml --namespace siglensent
   ```

9. **Update DNS for TLS (If Applicable)**:
   1. Run:
      ```bash
      kubectl get svc -n siglensent
      ```
   2. Find the External IP of the `ingress-nginx-controller` service. Then create two A records in your DNS to point to this IP; one for `ingestHost` and one for `queryHost` as defined in your `custom-values.yaml`

**Note:** If you uninstall and reinstall the chart, you'll need to update your DNS again. But if you do a `helm upgrade` instead, the ingress controller will persist, so you won't have to update your DNS.
