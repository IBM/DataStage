# DataStage Remote Engine on Kubernetes

## License
[IBM DataStage as a Service Anywhere](https://www.ibm.com/support/customer/csol/terms/?ref=i126-9243-06-11-2023-zz-en)

## Requirements
DataStage Remote Engine supports deployment on the following platforms:
* OpenShift 4.12 and above
    * Details on setting up an OpenShift cluster: https://docs.openshift.com/container-platform/4.12/welcome/index.html
* IBM Cloud Kubernetes Service (IKS)
    * Details on setting up an IKS cluster: https://cloud.ibm.com/docs/containers?topic=containers-getting-started&interface=ui
    * Setting up file Storage: https://cloud.ibm.com/docs/containers?topic=containers-file_storage
* Amazon Elastic Kubernetes Service (EKS)
    * Details on setting up an EKS cluster: https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html
    * Setting up and Elastic file system: https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=storage-setting-up-amazon-elastic-file-system (see details below)

## Pre-Requisites
The following software are required to be installed on the client from where you will be executing this script:

1. `kubectl` or `oc`
2. `jq`

## Sizing
The remote engine supports three default sizes: small, medium, and large.

### Small
- 2 compute pods: 3 vCPU and 12 GB RAM
- 1 conductor pod: 1 vCPU and 4 GB RAM

### Medium
- 2 compute pods: 6 vCPU and 24 GB RAM
- 1 conductor pod: 2 vCPU and 4 GB RAM

### Large
- 3 compute pods: 8 vCPU and 32 GB RAM
- 1 conductor pod: 4 vCPU and 4 GB RAM

## IBM Cloud API key
1. An IBM Cloud API key is required for registering the remote engine to your Cloud Pak for Data project on IBM Cloud.
    1. Click Manage > Access (IAM) > API keys to open the “API keys” page (URL: https://cloud.ibm.com/iam/apikeys).
    2. Ensure that My IBM Cloud API keys is selected in the View list.
    3. Click Create an IBM Cloud API key, and then specify a name and description
2. IBM Cloud Container Registry APIKey. This apikey will be used to download the images needed to run Remote Engine. Currently there is no way to generate this, so it needs to be requested via IBM Cloud Support: https://cloud.ibm.com/unifiedsupport

## Usage
To deploy the DataStage operator on cluster without global pull secret configured for the container registry, the pull secret needs to be created. You need an active connection to the cluster with either kubectl or oc cli available.

```
# create pull secret for container registry
./launch.sh create-pull-secret --namespace <namespace> --username <username> --password ${api-key} [--zen-url <zen-url>]

# deploy the operator
./launch.sh install --namespace <namespace> [--zen-url <zen-url>]

# create the api-key for dev or prod environment
./launch.sh create-apikey-secret --namespace <namespace> --apikey ${api-key} [--serviceid ${service-id}] [--zen-url <zen-url>]

# create the remote instance - add '--gateway api.dataplatform.cloud.ibm.com' if the instance needs to registers with prod env

./launch.sh create-instance --namespace <namespace> --name <name> --project-id <project-id> --storage-class <storage-class> [--storage-size <storage-size>] [--size <size>] [--data-center dallas|frankfurt|sydney|toronto] [--additional-users <IBMid-1000000000,IBMid-2000000000,IBMid-3000000000,...>] [--zen-url <zen-url>] --license-accept true
```
For documentation on how to create API keys, see https://cloud.ibm.com/docs/account?topic=account-manapikey.

## Setting up Amazon Elastic File System (EKS only)
Creating an EFS file system
Follow the CP4D instruction for creating an EFS file system.
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=storage-setting-up-amazon-elastic-file-system

Before you can set up dynamic provisioning, you must obtain the DNS name or IP address of your Amazon Elastic File System:

DNS name (recommended)
You can obtain the DNS name from the AWS Console on the Amazon EFS > File systems. Select the file system that you want to use. The DNS name is in the General section.
The DNS name has the following format: <file-storage-id>.efs.<region>.amazonaws.com.

IP address
You can obtain the IP address from the AWS Console on the Amazon EFS > File systems. Select the file system that you want to use. The IP address is on the Network tab.

```
# create the NFS provisioner with the EFS file system;
./launch.sh create-nfs-provisioner --namespace <namespace> --server <dns-name-or-IP>
```

## Installing with an input file
Instead of running the installation script multiple times, the entire installation can done with an input file. When running with an input file, the installation will retrieve the latest images available from the container registry. To update to the latest version simply rerun the installation with the same input file.

sample input file:
```
# indicate that you have accepted license for IBM DataStage as a Service Anywhere(https://www.ibm.com/support/customer/csol/terms/?ref=i126-9243-06-11-2023-zz-en)
license_accept=true

# the data center where your DataStage is provisioned on IBM cloud (dallas, frankfurt, sydney, or toronto); the default is dallas.
# data_center=dallas

# the namespace to deploy the remote engine
namespace=<namespace>

# the username and password for the container registry
username=iamapikey
password=<container-registry-api-key>

# IBM api key for the remote engine to use
api_key=<api-key>

# the CP4D service id username for the remote engine to use with api key
service_id=cpadmin

# the project ID that will be using this remote engine
projectId=<project_id>

# the name of the remote engine (alphanumeric and without spaces)
name=<name>

#the size of the pxruntime - small, medium, or large (default is small)
size=small

# the file storage class to use
storage_class=<storage-class-name>

# the storage size in gb
storage_size=20

# comma separated list of ids (IAM IDs for cloud, check https://cloud.ibm.com/docs/account?topic=account-identity-overview for details; uids/usernames for cp4d) that can also pass data to remote engine besides the owner
# additional_users=IBMid-1000000000,IBMid-2000000000,IBMid-3000000000...

# the zen url to use for CP4D environment
zen_url=<zen-url>

# the DNS name or IP of the EFS file system; omit if not deploying on AWS's EKS
# the provisioner will use the storage class name specified in storage_class
nfs_server=<dns-name-or-IP>

# the namespace to deploy the storage class provisioner; will deploy to the same
# namespace as the remote engine if omitted
provisioner_namespace=<namespace>
```

Running the install script with the input file:
```
./launch.sh -f inputFile.txt
```

## Mounting Additional Persistence Volumes
To mount additional storage volumes to the remote engine instance, edit the custom resource (CR) and add the additional PVCs under `additional_storage`
1. Edit the PXRemoteEngine CR via `oc` or `kubectl`
```
oc edit pxre <remote-engine-name>
```
2. For each PVC, add its name and mount path under the `additional_storage`.
```
spec:
  additional_storage:                      # mount additional persistent volumes
  - mount_path: /data1                     # the path to mount the persistent volume
    pvc_name: <pvc-1-name>                 # the name of the associated persistent volume claim
  - mount_path: /data2
    pvc_name: <pvc-2-name>
```

## Modifying ephemeral-storage limit:

Note that if the limit is raised higher than the amount of ephemeral storage available on the worker nodes, a worker node may run out of storage and cause stability issues.

To increase the ephemeral storage limit to the target size, eg. 20GB, use the following command.

```
oc patch pxre <cr-name> --patch '{"spec":{"ephemeralStorageLimit": "20Gi"}}' --type=merge
```
