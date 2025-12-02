# DataStage Remote Engine

**Remote Engine** for DataStage on IBM Cloud allows you to setup an execution engine to run your workloads at a cloud location of your choice. Currently this technology is in a closed Beta.

The setup can be done locally on Linux or Mac machines as a Docker instance, or as a service on a Kubernetes cluster. See the README.md in the respective folder for setup.

# Copying DataStage Remote Engine Images to a Private Registry

## Prerequisites

- Skopeo installed
- IBM Container Registry API key with access to DataStage registry
- IBM Cloud API key for DataStage service authentication
- Access to your private container registry (e.g., Artifactory)
- `jq` utility installed
- For Kubernetes/OpenShift: `kubectl` or `oc` CLI installed and access to a cluster
- For Docker/Podman: Docker or Podman installed on your server

## Step 1: Clone the DataStage Repository
```bash
git clone https://github.com/IBM/DataStage.git
cd DataStage/RemoteEngine
```

**Sample Output:**
```
Cloning into 'DataStage'...
remote: Enumerating objects: 1523, done.
remote: Counting objects: 100% (234/234), done.
remote: Compressing objects: 100% (156/156), done.
remote: Total 1523 (delta 98), reused 178 (delta 72), pack-reused 1289
Receiving objects: 100% (1523/1523), 2.34 MiB | 8.45 MiB/s, done.
Resolving deltas: 100% (645/645), done.
```

## Step 2: Get the Latest Image Digests

### Get Access Token
```bash
IBM_CONTAINER_REGISTRY_KEY="your-ibm-cloud-api-key"

ACCESS_TOKEN=$(curl -s -X POST \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --header "Accept: application/json" \
  --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" \
  --data-urlencode "apikey=$IBM_CONTAINER_REGISTRY_KEY" \
  "https://iam.cloud.ibm.com/identity/token" | jq -r '.access_token')

echo $ACCESS_TOKEN
```

**Sample Output:**
```
eyJraWQiOiIyMDI0MTEyMDE4MzAiLCJhbGciOiJSUzI1NiJ9.eyJpYW1faWQiOiJJQk1pZC0zMTAwMD...
```

### Get Runtime and Compute Digests
```bash
curl -s -X GET \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H 'accept: application/json;charset=utf-8' \
  "https://api.dataplatform.cloud.ibm.com/data_intg/v3/flows_runtime/remote_engine/versions" | \
  jq -r '.versions[0] | "Version: \(.px_runtime_version)\nRelease Date: \(.release_date)\npx_runtime: \(.image_digests.px_runtime)\npx_compute: \(.image_digests.px_compute)"'
```

**Sample Output:**
```
Version: 1.0.2502
Release Date: 11/19/2025
px_runtime: sha256:fc272799bd1634e47dab5cd3f0974e840ccd3248480e9915bb664b40ca39e9ad
px_compute: sha256:7870e7f7d2d650b318ca6008999c4406e64a6f09a494177d7a70064015efa7c2
```

## Step 3: Determine Which Images You Need

### For Kubernetes/OpenShift Deployments

You need **three images**:
- `ds-operator`
- `ds-px-runtime`
- `ds-px-compute`

**Get the Operator Digest:**

Navigate to the launch script directory and find the latest operator digest:
```bash
cd launch
grep "operator_digests=" launch.sh
```

**Sample Output:**
```
operator_digests="sha256:4d4e0e4355f2e24522880fd3a5ce2b0300096586d929a9d762b011dcfbdbec84 sha256:be24dd5fb73e40177810a0ff71ee885ddf0883ab3f8b790a6620a705848406c5 sha256:f6c7e12cd8d0cd981becb0f5f9abb6b1d833a10beb71a00d33e270d2f7fa2da8 sha256:4a53892a469c6b9b751a4cc2449378bfb0b15bfe1f3c0dd5056eeaf1587c82a4 sha256:06d91aac99dee5359ad21cc004c7f8f5999da1845c0a5dbdfbcab9b921a2f797 sha256:b2eedfb5707285f3f5e9fb6dbab4eacc529e62506c379f915f850d6d2a707e7c sha256:7e4885cdb1deef0cbbcff590357fa96be32b31d5809f045ff2cbf285ad45b0a6"
```

The **last digest** in the list is the latest operator digest: `sha256:7e4885cdb1deef0cbbcff590357fa96be32b31d5809f045ff2cbf285ad45b0a6`

**Summary of Kubernetes Digests:**
- **ds-operator**: `sha256:7e4885cdb1deef0cbbcff590357fa96be32b31d5809f045ff2cbf285ad45b0a6`
- **ds-px-runtime**: `sha256:fc272799bd1634e47dab5cd3f0974e840ccd3248480e9915bb664b40ca39e9ad`
- **ds-px-compute**: `sha256:7870e7f7d2d650b318ca6008999c4406e64a6f09a494177d7a70064015efa7c2`

### For Docker/Podman Deployments

You need **one image**:
- `ds-px-runtime`

**Summary of Docker/Podman Digest:**
- **ds-px-runtime**: `sha256:fc272799bd1634e47dab5cd3f0974e840ccd3248480e9915bb664b40ca39e9ad`

## Step 4: Copy Images to Your Private Registry Using Skopeo

### Set Up Variables
```bash
# IBM Container Registry credentials
IBM_REGISTRY_KEY="your-ibm-container-registry-api-key"

# Your private registry details
PRIVATE_REGISTRY="artifactory.example.com"
REGISTRY_USERNAME="your-username"
REGISTRY_PASSWORD="your-password"

# Image digests from Step 2
RUNTIME_DIGEST="sha256:fc272799bd1634e47dab5cd3f0974e840ccd3248480e9915bb664b40ca39e9ad"
COMPUTE_DIGEST="sha256:7870e7f7d2d650b318ca6008999c4406e64a6f09a494177d7a70064015efa7c2"
```

### Copy ds-px-runtime (Required for Both Kubernetes and Docker/Podman)
```bash
skopeo copy --all \
  --src-creds iamapikey:${IBM_REGISTRY_KEY} \
  --dest-creds ${REGISTRY_USERNAME}:${REGISTRY_PASSWORD} \
  --dest-tls-verify=false \
  docker://icr.io/datastage/ds-px-runtime@${RUNTIME_DIGEST} \
  docker://${PRIVATE_REGISTRY}/datastage/ds-px-runtime@${RUNTIME_DIGEST}
```

**Sample Output:**
```
Getting image source signatures
Copying blob sha256:b2c3d4e5f6a7...
Copying blob sha256:e5f6a7b8c9d0...
Copying config sha256:fc272799bd16...
Writing manifest to image destination
Storing signatures
```

### For Kubernetes/OpenShift Only: Copy Additional Images

If deploying to Kubernetes/OpenShift, also copy the operator and compute images:
```bash
# Set operator digest (from Step 3)
OPERATOR_DIGEST="sha256:7e4885cdb1deef0cbbcff590357fa96be32b31d5809f045ff2cbf285ad45b0a6"

# Copy ds-operator
skopeo copy --all \
  --src-creds iamapikey:${IBM_REGISTRY_KEY} \
  --dest-creds ${REGISTRY_USERNAME}:${REGISTRY_PASSWORD} \
  --dest-tls-verify=false \
  docker://icr.io/datastage/ds-operator@${OPERATOR_DIGEST} \
  docker://${PRIVATE_REGISTRY}/datastage/ds-operator@${OPERATOR_DIGEST}

# Copy ds-px-compute (digest already set above)
skopeo copy --all \
  --src-creds iamapikey:${IBM_REGISTRY_KEY} \
  --dest-creds ${REGISTRY_USERNAME}:${REGISTRY_PASSWORD} \
  --dest-tls-verify=false \
  docker://icr.io/datastage/ds-px-compute@${COMPUTE_DIGEST} \
  docker://${PRIVATE_REGISTRY}/datastage/ds-px-compute@${COMPUTE_DIGEST}
```

**Note:** Use `--dest-tls-verify=true` if your private registry has valid SSL certificates.

### Verify Images Were Copied
```bash
# Verify ds-px-runtime
skopeo inspect --creds ${REGISTRY_USERNAME}:${REGISTRY_PASSWORD} \
  docker://${PRIVATE_REGISTRY}/datastage/ds-px-runtime@${RUNTIME_DIGEST}

# For Kubernetes/OpenShift, also verify:
skopeo inspect --creds ${REGISTRY_USERNAME}:${REGISTRY_PASSWORD} \
  docker://${PRIVATE_REGISTRY}/datastage/ds-operator@${OPERATOR_DIGEST}

skopeo inspect --creds ${REGISTRY_USERNAME}:${REGISTRY_PASSWORD} \
  docker://${PRIVATE_REGISTRY}/datastage/ds-px-compute@${COMPUTE_DIGEST}
```

**Sample Output (for each image):**
```json
{
  "Name": "artifactory.example.com/datastage/ds-px-runtime",
  "Digest": "sha256:fc272799bd1634e47dab5cd3f0974e840ccd3248480e9915bb664b40ca39e9ad",
  "RepoTags": [],
  "Created": "2025-11-19T10:30:00.000000000Z",
  "DockerVersion": "",
  "Labels": null,
  "Architecture": "amd64",
  "Os": "linux",
  "Layers": [...]
}
```

---

# Deployment Instructions

Now that you have copied the images to your private registry, choose your deployment method:

## Option A: Deploy to Kubernetes/OpenShift

### Step 5a: Configure the Input File for Kubernetes

Navigate to the launch directory:
```bash
cd DataStage/RemoteEngine/launch
```

Create `inputFile.txt`:
```bash
# License acceptance (required)
license_accept=true

# Namespace to deploy the remote engine
namespace=datastage-remote

# Data center (for IBM Cloud deployments)
data_center=dallas

# Private registry credentials
# These are the credentials for YOUR private registry (Artifactory, etc.)
username=your-artifactory-username
password=your-artifactory-password

# IBM Cloud API key for DataStage service authentication
# This is your IBM Cloud API key (NOT the container registry key)
api_key=your-ibm-cloud-api-key

# Project configuration
projectId=project-id-1,project-id-2
name=remote-engine-01
size=small

# Storage configuration
storage_class=your-storage-class
storage_size=20

# Custom registry settings (REQUIRED when using private registry)
CUSTOM_DOCKER_REGISTRY=artifactory.example.com
OPERATOR_REGISTRY_SUFFIX=datastage
DOCKER_REGISTRY_SUFFIX=datastage

# Image digests (from Steps 2 and 3)
USE_DIGESTS=sha256:7e4885cdb1deef0cbbcff590357fa96be32b31d5809f045ff2cbf285ad45b0a6,sha256:fc272799bd1634e47dab5cd3f0974e840ccd3248480e9915bb664b40ca39e9ad,sha256:7870e7f7d2d650b318ca6008999c4406e64a6f09a494177d7a70064015efa7c2
```

### Important Notes for Kubernetes:

**Three Different Credentials:**
1. **IBM Container Registry Key** (used in Step 4) - Used by skopeo to pull images from `icr.io/datastage`
2. **Private Registry Credentials** (`username`/`password` in input file) - Used by Kubernetes to pull from your Artifactory
3. **IBM Cloud API Key** (`api_key` in input file) - Used by the remote engine to authenticate with DataStage service

**Registry Path Configuration:**
- `CUSTOM_DOCKER_REGISTRY`: Your registry hostname only (e.g., `artifactory.example.com`)
- `OPERATOR_REGISTRY_SUFFIX`: Path where ds-operator is stored (e.g., `datastage` means images are at `artifactory.example.com/datastage/ds-operator`)
- `DOCKER_REGISTRY_SUFFIX`: Path where ds-px-runtime and ds-px-compute are stored (typically the same as operator suffix)

**Digest Format:**
- Must be comma-separated with NO spaces
- Order: `operator,runtime,compute`

### Step 6a: Run the Kubernetes Installation
```bash
./launch.sh -f inputFile.txt
```

**Sample Output:**
```
IBM DataStage Remote Engine 1.0.11

Setting Kubernetes cli to 'oc'
Running against OpenShift cluster
Using custom docker registry for IBM Cloud.
DOCKER_REGISTRY=artifactory.mycompany.com
OPERATOR_REGISTRY=artifactory.mycompany.com/datastage
DOCKER_REGISTRY_PREFIX=artifactory.mycompany.com/datastage
Setting custom remote engine digests.
Using custom digest for ds-operator: sha256:7e4885cdb1deef0cbbcff590357fa96be32b31d5809f045ff2cbf285ad45b0a6
Using custom digest for ds-px-runtime: sha256:fc272799bd1634e47dab5cd3f0974e840ccd3248480e9915bb664b40ca39e9ad
Using custom digest for ds-px-compute: sha256:7870e7f7d2d650b318ca6008999c4406e64a6f09a494177d7a70064015efa7c2

Deploying DataStage operator to namespace datastage-remote...
secret/datastage-pull-secret created
secret/datastage-api-key-secret created
serviceaccount/ibm-cpd-datastage-remote-operator-serviceaccount created
role.rbac.authorization.k8s.io/ibm-cpd-datastage-remote-operator-role created
rolebinding.rbac.authorization.k8s.io/ibm-cpd-datastage-remote-operator-role-binding created
customresourcedefinition.apiextensions.k8s.io/pxremoteengines.ds.cpd.ibm.com created
deployment.apps/ibm-cpd-datastage-remote-operator created
DataStage operator deployment created.
pxremoteengine.ds.cpd.ibm.com/remote-engine-01 created
To check the status of the PXRemoteEngine instance, run the command below:
oc -n datastage-remote get pxre remote-engine-01
```

### Monitor the Kubernetes Installation

Check the status of the remote engine:
```bash
oc -n datastage-remote get pxre remote-engine-01
```

**Sample Output:**
```
NAME               VERSION   RECONCILED   STATUS      AGE
remote-engine-01   1.0.2502  1.0.2502     Ready       5m
```

Check the pods:
```bash
oc -n datastage-remote get pods
```

**Sample Output:**
```
NAME                                                  READY   STATUS    RESTARTS   AGE
ibm-cpd-datastage-remote-operator-7d8f9b6c5d-xyz12   1/1     Running   0          5m
remote-engine-01-ibm-datastage-px-runtime-0          1/1     Running   0          4m
remote-engine-01-ibm-datastage-px-compute-0          1/1     Running   0          4m
remote-engine-01-ibm-datastage-px-compute-1          1/1     Running   0          4m
```

When all pods show `Running` status and the PXRemoteEngine shows `Ready`, your remote engine is successfully deployed!

---

## Option B: Deploy to Docker/Podman

### Step 5b: Run the Docker/Podman Installation

Navigate to the docker directory:
```bash
cd DataStage/RemoteEngine/docker
```

Run the `dsengine.sh` script with custom registry parameters:
```bash
./dsengine.sh start \
  -n 'my_remote_engine_01' \
  -e "$ENCRYPTION_KEY" \
  -i "$ENCRYPTION_IV" \
  -p "$IBMCLOUD_CONTAINER_REGISTRY_APIKEY" \
  --project-id "$PROJECT_ID1,$PROJECT_ID2" \
  --registry "artifactory.example.com" \
  -u "your-artifactory-username" \
  --digest "sha256:fc272799bd1634e47dab5cd3f0974e840ccd3248480e9915bb664b40ca39e9ad"
```

**Parameter Explanation:**
- `-n`: Name of your remote engine
- `-e`: Encryption key (generate using `openssl enc -aes-256-cbc -k secret -P -md sha1 -pbkdf2`)
- `-i`: Initialization vector (from same openssl command)
- `-p`: IBM Container Registry API key (for authentication)
- `--project-id`: Comma-separated list of project IDs
- `--registry`: Your private registry hostname
- `-u`: Username for your private registry
- `--digest`: The ds-px-runtime digest from Step 2

**Note:** You will be prompted for the private registry password when the script runs.

**Sample Output:**
```
IBM DataStage Remote Engine 1.0.30

Docker login to Custom Container Registry.
Password: 
Login Succeeded!

Checking docker images ...
Checking image artifactory.example.com/datastage/ds-px-runtime@sha256:fc272799bd1634e47dab5cd3f0974e840ccd3248480e9915bb664b40ca39e9ad
Image does not exist locally, proceeding to download
docker pull artifactory.example.com/datastage/ds-px-runtime@sha256:fc272799bd1634e47dab5cd3f0974e840ccd3248480e9915bb664b40ca39e9ad

Initializing DataStage Remote Engine Runtime environment with name 'my_remote_engine_01' ...
Setting up docker environment
Starting instance 'my_remote_engine_01' ...
Running container 'my_remote_engine_01_runtime' ...
...
Remote Engine setup completed.
```

### Alternative: Using Environment Variables

You can set credentials as environment variables to avoid being prompted:
```bash
export ENCRYPTION_KEY="your-encryption-key"
export ENCRYPTION_IV="your-encryption-iv"
export IBMCLOUD_CONTAINER_REGISTRY_APIKEY="your-ibm-registry-key"
export PROJECT_ID1="project-id-1"
export PROJECT_ID2="project-id-2"
export REGISTRY_PASSWORD="your-artifactory-password"

./dsengine.sh start \
  -n 'my_remote_engine_01' \
  -e "$ENCRYPTION_KEY" \
  -i "$ENCRYPTION_IV" \
  -p "$IBMCLOUD_CONTAINER_REGISTRY_APIKEY" \
  --project-id "$PROJECT_ID1,$PROJECT_ID2" \
  --registry "artifactory.example.com" \
  -u "your-artifactory-username" \
  --digest "sha256:fc272799bd1634e47dab5cd3f0974e840ccd3248480e9915bb664b40ca39e9ad"
```

### Monitor the Docker/Podman Installation

Check the container status:
```bash
docker ps | grep my_remote_engine_01
# OR
podman ps | grep my_remote_engine_01
```

**Sample Output:**
```
a1b2c3d4e5f6  artifactory.example.com/datastage/ds-px-runtime@sha256:fc272799...  Running  my_remote_engine_01_runtime
```

Check the container logs:
```bash
docker logs my_remote_engine_01_runtime
# OR
podman logs my_remote_engine_01_runtime
```

Once the container is running and the engine is registered, you can select it in your DataStage project settings.

---

## Summary

You have now successfully:
1. Cloned the DataStage repository
2. Retrieved the latest image digests from the DataStage API
3. Copied the required images to your private registry using Skopeo
4. Deployed a DataStage Remote Engine using either:
    - **Kubernetes/OpenShift** with the `launch.sh` script and input file
    - **Docker/Podman** with the `dsengine.sh` script and custom registry parameters

The remote engine is now ready to run DataStage flows from your projects.