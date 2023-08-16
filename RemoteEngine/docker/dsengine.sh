#!/usr/bin/env bash

# ----------------------------------------------------------------------------------------------------
# IBM Confidential
# OCO Source Materials
# 5900-A3Q, 5737-H76
# Copyright IBM Corp. 2022
# The source code for this program is not published or other-wise divested of its trade
# secrets, irrespective of what has been deposited with the U.S.Copyright Office.
# ----------------------------------------------------------------------------------------------------

#set -e

#######################################################################
# constants
#######################################################################
# tool version
TOOL_VERSION=0.0.1
TOOL_NAME='IBM DataStage Remote Engine'
TOOL_SHORTNAME='DataStage Remote Engine'

# image information
ICR_REGISTRY='icr.io/datastage'
PX_VERSION='latest'

# container names
PXRUNTIME_IMAGE_NAME='ds-px-runtime'
PXCOMPUTE_IMAGE_NAME='ds-px-compute'

# Docker command
DOCKER_CMD='docker'
if ! [ -x "$(command -v docker)" ] && [ -x "$(command -v podman)" ]; then
    DOCKER_CMD='podman'
fi
DOCKER_VOLUMES_DIR='/tmp/docker/volumes'

# env constnats
GATEWAY_DOMAIN_YS1DEV='dataplatform.dev.cloud.ibm.com'
GATEWAY_DOMAIN_YPQA='dataplatform.test.cloud.ibm.com'
GATEWAY_DOMAIN_YPPROD='dataplatform.cloud.ibm.com'
GATEWAY_DOMAIN_FRPROD='eu-de.dataplatform.cloud.ibm.com'

# Defaults
DATASTAGE_HOME="https://${GATEWAY_DOMAIN_YPPROD}"
IAM_URL='https://iam.cloud.ibm.com'
PLATFORM='icp4d'
PX_MEMORY='4g'
COMPUTE_COUNT=0

bold=$(tput bold)
normal=$(tput sgr0)

STR_ENGINE_NAME='  -n, --remote-engine-name    Name of the remote engine instance'
STR_IAM_APIKEY='  -a, --apikey                IBM Cloud APIKey for the selected home argument'
STR_PROD_APIKEY='  -p, --prod-apikey           IBM Cloud Production APIKey for image download from DataStage Container registry'
STR_DSNEXT_SEC_KEY='  -e, --encryption key        Encryption key to be used'
STR_IVSPEC='  -i, --ivspec                Initialization vector'
STR_PROJECT_UID='  -d, --project-id            DataPlatform Project ID'
STR_DSTAGE_HOME='  --home                      IBM DataStage enviroment: [ys1dev, ypqa, ypprod (default), frprod]'
STR_VOLUMES='  --volume-dir                      Directory for persistent storage. Default location is ${DOCKER_VOLUMES_DIR}'
# STR_PLATFORM='  --platform                  Platform to executed against: [cloud (default), icp4d]'
# STR_VERSION='  --version                   Version of the remote engine to use'
STR_MEMORY='  --memory                    Memory allocated to the docker container. Default is 4Gb'
STR_HELP='  --help                      Print usage information'

#######################################################################
# cli functions
#######################################################################

help_header() {
    script_name=$(basename "${0}")
    echo ""
    print_tool_name_version
    echo "This tool manages manages IBM DataStage remote engine instances."
    echo "Find more information at: https://dataplatform.cloud.ibm.com/cli-docs"
    echo ""
}

ACTION='None'

print_help() {
    script_name=$(basename "${0}")
    help_header
    echo "${bold}usage:${normal} ${script_name} <command> [<args>]"
    echo ""
    echo "${bold}commands:${normal}"
    echo "    start         start a remote engine instance"
    echo "    stop          stop a remote engine instance"
    echo "    restart       restart a remote engine instance"
    echo "    cleanup       cleanup a remote engine instance"
    echo "    help          Print usage information"
    echo ""
}

function main(){
    if (( "${#}" == 0 )); then
        print_help 0;
        exit 1
    fi

    case ${1} in
        start | stop | restart | cleanup | help)
            $1 "${@:2}";
        ;;
        * )
            echo "unknown command: $1";
            print_help 1;
            exit 1;
        ;;
    esac
}

print_usage() {
    help_header

    if [[ "${ACTION}" == 'start' ]]; then
        echo "${bold}usage:${normal} ${script_name} start [-n | --remote-engine-name] [-a | --apikey] [-p | --prod-apikey] [-e | --encryption-key] [-i | --ivspec] [-d | --project-id] [--home] [--memory]"
    elif [[ "${ACTION}" == 'stop' ]]; then
        echo "${bold}usage:${normal} ${script_name} stop [-n | --remote-engine-name]"
    elif [[ "${ACTION}" == 'restart' ]]; then
        echo "${bold}usage:${normal} ${script_name} restart [-n | --remote-engine-name]"
    elif [[ "${ACTION}" == 'cleanup' ]]; then
        echo "${bold}usage:${normal} ${script_name} cleanup [-n | --remote-engine-name] [-a | --apikey] [-d | --project-id] [--home]"
    fi

    echo ""
    echo "${bold}options:${normal}"
    echo "${STR_ENGINE_NAME}"

    if [[ "${ACTION}" == 'start' || "${ACTION}" == 'cleanup' ]]; then
        echo "${STR_IAM_APIKEY}"
    fi

    if [[ "${ACTION}" == 'start' ]]; then
        echo "${STR_PROD_APIKEY}"
        echo "${STR_DSNEXT_SEC_KEY}"
        echo "${STR_IVSPEC}"
    fi

    if [[ "${ACTION}" == 'start' || "${ACTION}" == 'cleanup' ]]; then
        echo "${STR_PROJECT_UID}"
        echo "${STR_DSTAGE_HOME}"
    fi

    if [[ "${ACTION}" == 'start' ]]; then
        echo "${STR_MEMORY}"
        echo "${STR_VOLUMES}"
        # echo "${STR_PLATFORM}"
        # echo "${STR_VERSION}"
    fi

    echo "${STR_HELP}"
    echo ""
}

function start() {
    ACTION='start'
    if [[ "${#}" == 0 ]]; then
        print_usage
        exit 1
    fi

    # process options
    while [[ "$1" != "" ]]; do
        case "$1" in
        -n | --remote-engine-name)
            shift
            REMOTE_ENGINE_NAME="$1"
            ;;
        -a | --apikey)
            shift
            IAM_APIKEY="$1"
            ;;
        -p | --prod-apikey)
            shift
            IAM_APIKEY_PROD="$1"
            ;;
        # --compute-count)
        #     shift
        #     COMPUTE_COUNT="$1"
        #     ;;
        -e | --encryption-key)
            shift
            DSNEXT_SEC_KEY="$1"
            ;;
        -i | --ivspec)
            shift
            IVSPEC="$1"
            ;;
        -d | --project-id)
            shift
            PROJECT_ID="$1"
            ;;
        --home)
            shift
            DATASTAGE_HOME="$1"
            ;;
        --memory)
            shift
            PX_MEMORY="$1"
            ;;
        --volume-dir)
            shift
            DOCKER_VOLUMES_DIR="$1"
            ;;
        # --platform)
        #     shift
        #     PLATFORM="$1"
        #     ;;
        # --version)
        #     shift
        #     PX_VERSION="$1"
        #     ;;
        -h | --help)
            print_usage
            exit 1
            ;;
        *)
            echo "Unknown option specified: $1"
            print_usage
            exit 1
            ;;
        esac
        shift
    done
}

function stop() {
    ACTION='stop'
    if [[ "$#" == 0 ]]; then
        print_usage
        exit 1
    fi

    # process options
    while [[ "$1" != "" ]]; do
        case "$1" in
        -n | --remote-engine-name)
            shift
            REMOTE_ENGINE_NAME="$1"
            ;;
        -h | --help)
            print_usage
            exit 1
            ;;
        *)
            print_usage
            exit 1
            ;;
        esac
        shift
    done
}

function restart() {
    ACTION='restart'
    if [[ "$#" == 0 ]]; then
        print_usage
        exit 1
    fi

    # process options
    while [[ "$1" != "" ]]; do
        case "$1" in
        -n | --remote-engine-name)
            shift
            REMOTE_ENGINE_NAME="$1"
            ;;
        -h | --help)
            print_usage
            exit 1
            ;;
        *)
            print_usage
            exit 1
            ;;
        esac
        shift
    done
}

function cleanup() {
    ACTION='cleanup'
    if [[ "$#" == 0 ]]; then
        print_usage
        exit 1
    fi

    # process options
    while [[ "$1" != "" ]]; do
        case "$1" in
        -n | --remote-engine-name)
            shift
            REMOTE_ENGINE_NAME="$1"
            ;;
        -a | --apikey)
            shift
            IAM_APIKEY="$1"
            ;;
        -d | --project-id)
            shift
            PROJECT_ID="$1"
            ;;
        --home)
            shift
            DATASTAGE_HOME="$1"
            ;;
        --platform)
            shift
            PLATFORM="$1"
            ;;
        -h | --help)
            print_usage
            exit 1
            ;;
        *)
            print_usage
            exit 1
            ;;
        esac
        shift
    done
}

#######################################################################
# script functions
#######################################################################

get_uname() {
    uname_out="$(uname -s)"
    case "${uname_out}" in
        Linux*)     OS_NAME=linux;;
        Darwin*)    OS_NAME=mac;;
        CYGWIN*)    OS_NAME=cygwin;;
        MINGW*)     OS_NAME=mingw;;
        *)          OS_NAME="unknown:${uname_out}"
    esac
}

print_header() {
    echo ""
    echo "${bold}$1${normal}"
}

custom_sed(){
    change_from=$1
    change_to=$2
    target_file=$3

    if [ "$OS_NAME" == "mac" ]; then
        sed -i '' "s|${change_from}|${change_to}|g" "${target_file}"
    else
        sed -i "s|${change_from}|${change_to}|g" "${target_file}"
    fi
}

echo_error_and_exit() {
    echo "ERROR: ${1}"
    exit 1
}

print_tool_name_version() {
    print_header "$TOOL_NAME ${TOOL_VERSION}"
}

#######################################################################
# docker functions
#######################################################################

check_docker_daemon() {
    if ! $DOCKER_CMD info > /dev/null 2>&1; then
        echo_error_and_exit "Docker daemon is not running, please start Docker before executing this script."
    fi
}

# docker login
docker_login() {
    echo ""
    [ -z $IAM_APIKEY_PROD ] && echo_error_and_exit "Please specify DataStage Container Registry IAM APIKey (-p | --prod-apikey). Aborting."
    DELAY=5
    until $DOCKER_CMD login -u iamapikey -p $IAM_APIKEY_PROD $ICR_REGISTRY  || [ $DELAY -eq 10 ]; do
        sleep $(( DELAY++ ))
    done
    status=$?
    if [ $status -ne 0 ]; then
        echo "docker login return code: $status."
        echo_error_and_exit "Aborting setup."
    fi
}

retrieve_latest_px_version() {
    echo "Getting IAM token to access Container Registry"
    get_cr_iam_token
    icr_response=$(curl -s -X GET -H "accept: application/json" -H "Account: d10b01a616ed4b73a9ac8a052424a345" -H "Authorization: Bearer $CR_IAM_TOKEN" --url "https://icr.io/api/v1/images?includeIBM=false&includePrivate=true&includeManifestLists=true&vulnerabilities=true&repository=${PXRUNTIME_IMAGE_NAME}")
    PX_VERSION=$(echo "${icr_response}" | jq '. |= sort_by(.Created) | .[length -1] | .RepoDigests[0]' | cut -d@ -f2 | tr -d '"')
    echo "Obtained digest=$PX_VERSION"
}

check_or_pull_image() {
    IMAGE_NAME=$1
    if [[ "$($DOCKER_CMD images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
        echo "Image ${IMAGE_NAME} does not exist locally, proceeding to download"
        docker_login
        echo "$DOCKER_CMD pull $IMAGE_NAME"
        $DOCKER_CMD pull $IMAGE_NAME
        if [ $status -ne 0 ]; then
            echo "docker pull run return code: $status."
            echo_error_and_exit "Could not download specified image, aborting script run."
        fi
    else
        echo "Image ${IMAGE_NAME} exists locally"
    fi
}


check_pxruntime_container_exists_and_running() {
    if [[ $( $DOCKER_CMD ps | grep "${PXRUNTIME_CONTAINER_NAME}" | wc -l ) -gt 0 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

check_pxruntime_container_exists() {
    if [[ $( $DOCKER_CMD ps -a | grep "${PXRUNTIME_CONTAINER_NAME}" | wc -l ) -gt 0 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

check_unused_port_forpxruntime() {
    echo "Checking open ports ..."
    PXRUNTIME_PORT='9443'
    for i in {3..103}; do
        if [[ $( netstat -an | grep -w $((9440 + ${i})) | grep LISTEN | wc -l ) -gt 0 ]]; then
            echo "Port $((9440 + ${i})) is not available, checking port $((9440 + ${i} + 1))"
        else
            PXRUNTIME_PORT="$((9440 + ${i}))"
            break
        fi
    done
    PXRUNTIME_VERSION_ENDPOINT="https://localhost:${PXRUNTIME_PORT}/v3/px_runtime/version"
    PXCOMPUTE_VERSION_ENDPOINT='https://localhost:9443/v3/px_runtime/version'
}

check_used_port_pxruntime() {
    if [ "$DOCKER_CMD" == "podman" ]; then
        PXRUNTIME_USED_PORTS=$($DOCKER_CMD inspect --format='{{range $p, $conf := .NetworkSettings.Ports}} {{(index $conf 0).HostPort}} {{end}}' ${PXRUNTIME_CONTAINER_NAME})
    else
        PXRUNTIME_USED_PORTS=$($DOCKER_CMD inspect --format='{{.Config.ExposedPorts}}' ${PXRUNTIME_CONTAINER_NAME})
    fi
    PXRUNTIME_PORT=$(echo ${PXRUNTIME_USED_PORTS} | grep -o "[0-9.]\+")
    echo "Found ${PXRUNTIME_CONTAINER_NAME} with port ${PXRUNTIME_PORT}"
    PXRUNTIME_VERSION_ENDPOINT="https://localhost:${PXRUNTIME_PORT}/v3/px_runtime/version"
    PXCOMPUTE_VERSION_ENDPOINT='https://localhost:9443/v3/px_runtime/version'
}

stop_px_runtime_docker() {
    echo "Stopping container '${PXRUNTIME_CONTAINER_NAME}' ..."
    $DOCKER_CMD stop ${PXRUNTIME_CONTAINER_NAME}

    if [[ $( $DOCKER_CMD ps | grep "${PXRUNTIME_CONTAINER_NAME}" | wc -l ) -gt 0 ]]; then
        # wait until docker is stopped
        until [[ $( $DOCKER_CMD ps | grep $PXRUNTIME_CONTAINER_NAME | wc -l ) -eq 0 ]]; do
            echo '  - Waiting for the container to stop'
            sleep 1
        done
    else
        echo "Container '${PXRUNTIME_CONTAINER_NAME}' is not running."
    fi
}

remove_px_runtime_docker() {
    echo "Removing container '${PXRUNTIME_CONTAINER_NAME}' ..."
    $DOCKER_CMD rm ${PXRUNTIME_CONTAINER_NAME}

    # wait until docker is stopped
    until [[ $( $DOCKER_CMD ps -a | grep $PXRUNTIME_CONTAINER_NAME | wc -l ) -eq 0 ]]; do
        echo '  - Waiting for the container to stop'
        sleep 1
    done
}

run_px_runtime_docker() {
    echo "Running container '${PXRUNTIME_CONTAINER_NAME}' ..."
    echo "Using port ${PXRUNTIME_PORT}"
    end_port_1=$(( 10000 + ${COMPUTE_COUNT} ))
    end_port_2=$(( 11000 + ${COMPUTE_COUNT} ))
    # -p 10000-${end_port_1}:10000-${end_port_1} -p 11000-${end_port_2}:11000-${end_port_2} -p 9443:9443 \

    runtime_docker_opts=(
        --detach
        -p ${PXRUNTIME_PORT}:9443
        --name ${PXRUNTIME_CONTAINER_NAME}
        --hostname="$(hostname)"
        --memory=${PX_MEMORY}
        --env COMPONENT_ID=ds-px-runtime
        --env ENVIRONMENT_TYPE=CLOUD
        --env ENVIRONMENT_NAME=${PLATFORM}
        --env ICP4D_URL=""
        --env REMOTE_ENGINE=yes
        --env USE_EXTERNAL_SERVICE=true
        --env WLP_SKIP_MAXPERMSIZE=true
        --env GATEWAY_URL=${GATEWAY_URL}
        --env IAM_URL=${IAM_URL}
        --env SERVICE_API_KEY=${IAM_APIKEY}
        --env REMOTE_ENGINE_NAME=${REMOTE_ENGINE_NAME}
        --env DSNEXT_SEC_KEY=${DSNEXT_SEC_KEY}
        --env IVSPEC=${IVSPEC}
        # --network=${PXRUNTIME_CONTAINER_NAME}
    )

    if [[ "${PLATFORM}" == 'icp4d' ]]; then
        runtime_docker_opts+=(
            --env WLMON=1
            --env WLM_CONTINUE_ON_COMMS_ERROR=0
            --env WLM_CONTINUE_ON_QUEUE_ERROR=0
            --env WLM_QUEUE_WAIT_TIMEOUT=0
            -v "${DS_STORAGE_HOST_DIR}":/ds-storage
            -v "${PX_STORAGE_HOST_DIR}":/px-storage
            -v "${SCRATCH_DIR}":/opt/ibm/PXService/Server/scratch
        )
    fi

    $DOCKER_CMD run "${runtime_docker_opts[@]}" $PXRUNTIME_DOCKER_IMAGE
    status=$?
    if [ $status -ne 0 ]; then
        echo "docker run return code: $status."
        echo_error_and_exit "Aborting script run."
    fi

    # wait until docker is in a running state - doesn't mean server has started
    until [[ $( $DOCKER_CMD ps -a | grep $PXRUNTIME_CONTAINER_NAME | wc -l ) -gt 0 ]]; do
        sleep 1
    done
}

start_px_runtime_docker() {
    echo "Starting container '${PXRUNTIME_CONTAINER_NAME}' ..."
    $DOCKER_CMD start ${PXRUNTIME_CONTAINER_NAME}

    # check and set the port
    sleep 2
    PXRUNTIME_PORT=$($DOCKER_CMD container ls --format "table {{.Names}}\t{{.Ports}}" | grep ${PXRUNTIME_CONTAINER_NAME} | sed -e 's/.*:\(.*\)->.*/\1/')
    echo "Container ${PXRUNTIME_CONTAINER_NAME} is using port ${PXRUNTIME_PORT}"
}

wait_readiness_px_runtime()
{
    TOTAL_RETRIES=49
    WAIT_DURATION=5
    ret=1
    count=0

    export CURL_SSL_BACKEND="secure-transport"
    while (true); do
        count=$(( $count + 1 ))
        echo "  waiting for ${PXRUNTIME_CONTAINER_NAME} to start... time elapsed: $(( $count * $WAIT_DURATION )) seconds"
        curl -ks -o /dev/null $PXRUNTIME_VERSION_ENDPOINT
        ret=$?
        if [ ${ret} -eq 0 ]; then
            while (true); do
                count=$(( $count + 1 ))
                sleep 5
                echo "  waiting for ${PXRUNTIME_CONTAINER_NAME} to start ... time elapsed: $(( $count * $WAIT_DURATION )) seconds"
                if curl -ks $PXRUNTIME_VERSION_ENDPOINT | grep -q '"status":"ok"'; then
                    curl -k $PXRUNTIME_VERSION_ENDPOINT
                    echo ""
                    echo "Started container ${PXRUNTIME_CONTAINER_NAME} in $(( $count * $WAIT_DURATION )) seconds"
                    break;
                elif [ ${ret} -ne 0 ] && [ ${count} -gt $TOTAL_RETRIES ]; then
                    echo_error_and_exit "Could not start container ${PXRUNTIME_CONTAINER_NAME} in $(( $count * $WAIT_DURATION )) seconds, aborting."
                fi
            done
            if curl -ks $PXRUNTIME_VERSION_ENDPOINT | grep -q '"status":"ok"'; then
                break;
            fi
        elif [ ${ret} -ne 0 ] && [ ${count} -lt $TOTAL_RETRIES ]; then
            sleep $WAIT_DURATION
        elif [ ${ret} -ne 0 ] && [ ${count} -gt $TOTAL_RETRIES ]; then
            echo_error_and_exit "Could not start container ${PXRUNTIME_CONTAINER_NAME} in $(( $count * $WAIT_DURATION )) seconds, aborting."
        fi
    done
}

stop_px_compute_docker() {
    echo "Stopping container '${PXCOMPUTE_CONTAINER_NAME}' ..."
    $DOCKER_CMD stop ${PXCOMPUTE_CONTAINER_NAME}

    # wait until docker is stopped
    until [[ $( $DOCKER_CMD ps | grep $PXCOMPUTE_CONTAINER_NAME | wc -l ) -eq 0 ]]; do
        echo '  - Waiting for the container to stop'
        sleep 1
    done
}

remove_px_compute_docker() {
    echo "Stopping container '${PXCOMPUTE_CONTAINER_NAME}' ..."
    $DOCKER_CMD stop ${PXCOMPUTE_CONTAINER_NAME}

    # wait until docker is stopped
    until [[ $( $DOCKER_CMD ps -a | grep $PXCOMPUTE_CONTAINER_NAME | wc -l ) -eq 0 ]]; do
        echo '  - Waiting for the container to stop'
        sleep 1
    done
}

run_px_compute() {
    CONTAINER_NAME=$1
    PORT1=$2
    echo "Starting container '${CONTAINER_NAME}' ..."
    compute_docker_opts=(
        --detach
        -p ${PORT1}:13502 \
        --hostname=`hostname` \
        --name ${CONTAINER_NAME}
        --env APT_ORCHHOME=/opt/ibm/PXService/Server/PXEngine
        --env DSHOME=/opt/ibm/PXService/Server/DSEngine
        --env ENVIRONMENT_NAME=${PLATFORM}
        --env HOME=/tmp
        --env JAVA_HOME=/opt/java
        --env JAVA_TOOL_OPTIONS=-XX:+IgnoreUnrecognizedVMOptions -XX:+UseContainerSupport -XX:+IdleTuningCompactOnIdle -XX:+IdleTuningGcOnIdle
        --env LD_LIBRARY_PATH=/opt/ibm/PXService/ASBNode/lib/cpp:/opt/ibm/PXService/Server/PXEngine/lib:/opt/ibm/PXService/Server/DSComponents/bin:/opt/ibm/PXService/Server/DSComponents/lib:/opt/ibm/PXService/Server/branded_odbc/lib:/opt/ibm/PXService/NetezzaClient/lib64:/opt/java/lib/j9vm:/opt/java/lib:/home/dsuser/sqllib/lib64:/home/dsuser/sqllib/lib64/icc:/home/dsuser/mq/lib64:
        --env NZ_ODBC_INI_PATH=/opt/ibm/PXService/Server/DSEngine
        --env ODBCINI=/opt/ibm/PXService/Server/DSEngine/odbc.ini
        --env PATH=/opt/ibm/PXService/Server/PXEngine/bin:/opt/java/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        --env USER_HOME=/user-home
        --env HOSTNAME=ds-px-compute-$i
        # --network=${PXRUNTIME_CONTAINER_NAME}
    )
    if [[ "${PLATFORM}" == 'icp4d' ]]; then
        compute_docker_opts+=(
            --env WLMON=1
            --env WLM_CONTINUE_ON_COMMS_ERROR=0
            --env WLM_CONTINUE_ON_QUEUE_ERROR=0
            --env WLM_QUEUE_WAIT_TIMEOUT=0
            -v "${DS_STORAGE_HOST_DIR}":/ds-storage
            -v "${PX_STORAGE_HOST_DIR}":/px-storage
        )
    fi
    $DOCKER_CMD run "${compute_docker_opts[@]}"  $PXCOMPUTE_DOCKER_IMAGE
    status=$?
    if [ $status -ne 0 ]; then
        echo "docker run return code: $status."
        echo_error_and_exit "Aborting script run."
    fi

    # wait until docker is in a running state - doesn't mean server has started
    until [[ $( $DOCKER_CMD ps -a | grep ${CONTAINER_NAME} | wc -l ) -gt 0 ]]; do
        sleep 1
    done
}

wait_readiness_px_compute() {
    TOTAL_RETRIES=4
    WAIT_DURATION=1
    count=0
    CONTAINER_NAME=$1
    while (true); do
        count=$(( $count + 1 ))
        echo "  waiting for ${CONTAINER_NAME} to start ... time elapsed: $(( $count * $WAIT_DURATION )) seconds"
        TCP_CONNECTIONS=$($DOCKER_CMD exec -it ${CONTAINER_NAME} cat /proc/`ps -ef | grep PXRemoteApp | grep -v grep | awk '{ print $2 }'`/net/tcp | grep 34BE)
        if [ ! -z "$TCP_CONNECTIONS" ]; then
            echo ""
            $DOCKER_CMD exec -it ${CONTAINER_NAME} cat /proc/`ps -ef | grep PXRemoteApp | grep -v grep | awk '{ print $2 }'`/net/tcp | grep 34BE
            echo "Started container ${CONTAINER_NAME} in $(( $count * $WAIT_DURATION )) seconds"
            break
        elif [ ${count} -gt $TOTAL_RETRIES ]; then
            echo "Warning - could not verify java remote app on ${CONTAINER_NAME}"
            break
            # echo_error_and_exit "Could not start container ${CONTAINER_NAME} in $(( $count * $WAIT_DURATION )) seconds, aborting."
        fi
        sleep 5
    done

}

initialize_docker_network() {
    echo "Setting up docker network"
    $DOCKER_CMD network inspect ${PXRUNTIME_CONTAINER_NAME} >/dev/null 2>&1 || $DOCKER_CMD network create -d bridge ${PXRUNTIME_CONTAINER_NAME}
}

#######################################################################
# IBM Cloud functions
#######################################################################

get_iam_token() {

    IAM_URL="${IAM_URL%/}"
    IAM_URL="${IAM_URL}/identity/token"

    _iam_response=$(curl -sS -X POST \
                -H 'Content-Type: application/x-www-form-urlencoded' \
                -H 'Accept: application/json' \
                --data-urlencode 'grant_type=urn:ibm:params:oauth:grant-type:apikey' \
                --data-urlencode "apikey=${IAM_APIKEY}" \
                "${IAM_URL}")
    IAM_TOKEN=$(printf "%s" ${_iam_response} | jq -r .access_token | tr -d '"')

    if [[ -z "${IAM_TOKEN}" || "${IAM_TOKEN}" == "null" ]]; then
        echo ""
        if [[ "$_iam_response" ]]; then
            echo "Response = ${_iam_response}"
        fi
        echo_error_and_exit "Failed to get IAM Token, please try again ..."
    fi
}

get_cr_iam_token() {
    _iam_response=$(curl -sS -X POST \
                -H 'Content-Type: application/x-www-form-urlencoded' \
                -H 'Accept: application/json' \
                --data-urlencode 'grant_type=urn:ibm:params:oauth:grant-type:apikey' \
                --data-urlencode "apikey=${IAM_APIKEY_PROD}" \
                'https://iam.cloud.ibm.com/identity/token')
    CR_IAM_TOKEN=$(printf "%s" ${_iam_response} | jq -r .access_token | tr -d '"')

    if [[ -z "${CR_IAM_TOKEN}" || "${CR_IAM_TOKEN}" == "null" ]]; then
        echo ""
        if [[ "$_iam_response" ]]; then
            echo "Response = ${_iam_response}"
        fi
        echo_error_and_exit "Failed to get IAM Token for CR, please try again ..."
    fi
}

get_bss_id_from_token() {
    _token=$1

    # base64 seems to spit out some error message on stderr but it works anyway
    _token=`echo ${_token} | cut -f2 -d"." | base64 -d 2>/dev/null`
    _bss_id=`echo $_token | ${JQ} -j '.account.bss'`
    echo ${_bss_id}
}

#######################################################################
# DataStage functions
#######################################################################

# -----------------------------
# Runtime
# -----------------------------

get_remote_engine_id() {
    _engine_register_response=$(curl -sS -X 'GET' "${GATEWAY_URL}/data_intg/v3/flows_runtime/remote_engine/register?type=singular" \
        -H 'accept: application/json;charset=utf-8' \
        -H "Authorization: Bearer $IAM_TOKEN")

    # handle multple values
    REMOTE_ENGINE_ID=$(printf "%s" "${_engine_register_response}" \
        | jq "[.[] | select(.display_name==\"${REMOTE_ENGINE_NAME}\")][0]" | jq '.id' | tr -d '"')

    if [[ ${REMOTE_ENGINE_ID} =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]; then
        echo "Got remote engine '${REMOTE_ENGINE_NAME}' registration with id: ${REMOTE_ENGINE_ID}"
    else
        echo ""
        echo "Response: ${_engine_register_response}"
        echo_error_and_exit "Could not get remote engine registration id."
    fi
    sleep 10
}

remove_remote_engine () {
    _engine_delete_response=$(curl -sS -X 'DELETE' "${GATEWAY_URL}/data_intg/v3/flows_runtime/remote_engine/register?engine_id=${REMOTE_ENGINE_ID}" \
        -H 'accept: */*' \
        -H "Authorization: Bearer $IAM_TOKEN")
    echo "Deleted remote engine with id: ${REMOTE_ENGINE_ID}"
}

# -----------------------------
# Assets
# -----------------------------

update_datastage_settings() {
    _datastage_settings_get_response=$(curl -sS -X 'GET' "${GATEWAY_URL}/data_intg/v3/assets/datastage_settings?project_id=${PROJECT_ID}" \
        -H 'accept: application/json' \
        -H "Authorization: Bearer $IAM_TOKEN")

    if [[ -z "${_datastage_settings_get_response}" || "${_datastage_settings_get_response}" == "null" ]]; then
        echo ""
        echo "Response: ${_datastage_settings_get_response}"
        echo_error_and_exit "Failed to get DataStage Settings, please try again"
    fi

    # is there any project env already present with this remote engine. There could be multiple envs with the same remote engine id, so select the first one
    DATASTAGE_SETTINGS_ASSET_ID=$(printf "%s" "${_datastage_settings_get_response}" | jq -r .metadata.asset_id | tr -d '"')
    if [[ ${DATASTAGE_SETTINGS_ASSET_ID} =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]; then
        echo "DataStage Settings asset id: ${DATASTAGE_SETTINGS_ASSET_ID}"
        echo ""
    fi

    payload="{
      \"project\": {
          \"runEnvironmentIds\": [\"${PROJECT_ENV_ASSET_ID}\"],
          \"runRemoteEngineEnforcement\": true
       }
    }"

    if [[ ${ACTION} == "cleanup" ]]; then
        payload="{
          \"project\": {
              \"runEnvironmentIds\": [],
              \"runRemoteEngineEnforcement\": false
           }
        }"
    fi

    _datastage_settings_put_response=$(curl -s -X PUT "${GATEWAY_URL}/data_intg/v3/assets/datastage_settings/${DATASTAGE_SETTINGS_ASSET_ID}?project_id=${PROJECT_ID}" \
    --header "Authorization: Bearer $IAM_TOKEN" \
    --header 'Content-Type: application/json' \
    --data-raw "$payload")

    if [[ -z "${_datastage_settings_put_response}" || "${_datastage_settings_put_response}" == "null" ]]; then
        echo ""
        echo "Response: ${_datastage_settings_put_response}"
        echo_error_and_exit "Failed to update DataStage settings, please try again"
    fi

    if [[ ${ACTION} == "start" ]]; then
        DATASTAGE_SETTINGS_RUN_ENVIRONMENT_IDS=$(printf "%s" "${_datastage_settings_put_response}" | jq -r .entity.project.runEnvironmentIds[])
        if [[ -z "${DATASTAGE_SETTINGS_RUN_ENVIRONMENT_IDS}" || "${DATASTAGE_SETTINGS_RUN_ENVIRONMENT_IDS}" == "null" ]]; then
            echo ""
            echo "Response: ${_datastage_settings_put_response}"
            echo "WARNING: could not find the Runtime Environment ID in DataStage Settings, please check in the UI"
        else
            echo "DataStage Settings updated to use runEnvironmentIds: ${PROJECT_ENV_ASSET_ID}"
        fi
    fi
}

reset_datastage_settings() {
    update_datastage_settings
}

# -----------------------------
# Environments
# -----------------------------

get_environment_id() {
    _project_env_get_response=$(curl -sS -X 'GET' "${GATEWAY_URL}/v2/environments?project_id=${PROJECT_ID}" \
        -H 'accept: application/json' \
        -H "Authorization: Bearer $IAM_TOKEN")

    if [[ -z "${_project_env_get_response}" || "${_project_env_get_response}" == "null" ]]; then
        echo ""
        echo "Response: ${_project_env_get_response}"
        echo_error_and_exit "Failed to get Project Environment list, please try again"
    fi

    # is there any project env already present with this remote engine. There could be multiple envs with the same remote engine id, so select the first one
    PROJECT_ENV_ASSET_ID=$(printf "%s" "${_project_env_get_response}" | jq -r "[.resources | .[] | select(.entity.environment.environment_variables.REMOTE_ENGINE==\"${REMOTE_ENGINE_ID}\") | .metadata.asset_id][0]" | tr -d '"')
    if [[ ${PROJECT_ENV_ASSET_ID} =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]; then
        # echo "Got project environment with id: ${PROJECT_ENV_ASSET_ID}"
        echo ""
    fi
    # dont else and exit from here, since in a regular start, we simply if env with this remote engine is
    # present else we create a new one
}


create_environment() {
    _project_env_create_response=$(curl -sS -X 'POST' "${GATEWAY_URL}/v2/environments?project_id=${PROJECT_ID}" \
        -H 'accept: application/json' \
        -H "Authorization: Bearer $IAM_TOKEN" \
        -H 'Content-Type: application/json' \
        -d "{
  \"name\": \"${REMOTE_ENGINE_NAME}\",
  \"description\": \"DataStage Remote Engine ${REMOTE_ENGINE_NAME}\",
  \"display_name\": \"${REMOTE_ENGINE_NAME}\",
  \"type\": \"datastage\",
  \"hardware_specification\": {
    \"datastage\": {
      \"num_conductors\": 1,
      \"num_computes\": 0,
      \"conductor\": {
        \"cpu\": {
          \"units\": \"1\",
          \"model\": \"\"
        },
        \"mem\": {
          \"size\": \"4Gi\"
        }
      },
      \"compute\": {
        \"cpu\": {
          \"units\": \"1\",
          \"model\": \"\"
        },
        \"mem\": {
          \"size\": \"4Gi\"
        }
      }
    }
  },
  \"tools_specification\": {
    \"runtime_root_folder\": \"/DataStage/\"
  },
  \"software_specification\": {

  },
  \"environment_variables\": {
    \"REMOTE_ENGINE\": \"${REMOTE_ENGINE_ID}\"
  }
}"
        )

    PROJECT_ENV_ASSET_ID=$(printf "%s" "${_project_env_create_response}" | jq '.metadata.asset_id' | tr -d '"')
    if [[ -z "${PROJECT_ENV_ASSET_ID}" || "${PROJECT_ENV_ASSET_ID}" == "null" ]]; then
        echo ""
        if [[ "$_project_env_create_response" ]]; then
            echo "Response = ${_project_env_create_response}"
        fi
        echo_error_and_exit "Failed to create environment in Project, please try again"
    fi

    if [[ ${PROJECT_ENV_ASSET_ID} =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]; then
        # echo "Got project environment with id: ${PROJECT_ENV_ASSET_ID}"
        true
    else
        echo ""
        echo "Response: ${_project_env_get_response}"
        echo_error_and_exit "Could not create an environment with this remote engine, or failed to check project environment status."
    fi
    echo "Created environment runtime with id: ${PROJECT_ENV_ASSET_ID}"
}

remove_environment() {
    _project_env_delete_response=$(curl -sS -X 'DELETE' "${GATEWAY_URL}/v2/environments/${PROJECT_ENV_ASSET_ID}?project_id=${PROJECT_ID}" \
        -H 'accept: */*' \
        -H "Authorization: Bearer $IAM_TOKEN")
    echo "Deleted environment runtime with id: ${PROJECT_ENV_ASSET_ID}"
}

#######################################################################
# Validation functions
#######################################################################

check_datastage_home() {
    if [[ "$DATASTAGE_HOME" == *"${GATEWAY_DOMAIN_YS1DEV}" ]]; then
        GATEWAY_URL='https://api.dataplatform.dev.cloud.ibm.com'
        IAM_URL='https://iam.test.cloud.ibm.com'

    elif [[ "$DATASTAGE_HOME" == *"${GATEWAY_DOMAIN_YPQA}" ]]; then
        GATEWAY_URL='https://api.dataplatform.test.cloud.ibm.com'

    elif [[ "$DATASTAGE_HOME" == *"${GATEWAY_DOMAIN_YPPROD}" ]]; then
        GATEWAY_URL='https://api.dataplatform.cloud.ibm.com'

    elif [[ "$DATASTAGE_HOME" == *"${GATEWAY_DOMAIN_FRPROD}" ]]; then
        GATEWAY_URL='https://${GATEWAY_DOMAIN_FRPROD}'

    else
        echo_error_and_exit "Incorrect value specified: '--home ${DATASTAGE_HOME}', aborting. Use one of the allowed values:
        - https://api.dataplatform.dev.cloud.ibm.com
        - https://api.dataplatform.test.cloud.ibm.com
        - https://api.dataplatform.cloud.ibm.com (default)
        - https://api.eu-de.dataplatform.cloud.ibm.com"
    fi

}

check_platform() {
    if [[ "$PLATFORM" != 'cloud' && "$PLATFORM" != 'icp4d' ]]; then
        echo_error_and_exit "Incorrect value specified: '--platform ${PLATFORM}', aborting. Use one of the allowed values:
        - cloud (default)
        - icp4d"
    fi
}

validate_action_arguments() {
    if [[ "${ACTION}" == 'start' || "${ACTION}" == 'cleanup' ]]; then
        [ -z $IAM_APIKEY ] && echo_error_and_exit "Please specify an IBM Cloud IAM APIKey (-a | --apikey) for the respective environment. Aborting."
    fi

    if [[ "${ACTION}" == 'start' ]]; then
        [ -z $DSNEXT_SEC_KEY ] && echo_error_and_exit "Please specify an encryption key (-e | --encryption-key. Aborting."
        [ -z $IVSPEC ] && echo_error_and_exit "Please specify the initialization vector for the encryption key (-i | --ivspec). Aborting."
        [ -z $PROJECT_ID ] && echo_error_and_exit "Please specify the project ID in which you want to create the Remote Engine environment (-p | --prod-apikey). Aborting."
    fi

    # needed for all options
    [ -z $REMOTE_ENGINE_NAME ] && echo_error_and_exit "Please specify a name for the Remote Engine instance (-n | --remote-engine-name). Aborting."

    # validate values of choice arguments
    check_datastage_home
    check_platform

    # If everything is available, make sure docker daemon is running before proceeding
    check_docker_daemon

    # print in the console
    echo "DATASTAGE_HOME=${DATASTAGE_HOME}"
    echo "GATEWAY_URL=${GATEWAY_URL}"
    echo "PROJECT_ID=${PROJECT_ID}"
    echo "REMOTE_ENGINE_PREFIX=${REMOTE_ENGINE_NAME}"
    echo "CONTAINER_MEMORY=${PX_MEMORY}"
    echo "DOCKER_VOLUMES_DIR=${DOCKER_VOLUMES_DIR}"
    echo ""

    # finalize constants if all arguments are valid
    PXRUNTIME_CONTAINER_NAME="${REMOTE_ENGINE_NAME//[ ]/_}_runtime"
    PXCOMPUTE_CONTAINER_NAME="${REMOTE_ENGINE_NAME//[ ]/_}_compute"
    echo "REMOTE_ENGINE_VERSION=${PX_VERSION}"

    update_docker_volume_permissions
}

update_docker_volume_permissions() {

    if [[ "${PLATFORM}" == 'icp4d' ]]; then
        DS_STORAGE_HOST_DIR="${DOCKER_VOLUMES_DIR}/ds-storage"
        PX_STORAGE_HOST_DIR="${DOCKER_VOLUMES_DIR}/${PXRUNTIME_CONTAINER_NAME}/px-storage"
        SCRATCH_DIR="${DOCKER_VOLUMES_DIR}/scratch"

        if [[ "${ACTION}" == 'start' ]]; then
            echo "Setting ICP4D specific variables ..."
            if [ ! -d "${DS_STORAGE_HOST_DIR}" ]; then
              echo "${DS_STORAGE_HOST_DIR} does not exist, creating ..."
              mkdir -p "${DS_STORAGE_HOST_DIR}"
            fi
            if [ ! -d "${PX_STORAGE_HOST_DIR}" ]; then
              echo "${PX_STORAGE_HOST_DIR} does not exist, creating ..."
              mkdir -p "${PX_STORAGE_HOST_DIR}"
            fi
            chmod -R 777 "${DOCKER_VOLUMES_DIR}"
        fi
    fi

}

#######################################################################
# main
#######################################################################
get_uname
main "$@";

print_tool_name_version
echo ""

validate_action_arguments

if [[ ${ACTION} == "start" ]]; then

    # check if this container is present and running. If so then exit with a prompt
    echo "Checking for existing container '${PXRUNTIME_CONTAINER_NAME}'"
    if [[ $(check_pxruntime_container_exists_and_running) == "true" ]]; then
        echo_error_and_exit "Container '${PXRUNTIME_CONTAINER_NAME}' is already running. Aborting."
    fi


    # check if this container is present but not running. Restart the container
    if [[ $(check_pxruntime_container_exists) == "true" ]]; then
        check_used_port_pxruntime
        start_px_runtime_docker
        wait_readiness_px_runtime

        echo ""
        echo "Runtime Environment 'Remote Engine ${REMOTE_ENGINE_NAME}' is available, and can be used to run DataStage flows"

        exit 0
    fi

    # check if the runtime image exists, if not, then download
    print_header "Checking docker images ..."
    if [[ "${PX_VERSION}" == 'latest' ]]; then
        retrieve_latest_px_version
    fi
    # update the image variables to use the PX_VERSION version
    if [[ "$string" == "latest" || "$string" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        PXRUNTIME_DOCKER_IMAGE="${ICR_REGISTRY}/ds-px-runtime:${PX_VERSION}"
        PXCOMPUTE_DOCKER_IMAGE="${ICR_REGISTRY}/ds-px-compute:${PX_VERSION}"
    else
        PXRUNTIME_DOCKER_IMAGE="${ICR_REGISTRY}/ds-px-runtime@${PX_VERSION}"
        PXCOMPUTE_DOCKER_IMAGE="${ICR_REGISTRY}/ds-px-compute@${PX_VERSION}"
    fi
    check_or_pull_image $PXRUNTIME_DOCKER_IMAGE
    # check_or_pull_image $PXCOMPUTE_DOCKER_IMAGE
    print_header "Initializing ${TOOL_SHORTNAME} Runtime environment with name '${REMOTE_ENGINE_NAME}' ..."
    echo "Setting up docker environment"
    check_unused_port_forpxruntime

    # initialize_docker_network

    # docker run
    # ---------------------
    TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
    print_header "Starting instance '${REMOTE_ENGINE_NAME}' ..."
    run_px_runtime_docker
    wait_readiness_px_runtime


    # datastage api calls
    # ---------------------

    print_header "Finalizing Remote Engine instance '${REMOTE_ENGINE_NAME}'..."

    echo "Getting IAM token"
    get_iam_token

    echo "Confirming Remote Engine registration ..."
    get_remote_engine_id

    print_header "Setting up Runtime environment using Remote Engine '${REMOTE_ENGINE_NAME}' ..."
    echo "Checking if runtime environment with REMOTE_ENGINE=${REMOTE_ENGINE_ID} is available ..."
    get_environment_id
    if [[ -z "${PROJECT_ENV_ASSET_ID}" || "${PROJECT_ENV_ASSET_ID}" == "null" ]]; then
        echo "Could not find an existing environment with REMOTE_ENGINE=${REMOTE_ENGINE_ID}, creating a new one ..."
        create_environment
    else
        echo "Found existing environment with REMOTE_ENGINE=${REMOTE_ENGINE_ID} with id: ${PROJECT_ENV_ASSET_ID}"
    fi
    echo "Runtime Environment 'Remote Engine ${REMOTE_ENGINE_NAME}' is registered."

    echo "Updating the project to use ${REMOTE_ENGINE_NAME} as the default environment"
    update_docker_volume_permissions
    update_datastage_settings
    echo "Remote Engine docker setup is complete"

    PROJECTS_LINK="${DATASTAGE_HOME}/projects/${PROJECT_ID}"
    echo ""
    echo "Remote Engine setup is complete."
    echo ""
    echo "Project environments:"
    echo "* ${PROJECTS_LINK}/manage/environments/templates?context=cpdaas"
    echo ""
    echo "Project settings:"
    echo "* ${PROJECTS_LINK}/manage/tool-configurations/datastage_admin_settings_section?context=cpdaas"
    echo ""
    echo "Project assets:"
    echo "* ${PROJECTS_LINK}/assets?context=cpdaas"

    # echo ""
    # echo "${bold}Starting ${TOOL_SHORTNAME} Compute ...${normal}"
    # COMPUTE_PORT=13502
    # for i in $(seq 0 ${COMPUTE_COUNT}); do
    #     CONTAINER_NAME="${PXCOMPUTE_CONTAINER_NAME}-${i}"
    #     cleanup_container "${CONTAINER_NAME}"
    #     run_px_compute "${CONTAINER_NAME}" ${COMPUTE_PORT}
    #     wait_readiness_px_compute "${CONTAINER_NAME}"
    #     COMPUTE_PORT=$(( COMPUTE_PORT + 1 ))
    # done

    # use remote_engine/register GET call to confirm the registration
    # User environtes/create POST call to create an env with the REMOTE_ENGINE from the GET call
    # Job https://api.dataplatform.dev.cloud.ibm.com/v2/jobs/docs/swagger/#/Jobs/jobs_create POST, with env_id from POST CALL response
    # Run Job https://api.dataplatform.dev.cloud.ibm.com/v2/jobs/docs/swagger/#/Job%20Runs


    # echo ""
    # echo "${bold}Running rowgen peek ...${normal}"
    # echo ""
    # docker exec -it ds-px-runtime osh -f /tests/rowgen_peek.txt

elif [[ ${ACTION} == "stop" ]]; then

    stop_px_runtime_docker
    remove_px_runtime_docker

elif [[ ${ACTION} == "restart" ]]; then

    # stop the docker container
    # --------------------------
    echo "Checking for existing container '${PXRUNTIME_CONTAINER_NAME}'"
    if [[ $(check_pxruntime_container_exists_and_running) == "true" ]]; then
        echo ""
        stop_px_runtime_docker
    fi

    echo ""
    check_used_port_pxruntime
    start_px_runtime_docker
    wait_readiness_px_runtime

    echo ""
    echo "Runtime Environment 'Remote Engine ${REMOTE_ENGINE_NAME}' is available, and can be used to run DataStage flows"

elif [[ ${ACTION} == "cleanup" ]]; then

    stop_px_runtime_docker
    remove_px_runtime_docker
    # stop_px_compute_docker

    print_header "Cleaning Remote Engine '${REMOTE_ENGINE_NAME}'..."

    echo "Getting IAM token"
    get_iam_token

    echo "Getting Remote Engine ID ..."
    get_remote_engine_id
    echo "Getting Project Environment Engine ID ..."
    get_environment_id

    echo "Removing Remote Engine registration ..."
    remove_remote_engine

    echo "Removing Runtime associated with the remote Engine ..."
    remove_environment

    echo "Resetting DataStage settings"
    reset_datastage_settings

    if [[ "${PLATFORM}" == 'icp4d' ]]; then
        if [ -d "$directory" ]; then
            echo "Removing ${DOCKER_VOLUMES_DIR}/${PXRUNTIME_CONTAINER_NAME}"
            rm -rf "${DOCKER_VOLUMES_DIR}/${PXRUNTIME_CONTAINER_NAME}"
        fi
    fi
fi

echo ""
echo "--- Done ---"
