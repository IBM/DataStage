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

## Step 2: Get the Image Digests

### Step 2a: For remote engine for IBM Cloud, it is okay to use the latest image digests

#### First get access token (using your IBM Container Registry API key)
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

#### Get latest ds-operator digest
```bash
curl -s -X GET \
  -H "accept: application/json" \
  -H "Account: d10b01a616ed4b73a9ac8a052424a345" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --url "https://icr.io/api/v1/images?includeIBM=false&includePrivate=true&includeManifestLists=true&vulnerabilities=true&repository=ds-operator" | \
  jq '. |= sort_by(.Created) | .[length -1] | .RepoDigests[0]' | cut -d@ -f2 | tr -d '"'
```

**Sample Output:**
```
sha256:373b2d4dd50a780a151113caeb6aa16552001edc55bdf4ce598983e679b6bebf
```

#### Get latest ds-px-runtime digest
```bash
curl -s -X GET \
  -H "accept: application/json" \
  -H "Account: d10b01a616ed4b73a9ac8a052424a345" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --url "https://icr.io/api/v1/images?includeIBM=false&includePrivate=true&includeManifestLists=true&vulnerabilities=true&repository=ds-px-runtime" | \
  jq '. |= sort_by(.Created) | .[length -1] | .RepoDigests[0]' | cut -d@ -f2 | tr -d '"'
```

**Sample Output:**
```
sha256:c590dfbe4d25e6b7e5340f472d1a4a0cc5fdc996676f6c1a9038080f251f56a6
```

#### Get latest ds-px-compute digest
```bash
curl -s -X GET \
  -H "accept: application/json" \
  -H "Account: d10b01a616ed4b73a9ac8a052424a345" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --url "https://icr.io/api/v1/images?includeIBM=false&includePrivate=true&includeManifestLists=true&vulnerabilities=true&repository=ds-px-compute" | \
  jq '. |= sort_by(.Created) | .[length -1] | .RepoDigests[0]' | cut -d@ -f2 | tr -d '"'
```

**Sample Output:**
```
sha256:c490677665a69df0f468b49048c41ac883f3eb50354a3359bab7736f0f2737f9
```

### Step 2b: For remote engine for CP4D, it is recommended you use the official pre-built image digests that matches the DataStage version of the destination cluster you are connecting to (zen_url)

### For Kubernetes/OpenShift Deployments

You can get the image digests you need near the top of the launch.sh file. They are ordered by DataStage version starting from 5.1.0:

```bash
egrep "supported_versions=|asset_versions=|operator_digests=|px_runtime_digests=|px_compute_digests=" launch.sh
```

**Sample Output:**
```
supported_versions="5.1.0 5.1.1 5.1.2 5.1.3 5.2.0 5.2.1 5.2.2 5.3.0"
asset_versions="510 511 512 513 520 521 522 530"
operator_digests="sha256:4d4e0e4355f2e24522880fd3a5ce2b0300096586d929a9d762b011dcfbdbec84 sha256:315de39c1ce4e72b8af224a676da8c73f3118c455ab427b412edb22da795ae00 sha256:47bbb1b75e59e05e025134c8dd52adc6276050213b0a9deb51067aecb2f6056c sha256:f57d3d5b20521d546a0a9b6af839cc659c1f08357d5d06da93aacf1ad5ee08e4 sha256:2d753908d9581d10e66e087f809fe7c212dc73cbffc60bc6728b7b28b6ff9c57 sha256:2809185dd56232f2956eea571833df8858530c961bba919a967e83c9c3c24877 sha256:95f150a03ee72d4cf3df5db14d398297787451afed69d1f565498a09e5e6d05d sha256:1d0f615945b7784d187501c5eb74e4a63f07d0abedce1be43b48c5e646a54973"
px_runtime_digests="sha256:e9c63c0334620ac72bc3a7343a6e4e8184a2e48ca2cd1f54f06734fddedc0949 sha256:3000c8a98cef44be354cad92ea7790d075f3fed7b7cde69c9d59f1d52f25499a sha256:9e9b1562eee6d09969d6e967f0698f2320c0f75aad9b75643d4818d3596c7f7b sha256:d429306e12a74f34f8a86e0800be346abaff509d4aaf0e9fcefafcaf6ef36769 sha256:6e394510b8dddcb3e0858cf344955e411478927dc3ee35997d69d21bfd06f9d9 sha256:3abc437a0df489b2eb31d078676a3fe6bdd942e0d84b011479a8a0ceba8e02e0 sha256:d0d5b526f3e56539389a17f7f851bb7947332dc849728fa36eef099c1db50ae3 sha256:a9562467423d541c88c87fd509fbe929439be2633b64660eae578363e30e536e"
px_compute_digests="sha256:266730b6769f585a6c943f3db5ad9174c058e6d00704f2c8a7b0f76cef1de29b sha256:eb9979137e0c724b0087246757666c662e1d430c5590a1a9e674f887be62f699 sha256:daf937b4d46f950b30f5c8d27f3f5b2d61703a8c403869befbdd62c47dd27a3d sha256:9c291405cf498cd88587ce5ae37cf0967718d17e8a7b4b7ea19796d3c5676c09 sha256:52754f8689e31100cd088163c7d1f7c1aa29863c6acbb3f2a41f6d141050ce1a sha256:391396d4d9bd48157eb29c1deb18746bf9be56321c94a99fdd35f8e4a3e6147d sha256:adafd046967c0beda9355f3aadd87d79aa464116c90fe12291fee4d9435a96f2 sha256:686a2fa095f4fb216136608b71732c76a237fd9b4c52091e54117425edd4d80e"
```

For example, if we want to use the ds-operator, ds-px-runtime, and ds-px-compute images for DataStage version 5.3.0, then we will use the following image digests:

- **ds-operator**: `sha256:1d0f615945b7784d187501c5eb74e4a63f07d0abedce1be43b48c5e646a54973`
- **ds-px-runtime**: `sha256:a9562467423d541c88c87fd509fbe929439be2633b64660eae578363e30e536e`
- **ds-px-compute**: `sha256:686a2fa095f4fb216136608b71732c76a237fd9b4c52091e54117425edd4d80e`

### For Docker/Podman Deployments

You can get the image digests you need near the top of the dsengine.sh file. They are ordered by DataStage version starting from 5.1.0:

```bash
egrep "supported_versions=|asset_versions=|px_runtime_digests=" dsengine.sh
```

**Sample Output:**
```
supported_versions="5.1.0 5.1.1 5.1.2 5.1.3 5.2.0 5.2.1 5.2.2 5.3.0"
asset_versions="510 511 512 513 520 521 522 530"
px_runtime_digests="sha256:e9c63c0334620ac72bc3a7343a6e4e8184a2e48ca2cd1f54f06734fddedc0949 sha256:3000c8a98cef44be354cad92ea7790d075f3fed7b7cde69c9d59f1d52f25499a sha256:9e9b1562eee6d09969d6e967f0698f2320c0f75aad9b75643d4818d3596c7f7b sha256:d429306e12a74f34f8a86e0800be346abaff509d4aaf0e9fcefafcaf6ef36769 sha256:6e394510b8dddcb3e0858cf344955e411478927dc3ee35997d69d21bfd06f9d9 sha256:3abc437a0df489b2eb31d078676a3fe6bdd942e0d84b011479a8a0ceba8e02e0 sha256:d0d5b526f3e56539389a17f7f851bb7947332dc849728fa36eef099c1db50ae3 sha256:a9562467423d541c88c87fd509fbe929439be2633b64660eae578363e30e536e"
```

For example, if we want to use the ds-px-runtime image for DataStage version 5.3.0, then we will use the following image digest:

- **ds-px-runtime**: `sha256:a9562467423d541c88c87fd509fbe929439be2633b64660eae578363e30e536e`

## Step 3: Determine Which Images You Need

### For Kubernetes/OpenShift Deployments

You need **three images**:
- `ds-operator`
- `ds-px-runtime`
- `ds-px-compute`

**Summary of Kubernetes Digests:**
- **ds-operator**: `sha256:373b2d4dd50a780a151113caeb6aa16552001edc55bdf4ce598983e679b6bebf`
- **ds-px-runtime**: `sha256:c590dfbe4d25e6b7e5340f472d1a4a0cc5fdc996676f6c1a9038080f251f56a6`
- **ds-px-compute**: `sha256:c490677665a69df0f468b49048c41ac883f3eb50354a3359bab7736f0f2737f9`

### For Docker/Podman Deployments

You need **one image**:
- `ds-px-runtime`

**Summary of Docker/Podman Digest:**
- **ds-px-runtime**: `sha256:c590dfbe4d25e6b7e5340f472d1a4a0cc5fdc996676f6c1a9038080f251f56a6`

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
RUNTIME_DIGEST="sha256:c590dfbe4d25e6b7e5340f472d1a4a0cc5fdc996676f6c1a9038080f251f56a6"
COMPUTE_DIGEST="sha256:c490677665a69df0f468b49048c41ac883f3eb50354a3359bab7736f0f2737f9"
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
# Set operator digest (from Step 2)
OPERATOR_DIGEST="sha256:373b2d4dd50a780a151113caeb6aa16552001edc55bdf4ce598983e679b6bebf"

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
  "Digest": "sha256:c590dfbe4d25e6b7e5340f472d1a4a0cc5fdc996676f6c1a9038080f251f56a6",
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

# Image digests (from Step 2)
USE_DIGESTS=sha256:373b2d4dd50a780a151113caeb6aa16552001edc55bdf4ce598983e679b6bebf,sha256:c590dfbe4d25e6b7e5340f472d1a4a0cc5fdc996676f6c1a9038080f251f56a6,sha256:c490677665a69df0f468b49048c41ac883f3eb50354a3359bab7736f0f2737f9
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
Using custom digest for ds-operator: sha256:373b2d4dd50a780a151113caeb6aa16552001edc55bdf4ce598983e679b6bebf
Using custom digest for ds-px-runtime: sha256:c590dfbe4d25e6b7e5340f472d1a4a0cc5fdc996676f6c1a9038080f251f56a6
Using custom digest for ds-px-compute: sha256:c490677665a69df0f468b49048c41ac883f3eb50354a3359bab7736f0f2737f9

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
  --digest "sha256:c590dfbe4d25e6b7e5340f472d1a4a0cc5fdc996676f6c1a9038080f251f56a6"
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
Checking image artifactory.example.com/datastage/ds-px-runtime@sha256:c590dfbe4d25e6b7e5340f472d1a4a0cc5fdc996676f6c1a9038080f251f56a6
Image does not exist locally, proceeding to download
docker pull artifactory.example.com/datastage/ds-px-runtime@sha256:c590dfbe4d25e6b7e5340f472d1a4a0cc5fdc996676f6c1a9038080f251f56a6

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
  --digest "sha256:c590dfbe4d25e6b7e5340f472d1a4a0cc5fdc996676f6c1a9038080f251f56a6"
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