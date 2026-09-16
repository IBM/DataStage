#!/usr/bin/env bash
# DataStage Remote Engine - Helm Deploy Script
# Usage: ./helm-deploy.sh <input-file.txt>

# tool version
TOOL_VERSION=1.0.0
TOOL_NAME='IBM DataStage Remote Engine for Helm'

supported_versions="5.1.0 5.1.1 5.1.2 5.1.3 5.2.0 5.2.1 5.2.2 5.3.0 5.3.1 5.4.0"
asset_versions="510 511 512 513 520 521 522 530 531 540"
operator_digests="sha256:2ced6ab631a869af0bf5cdfc0c494b78bb13e7fc7c935a84a62a94aa1183b623 sha256:b617c3faf2dc1e67f89dbe9baaf8456916c5c0dd9a183bb09fbb73eb9cb6e327 sha256:eec7dae8518f8e990904986d6b794735498fe1170bf2e9fc837aec8ec3e938ad sha256:212c975eaf76301c6c76fd3c33504e7696cc2b4da8d09f67baab43fea6a32cbb sha256:e13148eec54b11e0126f2e321a4c926951af4b741102c02b77d1b9e906619fbb sha256:d7a883657cfdc7e44c97db02b39d4af1a970990675045b886dcae56be149765e sha256:3a857a501a414018db4caf67ec27a16b0b27862c917d6d9863bfab7334b33d68 sha256:9fa25c170f2436214693eda0fadfd52a39b05f195d608407e6b45280a3357402 sha256:0c1c9a477be3aff53429e32b41a62e23c1e47f6375ef3a9fb6c7a5922088d650 sha256:e849e5a1ae70981a6f4f369fa958ee361afc5879e1e4d4c03778020e995934c2"
px_runtime_digests="sha256:e0e93f238899c60249c04f159326cd6338e59a179ba5762e7fab6b1855295444 sha256:3000c8a98cef44be354cad92ea7790d075f3fed7b7cde69c9d59f1d52f25499a sha256:74a3ba0c7316793b91b9a8410af1c30282020cbef6ed975f5787cfb61aa6ecb5 sha256:b1f2ce9976dd6ec08bfad47d6f06b6e0b5b91b7a8781c28d29e5c1e43f5206d5 sha256:2670bf08422818d9e6c1b8703f2f93fa47d3adc2110648a5b8a4e82153cd629f sha256:f57a35d763bd61f647acd12e1195250da2b567850fbddbb48ed306bd6d845e95 sha256:d86ca09f61a007582ac6442e220e9d1f2cb2ba79adf3f6038b007b302119ae37 sha256:0630e2d63e028bd27fc7c8ccbfe6270f418d14980fde00345834fe3788cb4dc1 sha256:be2a6a0481a74bc17e25202cdc730d9fd64e9960f36900f3f3aabdb1e310e7fe sha256:f40ab11a1d2a2dd92ae047a1a7079d4991cb3c63b939c6f27565e4ab45b31d2b"
px_compute_digests="sha256:5f7bca52a9f9adb997d43183f6b08ecc5719c1e44caaf798d095ab070b5c7cab sha256:eb9979137e0c724b0087246757666c662e1d430c5590a1a9e674f887be62f699 sha256:e7e821feeb731463fd5880bdd4147137a6ea3f3ca40f565b052f9864c6292e1f sha256:638222d47642f0017c8436598b6b62fe0db14c73dc0fcd26cdf10a821cc4a0fd sha256:0a1cac97d7e33fadbb63f7d9a4c625f61de65c288a110a23009b3b65a82e6a81 sha256:554885fbca20c548e9e6fac1498ad8f046e224bb88b5745822a564effa0d14c5 sha256:d69d6e981ed635caab4031b474950e109e1635352729c59f802fdeca5f9f6627 sha256:17c72e23a7dbcb3e7fd9426c0556409a73d610f499a1edf36dfd67ba1e48a47e sha256:2aa2ddcf48f25a2ae5269922f0cb345929dc2b3ca42f82470903c7339dc2ee16 sha256:f3ac3cbd74207d42d88bbb011093074773daffb0224d12a89287572045e03cfa"
flight_digests="sha256:ddb78a412a688a24300ec92ba51117d677b630412a362da6a2f07fc378cc4b62 sha256:ddb78a412a688a24300ec92ba51117d677b630412a362da6a2f07fc378cc4b62 sha256:ddb78a412a688a24300ec92ba51117d677b630412a362da6a2f07fc378cc4b62 sha256:ddb78a412a688a24300ec92ba51117d677b630412a362da6a2f07fc378cc4b62 sha256:ddb78a412a688a24300ec92ba51117d677b630412a362da6a2f07fc378cc4b62 sha256:ddb78a412a688a24300ec92ba51117d677b630412a362da6a2f07fc378cc4b62 sha256:ddb78a412a688a24300ec92ba51117d677b630412a362da6a2f07fc378cc4b62 sha256:ddb78a412a688a24300ec92ba51117d677b630412a362da6a2f07fc378cc4b62 sha256:ddb78a412a688a24300ec92ba51117d677b630412a362da6a2f07fc378cc4b62 sha256:ddb78a412a688a24300ec92ba51117d677b630412a362da6a2f07fc378cc4b62"

IAM_URL="https://iam.cloud.ibm.com"

CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/datastage-remote-engine"
INPUT_FILE="${1}"

echo_error_and_exit() {
    echo "ERROR: ${1}"
    exit 1
}

bold=$(tput bold)
normal=$(tput sgr0)

print_header() {
    echo ""
    echo "${bold}$1${normal}"
    echo ""
}

print_header "$TOOL_NAME ${TOOL_VERSION}"

if [ -z "$INPUT_FILE" ]; then
  echo "Usage: $0 <input-file.txt>"
  exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "ERROR: Input file not found: $INPUT_FILE"
  exit 1
fi

echo "Sourcing input file: $INPUT_FILE"
source <(grep -v '^#' "$INPUT_FILE" | grep -v '^$')
echo ""

# ------------------------------------------------------------
# Validate required fields
# ------------------------------------------------------------
[ -z "$name" ]          && echo "ERROR: name is required" && exit 1
[ -z "$namespace" ]     && echo "ERROR: namespace is required" && exit 1
[ -z "$api_key" ]       && echo "ERROR: api_key is required" && exit 1
[ -z "$username" ]      && echo "ERROR: username is required" && exit 1
[ -z "$password" ]      && echo "ERROR: password is required" && exit 1
[ -z "$projectId" ]     && echo "ERROR: projectId is required" && exit 1
[ -z "$storage_class" ] && echo "ERROR: storage_class is required" && exit 1
[ "$license_accept" != "true" ] && echo "ERROR: license_accept must be true" && exit 1

# ------------------------------------------------------------
# Resolve gateway from data_center
# ------------------------------------------------------------
case "$data_center" in
  dallas)          GATEWAY="api.dataplatform.cloud.ibm.com" ;;
  frankfurt)       GATEWAY="api.eu-de.dataplatform.cloud.ibm.com" ;;
  sydney)          GATEWAY="api.au-syd.dai.cloud.ibm.com" ;;
  toronto)         GATEWAY="api.ca-tor.dai.cloud.ibm.com" ;;
  london)          GATEWAY="api.eu-gb.dataplatform.cloud.ibm.com" ;;
  ys1dev)          GATEWAY="api.dataplatform.dev.cloud.ibm.com" IAM_URL="https://iam.test.cloud.ibm.com" ;;
  ypqa)            GATEWAY="api.dataplatform.test.cloud.ibm.com" ;;
  awsdev)          GATEWAY="api.dev.aws.data.ibm.com" IAM_URL="https://account-iam.platform.test.saas.ibm.com" ;;
  awstest)         GATEWAY="api.test.aws.data.ibm.com" IAM_URL="https://account-iam.platform.test.saas.ibm.com" ;;
  awsprod-apsouth) GATEWAY="api.ap-south-1.aws.data.ibm.com" IAM_URL="https://account-iam.platform.saas.ibm.com" ;;
  awsprod-useast)  GATEWAY="api.us-east-1.aws.data.ibm.com" IAM_URL="https://account-iam.platform.saas.ibm.com" ;;
  awsgovpreprod)   GATEWAY="api.dai.prep.ibmforusgov.com" IAM_URL="" ;;
  awsgovprod)      GATEWAY="api.dai.ibmforusgov.com" IAM_URL="" ;;
  *)               [ -z "$zen_url" ] && echo "Unknown value for data center '${data_center}'. Please specified either dallas, frankfurt, sydney, toronto, london, awsprod-apsouth, awsprod-useast, or awsgovprod." && exit 1 ;;
esac

# CP4D overrides gateway
if [ -n "$zen_url" ]; then
  GATEWAY=$(echo "$zen_url" | sed -e 's|^.*://||' -e 's|/.*||')
fi

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
        echo "Setting Kubernetes cli to '${kubernetesCLI}'"
      fi
    fi
  else
    isOpenShiftCluster="false"
    echo "Not running against OpenShift cluster"
  fi
}

determine_cli
determine_k8s

# ------------------------------------------------------------
# Fetch image digests
# ------------------------------------------------------------
if [ -n "$USE_DIGESTS" ]; then
  echo "Using provided digests: $USE_DIGESTS"
  IFS=',' read -r OPERATOR_DIGEST PX_RUNTIME_DIGEST PX_COMPUTE_DIGEST <<< "$USE_DIGESTS"
  if [[ ${ENABLE_FLIGHT} == "true" ]] || [[ ${ENABLE_SHARED_FLIGHT} == "true" ]]; then
    if [[ ! -z ${FLIGHT_DIGEST} ]]; then
      if [[ "${FLIGHT_DIGEST}" = sha256* ]]; then
        echo "Using custom digest for wdp-connect-flight-svc: ${FLIGHT_DIGEST}"
      else
        echo_error_and_exit "Custom wdp-connect-flight-svc digest is not in proper sha256 format."
      fi
    else
      echo_error_and_exit "ENABLE_FLIGHT or ENABLE_SHARED_FLIGHT is set to true and USE_DIGESTS is specified but FLIGHT_DIGEST digest is not specified. Aborting."
    fi
  fi
elif [ -n "$zen_url" ]; then
  if [[ "${username}" == "cp" ]]; then
    OPERATOR_REGISTRY="icr.io"
    DOCKER_REGISTRY_PREFIX="cp.icr.io"
    OPERATOR_REGISTRY_SUFFIX="cpopen"
    DOCKER_REGISTRY_SUFFIX="cp/cpd"
  fi

  asset_version=$(curl -k -s "https://${GATEWAY}/data_intg/v3/assets/version")
  parsed_version=$(echo "${asset_version}" | jq -r '.version')

  versionsArray=(${supported_versions})
  assetVersionsArray=(${asset_versions})
  operatorArray=(${operator_digests})
  pxruntimeArray=(${px_runtime_digests})
  pxcomputeArray=(${px_compute_digests})
  flightArray=(${flight_digests})

  if [ ${#versionsArray[@]} -ne ${#assetVersionsArray[@]} ]; then
    echo_error_and_exit "Mismatch size for '${supportedVersions}' and '${assetVersions}'"
  fi
  arraylength=${#versionsArray[@]}

  for (( i=0; i<${arraylength}; i++ ));
  do
    if [[ "${parsed_version}" =~ ${assetVersionsArray[$i]}\.[0-9]+\.[0-9]+ ]]; then
      version="${versionsArray[$i]}"
      OPERATOR_DIGEST="${operatorArray[$i]}"
      PX_RUNTIME_DIGEST="${pxruntimeArray[$i]}"
      PX_COMPUTE_DIGEST="${pxcomputeArray[$i]}"
      echo "Version determined from control plane: $version"
      if [[ ${ENABLE_FLIGHT} == "true" ]] || [[ ${ENABLE_SHARED_FLIGHT} == "true" ]]; then
        if [[ -z ${FLIGHT_DIGEST} ]]; then
          if [[ "${assetVersionsArray[$i]}" -ge "540" ]]; then
            FLIGHT_DIGEST="${flightArray[$i]}"
            echo "Retrieved wdp-connect-flight-svc digest."
          else
            echo_error_and_exit "Flight service is only supported starting from version 5.4.0. Aborting."
          fi
        else
          echo "Using custom digest for wdp-connect-flight-svc."
        fi
      fi
      break;
    fi
  done
  [ -z $PX_RUNTIME_DIGEST ] && echo_error_and_exit "Failed to retrieve ds-operator, ds-px-runtime, and ds-px-compute digests. Asset version ${parsed_version} not supported for CP4D remote engine. Supported asset versions are [${asset_versions}]. Aborting."
else
  echo "Fetching image digests..."

  # Get IAM token
  if [[ "${data_center}" == 'awsgov'* ]]; then
    TOKEN=$(curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" \
      -d "{ \"apikey\": \"${api_key}\" }" "https://${GATEWAY/api./}/api/rest/mcsp/apikeys/token" \
      | jq .token | cut -d\" -f2)
  elif [[ "$data_center" == aws* ]]; then
    TOKEN=$(curl -s -X POST \
      --header "Content-Type: application/json" \
      --header "Mcsp-ApiKey: $api_key" \
      "${IAM_URL}/api/2.0/accounts/${MCSP_ACCOUNT_ID}/apikeys/token" \
      | jq -r .token)
  else
    TOKEN=$(curl -s -X POST \
      --header "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" \
      --data-urlencode "apikey=$api_key" \
      ${IAM_URL}/identity/token | jq -r .access_token)
  fi

  [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ] && echo "ERROR: Failed to get access token" && exit 1

  DIGESTS=$(curl -s -X GET \
    -H "Authorization: Bearer $TOKEN" \
    -H "accept: application/json" \
    "https://${GATEWAY}/data_intg/v3/flows_runtime/remote_engine/versions")

  PX_RUNTIME_DIGEST=$(echo "$DIGESTS" | jq -r '.versions[0].image_digests.px_runtime')
  PX_COMPUTE_DIGEST=$(echo "$DIGESTS" | jq -r '.versions[0].image_digests.px_compute')

  [ -z "$PX_RUNTIME_DIGEST" ] || [ "$PX_RUNTIME_DIGEST" = "null" ] && echo "ERROR: Failed to get px_runtime digest" && exit 1
  [ -z "$PX_COMPUTE_DIGEST" ] || [ "$PX_COMPUTE_DIGEST" = "null" ] && echo "ERROR: Failed to get px_compute digest" && exit 1

  if [[ "${username}" == "cp" ]]; then
    OPERATOR_REGISTRY="icr.io"
    DOCKER_REGISTRY_PREFIX="cp.icr.io"
    OPERATOR_REGISTRY_SUFFIX="cpopen"
    DOCKER_REGISTRY_SUFFIX="cp/cpd"
    # Operator digest from latest official release
    operatorArray=(${operator_digests})
    OPERATOR_DIGEST="${operatorArray[-1]}"
    if [[ ${ENABLE_FLIGHT} == "true" ]] || [[ ${ENABLE_SHARED_FLIGHT} == "true" ]]; then
      if [[ -z ${FLIGHT_DIGEST} ]]; then
        flightArray=(${flight_digests})
        FLIGHT_DIGEST="${flightArray[-1]}"
      else
        echo "Using custom digest for wdp-connect-flight-svc."
      fi
    fi
  else
    # Operator digest from ICR using registry API key (password)
    echo "Fetching operator digest from ICR..."
    ICR_TOKEN=$(curl -X POST \
      --header "Content-Type: application/x-www-form-urlencoded" \
      --header "Accept: application/json" \
      --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" \
      --data-urlencode "apikey=$password" \
      https://iam.ng.bluemix.net/identity/token | jq -r .access_token)

    [ -z "$ICR_TOKEN" ] || [ "$ICR_TOKEN" = "null" ] && echo "ERROR: Failed to get ICR token" && exit 1

    OPERATOR_DIGEST=$(curl -s -X GET \
      -H "accept: application/json" \
      -H "Account: d10b01a616ed4b73a9ac8a052424a345" \
      -H "Authorization: Bearer $ICR_TOKEN" \
      "https://icr.io/api/v1/images?includeIBM=false&includePrivate=true&includeManifestLists=true&vulnerabilities=false&repository=ds-operator" \
      | jq -r '. |= sort_by(.Created) | .[length-1] | .RepoDigests[0]' \
      | cut -d@ -f2)

    [ -z "$OPERATOR_DIGEST" ] || [ "$OPERATOR_DIGEST" = "null" ] && echo "ERROR: Failed to get operator digest from ICR" && exit 1
    echo "Got operator digest from ICR"

    if [[ ${ENABLE_FLIGHT} == "true" ]] || [[ ${ENABLE_SHARED_FLIGHT} == "true" ]]; then
      if [[ -z ${FLIGHT_DIGEST} ]]; then
        echo "Fetching flight digest from ICR..."
        FLIGHT_DIGEST=$(curl -s -X GET \
          -H "accept: application/json" \
          -H "Account: d10b01a616ed4b73a9ac8a052424a345" \
          -H "Authorization: Bearer $ICR_TOKEN" \
          "https://icr.io/api/v1/images?includeIBM=false&includePrivate=true&includeManifestLists=true&vulnerabilities=false&repository=wdp-connect-flight-svc" \
          | jq -r '. |= sort_by(.Created) | .[length-1] | .RepoDigests[0]' \
          | cut -d@ -f2)
        [ -z "$FLIGHT_DIGEST" ] || [ "$FLIGHT_DIGEST" = "null" ] && echo "ERROR: Failed to get flight digest from ICR" && exit 1
        echo "Got flight digest from ICR"
      else
        echo "Using custom digest for wdp-connect-flight-svc."
      fi
    fi
  fi
fi

echo ""
echo "Digests:"
echo "  operator:   $OPERATOR_DIGEST"
echo "  px-runtime: $PX_RUNTIME_DIGEST"
echo "  px-compute: $PX_COMPUTE_DIGEST"
if [[ -n "${FLIGHT_DIGEST}" ]]; then
  echo "  flight:     $FLIGHT_DIGEST"
fi
echo ""

# ------------------------------------------------------------
# Generate values.yaml
# ------------------------------------------------------------
GENERATED_VALUES="$(dirname "$INPUT_FILE")/values-${name}.yaml"

cat > "$GENERATED_VALUES" << EOF
# Auto-generated from $INPUT_FILE
# $(date)

name: "$name"
namespace: "$namespace"
apiKey: "$api_key"
projectId: "$projectId"
storageClass: "$storage_class"
storageSize: "${storage_size:-10}"
size: "${size:-small}"
licenseAccept: true
isOpenShiftCluster: "$isOpenShiftCluster"

operatorDigest: "$OPERATOR_DIGEST"
pxRuntimeDigest: "$PX_RUNTIME_DIGEST"
pxComputeDigest: "$PX_COMPUTE_DIGEST"
EOF

# Optional fields
[ -n "$data_center" ]      && echo "dataCenter: \"$data_center\""           >> "$GENERATED_VALUES"
[ -n "$zen_url" ]          && echo "zenUrl: \"$zen_url\""                   >> "$GENERATED_VALUES"
[ -n "$username" ]         && echo "username: \"$username\""                >> "$GENERATED_VALUES"
[ -n "$password" ]         && echo "password: \"$password\""                >> "$GENERATED_VALUES"
[ -n "$service_id" ]       && echo "serviceId: \"$service_id\""             >> "$GENERATED_VALUES"
[ -n "$MCSP_ACCOUNT_ID" ]  && echo "mcspAccountId: \"$MCSP_ACCOUNT_ID\""    >> "$GENERATED_VALUES"
[ -n "$additional_users" ] && echo "additionalUsers: \"$additional_users\"" >> "$GENERATED_VALUES"
[ -n "$proxy_url" ]        && echo "proxyUrl: \"$proxy_url\""               >> "$GENERATED_VALUES"
[ -n "$CUSTOM_DOCKER_REGISTRY" ] && echo "customDockerRegistry: \"$CUSTOM_DOCKER_REGISTRY\""       >> "$GENERATED_VALUES"
[ -n "$OPERATOR_REGISTRY" ] && echo "operatorRegistry: \"$OPERATOR_REGISTRY\""                     >> "$GENERATED_VALUES"
[ -n "$DOCKER_REGISTRY_PREFIX" ]   && echo "dockerRegistryPrefix: \"$DOCKER_REGISTRY_PREFIX\""     >> "$GENERATED_VALUES"
[ -n "$OPERATOR_REGISTRY_SUFFIX" ] && echo "operatorRegistrySuffix: \"$OPERATOR_REGISTRY_SUFFIX\"" >> "$GENERATED_VALUES"
[ -n "$DOCKER_REGISTRY_SUFFIX" ]   && echo "dockerRegistrySuffix: \"$DOCKER_REGISTRY_SUFFIX\""     >> "$GENERATED_VALUES"
[ "$DISABLE_WLM_SCALING" = "true" ] && echo "disableWlmScaling: true"      >> "$GENERATED_VALUES"
[ -n "$FLIGHT_DIGEST" ]    && echo "flightDigest: \"$FLIGHT_DIGEST\""      >> "$GENERATED_VALUES"
[ "$ENABLE_FLIGHT" = "true" ]    && echo "enableFlightService: true"       >> "$GENERATED_VALUES"
[ "$ENABLE_SHARED_FLIGHT" = "true" ]   && echo "enableSharedFlightService: true"                   >> "$GENERATED_VALUES"

# File-based options - read file contents in
if [ -n "$cacert_location" ] && [ -f "$cacert_location" ]; then
  echo "caCert: |"                                                           >> "$GENERATED_VALUES"
  sed 's/^/  /' "$cacert_location"                                          >> "$GENERATED_VALUES"
fi
if [ -n "$KRB5_CONF_FILE" ] && [ -f "$KRB5_CONF_FILE" ]; then
  echo "krb5ConfFile: |"                                                     >> "$GENERATED_VALUES"
  sed 's/^/  /' "$KRB5_CONF_FILE"                                           >> "$GENERATED_VALUES"
fi
if [ -n "$KRB5_CONF_DIR" ] && [ -d "$KRB5_CONF_DIR" ]; then
  echo "krb5ConfDir: \"$KRB5_CONF_DIR\""                                    >> "$GENERATED_VALUES"
fi
if [ -n "$DB2Z_LICENSE" ] && [ -f "$DB2Z_LICENSE" ]; then
  echo "db2zLicense: |"                                                      >> "$GENERATED_VALUES"
  sed 's/^/  /' "$DB2Z_LICENSE"                                             >> "$GENERATED_VALUES"
fi
if [ -n "$nfs_server" ]; then
  echo "nfsServer: \"$nfs_server\""                                          >> "$GENERATED_VALUES"
  echo "nfsPath: \"${nfs_path:-/}\""                                        >> "$GENERATED_VALUES"
  [ -n "$provisioner_namespace" ] && echo "provisionerNamespace: \"$provisioner_namespace\"" >> "$GENERATED_VALUES"
fi

echo "Generated values file: $GENERATED_VALUES"
echo ""

# ------------------------------------------------------------
# Deploy
# ------------------------------------------------------------
$kubernetesCLI get namespace "$namespace" > /dev/null 2>&1 || $kubernetesCLI create namespace "$namespace"

$kubernetesCLI apply -f datastage-remote-engine/crds/pxremoteengines-crd.yaml --server-side --force-conflicts

helm upgrade --install "$name" "$CHART_DIR" -f "$GENERATED_VALUES"

echo ""
echo "Checking pods in $namespace..."
sleep 3
$kubernetesCLI get pods -n "$namespace"
echo ""
echo "Engine status:"
$kubernetesCLI get pxre -n "$namespace"
