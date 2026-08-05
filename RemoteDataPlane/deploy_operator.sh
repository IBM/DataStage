OPERATOR_REGISTRY="icr.io/cpopen"
kubernetesCLI="oc"

supported_versions="5.1.0 5.1.1 5.1.2 5.1.3 5.2.0 5.2.1 5.2.2 5.3.0 5.3.1 5.4.0"
asset_versions="510 511 512 513 520 521 522 530 531 540"
operator_digests="sha256:2ced6ab631a869af0bf5cdfc0c494b78bb13e7fc7c935a84a62a94aa1183b623 sha256:b617c3faf2dc1e67f89dbe9baaf8456916c5c0dd9a183bb09fbb73eb9cb6e327 sha256:eec7dae8518f8e990904986d6b794735498fe1170bf2e9fc837aec8ec3e938ad sha256:212c975eaf76301c6c76fd3c33504e7696cc2b4da8d09f67baab43fea6a32cbb sha256:e13148eec54b11e0126f2e321a4c926951af4b741102c02b77d1b9e906619fbb sha256:d7a883657cfdc7e44c97db02b39d4af1a970990675045b886dcae56be149765e sha256:3a857a501a414018db4caf67ec27a16b0b27862c917d6d9863bfab7334b33d68 sha256:9fa25c170f2436214693eda0fadfd52a39b05f195d608407e6b45280a3357402 sha256:0c1c9a477be3aff53429e32b41a62e23c1e47f6375ef3a9fb6c7a5922088d650 sha256:e849e5a1ae70981a6f4f369fa958ee361afc5879e1e4d4c03778020e995934c2"

OPERATOR_DIGEST="${operator_digests##* }"
version="${supported_versions##* }"

verify_args() {
  # check if oc cli available
  which oc > /dev/null
  if [ $? -ne 0 ]; then
    echo "Unable to locate oc cli"
    exit 3
  fi
  
  # check if the specified namespace exists and is a management namespace
  oc get namespace $namespace &> /dev/null
  if [ $? -ne 0 ]; then
    echo "Namespace $namespace not found."
    exit 3
  fi
  oc -n $namespace get cm physical-location-info-cm &> /dev/null
  if [ $? -ne 0 ]; then
    echo "The specified namespace $namespace is not a management namespace. Unable to locate the configmap physical-location-info-cm."
    exit 3
  fi

  # TODO set digest based on version in subsequent release
  if [[ ! $supported_versions =~ (^|[[:space:]])$version($|[[:space:]]) ]]; then
    echo "Unsupported version ${version}. Supported versions: ${supported_versions}"
    exit 3
  fi
}

check_version() {
  if [ -z $skipVersionCheck ]; then
    hub_url=`oc -n $namespace get cm physical-location-info-cm -o jsonpath='{.data.CPD_HUB_URL}'`
    if [ -z $hub_url ]; then
      echo "Unable to retrieve version from control plane. Defaulting version to ${version}".
      return 0
    fi
    asset_version=`curl -ks https://${hub_url}/data_intg/v3/assets/version`
    
    versionsArray=(${supported_versions})
    assetVersionsArray=(${asset_versions})
    digestsArray=(${operator_digests})

    if [ ${#versionsArray[@]} -ne ${#assetVersionsArray[@]} ]; then
      echo "Mismatch size for '${supported_versions}' and '${asset_versions}'"
      exit 1
    fi
    arraylength=${#versionsArray[@]}

    for (( i=0; i<${arraylength}; i++ ));
    do
      assetVersion="${assetVersionsArray[$i]}\.[0-9]+\.[0-9]+"
      echo "${asset_version}" | grep -E "${assetVersion}" &> /dev/null
      if [[ $? -eq 0 ]]; then
        version="${versionsArray[$i]}"
        OPERATOR_DIGEST="${digestsArray[$i]}"
        echo "Version determined from control plane: $version"
        echo "OPERATOR_DIGEST: ${OPERATOR_DIGEST}"
        break;
      fi 
    done
  else
    versionsArray=(${supported_versions})
    digestsArray=(${operator_digests})
    for (( i=0; i<${arraylength}; i++ ));
    do
      ventry=${versionsArray[$i]}
      if [ "$ventry" == "$version" ]; then
        OPERATOR_DIGEST="${digestsArray[$i]}"
        break;
      fi
    done
  fi
}

upgrade_pxruntimes() {
  # upgrade pxruntime instaces to the same version
  instance_count=`oc -n $namespace get pxruntime 2> /dev/null | wc -l | tr -d ' '`
  if [ $instance_count -gt 0 ]; then
    echo "Updating PXRuntime instances in $namespace to version ${version}"
    oc -n ${namespace} get pxruntime 2> /dev/null | awk 'NR>1 { print $1 }' | xargs -I % oc -n ${namespace} patch pxruntime % --type=merge -p "{\"spec\":{\"version\": \"${version}\"}}"
  fi
}

create_pxruntime_crd() {
  cat <<EOF | $kubernetesCLI -n $namespace apply ${dryRun} -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  creationTimestamp: null
  name: pxruntimes.ds.cpd.ibm.com
spec:
  group: ds.cpd.ibm.com
  names:
    kind: PXRuntime
    listKind: PXRuntimeList
    plural: pxruntimes
    singular: pxruntime
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
      - description: The desired version of PXRuntime
        jsonPath: .spec.version
        name: Version
        type: string
      - description: The actual version PXRuntime
        jsonPath: .status.dsVersion
        name: Reconciled
        type: string
      - description: The status of PXRuntime
        jsonPath: .status.dsStatus
        name: Status
        type: string
      - description: The age of PXRuntime
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
  name: ibm-cpd-datastage-operator-serviceaccount
  namespace: $namespace
  labels:
    app.kubernetes.io/instance: ibm-cpd-datastage-operator-sa
    app.kubernetes.io/managed-by: ibm-cpd-datastage-operator
    app.kubernetes.io/name: ibm-cpd-datastage-operator-sa
EOF
}

create_role() {
  cat <<EOF | $kubernetesCLI -n $namespace apply ${dryRun} -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ibm-cpd-datastage-operator-role
  namespace: $namespace
  labels:
     app.kubernetes.io/instance: ibm-cpd-datastage-operator-cluster-role
     app.kubernetes.io/managed-by: ibm-cpd-datastage-operator
     app.kubernetes.io/name: ibm-cpd-datastage-operator-cluster-role

rules:
  - apiGroups:
      - ''
    resources:
      - configmaps
      - persistentvolumeclaims
      - pods
      - secrets
      - serviceaccounts
      - services
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - ''
    resources:
      - pods/exec
    verbs:
      - create
      - get
  - apiGroups:
      - apps
    resources:
      - deployments
      - replicasets
      - statefulsets
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - apps
    resources:
      - deployments/scale
      - statefulsets/scale
    verbs:
      - get
      - patch
      - update
  - apiGroups:
      - autoscaling
    resources:
      - horizontalpodautoscalers
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - batch
    resources:
      - jobs
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - batch
    resources:
      - jobs/status
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ds.cpd.ibm.com
    resources:
      - pxruntimes
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - ds.cpd.ibm.com
    resources:
      - pxruntimes/finalizers
    verbs:
      - patch
      - update
  - apiGroups:
      - ds.cpd.ibm.com
    resources:
      - pxruntimes/status
    verbs:
      - get
      - list
      - patch
      - update
  - apiGroups:
      - networking.k8s.io
    resources:
      - networkpolicies
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - policy
    resources:
      - poddisruptionbudgets
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - rbac.authorization.k8s.io
    resources:
      - rolebindings
      - roles
    verbs:
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
  name: ibm-cpd-datastage-operator-role-binding
  namespace: $namespace
  labels:
    app.kubernetes.io/instance: ibm-cpd-datastage-operator-role-binding
    app.kubernetes.io/managed-by: ibm-cpd-datastage-operator
    app.kubernetes.io/name: ibm-cpd-datastage-operator-role-binding
subjects:
- kind: ServiceAccount
  name: ibm-cpd-datastage-operator-serviceaccount
  namespace: $namespace
roleRef:
  kind: Role
  name: ibm-cpd-datastage-operator-role
  apiGroup: rbac.authorization.k8s.io
EOF
}

create_operator_deployment() {
  # remove deployment with incorrect name used previously
  $kubernetesCLI -n $namespace delete deploy ibm-cpd-datastage-operator --ignore-not-found=true
  cat <<EOF | $kubernetesCLI -n $namespace apply ${dryRun} -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ibm-cpd-datastage-operator
  annotations:
    cloudpakId: 49a42b864bb94569bef0188ead948f11
    cloudpakName: IBM DataStage Enterprise Plus Cartridge for IBM Cloud Pak for Data
    productID: d8a97b146d6f4bf18f033db9105f87f1
    productMetric: FREE
    productName: IBM DataStage Enterprise Plus for Cloud Pak for Data
    productVersion: 5.0.0
  labels:
    app.kubernetes.io/instance: ibm-cpd-datastage-operator
    app.kubernetes.io/managed-by: ibm-cpd-datastage-operator
    app.kubernetes.io/name: ibm-cpd-datastage-operator
    intent: projected
    icpdsupport/addOnId: datastage
    icpdsupport/app: operator
    name: ibm-cpd-datastage-operator
spec:
  selector:
    matchLabels:
      name: ibm-cpd-datastage-operator
  replicas: 1
  template:
    metadata:
      annotations:
        productID: ff566289767a4a7f822ab01ebaa16cf4
        productMetric: FREE
        productName: IBM DataStage as a Service Anywhere
        productVersion: 5.0.0
      labels:
        app.kubernetes.io/instance: ibm-cpd-datastage-operator
        app.kubernetes.io/managed-by: ibm-cpd-datastage-operator
        app.kubernetes.io/name: ibm-cpd-datastage-operator
        intent: projected
        icpdsupport/addOnId: datastage
        icpdsupport/app: operator
        name: ibm-cpd-datastage-operator
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
            - "./pxremote_watches.yaml"
          image: ${OPERATOR_REGISTRY}/ds-operator@${OPERATOR_DIGEST}
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
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
              ephemeral-storage: 250Mi
            limits:
              cpu: 1
              memory: 1024Mi
              ephemeral-storage: 900Mi
      serviceAccount: ibm-cpd-datastage-operator-serviceaccount
      serviceAccountName: ibm-cpd-datastage-operator-serviceaccount
      terminationGracePeriodSeconds: 10
EOF
}

create_cr_role() {
  cat <<EOF | $kubernetesCLI -n $namespace apply ${dryRun} -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    icpdata_tether_resource: "true"
  name: zen-datastage-cr-role
rules:
- apiGroups:
  - ds.cpd.ibm.com
  resources:
  - pxruntimes
  - pxruntimes/status
  - pxruntimes/finalizers
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
EOF
}

create_cr_role_binging() {
  cat <<EOF | $kubernetesCLI -n $namespace apply ${dryRun} -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    icpdata_tether_resource: "true"
  name: zen-datastage-cr-rb
roleRef:
  kind: Role
  name: zen-datastage-cr-role
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: ibm-zen-agent-sa
  namespace: $namespace
EOF
}

handle_badusage() {
  echo ""
  echo "Usage: $0 --namespace <management-namespace> [--version <version>]"
  echo "--namespace: the management namespace to deploy the DataStage operator into"
  echo "--version: the version of the operator to deploy. The following versions are supported: ${supported_versions}"
  echo ""
  exit 3
}

while [ $# -gt 0 ]
do
    case $1 in
        --namespace|-n)
            shift
            namespace="${1}"
            ;;
        --digest)
            shift
            OPERATOR_DIGEST="${1}"
            ;;
        --version)
            shift
            version="${1}"
            skipVersionCheck="true"
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

if [[ -z $namespace ]]; then
  handle_badusage
fi

verify_args
check_version
create_pxruntime_crd
create_service_account
create_role
create_role_binding
create_operator_deployment
create_cr_role
create_cr_role_binging
upgrade_pxruntimes
