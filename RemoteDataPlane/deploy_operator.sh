OPERATOR_REGISTRY="icr.io/cpopen"
OPERATOR_DIGEST="sha256:c0af884eca4c68411f53a00dfb4bd486092c99977e161ef47ac1ed0602fb5e20"
kubernetesCLI="oc"

supportedVersions="5.0.0 5.0.1 5.0.2 5.0.3 5.1.0 5.1.1 5.1.2 5.1.3"
assetVersions="500 501 502 503 510 511 512 513"
imageDigests="sha256:c0af884eca4c68411f53a00dfb4bd486092c99977e161ef47ac1ed0602fb5e20 sha256:e21e3503e6f7e212109d104a4ef5a505ee0ca172d77eda9f65174bb104b8be07 sha256:c2c27cf0826e1f96aa523ec68374680ce1f7f8f4cc5512c28962933b22aabbfe sha256:0797ab7ed8d6c9aa644a6ca9468b279248d8deaf8afdf905464d44f4dd1824c3 sha256:07327f8ce59d24990a00b45ea1b2393b64b1d299130372855b9de4ed69e608e2 sha256:be24dd5fb73e40177810a0ff71ee885ddf0883ab3f8b790a6620a705848406c5 sha256:f6c7e12cd8d0cd981becb0f5f9abb6b1d833a10beb71a00d33e270d2f7fa2da8 sha256:4a53892a469c6b9b751a4cc2449378bfb0b15bfe1f3c0dd5056eeaf1587c82a4"
version="5.0.0"

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
  if [[ ! $supportedVersions =~ (^|[[:space:]])$version($|[[:space:]]) ]]; then
    echo "Unsupported version ${version}. Supported versions: ${supportedVersions}"
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
    
    versionsArray=(${supportedVersions})
    assetVersionsArray=(${assetVersions})
    digestsArray=(${imageDigests})

    if [ ${#versionsArray[@]} -ne ${#assetVersionsArray[@]} ]; then
      echo "Mismatch size for '${supportedVersions}' and '${assetVersions}'"
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
    versionsArray=(${supportedVersions})
    digestsArray=(${imageDigests})
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
  - pxruntimes
  - pxruntimes/status
  - pxruntimes/finalizers
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
  echo "--version: the version of the operator to deploy. The following versions are supported: ${supportedVersions}"
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
