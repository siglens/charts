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

## Cluster Setup

<details>
<summary><strong>GKE Cluster Setup</strong></summary>

### Prerequisites

**Install kubectx/kubectl:**
1. kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/
2. kubectx: https://github.com/ahmetb/kubectx

**Install Auth Plugin:**
1. Install gke-gcloud-auth-plugin
   - `brew install google-cloud-sdk`
   - See https://stackoverflow.com/a/74733176/16662168 if you have issues
   - `gcloud components install gke-gcloud-auth-plugin`
2. Run `gke-gcloud-auth-plugin --version` to verify it's installed

**Get Permissions:**
1. Go to the IAM page: https://console.cloud.google.com/iam-admin
2. Add these permissions for yourself if you don't have them:
   - Kubernetes Engine Admin
   - Kubernetes Engine Cluster Admin

### How to Create a GKE Cluster

1. Go to the GKE page: https://console.cloud.google.com/kubernetes
2. Click Create, and choose the Standard option
3. For the region, you should select the same region that you want the GCS bucket in, although it will still work if the GKE cluster and the GCS bucket are in different regions
4. Use Standard Tier
5. In the Node Pools → default-pool tab, set the number of nodes per zone
6. In the Nodes tab for the default-pool, choose an instance type with enough CPU/RAM, and configure the amount of disk space
7. Click Create (you don't need to alter the options in the other tabs)
8. On the main GKE page, click your cluster to go to the page for it
9. On the top, click Connect
10. Copy the Command Line Access command, and run it
11. In terminal, run `kubectx` to verify you're on your new cluster (if you have multiple clusters, it highlights the one you're on)
12. Wait for the cluster to finish getting set up

### Create a Service Account

**Note:** If you don't create the Service Account with the correct roles, I'm not sure how to update the roles; so you may need to make a new Service Account with the proper roles.

1. Go to the IAM page: https://console.cloud.google.com/iam-admin
2. Click the Service Accounts tab
3. Click Create Service Account
4. Set the name, then click Create and Continue
5. Add these roles:
   - Storage Admin
   - Storage Object Admin
   
   **Note:** There are several other roles similar to these, but when I tried those, they didn't give me enough permissions.
6. Click Done

### Use your Service Account

**Note:** If you're repeating this step on your cluster, first run `kubectl delete secrets gcs-key`. You might also want to delete any old keys in your Downloads folder.

1. Run `kubectl create namespace siglensent`
2. (Optional) Run `kubectl config set-context --current --namespace=siglensent` to make siglensent your default namespace (kubectl only searches in your default namespace unless you specify a different namespace, or specify to search all namespaces)
3. On the Service Accounts page, click your new Service Account
4. Go to the Keys tab
5. Click Add Key → Create New Key
6. Select the JSON key, and click Create to download it
7. In the terminal, run the following. Make sure to use the absolute path to your key:
   ```bash
   kubectl create secret generic gcs-key \
   --from-file=key.json=/path/to/your-key.json \
   --namespace=siglensent
   ```

</details>

<details>
<summary><strong>EKS Cluster Setup</strong></summary>

### Prerequisites

**Install kubectl:**
- kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/

**Install AWS CLI:**
- AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- Configure AWS credentials: `aws configure`

### How to Create an EKS Cluster

1. Begin setting up a new EKS cluster on the AWS console
   - Use "Custom Configuration"
   - Disable EKS Auto Mode
   - Name the cluster
   - Click "Create recommended role" to create the Cluster IAM role. Leave the default settings, and assign your new role

2. Continue using the default settings for the next few pages. Stop when you get to the Select Add-ons page

3. Use these add-ons:
   - CoreDNS
   - Kube-proxy
   - Amazon VPC CNI
   - Amazon EBS CSI Driver
   - Amazon EKS Pod Identity Agent

4. For the VPC CNI and EBS CSI add-ons, click "Create recommended role", keep the defaults, and then add that IAM role to the add-on

5. Click Next and create the cluster

6. Wait for the cluster to finish getting created

7. Go to the Compute tab in your cluster and click "Add node group"

8. Name the node group, and use "Create recommended role" to create a new role and assign it

9. Click next

10. Select the desired instance type and min/max/desired nodes

11. Leave the rest of the settings at their default, and create the node group

12. Wait until the node group is Active

### Connect to Your Cluster

Connect to your cluster using the AWS CLI:
```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

### Setup Service Account IAM Permissions (Optional)

This step is optional. If you won't configure SigLens to run with S3, then you don't need this step. If you want to give S3 permissions via an AWS access key and secret access key, you can skip this step.

1. Get the OpenID Connect provider URL on the Overview tab of your EKS cluster

2. Go to IAM → Identity Providers → Add provider

3. Configure the provider:
   - Use OpenID Connect
   - Paste your OpenID URL as the Provider URL
   - Use `sts.amazonaws.com` as the Audience

4. Go to IAM → Roles → Create role. Configure the role:
   - Use Web identity
   - Use your newly created Identity Provider as the identity provider
   - Use `sts.amazonaws.com` as the Audience
   - Click Add Condition
   - Use `<IDENTITY_PROVIDER>:sub` as the Key
   - Use StringEquals as the Condition
   - Use `system:serviceaccount:<NAMESPACE>:<RELEASE_NAME>-service-account` as the Value
     - The namespace is the namespace you'll install the helm chart into. It will be "siglensent" unless you change it in the values.yaml config file
     - The release name is what you'll install the chart with helm as. It will be "siglensent" unless you change it

5. Click Next

6. Add S3 full access permissions

7. Click Next

8. Name the role, add an optional description, and click Create Role

</details>

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

   If you've previously added the repository, ensure it's updated:
   ```bash
   helm repo update siglens-repo
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
      4. `worker.deployment.memory.request`
      5. `worker.deployment.replicas`
   2. Set the required storage size for the PVC of the worker node: `pvc.size` and storage class type: `storageClass.diskType`

5.5. **(Optional) Customize Storage Classes**:

By default, Siglensent uses GCP Persistent Disk (`pd.csi.storage.gke.io`) as the provisioner and defines two `StorageClass` objects:

- `gcp-pd-rwo` — used for worker node volumes (`pd-ssd` by default)
- `gcp-pd-standard-rwo` — used for raft node volumes (`pd-standard` by default)

These are customizable through the `storageClass` section in your `custom-values.yaml`.  
You can define **shared defaults** under `storageClass.<key>` and override per component (`worker`, `raft`) only if needed.

---

### ✅ Default: GCP

```yaml
storageClass:
  provisioner: pd.csi.storage.gke.io      # GCP default provisioner
  diskType: pd-standard                   # Default disk type
  reclaimPolicy: Retain
  allowVolumeExpansion: true
  volumeBindingMode: WaitForFirstConsumer

  worker:
    name: gcp-pd-rwo                      # name for worker PVCs

  raft:
    name: gcp-pd-standard-rwo             # name for raft PVCs
```

---

### 🌩️ AWS Example (override in `custom-values.yaml`)

```yaml
storageClass:
  provisioner: ebs.csi.aws.com            # AWS EBS CSI driver
  diskType: gp2
  reclaimPolicy: Delete

  worker:
    name: aws-ebs-gp2-rwo-worker
    diskType: gp3                         # Override the default gp2 value

  raft:
    name: aws-ebs-gp2-rwo-raft
```

> 💡 You only need to override fields that differ from the shared defaults.

---

> ⚠️ **Important:** Avoid changing the `name` of an existing `StorageClass` in a running cluster unless you know what you're doing. Doing so may break existing PersistentVolumeClaims and lead to data loss or pod scheduling issues.


6. **Update the RBAC Database Config (If SaaS is Enabled)**:

   ```
   config:
      rbac:
         provider: "postgresql" # Valid options are: postgresql, sqlite
         dbname: db1
         # Postgres configuration for RBAC
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

      2. **Setup Permissions**

         **Option 1: AWS access keys**:
         1. Create a secret with IAM keys that have access to S3 using the below command:
           ```bash
           kubectl create secret generic aws-keys \
           --from-literal=aws_access_key_id=<accessKey> \
           --from-literal=aws_secret_access_key=<secretKey> \
           --namespace=siglensent
           ```
         2. Set `s3.accessThroughAwsKeys: true` in your `custom-values.yaml`

         **Option 2: IAM Role**:
         1. Get the OpenID Connect provider URL for your cluster
         2. Go to IAM -> Identity providers -> Add provider, and setup a new OpenID Connect provider with that URL and the audience as `sts.amazonaws.com`
         3. Setup a role
            1. Go to IAM -> Roles -> Create role, and select the OIDC provider you just created
            2. Add the condition `<IDENTITY_PROVIDER>:sub = system:serviceaccount:<NAMESPACE>:<RELEASE_NAME>-service-account`. The `<NAMESPACE>` and `<RELEASE_NAME>` are the namespace and release name of your Helm chart; they'll both be `siglensent` if you follow this README exactly.
            3. Add S3 full access permissions, and create the role
         4. Add the service account to the `serviceAccountAnnotations` section in `values.yaml`
         5. Ensure your `custom-values.yaml` has `s3.accessThroughAwsKeys: false`

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
