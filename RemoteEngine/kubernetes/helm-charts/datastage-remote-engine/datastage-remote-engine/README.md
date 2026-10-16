# datastage-remote-engine Helm Chart

Deploys an IBM DataStage Remote Engine on Kubernetes (EKS, IKS, or OpenShift).
Equivalent to running `launch.sh` with an input file.

## Prerequisites

- `helm` v3
- `kubectl` configured against your target cluster
- RWX storage class available (e.g. `efs-sc`)
- IBM Cloud Container Registry API key (from IBM Cloud Support)
- IBM Cloud API key for the engine

## Image digests

`launch.sh` fetches current image digests from the control plane at deploy time.
With Helm you supply them manually. Get the latest digests by running:

```bash
# Get an IAM token first
TOKEN=$(curl -s -X POST \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" \
  --data-urlencode "apikey=<YOUR_API_KEY>" \
  https://iam.cloud.ibm.com/identity/token | jq -r .access_token)

# Dallas example - adjust gateway for your data center
curl -s -X GET \
  -H "Authorization: Bearer $TOKEN" \
  -H "accept: application/json" \
  https://api.dataplatform.cloud.ibm.com/data_intg/v3/flows_runtime/remote_engine/versions \
  | jq -r '.versions[0].image_digests'
```

For the operator digest, check the latest release in the IBM GitHub repo:
https://github.com/IBM/DataStage

## Install

```bash
helm install my-engine ./datastage-remote-engine \
  --set name=my-engine \
  --set namespace=my-namespace \
  --set apiKey=<IBM_CLOUD_API_KEY> \
  --set registryPassword=<ICR_API_KEY> \
  --set projectId=<PROJECT_ID> \
  --set storageClass=efs-sc \
  --set dataCenter=frankfurt \
  --set licenseAccept=true \
  --set operatorDigest=sha256:<digest> \
  --set pxRuntimeDigest=sha256:<digest> \
  --set pxComputeDigest=sha256:<digest>
```

Or use a values file:

```bash
helm install my-engine ./datastage-remote-engine -f my-values.yaml
```

## AWS deployment

Add `--set mcspAccountId=<MCSP_ACCOUNT_ID>` and use an AWS data center:

```bash
helm install my-engine ./datastage-remote-engine \
  --set dataCenter=awsprod-useast \
  --set mcspAccountId=<MCSP_ACCOUNT_ID> \
  ...
```

## Upgrade

To update image digests or config:

```bash
helm upgrade my-engine ./datastage-remote-engine -f my-values.yaml
```

Note: upgrading the PXRemoteEngine CR will trigger the operator to reconcile
and roll out updated images.

## Uninstall

```bash
helm uninstall my-engine
kubectl delete namespace <namespace>
```

The CRD (`pxremoteengines.ds.cpd.ibm.com`) is cluster-scoped and shared.
Helm will NOT delete it on uninstall. Remove it manually only if no other
engines are deployed in the cluster:

```bash
kubectl delete crd pxremoteengines.ds.cpd.ibm.com
```

## Data center / gateway mapping

| dataCenter        | gateway                                  |
|-------------------|------------------------------------------|
| dallas (default)  | api.dataplatform.cloud.ibm.com           |
| frankfurt         | api.eu-de.dataplatform.cloud.ibm.com     |
| sydney            | api.au-syd.dai.cloud.ibm.com             |
| toronto           | api.ca-tor.dai.cloud.ibm.com             |
| london            | api.eu-gb.dataplatform.cloud.ibm.com     |
| awsprod-apsouth   | api.ap-south-1.aws.data.ibm.com          |
| awsprod-useast    | api.us-east-1.aws.data.ibm.com           |
| awsgovprod        | api.dai.ibmforusgov.com                  |
