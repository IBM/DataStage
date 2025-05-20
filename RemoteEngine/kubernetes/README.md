# DataStage Remote Engine on Kubernetes

## License
### Cloud
[IBM DataStage as a Service Anywhere](https://www.ibm.com/support/customer/csol/terms/?ref=i126-9243-06-11-2023-zz-en)
### CP4D
[IBM DataStage Enterprise and IBM DataStage Enterprise Plus](https://www14.software.ibm.com/cgi-bin/weblap/lap.pl?li_formnum=L-QFYS-RTJPJH)

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
      
A file storage class with support for read-write-many(RWX) is required.
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

## Needed API keys
1. If you are specifically deploying a remote engine for IBM Cloud, an IBM Cloud API key is required for registering the remote engine to your Cloud Pak for Data project on IBM Cloud.
    1. Click Manage > Access (IAM) > API keys to open the “API keys” page (URL: https://cloud.ibm.com/iam/apikeys).
    2. Ensure that My IBM Cloud API keys is selected in the View list.
    3. Click Create an IBM Cloud API key, and then specify a name and description
2. If you are specifically deploying a remote engine for IBM Cloud, the IBM Cloud Container Registry APIKey. This apikey will be used to download the images needed to run Remote Engine for IBM Cloud. Currently there is no way to generate this, so it needs to be requested via IBM Cloud Support: https://cloud.ibm.com/unifiedsupport
3. If you are specifically deploying a remote engine for CP4D, the IBM Entitlement APIKey. This apikey will be used to download the images needed to run Remote Engine for CP4D. Please follow https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=information-obtaining-your-entitlement-api-key for instructions on how to obtain your IBM Entitlement API Key.

## Usage
To deploy the DataStage operator on cluster without global pull secret configured for the container registry, the pull secret needs to be created. You need an active connection to the cluster with either kubectl or oc cli available.

```
# create pull secret for container registry
./launch.sh create-pull-secret --namespace <namespace> --username <username> --password ${api-key} [--registry <docker-registry>] [--zen-url <zen-url> (if you are specifically deploying a remote engine for CP4D)]

# create the proxy secrets if proxies are used
# ./launch.sh create-proxy-secrets --namespace <namespace> --proxy <proxy_url> [--proxy-cacert <cacert_location>] [--zen-url <zen-url> (if you are specifically deploying a remote engine for CP4D)]

# create the krb5 configmaps if Kerberos Authentication is used
# ./launch.sh create-krb5-configmaps --namespace <namespace> --krb5-conf <krb5_conf_location> [--krb5-conf-dir <krb5_config_dir_location>]

# create secret to import DB2Z license
# ./launch.sh create-db2z-license-secret --namespace <namespace> --import-db2z-license <db2z_license_location>

# create the api-key for dev or prod environment
./launch.sh create-apikey-secret --namespace <namespace> --apikey ${api-key} [--serviceid ${service-id}] [--zen-url <zen-url> (if you are specifically deploying a remote engine for CP4D)]

# deploy the operator
./launch.sh install --namespace <namespace> [--registry <docker-registry>] [--operator-registry-suffix <operator-suffix>] [--docker-registry-suffix <docker-suffix>] [--digests <ds-operator-digest>,<ds-px-runtime-digest>,<ds-px-compute-digest>] [--zen-url <zen-url> (if you are specifically deploying a remote engine for CP4D)]

# create the remote instance - add '--gateway api.dataplatform.cloud.ibm.com' if the instance needs to registers with prod env

./launch.sh create-instance --namespace <namespace> --name <name> --project-id <project_id1,project_id2,project_id3,...> --storage-class <storage-class> [--storage-size <storage-size>] [--size <size>] [--data-center dallas|frankfurt|sydney|toronto (if you are specifically deploying a remote engine for IBM Cloud)] [--additional-users <IBMid-1000000000,IBMid-2000000000,IBMid-3000000000,...>] [--registry <docker-registry>] [--operator-registry-suffix <operator-suffix>] [--docker-registry-suffix <docker-suffix>] [--digests <ds-operator-digest>,<ds-px-runtime-digest>,<ds-px-compute-digest>] [--zen-url <zen-url> (if you are specifically deploying a remote engine for CP4D)] --license-accept true
```
For documentation on how to create IBM Cloud API keys, see https://cloud.ibm.com/docs/account?topic=account-manapikey.
To generate a CP4D API Key, go to "Profile and settings" when logged in to the CP4D Cluster to get your api key for the connection.

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
./launch.sh create-nfs-provisioner --namespace <namespace> --server <dns-name-or-IP> [--path <path to mount>] [--storage-class <storage-class>]
```

## Installing with an input file
Instead of running the installation script multiple times, the entire installation can done with an input file. When running with an input file, the installation will retrieve the latest images available from the container registry. To update to the latest version simply rerun the installation with the same input file.

sample input file:
```
# indicate that you have accepted license for IBM DataStage as a Service Anywhere(https://www.ibm.com/support/customer/csol/terms/?ref=i126-9243-06-11-2023-zz-en)
license_accept=true

# If you are specifically deploying a remote engine for IBM Cloud, the data center where your DataStage is provisioned on IBM cloud (dallas, frankfurt, sydney, or toronto); the default is dallas.
# data_center=dallas

# the namespace to deploy the remote engine
namespace=<namespace>

# If you are specifically deploying a remote engine for IBM Cloud, the username and api key for the IBM Cloud Container Registry.
# If you are specifically deploying a remote engine for CP4D, the username and api key for the IBM Entitled Registry.
username=<account-login-user>
password=<registry-api-key>

# If you are deploying a remote engine for IBM Cloud, this value will be the IBM Cloud api key for the remote engine to use.
# If you are deploying a remote engine for CP4D, this value will be the CP4D Cluster account login api key of the target cluster for the remote engine to use. Go to "Profile and settings" when logged in to get your api key for the connection.
api_key=<api-key>

# If you are specifically deploying a remote engine for CP4D, the CP4D service id username of the target cluster for the remote engine to use with api key
service_id=cpadmin

# the comma separated list of project IDs that will be using this remote engine
projectId=<project_id1,project_id2,project_id3,...>

# the name of the remote engine (alphanumeric and without spaces)
name=<name>

#the size of the pxruntime - small, medium, or large (default is small)
size=small

# the file storage class to use
storage_class=<storage-class-name>

# the storage size in gb
storage_size=20

# comma separated list of ids (IAM IDs for cloud, check https://cloud.ibm.com/docs/account?topic=account-identity-overview for details; uids/usernames for cp4d) that can also control remote engine besides the owner
# additional_users=<IBMid-1000000000,IBMid-2000000000,IBMid-3000000000...>

# If you are specifically deploying a remote engine for CP4D, the zen url of the target cluster to use for CP4D environment. Specifying this variable will automatically switch usage from IBM Cloud to CP4D.
zen_url=<zen-url>

# Specify the proxy url (eg. http://<username>:<password>@<proxy_ip>:<port>).
# proxy_url=<proxy-url>

# Specify the absolute location of the custom CA store for the specified proxy - if it is using a self signed certificate.
# cacert_location=<cacert-location>

# Specify the location of the Kerberos config file if using Kerberos Authentication.
# KRB5_CONF_FILE=<krb5_conf_location>

# Specify the directory of multiple Kerberos config files if using Kerberos Authentication. (Only supported with --krb5-conf, the krb5.conf file needs to include 'includedir /etc/krb5-config-files/krb5-config-dir' line).
# KRB5_CONF_DIR=<krb5_config_dir_location>

# Specify the location of the DB2Z license to import
# DB2Z_LICENSE=<db2z_license_location>

# Specify your custom container registry to pull images from if you are image mirroring using a private registry. If using this option, you must set USE_DIGESTS as well for IBM Cloud.
# CUSTOM_DOCKER_REGISTRY=<docker-registry>

# Custom operator registry suffix to use for the remote engine to pull ds-operator images from if using a custom container registry. Defaults to 'cpopen'.
# OPERATOR_REGISTRY_SUFFIX=<operator-suffix>

# Custom docker registry suffix to use for the remote engine to pull ds-px-runtime and ds-px-compute images from if using a custom container registry. Defaults to 'cp/cpd'.
# DOCKER_REGISTRY_SUFFIX=<docker-suffix>

# Custom digests to use for the remote engine. This option must be set if using a custom registry for IBM Cloud.
# USE_DIGESTS=<ds-operator-digest>,<ds-px-runtime-digest>,<ds-px-compute-digest>

# the DNS name or IP of the EFS file system; omit if not deploying on AWS's EKS
# the provisioner will use the storage class name specified in storage_class
# nfs_server=<dns-name-or-IP>

# the namespace to deploy the storage class provisioner; will deploy to the same
# namespace as the remote engine if omitted
# provisioner_namespace=<namespace>
```
This script will deploy a remote engine for CP4D Cluster. If you need to deploy remote engine for IBM Cloud, uncomment the data_center variable, comment out the zen_url and service_id variables, and change the api_key, username, and password variables according to the commented instructions.

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

## Troubleshooting
1. If the API Key Changes in DataStage aaS with Anywhere
    1. Rerun the launch.sh script again with the updated input file with the new API Key
    1. Make sure to restart the px-runtime pod to mount the updated apikey secret

1. If the px-runtime or px-compute pods are stuck waiting for certs
   ```
   $ kubectl -n amintest logs testamin01-ibm-datastage-px-compute-0
   rm: cannot remove '/opt/ibm/PXService/Server/DSEngine/isjdbc.config.biginsights': No such file or directory
   Use CPD_JAVA_CACERTS...
   Custom WDP certs folder found.  Will import certs to jre /opt/java...
   Additional cert folder  not found.
   Waiting for certs...
   Waiting for certs...
   Waiting for certs...
   Waiting for certs...
   ```
   You can work around the issue by doing the following:
   1. Log into the shell for either px-runtime or px-compute
   1. Run the following command:
      ```bash
      touch /opt/ibm/PXService/Server/PXEngine/etc/certs/pxesslcert.p12
      ```
