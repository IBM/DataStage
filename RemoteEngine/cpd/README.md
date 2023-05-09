# DataStage CPD Remote Engine
To deploy the DataStage operator on cluster without global pull secret configured for the container registry, the pull secret needs to be created. You need an active connection to the cluster with either kubectl or oc cli available.

```
# create pull secret for container registry
./launch.sh create-pull-secret --username <username> --password ${api-key}

# deploy the operator
./launch.sh install --namespace <namespace>

# create the api-key for dev or prod environment
./launch.sh create-apikey-secret --namespace <namespace> --apikey ${cloud-api-key}

# create the remote instance - add '--gateway api.dataplatform.cloud.ibm.com' if the instance needs to registers with prod env

./launch.sh create-instance --namespace <namespace> --name <name> --project-id <project-id> --storageClass <storage-class> [--storageSize <storage-size>] [--size <size>] [--gateway api.dataplatform.cloud.ibm.com]
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
# the namespace to deploy the remote engine
namespace=<namespace>

# the username and password for the container registry

username=<username>
password=<password-or-apikey>

# IBM cloud api key for the remote engine to use
api_key=<api-key>

# the project ID that will be using this remote engine
projectId=<project_id>

# the name of the remote engine (alphanumeric and without spaces)
name=<name>

#the size of the pxruntime - small, medium, or large (default is small)
size=small

# the storage class to use
storage_class=<storage-class-name>

# the storage size in gb
storage_size=20

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

## Pre-Requisites
The following software are required to be installed on the system:
- `kubectl` or `oc`
- `jq`
