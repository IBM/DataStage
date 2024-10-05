#!/usr/bin/env bash
# (C) Copyright IBM Corp. 2023  All Rights Reserved.
#
# This script is a utility to install DataStage Remote Engine

kubernetesCLI="oc"
curlCMD="curl"
scriptName=$(basename "$0")
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
filesDir="${scriptDir}/files"

serviceAccountFile="${filesDir}/datastage-sa.yaml"
roleFile="${filesDir}/datastage-role.yaml"
roleBindingFile="${filesDir}/datastage-rolebinding.yaml"
pxruntimeCRDFile="${filesDir}/ds.cpd.ibm.com_pxruntimes.yaml"
deploymentFile="${filesDir}/manager.yaml"

nfsProvisionerFile="${filesDir}/efs-provisioner.yaml"
nfsStorageClassFile="${filesDir}/efs-storageclass.yaml"
nfs_path="/"

DOCKER_REGISTRY="icr.io"
OPERATOR_REGISTRY="${DOCKER_REGISTRY}/datastage"
DOCKER_REGISTRY_PREFIX="${DOCKER_REGISTRY}/datastage"
DS_REGISTRY_SECRET="datastage-pull-secret"
DS_API_KEY_SECRET="datastage-api-key-secret"
DS_GATEWAY="api.dataplatform.cloud.ibm.com"
data_center="dallas"

px_runtime_digest="sha256:7b1a21a5ddacb157ba3e27729c493769f344a70ad4ae64fc7d4501efb66cd7f2"
px_compute_digest="sha256:dc3236055473b2e45d22162bbbd8c2d12888d2b8fac8d803bd275965cbf1cc22"
operator_digest="sha256:99e45f8f94834d8f0ed2e9dbba9724bd79726eb292c0f2cef30844c072e178dc"

# default username for icr.io when using apikey
username="iamapikey"

storage_size="10"
size="small"

set_curl_cmd() {
  if [ -z $proxy_url ]; then
    curlCMD="${curlCMD} --proxy ${proxy_url}"
  fi
}

determine_cli() {
  which kubectl
  if [[ $? -eq 0 ]]; then
    kubernetesCLI="kubectl";
  else
    which oc
    if [[ $? -eq 0 ]]; then
      kubernetesCLI="oc"
    else
      echo "Unable to locate oc nor kubectl cli in execution path."
      exit 1
    fi
  fi
  echo "Setting Kubernetes cli to '${kubernetesCLI}'"
}

determine_k8s()
{
  namespace_os_annotation=`$kubernetesCLI get namespace $namespace -o yaml | grep 'openshift.io' | wc -l`
  if [ $namespace_os_annotation -ne 0 ]; then
    isOpenShiftCluster="true"
    echo "Running against OpenShift cluster"
    # use oc if it's available
    if [ $kubernetesCLI != "oc" ]; then
      which oc
      if [[ $? -eq 0 ]]; then
        kubernetesCLI="oc"
      fi
    fi
  else
    isOpenShiftCluster="false"
  fi
}

create_nfs_provisioner() {
  echo "Creating NFS provisioner"
  if [ -z $nfs_server ]; then
    display_missing_arg "server"
  fi
  if [ -z $nfs_path ]; then
    display_missing_arg "path"
  fi
  if [ -z $provisioner_namespace ]; then
    provisioner_namespace="$namespace"
  fi
	if [ -z $provisioner_namespace ]; then
    display_missing_arg "namespace"
  fi
  if [ -z $storage_class ]; then
    storage_class="nfs-client"
  fi

  cat <<EOF | $kubernetesCLI -n $provisioner_namespace apply ${dryRun} -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${storage_class}-provisioner
  namespace: $provisioner_namespace
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${storage_class}-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-${storage_class}-provisioner
subjects:
  - kind: ServiceAccount
    name: ${storage_class}-provisioner
    namespace: $provisioner_namespace
roleRef:
  kind: ClusterRole
  name: ${storage_class}-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-${storage_class}-provisioner
  namespace: $provisioner_namespace
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-${storage_class}-provisioner
  namespace: $provisioner_namespace
subjects:
  - kind: ServiceAccount
    name: ${storage_class}-provisioner
    namespace: $provisioner_namespace
roleRef:
  kind: Role
  name: leader-locking-${storage_class}-provisioner
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${storage_class}-provisioner
  labels:
    app: ${storage_class}-provisioner
  namespace: $provisioner_namespace
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: ${storage_class}-provisioner
  template:
    metadata:
      labels:
        app: ${storage_class}-provisioner
    spec:
      serviceAccountName: ${storage_class}-provisioner
      containers:
        - name: ${storage_class}-provisioner
          image: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          volumeMounts:
            - name: ${storage_class}-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: k8s-sigs.io/nfs-subdir-external-provisioner
            - name: NFS_SERVER
              value: $nfs_server
            - name: NFS_PATH
              value: $nfs_path
      volumes:
        - name: ${storage_class}-root
          nfs:
            server: $nfs_server
            path: $nfs_path
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ${storage_class}
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner
parameters:
  archiveOnDelete: "false"
EOF

}

display_missing_arg()
{
  echo "Missing required parameter - ${1}"
  exit 1
}

validate_common_args()
{
  if [ -z $namespace ]; then
    display_missing_arg "namespace"
  fi
  check_namespace
}

create_pxruntime_crd() {
  cat <<EOF | $kubernetesCLI -n $namespace apply ${dryRun} -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  creationTimestamp: null
  name: pxremoteengines.ds.cpd.ibm.com
spec:
  group: ds.cpd.ibm.com
  names:
    kind: PXRemoteEngine
    listKind: PXRemoteEngineList
    plural: pxremoteengines
    singular: pxremoteengine
    shortNames:
    - pxre
    - pxres
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
      - description: The desired version of PXRemoteEngine
        jsonPath: .spec.version
        name: Version
        type: string
      - description: The actual version PXRemoteEngine
        jsonPath: .status.dsVersion
        name: Reconciled
        type: string
      - description: The status of PXRemoteEngine
        jsonPath: .status.dsStatus
        name: Status
        type: string
      - description: The age of PXRemoteEngine
        jsonPath: .metadata.creationTimestamp
        name: Age
        type: date
    name: v1
    schema:
      openAPIV3Schema:
        description: DataStage is the Schema for the datastages API
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: Spec defines the desired state of DataStage
            type: object
            x-kubernetes-preserve-unknown-fields: true
          status:
            description: Status defines the observed state of DataStage
            type: object
            x-kubernetes-preserve-unknown-fields: true
        type: object
    served: true
    storage: true
    subresources:
      status: {}
status:
  acceptedNames:
    kind: ""
    plural: ""
  conditions: null
  storedVersions: null
EOF
}

create_service_account() {
  #sed <"${serviceAccountFile}" "s#NAMESPACE_REPLACE#${namespace}#g" | $kubernetesCLI apply ${dryRun} -f -
  cat <<EOF | $kubernetesCLI -n $namespace apply ${dryRun} -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ibm-cpd-datastage-remote-operator-serviceaccount
  namespace: $namespace
  labels:
    app.kubernetes.io/instance: ibm-cpd-datastage-remote-operator-sa
    app.kubernetes.io/managed-by: ibm-cpd-datastage-remote-operator
    app.kubernetes.io/name: ibm-cpd-datastage-remote-operator-sa
imagePullSecrets:
- name: ibm-entitlement-key
- name: $DS_REGISTRY_SECRET
EOF
}

create_role() {
  cat <<EOF | $kubernetesCLI -n $namespace apply ${dryRun} -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ibm-cpd-datastage-remote-operator-role
  namespace: $namespace
  labels:
     app.kubernetes.io/instance: ibm-cpd-datastage-remote-operator-cluster-role
     app.kubernetes.io/managed-by: ibm-cpd-datastage-remote-operator
     app.kubernetes.io/name: ibm-cpd-datastage-remote-operator-cluster-role

rules:
- apiGroups:
  - ""
  - batch
  - extensions
  - apps
  - policy
  - rbac.authorization.k8s.io
  - autoscaling
  - route.openshift.io
  - authorization.openshift.io
  - networking.k8s.io
  resources:
  - secrets
  - pods
  - pods/exec
  - pods/log
  - jobs
  - configmaps
  - deployments
  - deployments/scale
  - statefulsets
  - statefulsets/scale
  - replicasets
  - services
  - persistentvolumeclaims
  - persistentvolumes
  - cronjobs
  - serviceaccounts
  - roles
  - rolebindings
  - horizontalpodautoscalers
  - jobs/status
  - pods/status
  - networkpolicies
  verbs:
  - apply
  - create
  - get
  - delete
  - watch
  - update
  - edit
  - list
  - patch
- apiGroups:
  - ds.cpd.ibm.com
  resources:
  - pxremoteengines
  - pxremoteengines/status
  - pxremoteengines/finalizers
  verbs:
  - apply
  - edit
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
EOF
}

create_role_binding() {
  cat <<EOF | $kubernetesCLI -n $namespace apply ${dryRun} -f -
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ibm-cpd-datastage-remote-operator-role-binding
  namespace: $namespace
  labels:
    app.kubernetes.io/instance: ibm-cpd-datastage-remote-operator-role-binding
    app.kubernetes.io/managed-by: ibm-cpd-datastage-remote-operator
    app.kubernetes.io/name: ibm-cpd-datastage-remote-operator-role-binding
subjects:
- kind: ServiceAccount
  name: ibm-cpd-datastage-remote-operator-serviceaccount
  namespace: $namespace
roleRef:
  kind: Role
  name: ibm-cpd-datastage-remote-operator-role
  apiGroup: rbac.authorization.k8s.io
EOF
}

create_operator_deployment() {
  runAsUser="runAsUser: 1001"
  k8sEnv=""
  if [[ "$isOpenShiftCluster" = "true" ]]; then
    # remove runAsUser for openshift
    #sed <"${deploymentFile}" "/runAsUser: 1001/d" | $kubernetesCLI -n ${namespace} apply ${dryRun} -f -
    runAsUser=""
  else
    # add KUBERNETES=True env
    # sed <"${deploymentFile}" "s/env:/env:\n            - name: KUBERNETES\n              value: \"True\"/g" | $kubernetesCLI -n ${namespace} apply ${dryRun} -f -
    k8sEnv=$'- name: KUBERNETES\n              value: "True"'
  fi
  # remove deployment with incorrect name used previously
  $kubernetesCLI -n $namespace delete deploy ibm-cpd-datastage-operator --ignore-not-found=true
	$kubernetesCLI -n $namespace delete deploy ibm-cpd-datastage-remote-operator --ignore-not-found=true
  cat <<EOF | $kubernetesCLI -n $namespace apply ${dryRun} -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ibm-cpd-datastage-remote-operator
  annotations:
    productID: ff566289767a4a7f822ab01ebaa16cf4
    productMetric: FREE
    productName: IBM DataStage as a Service Anywhere
    productVersion: 4.8.0
  labels:
    app.kubernetes.io/instance: ibm-cpd-datastage-remote-operator
    app.kubernetes.io/managed-by: ibm-cpd-datastage-remote-operator
    app.kubernetes.io/name: ibm-cpd-datastage-remote-operator
    intent: projected
    icpdsupport/addOnId: datastage
    icpdsupport/app: operator
    name: ibm-cpd-datastage-remote-operator
spec:
  selector:
    matchLabels:
      name: ibm-cpd-datastage-remote-operator
  replicas: 1
  template:
    metadata:
      annotations:
        productID: ff566289767a4a7f822ab01ebaa16cf4
        productMetric: FREE
        productName: IBM DataStage as a Service Anywhere
        productVersion: 4.8.0
      labels:
        app.kubernetes.io/instance: ibm-cpd-datastage-remote-operator
        app.kubernetes.io/managed-by: ibm-cpd-datastage-remote-operator
        app.kubernetes.io/name: ibm-cpd-datastage-remote-operator
        intent: projected
        icpdsupport/addOnId: datastage
        icpdsupport/app: operator
        name: ibm-cpd-datastage-remote-operator
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/arch
                    operator: In
                    values:
                      - amd64
      containers:
        - name: manager
          args:
            - "--zap-log-level"
            - "error"
            - "--max-concurrent-reconciles"
            - "6"
            - "--watches-file"
            - "./px_remote_engine_watches.yaml"
          image: ${OPERATOR_REGISTRY}/ds-operator@${operator_digest}
          imagePullPolicy: IfNotPresent
          livenessProbe:
            httpGet:
              path: /healthz
              port: 6789
            initialDelaySeconds: 15
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: /readyz
              port: 6789
            initialDelaySeconds: 5
            periodSeconds: 10
          securityContext:
            privileged: false
            runAsNonRoot: true
            $runAsUser
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: false
            capabilities:
              drop:
                - ALL
          env:
            - name: WATCH_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: OPERATOR_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            $k8sEnv
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
              ephemeral-storage: 250Mi
            limits:
              cpu: 1
              memory: 512Mi
              ephemeral-storage: 900Mi
      serviceAccount: ibm-cpd-datastage-remote-operator-serviceaccount
      serviceAccountName: ibm-cpd-datastage-remote-operator-serviceaccount
      terminationGracePeriodSeconds: 10
EOF
}

create_pull_secret() {
  if [ -z $password ]; then
    display_missing_arg "password"
  fi
  if [ -z $username ]; then
    display_missing_arg "username"
  fi
	$kubernetesCLI -n ${namespace} delete secret $DS_REGISTRY_SECRET --ignore-not-found=true ${dryRun}
  $kubernetesCLI -n ${namespace} create secret docker-registry $DS_REGISTRY_SECRET --docker-server=${DOCKER_REGISTRY} --docker-username=${username} --docker-password=${password} --docker-email=cpd@us.ibm.com ${dryRun}
}

create_apikey_secret() {
  if [ -z $api_key ]; then
    display_missing_arg "apikey"
  fi
  # name is used for cr name in inputFile
  if [[ ! -z $name ]] && [[ -z $inputFile ]]; then
    DS_API_KEY_SECRET="${name}"
  fi
	$kubernetesCLI -n ${namespace} delete secret $DS_API_KEY_SECRET --ignore-not-found=true ${dryRun}
  $kubernetesCLI -n ${namespace} create secret generic $DS_API_KEY_SECRET --from-literal=api-key=${api_key}
}

remove_previous_resources() {
  $kubernetesCLI -n ${namespace} delete deploy ${name}-ibm-datastage-px-runtime --ignore-not-found=true
  $kubernetesCLI -n ${namespace} delete sts ${name}-ibm-datastage-px-compute --ignore-not-found=true
  $kubernetesCLI -n ${namespace} delete svc ${name}-ibm-datastage-px-runtime --ignore-not-found=true
  $kubernetesCLI -n ${namespace} delete svc ${name}-ibm-datastage-px-compute --ignore-not-found=true
}

get_resource_id() {
  px_cr_uid=`$kubernetesCLI -n ${namespace} get pxremoteengine $name -o=jsonpath='{.metadata.uid}'`
  if [ -z $px_cr_uid ]; then
    echo "Unable to retrieve resource ID for PXRemoteEngine ${name}"
    exit 1
  fi
}

change_ownership() {
  resource_name=$2
  resource_kind=$1
  echo "Changing ownership for ${resource_kind} ${resource_name} to PXRemoteEngine CR"
  $kubernetesCLI -n ${namespace} patch $resource_kind $resource_name -p "{\"metadata\":{\"ownerReferences\":[{\"apiVersion\":\"ds.cpd.ibm.com/v1\", \"kind\":\"PXRemoteEngine\", \"name\":\"${name}\", \"uid\":\"${px_cr_uid}\"}]}}" --type=merge
}

create_instance() {
  if [ -z $name ]; then
    display_missing_arg "name"
  fi
  if [ -z $storage_class ]; then
    display_missing_arg "storageClass"
  fi
  if [ -z $projectId ]; then
    display_missing_arg "project-id"
  fi
  if [ -z $license_accept ] || [ $license_accept != "true" ]; then
    display_missing_arg "license-accept"
  fi
  configure_data_center
  # check if pxruntime with the same name exists
  px_runtime_cr_count=`$kubernetesCLI -n $namespace get pxruntime $name --ignore-not-found=true | wc -l`
  if [ $px_runtime_cr_count -ne 0 ]; then
    remove_previous_resources
    has_previous_pxruntime_cr="true"
  fi
  $kubernetesCLI -n $namespace get pxremoteengine $name
  if [ $? -eq 0 ]; then
    echo "PXRemoteEngine $name already exists; updating its image digests."
    $kubernetesCLI -n $namespace patch pxremoteengine $name -p "{\"spec\":{\"docker_registry_prefix\":\"${DOCKER_REGISTRY_PREFIX}\", \"api_key_secret\":\"${DS_API_KEY_SECRET}\", \"image_digests\":{\"pxcompute\": \"${px_compute_digest}\", \"pxruntime\": \"${px_runtime_digest}\"}}}" --type=merge
  else
    cat <<EOF | $kubernetesCLI apply -f -
apiVersion: ds.cpd.ibm.com/v1
kind: PXRemoteEngine
metadata:
  name: $name
  namespace: $namespace
spec:
  license:
    accept: true
  storageClass: $storage_class
  storageSize: $storage_size
  scaleConfig: $size
  remote_engine: true
  project_id: $projectId
  docker_registry_prefix: $DOCKER_REGISTRY_PREFIX
  api_key_secret: $DS_API_KEY_SECRET
  GATEWAY: $DS_GATEWAY
  image_digests:
    pxcompute: $px_compute_digest
    pxruntime: $px_runtime_digest
EOF
fi
  if [ ! -z $has_previous_pxruntime_cr ]; then
    get_resource_id
    change_ownership secret ${name}-ibm-datastage-enc-secret
    change_ownership pvc ${name}-ibm-datastage-px-storage-pvc
    # remove finalizer and delete previous CR
    echo "Removing PXRuntime CR ${name}"
    $kubernetesCLI -n $namespace patch pxruntime $name -p '{"metadata":{"finalizers":null}}' --type=merge
    $kubernetesCLI -n $namespace delete pxruntime $name
  fi
  echo "To check the status of the PXRemoteEngine instance, run the command below:"
  echo "$kubernetesCLI -n $namespace get pxre ${name}"
}

handle_badusage() {
  echo ""
  echo "Usage: $0 create-pull-secret|create-apikey-secret|install|create-instance|create-nfs-provisioner --help"
  echo ""
  exit 3
}

handle_install_usage() {
  echo ""
  echo "Usage: $0 install --namespace <namespace>"
  echo "--namespace: the namespace to install the DataStage operator"
  exit 0
}

handle_pull_secret_usage() {
  echo ""
  echo "Description: create a docker registry secret used for pulling images"
  echo "Usage: $0 create-pull-secret --namespace <namespace> --username <username> --password <password>"
  echo "--namespace: the namespace to install the DataStage operator"
  echo "--username: the username for the container registry"
  echo "--password: the password for the container registry"
  exit 0
}

handle_apikey_usage() {
  echo ""
  echo "Description: creates a secret with the api key for the remote engine to use when calling DataStage services"
  echo "Usage: $0 create-apikey-secret --namespace <namespace> --apikey <api-key>"
  echo "--namespace: the namespace to create the api-key secret"
  echo "--apikey: the api-key for the remote engine to use when communicating with DataStage services"
  exit 0
}

handle_create_instance_usage() {
  echo ""
  echo "Description: creates an instance of the remote engine; the pull secret and the api-key secret should have been created in the same namespace."
  echo "Usage: $0 create-instance --namespace <namespace> --name <name> --project-id <project-id> --storage-class <storage-class> [--storage-size <storage-size>] [--size <size>] [data-center <data-center>] --license-accept true"
  echo "--namespace: the namespace to create the instance"
  echo "--name: the name of the remote engine"
  echo "--project-id: the project ID to register the remote engine"
  echo "--storageClass: the file storageClass to use"
  echo "--storageSize: the storage size to use (in GB); defaults to 10"
  echo "--size: the size of the instance (small, medium, large); defaults to small"
  echo "--data-center: the data center where your DataStage instance is provisioned on IBM cloud: dallas(default), or frankfurt"
  echo "--license-accept: set the to true to indicate that you have accepted the license for IBM DataStage as a Service Anywhere - https://www.ibm.com/support/customer/csol/terms/?ref=i126-9243-06-11-2023-zz-en"
  echo ""
  exit 0
}

handle_create_nfs_provisioner_usage() {
  echo ""
  echo "Description: create a storage class for provisioning PV from an NFS fileserver"
  echo "Usage: $0 create-nfs-provisioner --namespace <namespace> --server <nfs-server-ip> [--path <path to mount>]"
  echo "--namespace: the namespace to create the provisioner"
  echo "--server: the IP address of the nfs server"
  echo "--path: the path to mount from the nfs server; defaults to '/'."
  exit 0
}

check_jq_installation() {
  which jq
  if [[ $? -ne 0 ]]; then
    echo "The utility `jq` is required. It can be installed via `yum install jq` or `apt-get install jq`."
    exit 1
  fi
}

generate_access_token() {
  apikey="${password}"
  access_token=`$curlCMD -s -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" --data-urlencode "apikey=$apikey" "https://iam.ng.bluemix.net/identity/token" | jq .access_token | cut -d\" -f2`
  if [[ -z $access_token ]]; then
    echo "Unable to retrieve access token".
    # rerun command without silent flag
    $curlCMD -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" --data-urlencode "apikey=$apikey" "https://iam.ng.bluemix.net/identity/token"
    exit 1
  fi
}

# retrieve px image digests from ds-runtime
retrieve_px_image_digests() {
  if [ -z $api_key ]; then
    # retrieve apikey from secret
    api_key=`$kubernetesCLI -n $namespace get secret $DS_API_KEY_SECRET -o=jsonpath="{.data.api-key}" | base64 -d`
  fi
  if [ $DS_GATEWAY = "api.dataplatform.cloud.ibm.com" ]; then
    cloud_access_token=`$curlCMD -s -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" --data-urlencode "apikey=$api_key" "https://iam.cloud.ibm.com/identity/token" | jq .access_token | cut -d\" -f2`
  else 
    cloud_access_token=`$curlCMD -s -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" --data-urlencode "apikey=$api_key" "https://iam.test.cloud.ibm.com/identity/token" | jq .access_token | cut -d\" -f2`
  fi
  if [ -z $cloud_access_token ]; then
    echo "Unable to retrieve access token from IBM Cloud."
    exit 1
  fi
  image_digests=`$curlCMD -s -X GET -H "Authorization: Bearer $cloud_access_token" -H 'accept: application/json;charset=utf-8' https://${DS_GATEWAY}/data_intg/v3/flows_runtime/remote_engine/versions | jq -r '.versions[0].image_digests.px_runtime, .versions[0].image_digests.px_compute'`
  image_digest_array=(${image_digests})
  if [ ${#image_digest_array[@]} -eq 2 ]; then
    px_runtime_digest="${image_digest_array[0]}"
    px_compute_digest="${image_digest_array[1]}"
    echo "Retrieved digest for ds-px-runtime: ${px_runtime_digest}"
    echo "Retrieved digest for ds-px-compute: ${px_compute_digest}"
  fi
}

retrieve_latest() {
  image="$1"
  latest_digest=`$curlCMD -s -X GET -H "accept: application/json" -H "Account: d10b01a616ed4b73a9ac8a052424a345" -H "Authorization: Bearer $access_token" --url "https://icr.io/api/v1/images?includeIBM=false&includePrivate=true&includeManifestLists=true&vulnerabilities=true&repository=${image}" | jq '. |= sort_by(.Created) | .[length -1] | .RepoDigests[0]' | cut -d@ -f2 | tr -d '"'`
  echo "$latest_digest"
}

retrieve_latest_image_digests() {
  check_jq_installation
  if [ $username = "iamapikey" ]; then
    generate_access_token
    retrieved_digest=$(retrieve_latest 'ds-px-runtime')
    if [[ $retrieved_digest = sha256* ]]; then
      px_runtime_digest="${retrieved_digest}"
      echo "Retrieved digest for ds-px-runtime: ${px_runtime_digest}"
    else
      echo "Unable to retrieve latest digest for ds-px-runtime; defaulting to ${px_runtime_digest}."
    fi
    retrieved_digest=$(retrieve_latest 'ds-px-compute')
    if [[ $retrieved_digest = sha256* ]]; then
      px_compute_digest="${retrieved_digest}"
      echo "Retrieved digest for ds-px-compute: ${px_compute_digest}"
    else
      echo "Unable to retrieve latest digest for ds-px-compute; defaulting to ${px_compute_digest}."
    fi
    retrieved_digest=$(retrieve_latest 'ds-operator')
    if [[ $retrieved_digest = sha256* ]]; then
      operator_digest="${retrieved_digest}"
      echo "Retrieved digest for ds-operator: ${operator_digest}"
    else
      echo "Unable to retrieve latest digest for ds-operator; defaulting to ${operator_digest}."
    fi
  else
    # set cpd registry location
    OPERATOR_REGISTRY="icr.io/cpopen"
    DOCKER_REGISTRY_PREFIX="cp.icr.io/cp/cpd"
    retrieve_px_image_digests
  fi 
}

# determine registry from pull secret
determine_registry() {
  $kubernetesCLI -n $namespace get secret $DS_REGISTRY_SECRET > /dev/null
  if [ $? -ne 0 ]; then
    echo "The pull secret for the container registry has not been created."
    exit 1
  fi
  username_secret=`$kubernetesCLI -n $namespace get secret $DS_REGISTRY_SECRET -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq -r '.auths | select(."icr.io") | ."icr.io" | .username'`
  if [ $username_secret = "cp" ]; then
    OPERATOR_REGISTRY="icr.io/cpopen"
    DOCKER_REGISTRY_PREFIX="cp.icr.io/cp/cpd"
    retrieve_api_key
    if [ ! -z $api_key ]; then
      retrieve_px_image_digests
    fi
  elif [ $username_secret = "iamapikey" ]; then
    password_secret=`$kubernetesCLI -n $namespace get secret $DS_REGISTRY_SECRET -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq -r '.auths | select(."icr.io") | ."icr.io" | .password'`
    # set the registry credentials to be the ones from the secret
    if [ ! -z $password_secret ]; then
      password="${password_secret}"
      retrieve_latest_image_digests
    fi
  fi
}

retrieve_api_key() {
  $kubernetesCLI -n $namespace get secret $DS_API_KEY_SECRET > /dev/null
  if [ $? -ne 0 ]; then
    echo "The secret containing the API key IBM Cloud has not been created."
    exit 1
  fi
  api_key=`$kubernetesCLI -n $namespace get secret $DS_API_KEY_SECRET -o jsonpath='{.data.api-key}' | base64 -d`
}

check_namespace() {
  $kubernetesCLI get namespace $namespace > /dev/null
  if [ $? -ne 0 ]; then
    echo "The namespace $namepace does not exist. Please create it and run the command again."
    exit 1
  fi
}

configure_data_center() {
  if [ $data_center = "frankfurt" ]; then
    # eu-de
    DS_GATEWAY="api.eu-de.dataplatform.cloud.ibm.com"
  elif [ $data_center != "dallas" ]; then
    echo "Unknown value for data center '${data_center}'. Please specified either dallas, or frankfurt."
    exit 1
  fi
}

while [ $# -gt 0 ]
do
    case $1 in
        --help)
            dsdisplayHelp="true"
            ;;
        --namespace)
            shift
            namespace="${1}"
            ;;
        --apikey)
            shift
            api_key="${1}"
            ;;
        --username)
            shift
            username="${1}"
            ;;
        --password)
            shift
            password="${1}"
            ;;
        --project-id)
            shift
            projectId="${1}"
            ;;
        --name)
            shift
            name="${1}"
            ;;
        --storageClass|--storage-class)
            shift
            storage_class="${1}"
            ;;
        --storageSize|--storage-size)
            shift
            storage_size="${1}"
            ;;
        --data-center)
            shift
            data_center="${1}"
            ;;
        --size)
           shift
           size="${1}"
           ;;
        --registry)
            shift
            DOCKER_REGISTRY="${1}"
            ;;
        --registry-prefix)
            shift
            DOCKER_REGISTRY_PREFIX="${1}"
            ;;
        --gateway)
            shift
            DS_GATEWAY="${1}"
            ;;
        --server)
            shift
            nfs_server="${1}"
            ;;
        --path)
            shift
            nfs_path="${1}"
            ;;
        --file|-f)
            shift
            inputFile="${1}"
            ;;
        --license-accept)
            shift
            license_accept="${1}"
            ;;
        install)
            action="install"
            ;;
        create-pull-secret)
             action="create-pull-secret"
            ;;
        create-apikey-secret)
            action="create-apikey-secret"
             ;;
        create-instance)
            action="create-instance"
            ;;
        create-nfs-provisioner)
            action="create-nfs-provisioner"
            ;;
        *)
            echo "Unknown parameter '${1}'"
            handle_badusage
            ;;
    esac
    if [ $# -gt 0 ]
    then
        shift
    fi
done

if [[ -z $action ]] && [[ -z $inputFile ]]; then
  handle_badusage
fi

handle_action_install() {
  if [ -z $password ]; then
    # this is from individual install action - check if the pull secret is for datastage repo
    determine_registry


  fi
  echo "Deploying DataStage operator to namespace ${namespace}..."
  create_service_account
  create_role
  create_role_binding
  create_pxruntime_crd
  create_operator_deployment
  echo "DataStage operator deployment created."
}

if [[ ! -z $dsdisplayHelp ]]; then
  case $action in
    install)
      handle_install_usage
      ;;
    create-pull-secret)
      handle_pull_secret_usage
      ;;
    create-apikey-secret)
      handle_apikey_usage
      ;;
    create-instance)
      handle_create_instance_usage
      ;;
    create-nfs-provisioner)
      handle_create_nfs_provisioner_usage
      ;;
    esac
fi

determine_cli
if [ -z $inputFile ]; then
  determine_k8s
  validate_common_args
fi

case $action in
install)
  handle_action_install
  ;;
create-pull-secret)
  create_pull_secret
  ;;
create-apikey-secret)
  create_apikey_secret
  ;;
create-instance)
  determine_registry
  create_instance
  ;;
create-nfs-provisioner)
  create_nfs_provisioner
  ;;
esac

if [ ! -z $inputFile ]; then
  source $inputFile
  set_curl_cmd
  determine_k8s
  validate_common_args
  retrieve_latest_image_digests
	if [[ ! -z $nfs_server ]]; then
    create_nfs_provisioner
  fi
  create_pull_secret
  create_apikey_secret
  handle_action_install
  create_instance
fi
