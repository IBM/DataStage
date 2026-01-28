#!/usr/bin/env bash
# (C) Copyright IBM Corp. 2023  All Rights Reserved.
#
# This script is a utility to install DataStage Remote Engine

# tool version
TOOL_VERSION=1.0.14
TOOL_NAME='IBM DataStage Remote Engine'

kubernetesCLI="oc"
scriptName=$(basename "$0")
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
filesDir="${scriptDir}/files"
CURL_CMD="curl"
remote_controlplane_env="cloud"
additional_users=""
wlmScalingParam=""
podExecPerms="- pods/exec"

serviceAccountFile="${filesDir}/datastage-sa.yaml"
roleFile="${filesDir}/datastage-role.yaml"
roleBindingFile="${filesDir}/datastage-rolebinding.yaml"
pxruntimeCRDFile="${filesDir}/ds.cpd.ibm.com_pxruntimes.yaml"
deploymentFile="${filesDir}/manager.yaml"

nfsProvisionerFile="${filesDir}/efs-provisioner.yaml"
nfsStorageClassFile="${filesDir}/efs-storageclass.yaml"
nfs_path="/"

DOCKER_REGISTRY="icr.io"
OPERATOR_REGISTRY_SUFFIX="cpopen"
DOCKER_REGISTRY_SUFFIX="cp/cpd"
DS_REGISTRY_SECRET="datastage-pull-secret"
DS_API_KEY_SECRET="datastage-api-key-secret"
DS_PROXY_URL="datastage-proxy-url"
DS_GATEWAY="api.dataplatform.cloud.ibm.com"
IAM_URL="https://iam.cloud.ibm.com"
data_center="dallas"

operator_digest="sha256:1d0f615945b7784d187501c5eb74e4a63f07d0abedce1be43b48c5e646a54973"

supported_versions="5.1.0 5.1.1 5.1.2 5.1.3 5.2.0 5.2.1 5.2.2 5.3.0"
asset_versions="510 511 512 513 520 521 522 530"
operator_digests="sha256:4d4e0e4355f2e24522880fd3a5ce2b0300096586d929a9d762b011dcfbdbec84 sha256:315de39c1ce4e72b8af224a676da8c73f3118c455ab427b412edb22da795ae00 sha256:47bbb1b75e59e05e025134c8dd52adc6276050213b0a9deb51067aecb2f6056c sha256:f57d3d5b20521d546a0a9b6af839cc659c1f08357d5d06da93aacf1ad5ee08e4 sha256:2d753908d9581d10e66e087f809fe7c212dc73cbffc60bc6728b7b28b6ff9c57 sha256:2809185dd56232f2956eea571833df8858530c961bba919a967e83c9c3c24877 sha256:95f150a03ee72d4cf3df5db14d398297787451afed69d1f565498a09e5e6d05d sha256:1d0f615945b7784d187501c5eb74e4a63f07d0abedce1be43b48c5e646a54973"
px_runtime_digests="sha256:e9c63c0334620ac72bc3a7343a6e4e8184a2e48ca2cd1f54f06734fddedc0949 sha256:3000c8a98cef44be354cad92ea7790d075f3fed7b7cde69c9d59f1d52f25499a sha256:9e9b1562eee6d09969d6e967f0698f2320c0f75aad9b75643d4818d3596c7f7b sha256:d429306e12a74f34f8a86e0800be346abaff509d4aaf0e9fcefafcaf6ef36769 sha256:6e394510b8dddcb3e0858cf344955e411478927dc3ee35997d69d21bfd06f9d9 sha256:3abc437a0df489b2eb31d078676a3fe6bdd942e0d84b011479a8a0ceba8e02e0 sha256:d0d5b526f3e56539389a17f7f851bb7947332dc849728fa36eef099c1db50ae3 sha256:a9562467423d541c88c87fd509fbe929439be2633b64660eae578363e30e536e"
px_compute_digests="sha256:266730b6769f585a6c943f3db5ad9174c058e6d00704f2c8a7b0f76cef1de29b sha256:eb9979137e0c724b0087246757666c662e1d430c5590a1a9e674f887be62f699 sha256:daf937b4d46f950b30f5c8d27f3f5b2d61703a8c403869befbdd62c47dd27a3d sha256:9c291405cf498cd88587ce5ae37cf0967718d17e8a7b4b7ea19796d3c5676c09 sha256:52754f8689e31100cd088163c7d1f7c1aa29863c6acbb3f2a41f6d141050ce1a sha256:391396d4d9bd48157eb29c1deb18746bf9be56321c94a99fdd35f8e4a3e6147d sha256:adafd046967c0beda9355f3aadd87d79aa464116c90fe12291fee4d9435a96f2 sha256:686a2fa095f4fb216136608b71732c76a237fd9b4c52091e54117425edd4d80e"

# default username for icr.io when using apikey
username="iamapikey"
service_id="iamapikey"

storage_size="10"
size="small"

bold=$(tput bold)
normal=$(tput sgr0)

print_header() {
    echo ""
    echo "${bold}$1${normal}"
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
      echo_error_and_exit "Unable to locate oc nor kubectl cli in execution path."
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
  echo_error_and_exit "Missing required parameter - ${1}"
}

echo_error_and_exit() {
    echo "ERROR: ${1}"
    exit 1
}

echo_warn()
{
  echo "WARNING: ${1}"
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

  $kubernetesCLI -n $namespace get secret $DS_REGISTRY_SECRET > /dev/null
  if [ $? -ne 0 ]; then
    echo "WARNING: Creating service account without container registry pull secret. Falling back on global pull secret."
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
EOF
  else
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
  fi
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
  $podExecPerms
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
  - poddisruptionbudgets
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
  $kubernetesCLI -n ${namespace} delete secret $DS_REGISTRY_SECRET --ignore-not-found=true ${dryRun}
  if [ -z $password ] && [ -z $username ] && [ ! -z $zen_url ]; then
    echo_warn "Username and Password not specified for the container registry. Install will rely on global pull secrets to retrieve the images for CP4D."
  else
    if [ -z $password ]; then
      display_missing_arg "password"
    fi
    if [ -z $username ]; then
      display_missing_arg "username"
    fi
    if [[ ! -z ${CUSTOM_DOCKER_REGISTRY} ]]; then
      DOCKER_REGISTRY="${CUSTOM_DOCKER_REGISTRY}"
    fi
    $kubernetesCLI -n ${namespace} create secret docker-registry $DS_REGISTRY_SECRET --docker-server=${DOCKER_REGISTRY} --docker-username=${username} --docker-password=${password} --docker-email=cpd@us.ibm.com ${dryRun}
  fi
}

create_apikey_secret() {
  # name is used for cr name in inputFile
  if [[ ! -z $name ]] && [[ -z $inputFile ]]; then
    DS_API_KEY_SECRET="${name}"
  fi
  $kubernetesCLI -n ${namespace} delete secret $DS_API_KEY_SECRET --ignore-not-found=true ${dryRun}
  if [ -z $api_key ]; then
    display_missing_arg "apikey"
  fi
  if [ -z $service_id ]; then
    display_missing_arg "serviceid"
  fi
  $kubernetesCLI -n ${namespace} create secret generic $DS_API_KEY_SECRET --from-literal=api-key=${api_key} --from-literal=service-id=${service_id} --from-literal=mcsp-account-id=${MCSP_ACCOUNT_ID}
}

create_proxy_secrets() {
  $kubernetesCLI -n ${namespace} delete secret $DS_PROXY_URL --ignore-not-found=true ${dryRun}
  $kubernetesCLI -n ${namespace} delete secret connection-ca-certs --ignore-not-found=true ${dryRun}
  if [ ! -z $proxy_url ]; then
    CURL_CMD="curl --proxy ${proxy_url}"
    $kubernetesCLI -n ${namespace} create secret generic $DS_PROXY_URL --from-literal=proxy_url=${proxy_url}
    if [ ! -z $cacert_location ]; then
      if [ -f $cacert_location ]; then
        CURL_CMD="${CURL_CMD} --proxy-insecure"
        $kubernetesCLI -n ${namespace} create secret generic connection-ca-certs --from-file=${cacert_location}
      else
        echo_error_and_exit "The specified proxy certificate $cacert_location is not found."
      fi
    fi
  elif [ ! -z $cacert_location ]; then
    echo_error_and_exit "The option --proxy-cacert is only supported when --proxy is specified."
  fi
}

create_krb5_configmaps() {
  $kubernetesCLI -n ${namespace} delete configmap krb5-config-files --ignore-not-found=true ${dryRun}
  $kubernetesCLI -n ${namespace} delete configmap krb5-config-dir --ignore-not-found=true ${dryRun}
  if [[ ! -z $KRB5_CONF_FILE ]]; then
    if [[ -f $KRB5_CONF_FILE ]]; then
      $kubernetesCLI -n ${namespace} create configmap krb5-config-files --from-file=${KRB5_CONF_FILE}
      if [[ ! -z $KRB5_CONF_DIR ]]; then
        if [[ -d $KRB5_CONF_DIR ]]; then
          $kubernetesCLI -n ${namespace} create configmap krb5-config-dir --from-file=${KRB5_CONF_DIR}
        else
          echo_error_and_exit "The specified Kerberos config directory $KRB5_CONF_DIR is not found."
        fi
      fi
    else
      echo_error_and_exit "The specified Kerberos config file $KRB5_CONF_FILE is not found."
    fi
  elif [[ ! -z $KRB5_CONF_DIR ]]; then
    echo_error_and_exit "The option --krb5-conf-dir is only supported when --krb5-conf is specified."
  fi
}

create_db2z_license_secret() {
  $kubernetesCLI -n ${namespace} delete secret datastage-db2z-license --ignore-not-found=true ${dryRun}
  if [ ! -z $DB2Z_LICENSE ]; then
    if [ -f $DB2Z_LICENSE ]; then
      $kubernetesCLI -n ${namespace} create secret generic datastage-db2z-license --from-file=db2consv_ee.lic=${DB2Z_LICENSE}
      $kubernetesCLI -n ${namespace} delete pod -l app.kubernetes.io/component=px-runtime
    else
      echo_error_and_exit "The specified DB2Z license $DB2Z_LICENSE is not found."
    fi
  fi
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
    echo_error_and_exit "Unable to retrieve resource ID for PXRemoteEngine ${name}"
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
  # px_runtime_cr_count=`$kubernetesCLI -n $namespace get pxruntime $name --ignore-not-found=true | wc -l`
  # if [ $px_runtime_cr_count -ne 0 ]; then
  #   remove_previous_resources
  #   has_previous_pxruntime_cr="true"
  # fi
  $kubernetesCLI -n $namespace get pxremoteengine $name
  if [ $? -eq 0 ]; then
    echo "PXRemoteEngine $name already exists; updating its image digests."
    $kubernetesCLI -n $namespace patch pxremoteengine $name -p "{\"spec\":{\"docker_registry_prefix\":\"${DOCKER_REGISTRY_PREFIX}\", \"api_key_secret\":\"${DS_API_KEY_SECRET}\", \"project_id\": \"${projectId}\", \"remote_controlplane_env\":\"${remote_controlplane_env}\", \"image_digests\":{\"pxcompute\": \"${px_compute_digest}\", \"pxruntime\": \"${px_runtime_digest}\"}, \"additional_users\":\"${additional_users}\"}}" --type=merge
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
  project_id: [$projectId]
  $wlmScalingParam
  docker_registry_prefix: $DOCKER_REGISTRY_PREFIX
  api_key_secret: $DS_API_KEY_SECRET
  remote_controlplane_env: $remote_controlplane_env
  additional_users: $additional_users
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
  echo "Usage: $0 create-pull-secret|create-proxy-secrets|create-krb5-configmaps|create-apikey-secret|install|create-instance|create-nfs-provisioner --help"
  echo ""
  exit 3
}

handle_install_usage() {
  echo ""
  echo "Usage: $0 install --namespace <namespace> [--data-center <data-center>] [--registry <docker-registry>] [--operator-registry-suffix <operator-suffix>] [--docker-registry-suffix <docker-suffix>] [--digests <ds-operator-digest>,<ds-px-runtime-digest>,<ds-px-compute-digest>] [--disable-wlm-scaling <true/false>] [--zen-url <zen-url>]"
  echo "--namespace: the namespace to install the DataStage operator"
  echo "--data-center: the data center where your DataStage instance is provisioned on IBM cloud (ignored for cp4d): dallas(default), frankfurt, sydney, toronto, london, or awsprod"
  echo "--registry: Custom container registry to pull images from if you are image mirroring using a private registry. If using this option, you must set --digests as well for IBM Cloud."
  echo "--operator-registry-suffix: Custom operator registry suffix to use for the remote engine to pull ds-operator images from if using a custom container registry. Defaults to 'cpopen'."
  echo "--docker-registry-suffix: Custom docker registry suffix to use for the remote engine to pull ds-px-runtime and ds-px-compute images from if using a custom container registry. Defaults to 'cp/cpd'."
  echo "--digests: Custom digests to use for the remote engine. This option must be set if using a custom registry for IBM Cloud."
  echo "--disable-wlm-scaling: [true/false] Disables WLM scaling and removes pod/exec permissions. Defaults to 'false'."
  echo "--zen-url: CP4D zen url. Specifying this will switch flow to cp4d. (required for cp4d)"
  exit 0
}

handle_pull_secret_usage() {
  echo ""
  echo "Description: create a docker registry secret used for pulling images"
  echo "Usage: $0 create-pull-secret --namespace <namespace> --username <username> --password <password> [--registry <docker-registry>] [--zen-url <zen-url>]"
  echo "--namespace: the namespace to install the DataStage operator"
  echo "--username: the username for the container registry"
  echo "--password: the password for the container registry"
  echo "--registry: Custom container registry to pull images from"
  echo "--zen-url: CP4D zen url. Specifying this will switch flow to cp4d. (required for cp4d)"
  exit 0
}

handle_proxy_usage() {
  echo ""
  echo "Description: create a secret used for proxy urls and cacerts"
  echo "Usage: $0 create-proxy-secrets --namespace <namespace> --proxy <proxy_url> [--proxy-cacert <cacert_location>] [--zen-url <zen-url>]"
  echo "--namespace: the namespace to install the DataStage operator"
  echo "--proxy: Specify the proxy url (eg. http://<username>:<password>@<proxy_ip>:<port>)"
  echo "--proxy-cacert: Specify the absolute location of the custom CA store for the specified proxy - if it is using a self signed certificate"
  echo "--zen-url: CP4D zen url. Specifying this will switch flow to cp4d. (required for cp4d)"
  exit 0
}

handle_krb5_usage() {
  echo ""
  echo "Description: create configmaps used for Kerberos authentication"
  echo "Usage: $0 create-krb5-configmaps --namespace <namespace> --krb5-conf <krb5_conf_location> [--krb5-conf-dir <krb5_config_dir_location>]"
  echo "--namespace: the namespace to install the DataStage operator"
  echo "--krb5-conf: Specify the location of the Kerberos config file if using Kerberos Authentication."
  echo "--krb5-conf-dir: Specify the directory of multiple Kerberos config files if using Kerberos Authentication. (Only supported with --krb5-conf, the krb5.conf file needs to include 'includedir /etc/krb5-config-files/krb5-config-dir' line)"
  exit 0
}

handle_import_db2z_license_usage() {
  echo ""
  echo "Description: create secret to import DB2Z license"
  echo "Usage: $0 create-db2z-license-secret --namespace <namespace> --import-db2z-license <db2z_license_location>"
  echo "--namespace: the namespace to install the DataStage operator"
  echo "--import-db2z-license: Specify the location of the DB2Z license to import"
  exit 0
}

handle_apikey_usage() {
  echo ""
  echo "Description: creates a secret with the api key for the remote engine to use when calling DataStage services"
  echo "Usage: $0 create-apikey-secret --namespace <namespace> --apikey <api-key> [--serviceid <service-id>] [--mcsp-account-id <mcsp-account-id>] [--zen-url <zen-url>]"
  echo "--namespace: the namespace to create the api-key secret"
  echo "--apikey: the api-key for the remote engine to use when communicating with DataStage services"
  echo "--serviceid: the username to use with the apikey"
  echo "--mcsp-account-id: The account ID of the AWS governing owner account (required for awsprod)."
  echo "--zen-url: CP4D zen url. Specifying this will switch flow to cp4d. (required for cp4d)"
  exit 0
}

handle_create_instance_usage() {
  echo ""
  echo "Description: creates an instance of the remote engine; the pull secret and the api-key secret should have been created in the same namespace."
  echo "Usage: $0 create-instance --namespace <namespace> --name <name> --project-id <project-id1,project-id2,project-id3,...> --storage-class <storage-class> [--storage-size <storage-size>] [--size <size>] [--data-center <data-center>] [--registry <docker-registry>] [--operator-registry-suffix <operator-suffix>] [--docker-registry-suffix <docker-suffix>] [--digests <ds-operator-digest>,<ds-px-runtime-digest>,<ds-px-compute-digest>] [--disable-wlm-scaling <true/false>] [--zen-url <zen-url>] --license-accept true"
  echo "--namespace: the namespace to create the instance"
  echo "--name: the name of the remote engine"
  echo "--project-id: the comma separated list of project IDs to register the remote engine"
  echo "--storageClass: the file storageClass to use"
  echo "--storageSize: the storage size to use (in GB); defaults to 10"
  echo "--size: the size of the instance (small, medium, large); defaults to small"
  echo "--data-center: the data center where your DataStage instance is provisioned on IBM cloud (ignored for cp4d): dallas(default), frankfurt, sydney, toronto, london, or awsprod"
  echo "--license-accept: set the to true to indicate that you have accepted the license for IBM DataStage as a Service Anywhere - https://www.ibm.com/support/customer/csol/terms/?ref=i126-9243-06-11-2023-zz-en"
  echo "--additional-users: comma separated list of ids (IAM IDs for cloud, check https://cloud.ibm.com/docs/account?topic=account-identity-overview for details; uids/usernames for cp4d) that can also control remote engine besides the owner"
  echo "--registry: Custom container registry to pull images from if you are image mirroring using a private registry. If using this option, you must set --digests as well for IBM Cloud."
  echo "--operator-registry-suffix: Custom operator registry suffix to use for the remote engine to pull ds-operator images from if using a custom container registry. Defaults to 'cpopen'."
  echo "--docker-registry-suffix: Custom docker registry suffix to use for the remote engine to pull ds-px-runtime and ds-px-compute images from if using a custom container registry. Defaults to 'cp/cpd'."
  echo "--digests: Custom digests to use for the remote engine. This option must be set if using a custom registry for IBM Cloud."
  echo "--disable-wlm-scaling: [true/false] Disables WLM scaling and removes pod/exec permissions. Defaults to 'false'."
  echo "--zen-url: CP4D zen url. Specifying this will switch flow to cp4d. (required for cp4d)"
  echo ""
  exit 0
}

handle_create_nfs_provisioner_usage() {
  echo ""
  echo "Description: create a storage class for provisioning PV from an NFS fileserver"
  echo "Usage: $0 create-nfs-provisioner --namespace <namespace> --server <nfs-server-ip> [--path <path to mount>] [--storage-class <storage-class>]"
  echo "--namespace: the namespace to create the provisioner"
  echo "--server: the IP address of the nfs server"
  echo "--path: the path to mount from the nfs server; defaults to '/'."
  echo "--storageClass: the file storageClass to use; defaults to 'nfs-client'."
  exit 0
}

check_jq_installation() {
  which jq
  if [[ $? -ne 0 ]]; then
    echo_error_and_exit "The utility `jq` is required. It can be installed via `yum install jq` or `apt-get install jq`."
  fi
}

generate_access_token() {
  apikey="${password}"
  access_token=`$CURL_CMD -s -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" --data-urlencode "apikey=$apikey" "https://iam.ng.bluemix.net/identity/token" | jq .access_token | cut -d\" -f2`
  if [[ $? -ne 0 ]] || [[ -z $access_token ]] || [[ "$access_token" == "null" ]]; then
    # rerun command without silent flag
    $CURL_CMD -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" --data-urlencode "apikey=$apikey" "https://iam.ng.bluemix.net/identity/token"
    echo_error_and_exit "Unable to retrieve access token."
  fi
}

# retrieve px image digests from ds-runtime for cp4d
retrieve_px_image_digests_for_cp4d() {
  echo "Getting PX Version from CP4D API"
  if [[ -z ${CUSTOM_DOCKER_REGISTRY} ]] && [[ "$DOCKER_REGISTRY" == "icr.io" ]]; then
    # set cpd registry location
    OPERATOR_REGISTRY="icr.io/cpopen"
    DOCKER_REGISTRY_PREFIX="cp.icr.io/cp/cpd"
  else
    # for testing with dev images
    if [[ "$DOCKER_REGISTRY" == "docker-na-public.artifactory.swg-devops.com" ]]; then
      OPERATOR_REGISTRY="${DOCKER_REGISTRY}/wcp-datastage-team-docker-local"
      DOCKER_REGISTRY_PREFIX="${DOCKER_REGISTRY}/wcp-datastage-team-docker-local/ubi"
    elif [[ "$DOCKER_REGISTRY" == "cp.stg.icr.io" ]]; then
      OPERATOR_REGISTRY="${DOCKER_REGISTRY}/cp"
      DOCKER_REGISTRY_PREFIX="${DOCKER_REGISTRY}/cp/cpd"
    else
      # assume that it's a custom docker registry image mirroring
      OPERATOR_REGISTRY="${DOCKER_REGISTRY}/${OPERATOR_REGISTRY_SUFFIX}"
      DOCKER_REGISTRY_PREFIX="${DOCKER_REGISTRY}/${DOCKER_REGISTRY_SUFFIX}"
      echo "Using custom docker registry for CP4D."
    fi
  fi
  echo "DOCKER_REGISTRY=${DOCKER_REGISTRY}"
  echo "OPERATOR_REGISTRY=${OPERATOR_REGISTRY}"
  echo "DOCKER_REGISTRY_PREFIX=${DOCKER_REGISTRY_PREFIX}"
  if [[ -v USE_DIGESTS ]]; then
    set_remote_engine_digests
  else
    check_version_for_cp4d
  fi


  # if [ -z $api_key ]; then
  #   # retrieve apikey from secret
  #   api_key=$($kubernetesCLI -n $namespace get secret $DS_API_KEY_SECRET -o=jsonpath="{.data.api-key}" | base64 -d)
  # fi
  # if [ -z $service_id ]; then
  #   # retrieve service id from secret
  #   service_id=$($kubernetesCLI -n $namespace get secret $DS_API_KEY_SECRET -o=jsonpath="{.data.service-id}" | base64 -d)
  # fi
  # [ -z $api_key ] && echo_error_and_exit "Please specify CP4D api-key (--apikey) for cp4d environment. Aborting."
  # [ -z $service_id ] && echo_error_and_exit "Please specify service id username (--serviceid) for cp4d environment. Aborting."
  # access_token=`$CURL_CMD -s -X POST --header "cache-control: no-cache" --header "Content-type: application/json" -d "{\"userName\":\"$service_id\",\"api_key\":\"$api_key\"}" "https://${DS_GATEWAY}/icp4d-api/v1/authorize" | jq .token | cut -d\" -f2`
  # image_digests=$($CURL_CMD -s -X GET -H "Authorization: Bearer $access_token" -H 'accept: application/json;charset=utf-8' https://${DS_GATEWAY}/data_intg/v3/flows_runtime/remote_engine/versions | jq -r '.versions[0].image_digests.px_runtime, .versions[0].image_digests.px_compute')
  # image_digest_array=(${image_digests})
  # if [ ${#image_digest_array[@]} -eq 2 ]; then
  #   px_runtime_digest="${image_digest_array[0]}"
  #   px_compute_digest="${image_digest_array[1]}"
  #   echo "Retrieved digest for ds-px-runtime: ${px_runtime_digest}"
  #   echo "Retrieved digest for ds-px-compute: ${px_compute_digest}"
  # fi
}

# retrieve asset version from cp4d to determine which digests to use
check_version_for_cp4d() {
  asset_version=$($CURL_CMD -s "https://${DS_GATEWAY}/data_intg/v3/assets/version")
  parsed_version=$(echo "${asset_version}" | jq .version)

  versionsArray=(${supported_versions})
  assetVersionsArray=(${asset_versions})
  operatorArray=(${operator_digests})
  pxruntimeArray=(${px_runtime_digests})
  pxcomputeArray=(${px_compute_digests})

  if [ ${#versionsArray[@]} -ne ${#assetVersionsArray[@]} ]; then
    echo_error_and_exit "Mismatch size for '${supportedVersions}' and '${assetVersions}'"
  fi
  arraylength=${#versionsArray[@]}

  for (( i=0; i<${arraylength}; i++ ));
  do
    assetVersion="${assetVersionsArray[$i]}\.[0-9]+\.[0-9]+"
    echo "${asset_version}" | grep -E "${assetVersion}" &> /dev/null
    if [[ $? -eq 0 ]]; then
      version="${versionsArray[$i]}"
      operator_digest="${operatorArray[$i]}"
      px_runtime_digest="${pxruntimeArray[$i]}"
      px_compute_digest="${pxcomputeArray[$i]}"
      echo "Version determined from control plane: $version"
      echo "Retrieved ds-operator digest: $operator_digest"
      echo "Retrieved ds-px-runtime digest: $px_runtime_digest"
      echo "Retrieved ds-px-compute digest: $px_compute_digest"
      break;
    fi
  done
  [ -z $px_runtime_digest ] && echo_error_and_exit "Failed to retrieve ds-operator, ds-px-runtime, and ds-px-compute digests. Asset version ${parsed_version} not supported for CP4D remote engine. Supported asset versions are [${asset_versions}]. Aborting."
}

# retrieve px image digests from ds-runtime
retrieve_px_image_digests() {
  echo "Getting Cloud access token to access available image digests."
  if [ -z $api_key ]; then
    # retrieve apikey from secret
    api_key=`$kubernetesCLI -n $namespace get secret $DS_API_KEY_SECRET -o=jsonpath="{.data.api-key}" | base64 -d`
  fi
  if [[ "${data_center}" == 'aws'* ]]; then
    if [ -z $MCSP_ACCOUNT_ID ]; then
      # retrieve mcsp-account-id from secret
      MCSP_ACCOUNT_ID=`$kubernetesCLI -n $namespace get secret $DS_API_KEY_SECRET -o=jsonpath="{.data.mcsp-account-id}" | base64 -d`
    fi
    [ -z $MCSP_ACCOUNT_ID ] && display_missing_arg "mcsp-account-id"
    cloud_access_token=`$CURL_CMD -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Mcsp-ApiKey: $api_key" "${IAM_URL}/api/2.0/accounts/${MCSP_ACCOUNT_ID}/apikeys/token" | jq .token | cut -d\" -f2`
  else
    cloud_access_token=`$CURL_CMD -s -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" --data-urlencode "apikey=$api_key" "${IAM_URL}/identity/token" | jq .access_token | cut -d\" -f2`
  fi
  if [ -z $cloud_access_token ]; then
    echo_error_and_exit "Unable to retrieve access token from IBM Cloud."
  fi
  image_digests=`$CURL_CMD -s -X GET -H "Authorization: Bearer $cloud_access_token" -H 'accept: application/json;charset=utf-8' https://${DS_GATEWAY}/data_intg/v3/flows_runtime/remote_engine/versions | jq -r '.versions[0].image_digests.px_runtime, .versions[0].image_digests.px_compute'`
  image_digest_array=(${image_digests})
  if [ ${#image_digest_array[@]} -eq 2 ]; then
    px_runtime_digest="${image_digest_array[0]}"
    px_compute_digest="${image_digest_array[1]}"
    echo "Retrieved digest for ds-px-runtime: ${px_runtime_digest}"
    echo "Retrieved digest for ds-px-compute: ${px_compute_digest}"
  fi
  [ -z $px_runtime_digest ] && echo_error_and_exit "Failed to retrieve ds-px-runtime digest. Aborting."
  [ -z $px_compute_digest ] && echo_error_and_exit "Failed to retrieve ds-px-compute digest. Aborting."
}

retrieve_latest() {
  image="$1"
  latest_digest=`$CURL_CMD -s -X GET -H "accept: application/json" -H "Account: d10b01a616ed4b73a9ac8a052424a345" -H "Authorization: Bearer $access_token" --url "https://icr.io/api/v1/images?includeIBM=false&includePrivate=true&includeManifestLists=true&vulnerabilities=true&repository=${image}" | jq '. |= sort_by(.Created) | .[length -1] | .RepoDigests[0]' | cut -d@ -f2 | tr -d '"'`
  if [[ $? -ne 0 ]] || [[ -z $latest_digest ]] || [[ "$latest_digest" == "null" ]]; then
    # rerun command without silent flag
    $CURL_CMD -X GET -H "accept: application/json" -H "Account: d10b01a616ed4b73a9ac8a052424a345" -H "Authorization: Bearer $access_token" --url "https://icr.io/api/v1/images?includeIBM=false&includePrivate=true&includeManifestLists=true&vulnerabilities=true&repository=${image}"
    echo_error_and_exit "Failed to retrieve the latest digest for ${image}. Aborting after error output."
  fi
  echo "$latest_digest"
}

retrieve_latest_image_digests() {
  check_jq_installation
  if [[ -z ${CUSTOM_DOCKER_REGISTRY} ]] && [[ "${DOCKER_REGISTRY}" == "icr.io" ]] && [[ "$username" == "iamapikey" ]]; then
    OPERATOR_REGISTRY="icr.io/datastage"
    DOCKER_REGISTRY_PREFIX="icr.io/datastage"
    echo "DOCKER_REGISTRY=${DOCKER_REGISTRY}"
    echo "OPERATOR_REGISTRY=${OPERATOR_REGISTRY}"
    echo "DOCKER_REGISTRY_PREFIX=${DOCKER_REGISTRY_PREFIX}"
    if [[ -v USE_DIGESTS ]]; then
      set_remote_engine_digests
    else
      generate_access_token
      echo "Retrieving latest digest for ds-operator."
      retrieved_digest=$(retrieve_latest 'ds-operator')
      if [[ $retrieved_digest = sha256* ]]; then
        operator_digest="${retrieved_digest}"
        echo "Retrieved digest for ds-operator: ${operator_digest}"
      else
        echo_error_and_exit "Unable to retrieve latest digest for ds-operator. Aborting."
      fi
      echo "Retrieving latest digest for ds-px-runtime."
      retrieved_digest=$(retrieve_latest 'ds-px-runtime')
      if [[ $retrieved_digest = sha256* ]]; then
        px_runtime_digest="${retrieved_digest}"
        echo "Retrieved digest for ds-px-runtime: ${px_runtime_digest}"
      else
        echo_error_and_exit "Unable to retrieve latest digest for ds-px-runtime. Aborting."
      fi
      echo "Retrieving latest digest for ds-px-compute."
      retrieved_digest=$(retrieve_latest 'ds-px-compute')
      if [[ $retrieved_digest = sha256* ]]; then
        px_compute_digest="${retrieved_digest}"
        echo "Retrieved digest for ds-px-compute: ${px_compute_digest}"
      else
        echo_error_and_exit "Unable to retrieve latest digest for ds-px-compute. Aborting."
      fi
    fi
  elif [[ -z ${CUSTOM_DOCKER_REGISTRY} ]] && [[ "${DOCKER_REGISTRY}" == "icr.io" ]]; then
    # set cpd registry location
    OPERATOR_REGISTRY="icr.io/cpopen"
    DOCKER_REGISTRY_PREFIX="cp.icr.io/cp/cpd"
    echo "DOCKER_REGISTRY=${DOCKER_REGISTRY}"
    echo "OPERATOR_REGISTRY=${OPERATOR_REGISTRY}"
    echo "DOCKER_REGISTRY_PREFIX=${DOCKER_REGISTRY_PREFIX}"
    if [[ -v USE_DIGESTS ]]; then
      set_remote_engine_digests
    else
      retrieve_px_image_digests
    fi
  else
    # assume that it's a custom docker registry image mirroring
    OPERATOR_REGISTRY="${DOCKER_REGISTRY}/${OPERATOR_REGISTRY_SUFFIX}"
    DOCKER_REGISTRY_PREFIX="${DOCKER_REGISTRY}/${DOCKER_REGISTRY_SUFFIX}"
    echo "Using custom docker registry for IBM Cloud."
    echo "DOCKER_REGISTRY=${DOCKER_REGISTRY}"
    echo "OPERATOR_REGISTRY=${OPERATOR_REGISTRY}"
    echo "DOCKER_REGISTRY_PREFIX=${DOCKER_REGISTRY_PREFIX}"
    if [[ -v USE_DIGESTS ]]; then
      set_remote_engine_digests
    else
      echo_error_and_exit "Must use --digests to set the digests for ds-operator, ds-px-runtime, and ds-px-compute to use with custom registry for IBM Cloud."
    fi
  fi
}

# determine registry from pull secret
determine_registry() {
# TODO - select version is not yet supported on cp4d as we do not have a versioning strategy
  configure_data_center
  if [[ ! -z ${CUSTOM_DOCKER_REGISTRY} ]]; then
    DOCKER_REGISTRY="${CUSTOM_DOCKER_REGISTRY}"
  fi
  if [[ "$remote_controlplane_env" == "icp4d" ]]; then
    retrieve_px_image_digests_for_cp4d
  else
    $kubernetesCLI -n $namespace get secret $DS_REGISTRY_SECRET > /dev/null
    if [ $? -ne 0 ]; then
      echo_error_and_exit "The pull secret for the container registry has not been created."
    fi
    username_secret=`$kubernetesCLI -n $namespace get secret $DS_REGISTRY_SECRET -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq -r '.auths | select(."'${DOCKER_REGISTRY}'") | ."'${DOCKER_REGISTRY}'" | .username'`
    if [[ -z ${CUSTOM_DOCKER_REGISTRY} ]] && [[ "${DOCKER_REGISTRY}" == "icr.io" ]] && [[ "$username_secret" == "cp" ]]; then
      OPERATOR_REGISTRY="icr.io/cpopen"
      DOCKER_REGISTRY_PREFIX="cp.icr.io/cp/cpd"
      echo "DOCKER_REGISTRY=${DOCKER_REGISTRY}"
      echo "OPERATOR_REGISTRY=${OPERATOR_REGISTRY}"
      echo "DOCKER_REGISTRY_PREFIX=${DOCKER_REGISTRY_PREFIX}"
      if [[ -v USE_DIGESTS ]]; then
        set_remote_engine_digests
      else
        retrieve_api_key
        if [ ! -z $api_key ]; then
          retrieve_px_image_digests
        else
          echo_error_and_exit "Failed to retrieve apikey from secret. Aborting."
        fi
      fi
    else
      password_secret=`$kubernetesCLI -n $namespace get secret $DS_REGISTRY_SECRET -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq -r '.auths | select(."'${DOCKER_REGISTRY}'") | ."'${DOCKER_REGISTRY}'" | .password'`
      # set the registry credentials to be the ones from the secret
      if [ ! -z $password_secret ]; then
        username="${username_secret}"
        password="${password_secret}"
        retrieve_latest_image_digests
      else
        echo_error_and_exit "Failed to retrieve password from secret. Aborting."
      fi
    fi
  fi
}

set_remote_engine_digests() {
  echo "Setting custom remote engine digests."
  IFS="," read -ra DIGEST_LIST <<< "${USE_DIGESTS}"
  if [[ ${#DIGEST_LIST[@]} != 3 ]]; then
    echo_error_and_exit "Please specify the digests to use; one each for ds-operator, ds-px-runtime, and ds-px-compute. ${#DIGEST_LIST[@]} disgest specified; 3 expected."
  fi
  if [[ "${DIGEST_LIST[0]}" = sha256* ]]; then
    operator_digest="${DIGEST_LIST[0]}"
    echo "Using custom digest for ds-operator: ${operator_digest}"
  else
    echo_error_and_exit "Custom ds-operator digest is not in proper sha256 format."
  fi
  if [[ "${DIGEST_LIST[1]}" = sha256* ]]; then
    px_runtime_digest="${DIGEST_LIST[1]}"
    echo "Using custom digest for ds-px-runtime: ${px_runtime_digest}"
  else
    echo_error_and_exit "Custom ds-px-runtime digest is not in proper sha256 format."
  fi
  if [[ "${DIGEST_LIST[2]}" = sha256* ]]; then
    px_compute_digest="${DIGEST_LIST[2]}"
    echo "Using custom digest for ds-px-compute: ${px_compute_digest}"
  else
    echo_error_and_exit "Custom ds-px-compute digest is not in proper sha256 format."
  fi
}

retrieve_api_key() {
  $kubernetesCLI -n $namespace get secret $DS_API_KEY_SECRET > /dev/null
  if [ $? -ne 0 ]; then
    echo_error_and_exit "The secret containing the API key IBM Cloud has not been created."
  fi
  api_key=`$kubernetesCLI -n $namespace get secret $DS_API_KEY_SECRET -o jsonpath='{.data.api-key}' | base64 -d`
}

check_namespace() {
  $kubernetesCLI get namespace $namespace > /dev/null
  if [ $? -ne 0 ]; then
    echo_error_and_exit "The namespace $namepace does not exist. Please create it and run the command again."
  fi
}

configure_data_center() {
if [[ "$remote_controlplane_env" != "icp4d" ]]; then
  [ -z $data_center ] && display_missing_arg "data-center"
  if [ $data_center = "frankfurt" ]; then
    # eu-de
    DS_GATEWAY="api.eu-de.dataplatform.cloud.ibm.com"
  elif [ $data_center = "sydney" ]; then
    # au-syd
    DS_GATEWAY="api.au-syd.dai.cloud.ibm.com"
  elif [ $data_center = "toronto" ]; then
    # ca-tor
    DS_GATEWAY="api.ca-tor.dai.cloud.ibm.com"
  elif [ $data_center = "london" ]; then
    # eu-gb
    DS_GATEWAY="api.eu-gb.dataplatform.cloud.ibm.com"
  elif [ $data_center = "ys1dev" ]; then
    # dataplatform.dev
    DS_GATEWAY="api.dataplatform.dev.cloud.ibm.com"
    IAM_URL="https://iam.test.cloud.ibm.com"
  elif [ $data_center = "ypqa" ]; then
    # dataplatform.test
    DS_GATEWAY="api.dataplatform.test.cloud.ibm.com"
  elif [ $data_center = "awsdev" ]; then
    # dev.aws
    DS_GATEWAY="api.dev.aws.data.ibm.com"
    IAM_URL="https://account-iam.platform.test.saas.ibm.com"
  elif [ $data_center = "awstest" ]; then
    # test.aws
    DS_GATEWAY="api.test.aws.data.ibm.com"
    IAM_URL="https://account-iam.platform.test.saas.ibm.com"
  elif [ $data_center = "awsprod" ]; then
    # ap-south-1.aws
    DS_GATEWAY="api.ap-south-1.aws.data.ibm.com"
    IAM_URL="https://account-iam.platform.saas.ibm.com"
  elif [ $data_center != "dallas" ]; then
    echo_error_and_exit "Unknown value for data center '${data_center}'. Please specified either dallas, frankfurt, sydney, toronto, london, or awsprod."
  fi
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
        --serviceid)
            shift
            service_id="${1}"
            ;;
        --username)
            shift
            username="${1}"
            ;;
        --password)
            shift
            password="${1}"
            ;;
        --proxy)
            shift
            proxy_url="${1}"
            ;;
        --proxy-cacert)
            shift
            cacert_location="${1}"
            ;;
        --krb5-conf)
            shift
            KRB5_CONF_FILE="${1}"
            ;;
        --krb5-conf-dir)
            shift
            KRB5_CONF_DIR="${1}"
            ;;
        --import-db2z-license)
            shift
            DB2Z_LICENSE="${1}"
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
            CUSTOM_DOCKER_REGISTRY="${1}"
            ;;
        --operator-registry-suffix)
            shift
            OPERATOR_REGISTRY_SUFFIX="${1}"
            ;;
        --docker-registry-suffix)
            shift
            DOCKER_REGISTRY_SUFFIX="${1}"
            ;;
        --digests)
            shift
            USE_DIGESTS="${1}"
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
        --additional-users)
            shift
            additional_users="${1}"
            ;;
        --zen-url)
            shift
            zen_url="${1}"
            ;;
        --mcsp-account-id)
            shift
            MCSP_ACCOUNT_ID="$1"
            ;;
        --disable-wlm-scaling)
            shift
            DISABLE_WLM_SCALING="$1"
            ;;
        install)
            action="install"
            ;;
        create-pull-secret)
             action="create-pull-secret"
            ;;
        create-proxy-secrets)
            action="create-proxy-secrets"
             ;;
        create-krb5-configmaps)
            action="create-krb5-configmaps"
             ;;
        create-db2z-license-secret)
            action="create-db2z-license-secret"
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

validate_and_setup_cp4d_args() {
  echo "CP4D environment found, curl will be used without ssl validation ..."
  CURL_CMD="curl -k"
  DS_GATEWAY="$(echo ${zen_url} | sed -e 's/^.*:\/\///g' -e 's/\/.*//g')"
  remote_controlplane_env="icp4d"
}

if [[ ! -z $dsdisplayHelp ]]; then
  case $action in
    install)
      handle_install_usage
      ;;
    create-pull-secret)
      handle_pull_secret_usage
      ;;
    create-proxy-secrets)
      handle_proxy_usage
      ;;
    create-krb5-configmaps)
      handle_krb5_usage
      ;;
    create-db2z-license-secret)
      handle_import_db2z_license_usage
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

print_header "$TOOL_NAME ${TOOL_VERSION}"
determine_cli
if [ -z $inputFile ]; then
  if [[ ! -z $zen_url ]]; then
    validate_and_setup_cp4d_args
  elif [[ "${data_center}" == 'aws'* ]]; then
    remote_controlplane_env="aws"
  fi
  if [[ "${DISABLE_WLM_SCALING}" == "true" ]]; then
    wlmScalingParam="enableWLMScaling: false"
    podExecPerms=""
  fi
  validate_common_args
  determine_k8s
fi

case $action in
install)
  handle_action_install
  ;;
create-pull-secret)
  create_pull_secret
  ;;
create-proxy-secrets)
  create_proxy_secrets
  ;;
create-krb5-configmaps)
  create_krb5_configmaps
  ;;
create-db2z-license-secret)
  create_db2z_license_secret
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
  if [[ ! -z $zen_url ]]; then
    validate_and_setup_cp4d_args
  elif [[ "${data_center}" == 'aws'* ]]; then
    remote_controlplane_env="aws"
  fi
  if [[ "${DISABLE_WLM_SCALING}" == "true" ]]; then
    wlmScalingParam="enableWLMScaling: false"
    podExecPerms=""
  fi
  validate_common_args
  determine_k8s
  if [[ ! -z $nfs_server ]]; then
    create_nfs_provisioner
  fi
  create_pull_secret
  create_proxy_secrets
  create_krb5_configmaps
  create_db2z_license_secret
  create_apikey_secret
  determine_registry
  handle_action_install
  create_instance
fi
