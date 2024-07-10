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
TOOL_VERSION=0.0.3
TOOL_NAME='IBM DataStage Remote Engine'
TOOL_SHORTNAME='DataStage Remote Engine'

# image information
DOCKER_REGISTRY='icr.io/datastage'
PX_VERSION='latest'
SELECT_PX_VERSION='false'

# container names
PXRUNTIME_IMAGE_NAME='ds-px-runtime'
PXCOMPUTE_IMAGE_NAME='ds-px-compute'

# Docker command
DOCKER_CMD='docker'
if ! [ -x "$(command -v docker)" ] && [ -x "$(command -v podman)" ]; then
    DOCKER_CMD='podman'
fi
DOCKER_VOLUMES_DIR='/tmp/docker/volumes'
MOUNT_DIRS=()
SCRATCH_DIR_OVERRIDE='false'
PROJECT_ID='None'

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
PX_CPUS='2'
PX_MEMORY_OVERRIDE='0g'
PX_CPUS_OVERRIDE='0'
COMPUTE_COUNT=0
CONTAINER_USER='NOT_SET'

bold=$(tput bold)
normal=$(tput sgr0)

STR_ENGINE_NAME='  -n, --remote-engine-name    Name of the remote engine instance'
STR_IAM_APIKEY='  -a, --apikey                IBM Cloud APIKey for the selected home argument'
STR_PROD_APIKEY='  -p, --prod-apikey           IBM Cloud Production APIKey for image download from DataStage Container registry. It can be requested via IBM Cloud Support: https://cloud.ibm.com/unifiedsupport'
STR_DSNEXT_SEC_KEY='  -e, --encryption key        Encryption key to be used'
STR_IVSPEC='  -i, --ivspec                Initialization vector'
STR_PROJECT_UID='  -d, --project-id            DataPlatform Project ID'
STR_DSTAGE_HOME='  --home                      Select IBM DataStage Cloud datacenter: [ypprod (default), frprod]'
STR_VOLUMES="  --volume-dir                Specify a directory for datastage persistent storage. Default location is ${DOCKER_VOLUMES_DIR}"
STR_MOUNT_DIR="  --mount-dir                 Mount a directory. This flag can be specified multiple times."
STR_SELECT_PX_VERSION='  --select-version            [true | false]. Select the remote engine version to use from a list of given choices (default is false).'
STR_SET_USER='  --set-user                  Specify the username to be used to run the container. If not set, the current user is used.'
# STR_PLATFORM='  --platform                  Platform to executed against: [cloud (default), icp4d]'
# STR_VERSION='  --version                   Version of the remote engine to use'
STR_MEMORY='  --memory                    Specify memory allocated to the docker container (default is 4G).'
STR_CPUS='  --cpus                      Specify CPU allocated to the docker container (default is 2 cores).'
STR_MEMORY_UPDATE='  --memory                    Update memory allocated to the docker container. Needs Project ID to be specified (-d | --project-id)'
STR_CPUS_UPDATE='  --cpus                      Update CPU allocated to the docker container. Needs Project ID to be specified (-d | --project-id)'
STR_USE_ENT_KEY='  --use-entitlement-key       [true | false]. Use entitlement key obtained from https://myibm.ibm.com to download the images, else use a container registry apikey (default is false).'
STR_HELP='  help, --help                Print usage information'


#######################################################################
# cli functions
#######################################################################

help_header() {
    script_name=$(basename "${0}")
    print_tool_name_version
    echo "This tool manages manages IBM DataStage remote engine instances."
    echo "Find more information at: https://github.com/IBM/DataStage/blob/main/RemoteEngine"
    echo ""
}

ACTION='None'

print_help() {
    script_name=$(basename "${0}")
    help_header
    echo "${bold}usage:${normal} ${script_name} <command> [<args>]"
    echo ""
    echo "${bold}commands:${normal}"
    echo "    start           start a remote engine instance"
    echo "    stop            stop a remote engine instance"
    echo "    update          update a remote engine instance"
    echo "    cleanup         cleanup a remote engine instance"
    echo "    help, --help    Print usage information"
    echo ""
}

function main(){
    if (( "${#}" == 0 )); then
        print_help 0;
        exit 1
    fi

    if [[ "${1}" == 'help' || "${1}" == '--help' ]]; then
        print_help 0;
        exit 1
    fi

    case ${1} in
        start | stop | update | cleanup | help)
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
        echo -e "${bold}usage:${normal} ${script_name} start [-n | --remote-engine-name] [-a | --apikey] [-p | --prod-apikey] [-e | --encryption-key] \n                         [-i | --ivspec] [-d | --project-id] [--home] [--memory] [--cpus] [--volume-dir]\n                         [--select-version] [--set-user] [--help]"
    elif [[ "${ACTION}" == 'update' ]]; then
        echo -e "${bold}usage:${normal} ${script_name} update [-n | --remote-engine-name] [-p | --prod-apikey] [--select-version] \n                          [--memory] [--cpus] [-d | --project-id] [--help]"
    elif [[ "${ACTION}" == 'stop' ]]; then
        echo "${bold}usage:${normal} ${script_name} stop [-n | --remote-engine-name]"
    elif [[ "${ACTION}" == 'cleanup' ]]; then
        echo "${bold}usage:${normal} ${script_name} cleanup [-n | --remote-engine-name] [-a | --apikey] [-d | --project-id] [--home]"
    elif [[ "${ACTION}" == 'help' ]]; then
        print_help 1;
        exit 1;
    fi

    echo ""
    echo "${bold}options:${normal}"
    echo "${STR_ENGINE_NAME}"

    if [[ "${ACTION}" == 'start' || "${ACTION}" == 'cleanup' ]]; then
        echo "${STR_IAM_APIKEY}"
    fi

    if [[ "${ACTION}" == 'start' || "${ACTION}" == 'update' ]]; then
        echo "${STR_PROD_APIKEY}"
        if [[ "${ACTION}" == 'start' ]]; then
            echo "${STR_DSNEXT_SEC_KEY}"
            echo "${STR_IVSPEC}"
        fi
    fi

    if [[ "${ACTION}" == 'start' ||  "${ACTION}" == 'update' || "${ACTION}" == 'cleanup' ]]; then
        echo "${STR_PROJECT_UID}"
        echo "${STR_DSTAGE_HOME}"
    fi

    if [[ "${ACTION}" == 'start' || "${ACTION}" == 'update' ]]; then
        if [[ "${ACTION}" == 'start' ]]; then
            echo "${STR_MEMORY}"
            echo "${STR_CPUS}"
            echo "${STR_VOLUMES}"
            echo "${STR_MOUNT_DIR}"
            echo "${STR_SET_USER}"
        elif [[ "${ACTION}" == 'update' ]]; then
            echo "${STR_MEMORY_UPDATE}"
            echo "${STR_CPUS_UPDATE}"
        fi
        echo "${STR_SELECT_PX_VERSION}"
        # echo "${STR_USE_ENT_KEY}"
        # echo "${STR_PLATFORM}"
    fi

    echo "${STR_HELP}"
    echo ""
}

function set_container_registry() {
    if [[ "${1}" == 'true' ]]; then
        DOCKER_REGISTRY='cp.icr.io/cp'
        echo_error_and_exit 'Setting --use-entitlement-key to true is currently not supported. Aborting.'
    elif [[ "${1}" == 'false' ]]; then
        DOCKER_REGISTRY='icr.io/datastage'
    else
        echo_error_and_exit 'Incorrect option specified for flag "--use-entitlement-key". Acceptable values are: [true, false]'
    fi
}

function handle_select_version() {
    if [[ "${1}" == 'true' || "${1}" == 'false' ]]; then
        SELECT_PX_VERSION="${1}"
    else
        echo_error_and_exit 'Incorrect option specified for flag "--select-version". Acceptable values are: [true, false]'
    fi
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
        --cpus)
            shift
            PX_CPUS="$1"
            ;;
        --volume-dir)
            shift
            DOCKER_VOLUMES_DIR="$1"
            ;;
        --mount-dir)
            shift
            MOUNT_DIRS+=("$1")
            ;;
        # --platform)
        #     shift
        #     PLATFORM="$1"
        #     ;;
        --select-version)
            shift
            handle_select_version "${1}"
            ;;
        --set-user)
            shift
            CONTAINER_USER="$1"
            ;;
        --use-entitlement-key)
            shift
            set_container_registry "${1}"
            ;;
        -h | --help | help)
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

function update() {
    ACTION='update'
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
        -d | --project-id)
            shift
            PROJECT_ID="$1"
            ;;
        --memory)
            shift
            PX_MEMORY_OVERRIDE="$1"
            ;;
        --cpus)
            shift
            PX_CPUS_OVERRIDE="$1"
            ;;
        --select-version)
            shift
            handle_select_version "${1}"
            ;;
        --use-entitlement-key)
            shift
            set_container_registry "${1}"
            ;;
        -h | --help | help)
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
        -h | --help | help)
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
        --volume-dir)
            shift
            DOCKER_VOLUMES_DIR="$1"
            ;;
        -h | --help | help)
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

create_dir_if_not_exist() {
    DIR_PATH=$1
    if [ ! -d $DIR_PATH ]; then
        echo "Folder ${DIR_PATH} does not exist, creating ..."
        mkdir -p "${DIR_PATH}"
        set_permissions "${DIR_PATH}"
    fi
}

set_permissions() {
    DIR_PATH=$1
    chmod -R 775 "${DIR_PATH}"
    if [[ "${CONTAINER_USER}" != 'NOT_SET' ]]; then
        chown -R $(id -u "${CONTAINER_USER}"):$(id -g "${CONTAINER_USER}") "${DIR_PATH}"
    fi
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
    if [[ "${DOCKER_REGISTRY}" == 'icr.io'* ]]; then
        docker_login_datastage
    else
        docker_login_cpd
    fi
}

docker_login_datastage() {
    echo ""
    [ -z $IAM_APIKEY_PROD ] && echo_error_and_exit "Please specify DataStage Container Registry IAM APIKey (-p | --prod-apikey). Aborting."
    DELAY=5
    until $DOCKER_CMD login -u iamapikey -p $IAM_APIKEY_PROD $DOCKER_REGISTRY  || [ $DELAY -eq 10 ]; do
        sleep $(( DELAY++ ))
    done
    status=$?
    if [ $status -ne 0 ]; then
        echo "docker login return code: $status."
        echo_error_and_exit "Aborting setup."
    fi
}

docker_login_cpd() {
    echo ""
    [ -z $IAM_APIKEY_PROD ] && echo_error_and_exit "Please specify CPD Entitlement Key (-p | --prod-apikey). Aborting."
    DELAY=5
    until $DOCKER_CMD login -u cp -p $IAM_APIKEY_PROD $DOCKER_REGISTRY  || [ $DELAY -eq 10 ]; do
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
    echo "Retrieved px-runtime digest = $PX_VERSION"
}

retrieve_latest_px_version_from_runtime() {
    echo "Getting PX Version to access Container Registry"
    PX_VERSION=$(curl -s -X GET -H "Authorization: Bearer $IAM_TOKEN" -H 'accept: application/json;charset=utf-8' "${GATEWAY_URL}/data_intg/v3/flows_runtime/remote_engine/versions" | jq -r '.versions[0].image_digests.px_runtime')
    echo "Retrieved px-runtime digest = $PX_VERSION"
}

get_all_px_versions_from_runtime() {
    echo "Getting PX Version to access Container Registry"
    PX_VERSIONS_RESPONSE=$(curl -s -X GET -H "Authorization: Bearer $IAM_TOKEN" -H 'accept: application/json;charset=utf-8' "${GATEWAY_URL}/data_intg/v3/flows_runtime/remote_engine/versions")
    PX_VERSION_PAIRS=$(printf "%s" "${PX_VERSIONS_RESPONSE}" | jq -r '.versions[] | "\(.px_runtime_version)(\(.image_digests.px_runtime))"')

    echo ''
    echo 'Choose the remote engine version to use:'
    PS3="Enter option number: "
    select version_pair in $PX_VERSION_PAIRS; do
        if [ -n "$version_pair" ]; then
            PX_VERSION_NUMBER=$(echo "$version_pair" | cut -d '(' -f 1)
            PX_VERSION=$(echo "$version_pair" | cut -d '(' -f 2- | tr -d ')' )
            echo ''
            echo "Selected $PX_VERSION_NUMBER (digest $PX_VERSION)"
            break
        else
            echo "Invalid option selection, please try again"
        fi
    done
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

# check_unused_port_forpxruntime() {
#     echo "Checking open ports ..."
#     PXRUNTIME_PORT='9443'
#     for i in {3..103}; do
#         if [[ $( netstat -an | grep -w $((9440 + ${i})) | grep LISTEN | wc -l ) -gt 0 ]]; then
#             echo "Port $((9440 + ${i})) is not available, checking port $((9440 + ${i} + 1))"
#         else
#             PXRUNTIME_PORT="$((9440 + ${i}))"
#             break
#         fi
#     done
#     PXRUNTIME_VERSION_ENDPOINT="https://localhost:${PXRUNTIME_PORT}/v3/px_runtime/version"
#     PXCOMPUTE_VERSION_ENDPOINT='https://localhost:9443/v3/px_runtime/version'
# }

# check_used_port_pxruntime() {
#     if [ "$DOCKER_CMD" == "podman" ]; then
#         PXRUNTIME_USED_PORTS=$($DOCKER_CMD inspect --format='{{range $p, $conf := .NetworkSettings.Ports}} {{(index $conf 0).HostPort}} {{end}}' ${PXRUNTIME_CONTAINER_NAME})
#     else
#         PXRUNTIME_USED_PORTS=$($DOCKER_CMD inspect --format='{{.Config.ExposedPorts}}' ${PXRUNTIME_CONTAINER_NAME})
#     fi
#     PXRUNTIME_PORT=$(echo ${PXRUNTIME_USED_PORTS} | grep -o "[0-9.]\+")
#     echo "Found ${PXRUNTIME_CONTAINER_NAME} with port ${PXRUNTIME_PORT}"
#     PXRUNTIME_VERSION_ENDPOINT="https://localhost:${PXRUNTIME_PORT}/v3/px_runtime/version"
#     PXCOMPUTE_VERSION_ENDPOINT='https://localhost:9443/v3/px_runtime/version'
# }

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

    # wait until container is removed
    until [[ $( $DOCKER_CMD ps -a | grep $PXRUNTIME_CONTAINER_NAME | wc -l ) -eq 0 ]]; do
        echo '  - Waiting for the container to be removed'
        sleep 1
    done
}

run_px_runtime_docker() {
    echo "Running container '${PXRUNTIME_CONTAINER_NAME}' ..."
    # end_port_1=$(( 10000 + ${COMPUTE_COUNT} ))
    # end_port_2=$(( 11000 + ${COMPUTE_COUNT} ))
    # -p 10000-${end_port_1}:10000-${end_port_1} -p 11000-${end_port_2}:11000-${end_port_2} -p 9443:9443 \

    runtime_docker_opts=(
        --detach
        --name ${PXRUNTIME_CONTAINER_NAME}
        --hostname="$(hostname)"
        --memory=${PX_MEMORY}
        --cpus=${PX_CPUS}
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
        --env WLM_JOB_START=1
        --env WLM_JOB_COUNT=5
        --network=${PXRUNTIME_CONTAINER_NAME}
    )

    CURRENT_USER=$(id -u)
    if [[ "${CONTAINER_USER}" != 'NOT_SET' ]]; then
        CURRENT_USER=$(id -u "${CONTAINER_USER}")
    fi
    echo "Using user ${CURRENT_USER} to run the container"

    if [[ -v MOUNT_DIRS && ! -z $MOUNT_DIRS ]]; then
        for mount in "${MOUNT_DIRS[@]}"; do
            if [[ -n "$mount" && -v mount && ! -z $mount ]]; then
                if [[ "${mount}" == *':/opt/ibm/PXService/Server/scratch' ]]; then
                    echo "Scratch directory set to: ${mount}"
                    SCRATCH_DIR_OVERRIDE='true'
                fi
                runtime_docker_opts+=(
                    -v "${mount}"
                )
            fi
        done
    fi

    if [[ "${SCRATCH_DIR_OVERRIDE}" == 'false' ]]; then
        create_dir_if_not_exist "${SCRATCH_DIR}"
        set_permissions "${DOCKER_VOLUMES_DIR}"
        runtime_docker_opts+=(
            -v "${SCRATCH_DIR}":/opt/ibm/PXService/Server/scratch
        )
    fi

    if [[ "${PLATFORM}" == 'icp4d' ]]; then
        runtime_docker_opts+=(
            --env WLMON=1
            --env WLM_CONTINUE_ON_COMMS_ERROR=0
            --env WLM_CONTINUE_ON_QUEUE_ERROR=0
            --env WLM_QUEUE_WAIT_TIMEOUT=0
            -v "${DS_STORAGE_HOST_DIR}":/ds-storage
            -v "${PX_STORAGE_HOST_DIR}":/px-storage
            --env DS_STORAGE_PATH=/ds-storage:/px-storage
            --env QSM_RULESET_ROOT_DIR=/ds-storage/rule-set
            --env DS_PX_INSTANCE_ID="${REMOTE_ENGINE_NAME}"
            --env ENABLE_DS_METRICS=false
            --user "${CURRENT_USER}"
        )
    fi

    $DOCKER_CMD run "${runtime_docker_opts[@]}" --entrypoint='/bin/bash' $PXRUNTIME_DOCKER_IMAGE -c "/px-storage/init-volume.sh;/px-storage/startup.sh"
    status=$?
    if [ $status -ne 0 ]; then
        echo "docker run return code: $status."
        echo_error_and_exit "Aborting script run."
    fi

    # once the container is up, reset permissions on the volumes dir
    set_permissions "${DOCKER_VOLUMES_DIR}"

    # wait until docker is in a running state - doesn't mean server has started
    until [[ $( $DOCKER_CMD ps -a | grep $PXRUNTIME_CONTAINER_NAME | wc -l ) -gt 0 ]]; do
        sleep 1
    done
}

start_px_runtime_docker() {
    echo "Starting container '${PXRUNTIME_CONTAINER_NAME}' ..."
    $DOCKER_CMD start ${PXRUNTIME_CONTAINER_NAME}
    sleep 2
}

wait_readiness_px_runtime()
{
    TOTAL_RETRIES=49
    WAIT_DURATION=5
    ret=1
    count=0

    PXRUNTIME_VERSION_ENDPOINT='https://localhost:9443/v3/px_runtime/version'

    export CURL_SSL_BACKEND="secure-transport"
    while (true); do
        count=$(( $count + 1 ))
        echo "  waiting for ${PXRUNTIME_CONTAINER_NAME} to start... time elapsed: $(( $count * $WAIT_DURATION )) seconds"
        $DOCKER_CMD exec "${PXRUNTIME_CONTAINER_NAME}" bash -c "curl -ks ${PXRUNTIME_VERSION_ENDPOINT}" 2>&1 | grep -q '"status":"ok"'
        ret=$?
        if [ ${ret} -eq 0 ]; then
            while (true); do
                count=$(( $count + 1 ))
                sleep 5
                echo "  waiting for ${PXRUNTIME_CONTAINER_NAME} to start... time elapsed: $(( $count * $WAIT_DURATION )) seconds"
                if $DOCKER_CMD exec "${PXRUNTIME_CONTAINER_NAME}" bash -c "curl -ks ${PXRUNTIME_VERSION_ENDPOINT}" | grep -q '"status":"ok"'; then
                    $DOCKER_CMD exec "${PXRUNTIME_CONTAINER_NAME}" bash -c "curl -ks ${PXRUNTIME_VERSION_ENDPOINT}"
                    echo ""
                    echo "Started container ${PXRUNTIME_CONTAINER_NAME} in $(( $count * $WAIT_DURATION )) seconds"
                    break;
                elif [ ${ret} -ne 0 ] && [ ${count} -gt $TOTAL_RETRIES ]; then
                    echo_error_and_exit "Could not start container ${PXRUNTIME_CONTAINER_NAME} in $(( $count * $WAIT_DURATION )) seconds, aborting."
                fi
            done
            if $DOCKER_CMD exec "${PXRUNTIME_CONTAINER_NAME}" bash -c "curl -ks ${PXRUNTIME_VERSION_ENDPOINT}" 2>&1 | grep -q '"status":"ok"'; then
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

cleanup_docker_network() {
    echo "Cleaning docker network"
    $DOCKER_CMD network rm ${PXRUNTIME_CONTAINER_NAME} >/dev/null 2>&1 || true
}

#######################################################################
# IBM Cloud functions
#######################################################################

get_iam_token() {

    IAM_URL="${IAM_URL%/}"
    IAM_URL="${IAM_URL%/identity/token}"

    _iam_response=$(curl -sS -X POST \
                -H 'Content-Type: application/x-www-form-urlencoded' \
                -H 'Accept: application/json' \
                --data-urlencode 'grant_type=urn:ibm:params:oauth:grant-type:apikey' \
                --data-urlencode "apikey=${IAM_APIKEY}" \
                "${IAM_URL}/identity/token")
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

patch_environment() {
    _project_env_patch_response=$(curl -sSi -X 'PATCH' "${GATEWAY_URL}/v2/environments/${PROJECT_ENV_ASSET_ID}?project_id=${PROJECT_ID}" \
        -H 'accept: application/json' \
        -H "Authorization: Bearer $IAM_TOKEN" \
        -H 'Content-Type: application/json' \
        -d "{
  \"/entity/environment/hardware_specification\": {
    \"datastage\": {
      \"num_conductors\": 1,
      \"num_computes\": 0,
      \"conductor\": {
        \"cpu\": {
          \"units\": \"${PX_CPUS}\",
          \"model\": \"\"
        },
        \"mem\": {
          \"size\": \"${PX_MEMORY}\"
        }
      },
      \"compute\": {
        \"cpu\": {
          \"units\": \"1\",
          \"model\": \"\"
        },
        \"mem\": {
          \"size\": \"4G\"
        }
      }
    }
  }
}"
        )
    _project_env_patch_response_status="$(echo $_project_env_patch_response | head -n 1 | cut -d' ' -f2)"
    if [[ -z "${_project_env_patch_response_status}" || "${_project_env_patch_response_status}" != "200" ]]; then
        echo "Response: ${_project_env_patch_response}"
        echo ""
        echo_error_and_exit "Failed to patch environment with id: ${PROJECT_ENV_ASSET_ID}."
    fi
    echo "Patched environment runtime with id: ${PROJECT_ENV_ASSET_ID}"
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
          \"units\": \"${PX_CPUS}\",
          \"model\": \"\"
        },
        \"mem\": {
          \"size\": \"${PX_MEMORY}\"
        }
      },
      \"compute\": {
        \"cpu\": {
          \"units\": \"1\",
          \"model\": \"\"
        },
        \"mem\": {
          \"size\": \"4G\"
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
    if [[ "$DATASTAGE_HOME" == *"${GATEWAY_DOMAIN_YS1DEV}" || "$DATASTAGE_HOME" == "ys1dev" ]]; then
        UI_GATEWAY_URL="https://${GATEWAY_DOMAIN_YS1DEV}"
        GATEWAY_URL="https://api.${GATEWAY_DOMAIN_YS1DEV}"
        IAM_URL='https://iam.test.cloud.ibm.com'

    elif [[ "$DATASTAGE_HOME" == *"${GATEWAY_DOMAIN_YPQA}"  || "$DATASTAGE_HOME" == "ypqa" ]]; then
        UI_GATEWAY_URL="https://${GATEWAY_DOMAIN_YPQA}"
        GATEWAY_URL="https://api.${GATEWAY_DOMAIN_YPQA}"

    elif [[ "$DATASTAGE_HOME" == *"${GATEWAY_DOMAIN_YPPROD}" || "$DATASTAGE_HOME" == "ypprod" ]]; then
        UI_GATEWAY_URL="https://${GATEWAY_DOMAIN_YPPROD}"
        GATEWAY_URL="https://api.${GATEWAY_DOMAIN_YPPROD}"

    elif [[ "$DATASTAGE_HOME" == *"${GATEWAY_DOMAIN_FRPROD}" || "$DATASTAGE_HOME" == "frprod" ]]; then
        UI_GATEWAY_URL="https://${GATEWAY_DOMAIN_FRPROD}"
        GATEWAY_URL="https://api.${GATEWAY_DOMAIN_FRPROD}"

    else
        echo_error_and_exit "Incorrect value specified: '--home ${DATASTAGE_HOME}', aborting. Use one of the allowed values:
        - https://api.${GATEWAY_DOMAIN_YS1DEV}
        - https://api.${GATEWAY_DOMAIN_YPQA}
        - https://api.${GATEWAY_DOMAIN_YPPROD} (default)
        - https://api.${GATEWAY_DOMAIN_FRPROD}"
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

    if [[ "${ACTION}" == 'start' || "${ACTION}" == 'update' ]]; then
        [ -z $IAM_APIKEY_PROD ] && echo_error_and_exit "Please specify a valid IBM Cloud Container Registry APIKey (-p | --prod-apikey). Aborting."
    fi

    if [[ "${ACTION}" == 'start' ]]; then
        [ -z $DSNEXT_SEC_KEY ] && echo_error_and_exit "Please specify an encryption key (-e | --encryption-key. Aborting."
        [ -z $IVSPEC ] && echo_error_and_exit "Please specify the initialization vector for the encryption key (-i | --ivspec). Aborting."
        if [[ "${PROJECT_ID}" == 'None' ]]; then
            echo_error_and_exit "Please specify the project ID (-p | --prod-apikey) in which you want to create the Remote Engine environment. Aborting."
        fi
    fi

    if [[ "${ACTION}" == 'update' ]]; then
        if [[ "${PX_MEMORY_OVERRIDE}" != "0g" || "${PX_CPUS_OVERRIDE}" != "0" ]]; then
            if [[ "${PROJECT_ID}" == 'None' ]]; then
                echo_error_and_exit "Please specify the project ID (-d | --project-id) if you want to change resource allocation. Aborting."
            fi
        fi
    fi

    # needed for all options
    [ -z $REMOTE_ENGINE_NAME ] && echo_error_and_exit "Please specify a name for the Remote Engine instance (-n | --remote-engine-name). Aborting."

    # validate values of choice arguments
    check_datastage_home
    check_platform

    # If everything is available, make sure docker daemon is running before proceeding
    check_docker_daemon

    # print in the console
    if [[ "${ACTION}" == 'start' ]]; then
        echo "DATASTAGE_HOME=${DATASTAGE_HOME}"
        echo "GATEWAY_URL=${GATEWAY_URL}"
        echo "PROJECT_ID=${PROJECT_ID}"
        echo "REMOTE_ENGINE_PREFIX=${REMOTE_ENGINE_NAME}"
        echo "DOCKER_REGISTRY=${DOCKER_REGISTRY}"
        echo "CONTAINER_MEMORY=${PX_MEMORY}"
        echo "CONTAINER_CPUS=${PX_CPUS}"
        echo "DOCKER_VOLUMES_DIR=${DOCKER_VOLUMES_DIR}"
        if [[ -v MOUNT_DIRS && ! -z $MOUNT_DIRS ]]; then
            echo "MOUNT_DIRS=${MOUNT_DIRS[@]}"
            for mount in "${MOUNT_DIRS[@]}"; do
                if [[ -n "$mount" && -v mount && ! -z $mount ]]; then
                    echo "${mount}"
                fi
            done
        fi
        echo ""
    fi

    # finalize constants if all arguments are valid
    PXRUNTIME_CONTAINER_NAME="${REMOTE_ENGINE_NAME//[ ]/_}_runtime"
    PXCOMPUTE_CONTAINER_NAME="${REMOTE_ENGINE_NAME//[ ]/_}_compute"
}

setup_docker_volumes() {
    DS_STORAGE_HOST_DIR="${DOCKER_VOLUMES_DIR}/ds-storage"
    CONTAINER_HOST_DIR="${DOCKER_VOLUMES_DIR}/${PXRUNTIME_CONTAINER_NAME}"
    PX_STORAGE_HOST_DIR="${CONTAINER_HOST_DIR}/px-storage"
    PX_STORAGE_WLM_DIR="${PX_STORAGE_HOST_DIR}/PXRuntime/WLM"
    SCRATCH_DIR="${DOCKER_VOLUMES_DIR}/scratch"

    if [[ "${ACTION}" == 'start' ]]; then

        if [[ "${PLATFORM}" == 'icp4d' ]]; then
            create_dir_if_not_exist "${DOCKER_VOLUMES_DIR}"
            create_dir_if_not_exist "${CONTAINER_HOST_DIR}"
            create_dir_if_not_exist "${DS_STORAGE_HOST_DIR}"
            create_dir_if_not_exist "${PX_STORAGE_HOST_DIR}"
            create_dir_if_not_exist "${PX_STORAGE_WLM_DIR}"
            set_permissions "${DOCKER_VOLUMES_DIR}"
        fi

        # Mount an empty file for running computes since they aren't supported locally
        touch "${PX_STORAGE_WLM_DIR}/.compute_running"
        # Mount an empty file telling WLM it is running in cpd mode but in a local docker
        touch "${PX_STORAGE_WLM_DIR}/.local_docker"

        echo "Creating init scripts ..."
        generate_startup_script
        generate_snc_script
        generate_log_retention_cfg
        generate_init_volume_script
    fi
}

generate_startup_script() {
    STARTUP_FILE="${PX_STORAGE_HOST_DIR}/startup.sh"
    if [ ! -f "${STARTUP_FILE}" ]; then
cat <<EOL > "${STARTUP_FILE}"
#!/bin/sh
set -x

secretDir="/etc/secrets"
iterateSecrets() {
   for filename in \${secretDir}/*; do
      envname=\`basename "\$filename"\`
      lines=\`cat \$filename | wc -l\`
      if [ \$lines -gt 1 ]; then
         # multiline - must be a cert file
         envcontent=\`cat \$filename | awk 'NR>2 {print last} {last=\$0}' | tr -d '\n'\`
      else
         envcontent=\`cat \$filename\`
      fi
      export \$envname=\$envcontent
   done
   # add support for using environment variable to extend LD_LIBRARY_PATH
   if [ ! -z \$ADDITIONAL_LD_LIRABRY_PATH ]; then
      export LD_LIRABRY_PATH="LD_LIRABRY_PATH:\${ADDITIONAL_LD_LIRABRY_PATH}"
   fi
}

startContainer() {
  # if [ -z \$COMPUTE_FASTNAME_PREFIX ]; then
  #   #px-compute
  #   #cert files created by px-runtime; needed by compute for ssl
  #   until [ -f /opt/ibm/PXService/Server/PXEngine/etc/certs/pxesslcert.p12 ]; do
  #     echo "Waiting for certs..."
  #     sleep 5
  #   done
  #   echo "Cert files found..."
  #   /opt/ibm/startcontainer.sh
  # else
  #   #px-runtime
  #   /opt/ibm/initScripts/startcontainer.sh
  # fi
  /opt/ibm/initScripts/startcontainer.sh
}
startCassandraSQLENgine() {
   if [ ! -z "\${CASSANDRA_SQLENGINE_ENABLED}" ] && [ "\${CASSANDRA_SQLENGINE_ENABLED}" = "True" ]; then
      echo "Starting Cassandra SQLEngine on port \${CASSANDRA_SQLENGINE_PORT} with \${CASSANDRA_SQLENGINE_MEMORY_MB}MB of memory."
      java_opts="-Xmx\${CASSANDRA_SQLENGINE_MEMORY_MB}m -cp /opt/ibm/PXService/Server/branded_odbc/java/lib/cassandra.jar"
      java \$java_opts com.ddtek.cassandracloud.sql.Server -port 19933 &
   fi
}

startMongoDBSQLEngine() {
   if [ ! -z "\${MONGODB_SQLENGINE_ENABLED}" ] && [ "\${MONGODB_SQLENGINE_ENABLED}" = "True" ]; then
      echo "Starting MongoDB SQLEngine on port \${MONGODB_SQLENGINE_PORT} with \${MONGODB_SQLENGINE_MEMORY_MB}MB of memory."
      java_opts="-Xmx\${MONGODB_SQLENGINE_MEMORY_MB}m -cp /opt/ibm/PXService/Server/branded_odbc/java/lib/mongodb.jar"
      java \$java_opts com.ddtek.jdbc.mongodb.phoenix.sql.Server -port 19967 &
   fi
}
iterateSecrets
startCassandraSQLENgine
startMongoDBSQLEngine
startContainer
EOL
        set_permissions "${STARTUP_FILE}"
    fi
}

generate_snc_script() {
    SNC_DIR="${DS_STORAGE_HOST_DIR}/snc"
    create_dir_if_not_exist "${SNC_DIR}"
    SNC_FILE="${SNC_DIR}/snc-automate.sh"

    if [ ! -f "${SNC_FILE}" ]; then
cat <<EOL > "${SNC_FILE}"
# retrieve environment variables from /etc/secrets
SNC_PSE=\`cat /etc/secrets/SNC_PSE\`
SNC_PASSCODE=\`cat /etc/secrets/SNC_PASSCODE\`
if [[ -v SECUDIR ]] && [[ -v SNC_LIB ]] && [[ -v SNC_PSE ]];
then
if [[ -v SNC_PASSCODE ]];
then
passcode=\$(echo -n \$SNC_PASSCODE)
echo \$passcode
user=\$(whoami)
echo \$user

export PATH=\$PATH:\$SECUDIR

echo -n \$SNC_PSE | base64 -d > \$SECUDIR/tmp.pse
sapgenpse seclogin -p \$SECUDIR/tmp.pse -x \$passcode -O \$user
#rm \$SECUDIR/tmp.pse
else
echo "SNC passcode must be set by user to proceed. Aborting SNC configuration."
fi
else
echo "SNC related environment variables must be set by user to proceed. Aborting SNC configuration."
fi
EOL
        set_permissions "${SNC_FILE}"
    fi
}

generate_log_retention_cfg() {
    LOG_CFG_DIR="${PX_STORAGE_HOST_DIR}/config/log_retention"
    create_dir_if_not_exist "${LOG_CFG_DIR}"
    LOG_CFG_FILE="${LOG_CFG_DIR}/LogRetention.cfg"

    if [ ! -f "${LOG_CFG_FILE}" ]; then
cat <<EOL > "${LOG_CFG_FILE}"
#           Licensed Materials - Property of IBM
#           (c) Copyright IBM Corp. 2010, 2020
#
# DataStage PX Runtime Log Configuration
# ===================================================

# Enables log retention manager if set to \`TRUE\` otherwise is not active
ENABLE_LOG_RETENTION=TRUE

# Sets the metric to check on logs for cleanup
# Use \`TIME\` to define a cutoff point in days for logs
# Use \`RUN\` to define a cutoff point by count for logs
LOG_RETENTION_POLICY = TIME
# The number of days to keep logs from runs
# Only active if the retention policy is set to this mode
LOG_RETENTION_DAYS = 10
# The number of runs to keep logs for
# Only active if the retention policy is set to this mode
LOG_RETENTION_RUNS = 10
# The frequency of log retention manager in hours
LOG_MANAGER_FREQ = 24
EOL
        set_permissions "${LOG_CFG_FILE}"
    fi
}

generate_init_volume_script() {
    INIT_VOL_FILE="${PX_STORAGE_HOST_DIR}/init-volume.sh"
    if [ ! -f "${INIT_VOL_FILE}" ]; then
cat <<EOL > "${INIT_VOL_FILE}"
#! /bin/bash
set -x

cp "/px-storage/startup.sh" /opt/ibm/startup.sh

cd /px-storage && mkdir -p pds_files/node1 pds_files/node2 Datasets certs data/sap config/wlm config/jdbc config/odbc PXRuntime/WLM/logs dbdrivers;
# create directory for tempdir
mkdir -p /opt/ibm/PXService/Server/scratch/tmpdir;
# mkdir -p /px-storage/ds-storage;
rm -rf /opt/ibm/PXService/Server/Datasets;
ln -s  /px-storage/pds_files /opt/ibm/PXService/Server/pds_files;
ln -s  /px-storage/Datasets /opt/ibm/PXService/Server/Datasets;
ln -s  /px-storage/certs /opt/ibm/PXService/Server/PXEngine/etc/certs;
ln -s  /px-storage/data/sap /opt/ibm/data/sap;
# create directory for snc configuratio for SAP connector
mkdir -p /ds-storage/snc;
if [[ ! -f "/ds-storage/snc/snc-automate.sh" ]]; then
  cp /etc/px_tmp/snc-automate.sh /ds-storage/snc/snc-automate.sh;
else
# update current file to set SNC_PSE and SNC_PASSCODE
  envCount=\`cat /ds-storage/snc/snc-automate.sh | grep '/etc/secrets' | wc -l\`
  if [[ \$envCount -eq 0 ]]; then
    sed -i '1s|^|SNC_PSE=\`cat /etc/secrets/SNC_PSE\`\nSNC_PASSCODE=\`cat /etc/secrets/SNC_PASSCODE\`\n|' /ds-storage/snc/snc-automate.sh
  fi
fi;

# only set for runtime
if [[ ! -z \$WLM_JOB_COUNT && ! -z \$WLM_JOB_START ]]; then
  if [[ -f /px-storage/config/wlm/wlm.config.xml ]]; then
    rm /opt/ibm/PXService/Server/DSWLM/dist/lib/wlm.config.xml;
  else
    mv /opt/ibm/PXService/Server/DSWLM/dist/lib/wlm.config.xml /px-storage/config/wlm/wlm.config.xml;
    sed -i "s/name=\"JobCount\" value=\"5\"/name=\"JobCount\" value=\"\${WLM_JOB_COUNT}\"/" /px-storage/config/wlm/wlm.config.xml;
    sed -i "s/name=\"StartJob\" value=\"2\"/name=\"StartJob\" value=\"\${WLM_JOB_START}\"/" /px-storage/config/wlm/wlm.config.xml;
    # line number for MediumPriorityJobsPolicy, JobCount is on the next line #}
    mediumPriorityLN=\`cat /px-storage/config/wlm/wlm.config.xml | grep -n 'Policy name="MediumPriorityJobsPolicy"' | cut -d ':' -f 1\`;
    jobCountLN=\$((mediumPriorityLN + 1));
    sed -i "\${jobCountLN}s/resource=\"JobCount\" value=\"5\"/resource=\"JobCount\" value=\"\${WLM_JOB_COUNT}\"/" /px-storage/config/wlm/wlm.config.xml;
    lowPriorityLN=\`cat /px-storage/config/wlm/wlm.config.xml | grep -n 'Policy name="LowPriorityJobsPolicy"' | cut -d ':' -f 1\`;
    jobCountLN=\$((lowPriorityLN + 1));
    sed -i "\${jobCountLN}s/resource=\"JobCount\" value=\"5\"/resource=\"JobCount\" value=\"\${WLM_JOB_COUNT}\"/" /px-storage/config/wlm/wlm.config.xml;
    highPriorityLN=\`cat /px-storage/config/wlm/wlm.config.xml | grep -n 'Policy name="HighPriorityJobsPolicy"' | cut -d ':' -f 1\`;
    jobCountLN=\$((highPriorityLN + 1));
    sed -i "\${jobCountLN}s/resource=\"JobCount\" value=\"5\"/resource=\"JobCount\" value=\"\${WLM_JOB_COUNT}\"/" /px-storage/config/wlm/wlm.config.xml;
    # update low and high to the same value
  fi;
  ln -s  /px-storage/config/wlm/wlm.config.xml /opt/ibm/PXService/Server/DSWLM/dist/lib/wlm.config.xml;
  if [[ -f /px-storage/config/wlm/Logging.properties ]]; then
    rm /opt/ibm/PXService/Server/DSWLM/dist/lib/Logging.properties;
  else
    mv /opt/ibm/PXService/Server/DSWLM/dist/lib/Logging.properties /px-storage/config/wlm/Logging.properties;
  fi
  ln -s  /px-storage/config/wlm/Logging.properties /opt/ibm/PXService/Server/DSWLM/dist/lib/Logging.properties;
fi;

if [[ -f /px-storage/config/jdbc/isjdbc.config  ]]; then
  rm /opt/ibm/PXService/Server/DSEngine/isjdbc.config;
  rm /opt/ibm/PXService/Server/DSEngine/isjdbc.config.biginsights;
  rm /opt/ibm/PXService/Server/DSEngine/isjdbc.config.default;
else
  mv /opt/ibm/PXService/Server/DSEngine/isjdbc.config /px-storage/config/jdbc/isjdbc.config;
  mv /opt/ibm/PXService/Server/DSEngine/isjdbc.config.biginsights /px-storage/config/jdbc/isjdbc.config.biginsights;
  mv /opt/ibm/PXService/Server/DSEngine/isjdbc.config.default /px-storage/config/jdbc/isjdbc.config.default;
fi;
ln -s  /px-storage/config/jdbc/isjdbc.config             /opt/ibm/PXService/Server/DSEngine/isjdbc.config;
ln -s  /px-storage/config/jdbc/isjdbc.config.biginsights /opt/ibm/PXService/Server/DSEngine/isjdbc.config.biginsights;
ln -s  /px-storage/config/jdbc/isjdbc.config.default     /opt/ibm/PXService/Server/DSEngine/isjdbc.config.default;
mkdir -p /ds-storage/rule-set /ds-storage/avi;
ln -s  /ds-storage/rule-set /opt/ibm/data/rule-set;
ln -s  /ds-storage/avi /opt/ibm/data/avi;
if [[ -f /ds-storage/connectors/odbc/config/odbc.ini ]]; then
  rm /opt/ibm/PXService/Server/DSEngine/.odbc.ini;
else
  # move odbc.ini from px-storage to ds-storage
  mkdir -p /ds-storage/connectors/odbc/config
  if [[ -f /px-storage/config/odbc/odbc.ini ]]; then
     mv /px-storage/config/odbc/odbc.ini /ds-storage/connectors/odbc/config/odbc.ini;
     rm /opt/ibm/PXService/Server/DSEngine/.odbc.ini;
  else
     mv /opt/ibm/PXService/Server/DSEngine/.odbc.ini /ds-storage/connectors/odbc/config/odbc.ini;
  fi;
fi;
ln -s /ds-storage/connectors/odbc/config/odbc.ini /opt/ibm/PXService/Server/DSEngine/.odbc.ini;
if [[ ! -f /px-storage/config/log_retention/LogRetention.cfg && -f /etc/px_tmp/LogRetention.cfg ]]; then
  mkdir -p /px-storage/config/log_retention;
  cp /etc/px_tmp/LogRetention.cfg /px-storage/config/log_retention/LogRetention.cfg;
fi;
# create symlink for DSWLM/logs
if [ -d /opt/ibm/PXService/Server/DSWLM/logs ]; then
  rm -rf /opt/ibm/PXService/Server/DSWLM/logs
  ln -s /px-storage/PXRuntime/WLM/logs /opt/ibm/PXService/Server/DSWLM/logs
fi
# create symlink for db2 catalog node/db
sed -i 's/dsadm/dsuser/g' /home/dsuser/sqllib/db2profile
if [[ ! -d /px-storage/db2 ]]; then
   mkdir -p /px-storage/db2/sqldbdir
   source /home/dsuser/sqllib/db2profile
   # db2 catalog fails when symlinked to an empty dir
   # the workaround is to catalog a dummy node and use the created dir for the symlink
   db2 CATALOG TCPIP NODE ignore REMOTE IGNORE.DB2.IBM.COM SERVER 50000
   mv /home/dsuser/sqllib/sqlnodir /px-storage/db2/sqlnodir
fi
if [[ ! -f /px-storage/db2/db2nodes.cfg ]]; then
   echo "0 ds-px-default-ibm-datastage-px-compute-0.ds-px-default-ibm-datastage-px-compute 0" > /px-storage/db2/db2nodes.cfg
fi
ln -s /px-storage/db2/db2nodes.cfg /home/dsuser/sqllib/db2nodes.cfg
ln -s /px-storage/db2/sqlnodir /home/dsuser/sqllib/sqlnodir
ln -s /px-storage/db2/sqldbdir /home/dsuser/sqllib/sqldbdir
# for px compute; call initScript to import java certs
if [[ -z "\${DS_PX_COMPUTE_REPLICAS}" ]]; then
  set +e;
  # different scripts for import certs on IBM and OpenJDK base image
  if [[ -f /opt/ibm/initScripts/03-misccerts.sh ]]; then
    /opt/ibm/initScripts/03-misccerts.sh;
  elif [[ -f /opt/ibm/initScripts/01-libertycert.sh ]]; then
    /opt/ibm/initScripts/01-libertycert.sh start;
  else
    echo "Missing cert update script";
  fi
fi
EOL
        set_permissions "${INIT_VOL_FILE}"
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
setup_docker_volumes

if [[ ${ACTION} == "start" ]]; then

    # check if this container is present and running. If so then exit with a prompt
    echo "Checking for existing container '${PXRUNTIME_CONTAINER_NAME}'"
    if [[ $(check_pxruntime_container_exists_and_running) == "true" ]]; then
        echo_error_and_exit "Container '${PXRUNTIME_CONTAINER_NAME}' is already running. Aborting."
    fi


    # check if this container is present but not running. Restart the container
    if [[ $(check_pxruntime_container_exists) == "true" ]]; then
        echo "Existing container ${PXRUNTIME_CONTAINER_NAME} found in a stopped state"
        start_px_runtime_docker
        wait_readiness_px_runtime

        echo ""
        echo "Runtime Environment 'Remote Engine ${REMOTE_ENGINE_NAME}' is available, and can be used to run DataStage flows"

        exit 0
    fi

    # IAM Token will be needed to retrieve latest digest, and make other api calls
    echo "Getting IAM token"
    get_iam_token
    # check if the runtime image exists, if not, then download
    print_header "Checking docker images ..."
    if [[ "${SELECT_PX_VERSION}" == 'true' ]]; then
        get_all_px_versions_from_runtime
    else
        if [[ "${DOCKER_REGISTRY}" == 'icr.io'* ]]; then
            retrieve_latest_px_version
        else
            retrieve_latest_px_version_from_runtime
        fi
    fi

    PXRUNTIME_DOCKER_IMAGE_NAME="${DOCKER_REGISTRY}/ds-px-runtime"
    # update the image variables to use the PX_VERSION version
    if [[ "$PX_VERSION" == "latest" || "$PX_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        PXRUNTIME_DOCKER_IMAGE="${PXRUNTIME_DOCKER_IMAGE_NAME}:${PX_VERSION}"
    else
        PXRUNTIME_DOCKER_IMAGE="${PXRUNTIME_DOCKER_IMAGE_NAME}@${PX_VERSION}"
    fi
    check_or_pull_image $PXRUNTIME_DOCKER_IMAGE
    print_header "Initializing ${TOOL_SHORTNAME} Runtime environment with name '${REMOTE_ENGINE_NAME}' ..."
    echo "Setting up docker environment"

    initialize_docker_network

    # docker run
    # ---------------------
    print_header "Starting instance '${REMOTE_ENGINE_NAME}' ..."
    run_px_runtime_docker
    wait_readiness_px_runtime


    # datastage api calls
    # ---------------------

    print_header "Finalizing Remote Engine instance '${REMOTE_ENGINE_NAME}'..."

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
        patch_environment
    fi
    echo "Runtime Environment 'Remote Engine ${REMOTE_ENGINE_NAME}' is registered."

    # echo "Updating the project to use ${REMOTE_ENGINE_NAME} as the default environment"
    # update_datastage_settings

    PROJECTS_LINK="${UI_GATEWAY_URL}/projects/${PROJECT_ID}"
    echo ""
    echo "Setup complete"
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
    echo ''
    echo 'Remote engine is setup. You can navigate to the project settings and select this engine to be used by the project.'
    print_header "Remote Engine setup completed."

elif [[ ${ACTION} == "update" ]]; then

    # check if this container is present and running. If so then exit with a prompt
    echo "Checking for existing container '${PXRUNTIME_CONTAINER_NAME}'"
    if [[ $(check_pxruntime_container_exists_and_running) != "true" ]]; then
        echo_error_and_exit "Container '${PXRUNTIME_CONTAINER_NAME}' not found or not running, aborting update."
    fi

    echo "Gathering variables required for update from the current container"
    DSNEXT_SEC_KEY=$($DOCKER_CMD exec "${PXRUNTIME_CONTAINER_NAME}" env | grep DSNEXT_SEC_KEY | cut -d'=' -f2)
    IVSPEC=$($DOCKER_CMD exec "${PXRUNTIME_CONTAINER_NAME}" env | grep IVSPEC | cut -d'=' -f2)
    PX_MEMORY=$(($($DOCKER_CMD inspect --format='{{.HostConfig.Memory}}' "${PXRUNTIME_CONTAINER_NAME}")/(1024*1024*1024))) # in GB
    PX_CPUS=$(($($DOCKER_CMD inspect --format='{{.HostConfig.NanoCpus}}' "${PXRUNTIME_CONTAINER_NAME}")/(1000*1000*1000))) # in cores
    GATEWAY_URL=$($DOCKER_CMD exec "${PXRUNTIME_CONTAINER_NAME}" env | grep GATEWAY_URL | cut -d'=' -f2)
    IAM_URL=$($DOCKER_CMD exec "${PXRUNTIME_CONTAINER_NAME}" env | grep IAM_URL | cut -d'=' -f2)
    IAM_APIKEY=$($DOCKER_CMD exec "${PXRUNTIME_CONTAINER_NAME}" env | grep SERVICE_API_KEY | cut -d'=' -f2)
    DS_STORAGE_HOST_DIR=$($DOCKER_CMD inspect "${PXRUNTIME_CONTAINER_NAME}" | jq -r '.[].Mounts | .[] | select(.Destination == "/ds-storage") | .Source')
    PX_STORAGE_HOST_DIR=$($DOCKER_CMD inspect "${PXRUNTIME_CONTAINER_NAME}" | jq -r '.[].Mounts | .[] | select(.Destination == "/px-storage") | .Source')
    SCRATCH_DIR=$($DOCKER_CMD inspect "${PXRUNTIME_CONTAINER_NAME}" | jq -r '.[].Mounts | .[] | select(.Destination == "/opt/ibm/PXService/Server/scratch") | .Source')
    # MOUNT_DIRS=$($DOCKER_CMD inspect "${PXRUNTIME_CONTAINER_NAME}" | jq -r '.[].Mounts | .[] | select(.Destination != "/ds-storage") | select(.Destination != "/px-storage") | select(.Destination != "/opt/ibm/PXService/Server/scratch") | "\(.Source):\(.Destination)"' | tr '\n' ' ')
    SAVEIFS=$IFS
    IFS=$'\n'
    MOUNT_DIRS_STR=$($DOCKER_CMD inspect "${PXRUNTIME_CONTAINER_NAME}" | jq -r '.[].Mounts | .[] | select(.Destination != "/ds-storage") | select(.Destination != "/px-storage") | select(.Destination != "/opt/ibm/PXService/Server/scratch") | "\(.Source):\(.Destination)"' | while read object; do echo "$object"; done)
    MOUNT_DIRS=($MOUNT_DIRS_STR)
    IFS=$SAVEIFS
    CONTAINER_USER=$($DOCKER_CMD inspect --format='{{.Config.User}}' "${PXRUNTIME_CONTAINER_NAME}")
    DOCKER_VOLUMES_DIR=$(dirname "$DS_STORAGE_HOST_DIR")
    SCRATCH_BASE_DIR=$(dirname "$SCRATCH_DIR")
    PX_MEMORY="${PX_MEMORY}G"

    # if scratch directory was overriden, put it back in MOUNT_DIRS
    if [[ "${SCRATCH_BASE_DIR}" != "${DOCKER_VOLUMES_DIR}" ]]; then
        MOUNT_DIRS+=("$SCRATCH_DIR:/opt/ibm/PXService/Server/scratch")
    fi

    if [[ "${PROJECT_ID}" != 'None' ]]; then

        if [[ "${PX_MEMORY_OVERRIDE}" != '0g' ]]; then
            echo "Container memory allocation changed from ${PX_MEMORY} to ${PX_MEMORY_OVERRIDE}"
            PX_MEMORY="${PX_MEMORY_OVERRIDE}"
        fi

        if [[ "${PX_CPUS_OVERRIDE}" != '0' ]]; then
            echo "Container cpu allocation changed from ${PX_CPUS} to ${PX_CPUS_OVERRIDE}"
            PX_CPUS="${PX_CPUS_OVERRIDE}"
        fi

    fi

    MASKED_DSNEXT_SEC_KEY="${DSNEXT_SEC_KEY:0:1}******${DSNEXT_SEC_KEY: -1}"
    MASKED_IVSPEC="${IVSPEC:0:1}******${IVSPEC: -1}"
    MASKED_IAM_APIKEY="${IAM_APIKEY:0:1}******${IAM_APIKEY: -1}"
    # validate
    [ -z $DSNEXT_SEC_KEY ] && "Could not retrieve DSNEXT_SEC_KEY from container ${PXRUNTIME_CONTAINER_NAME}."
    [ -z $IVSPEC ] && "Could not retrieve IVSPEC from container ${PXRUNTIME_CONTAINER_NAME}"
    [ -z $PX_MEMORY ] && "Could not retrieve PX_MEMORY from container ${PXRUNTIME_CONTAINER_NAME}"
    [ -z $PX_CPUS ] && "Could not retrieve PX_CPUS from container ${PXRUNTIME_CONTAINER_NAME}"
    [ -z $GATEWAY_URL ] && "Could not retrieve GATEWAY_URL from container ${PXRUNTIME_CONTAINER_NAME}"
    [ -z $IAM_URL ] && "Could not retrieve IAM_URL from container ${PXRUNTIME_CONTAINER_NAME}"
    [ -z $IAM_APIKEY ] && "Could not retrieve IAM_APIKEY from container ${PXRUNTIME_CONTAINER_NAME}"
    [ -z $DS_STORAGE_HOST_DIR ] && "Could not retrieve DS_STORAGE_HOST_DIR from container ${PXRUNTIME_CONTAINER_NAME}"
    [ -z $PX_STORAGE_HOST_DIR ] && "Could not retrieve PX_STORAGE_HOST_DIR from container ${PXRUNTIME_CONTAINER_NAME}"
    [ -z $SCRATCH_DIR ] && "Could not retrieve SCRATCH_DIR from container ${PXRUNTIME_CONTAINER_NAME}"
    [ -z $DOCKER_VOLUMES_DIR ] && "Could not retrieve DOCKER_VOLUMES_DIR from container ${PXRUNTIME_CONTAINER_NAME}"
    [ -z $CONTAINER_USER ] && "Could not retrieve CONTAINER_USER from container ${PXRUNTIME_CONTAINER_NAME}"

    echo "DSNEXT_SEC_KEY = ${MASKED_DSNEXT_SEC_KEY}"
    echo "IVSPEC = ${MASKED_IVSPEC}"
    echo "GATEWAY_URL = ${GATEWAY_URL}"
    echo "CONTAINER_MEMORY = ${PX_MEMORY}"
    echo "CONTAINER_CPUS = ${PX_CPUS}"
    echo "IAM_URL = ${IAM_URL}"
    echo "IAM_APIKEY = ${MASKED_IAM_APIKEY}"
    echo "DS_STORAGE_HOST_DIR = ${DS_STORAGE_HOST_DIR}"
    echo "PX_STORAGE_HOST_DIR = ${PX_STORAGE_HOST_DIR}"
    echo "SCRATCH_DIR = ${SCRATCH_DIR}"
    echo "CONTAINER_USER = ${CONTAINER_USER}"
    echo "DOCKER_VOLUMES_DIR = ${DOCKER_VOLUMES_DIR}"
    if [[ -v MOUNT_DIRS && ! -z $MOUNT_DIRS ]]; then
        echo "MOUNT_DIRS=${MOUNT_DIRS[@]}"
    fi

    echo ""
    stop_px_runtime_docker
    remove_px_runtime_docker

    # IAM Token will be needed to retrieve latest digest, and make other api calls
    echo "Getting IAM token"
    get_iam_token
    # check if the runtime image exists, if not, then download
    print_header "Checking docker images ..."
    if [[ "${SELECT_PX_VERSION}" == 'true' ]]; then
        get_all_px_versions_from_runtime
    else
        if [[ "${DOCKER_REGISTRY}" == 'icr.io'* ]]; then
            retrieve_latest_px_version
        else
            retrieve_latest_px_version_from_runtime
        fi
    fi

    PXRUNTIME_DOCKER_IMAGE_NAME="${DOCKER_REGISTRY}/ds-px-runtime"
    # update the image variables to use the PX_VERSION version
    if [[ "$PX_VERSION" == "latest" || "$PX_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        PXRUNTIME_DOCKER_IMAGE="${PXRUNTIME_DOCKER_IMAGE_NAME}:${PX_VERSION}"
    else
        PXRUNTIME_DOCKER_IMAGE="${PXRUNTIME_DOCKER_IMAGE_NAME}@${PX_VERSION}"
    fi
    check_or_pull_image $PXRUNTIME_DOCKER_IMAGE
    print_header "Initializing ${TOOL_SHORTNAME} Runtime environment with name '${REMOTE_ENGINE_NAME}' ..."
    echo "Setting up docker environment"

    initialize_docker_network

    print_header "Starting instance '${REMOTE_ENGINE_NAME}' ..."
    run_px_runtime_docker
    wait_readiness_px_runtime

    if [[ "${PROJECT_ID}" != 'None' ]]; then
        if [[ "${PX_MEMORY_OVERRIDE}" != '0g' || "${PX_CPUS_OVERRIDE}" != '0' ]]; then
            echo "Fetching Remote Engine registration ..."
            get_remote_engine_id
            echo "Fetching runtime environment with REMOTE_ENGINE=${REMOTE_ENGINE_ID} ..."
            get_environment_id
            if [[ -z "${PROJECT_ENV_ASSET_ID}" || "${PROJECT_ENV_ASSET_ID}" == "" ]]; then
                echo_error_and_exit 'Could not retrieve environment id'
            fi
            echo "Patching existing environment with REMOTE_ENGINE=${REMOTE_ENGINE_ID} with id: ${PROJECT_ENV_ASSET_ID}"
            patch_environment
        fi
    fi

    PROJECTS_LINK="${UI_GATEWAY_URL}/projects/${PROJECT_ID}"
    echo ""
    echo "Update complete"
    echo ""
    echo "Project settings:"
    echo "* ${PROJECTS_LINK}/manage/tool-configurations/datastage_admin_settings_section?context=cpdaas"
    echo ""
    echo "Project assets:"
    echo "* ${PROJECTS_LINK}/assets?context=cpdaas"

    echo ''
    print_header "Remote Engine update completed."

elif [[ ${ACTION} == "stop" ]]; then

    stop_px_runtime_docker
    print_header "Remote Engine container stopped."

elif [[ ${ACTION} == "cleanup" ]]; then
    echo "WARNING: This will remove the docker container, de-register the engine and remove the persistent storage used with this engine instance:"
    echo " - ${CONTAINER_HOST_DIR}"
    echo "You may backup this directory to any other location."
    echo "NOTE: If you want to update this remote engine, you do not need to remove/uninstall it. In that case please abort this command and run the update command: , "
    echo "      OR remove the container for this engine: '${DOCKER_CMD} rm ${PXRUNTIME_CONTAINER_NAME}'; and rerun the start command with the same name: '${REMOTE_ENGINE_NAME}'."
    read -p "Are you sure you want to proceed with the uninstall [y/n]? "
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then

        stop_px_runtime_docker
        remove_px_runtime_docker
        cleanup_docker_network

        print_header "Cleaning Remote Engine '${REMOTE_ENGINE_NAME}'..."

        if [[ "${PLATFORM}" == 'icp4d' ]]; then
            if [ -d "${CONTAINER_HOST_DIR}" ]; then
                rm -rf "${CONTAINER_HOST_DIR}"
            fi
        fi

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

        # echo "Resetting DataStage settings"
        # reset_datastage_settings

        PROJECTS_LINK="${UI_GATEWAY_URL}/projects/${PROJECT_ID}"
        echo ""
        echo "Cleanup complete"
        echo ""
        echo "Project settings:"
        echo "* ${PROJECTS_LINK}/manage/tool-configurations/datastage_admin_settings_section?context=cpdaas"
        echo ""
        echo "Project assets:"
        echo "* ${PROJECTS_LINK}/assets?context=cpdaas"

        echo ''
        echo 'Remote engine is cleaned up. You can navigate to the project settings and select a different engine if this engine was the default.'
        print_header "Remote Engine cleanup completed."
    else
        print_header "Remote Engine cleanup aborted."
    fi

fi

