#!/bin/bash

#set -x

PROG_DIR=`dirname $0`
INI_FILE=$PROG_DIR/dsjob.ini

CPDCTL_CONFIG=`egrep '^dsjob.cpdctl.config=' $INI_FILE | cut -d'=' -f2`
MAX_RUN_WAIT=`egrep '^dsjob.cpdctl.max-wait=' $INI_FILE | cut -d'=' -f2`
CPDCTL_PROFILE=`egrep '^dsjob.cpdctl.profile=' $INI_FILE | cut -d'=' -f2`
CPDCTL_ENC_KEY=`egrep '^cpdctl.encryption.key.path=' $INI_FILE | cut -d'=' -f2`
DEFAULT_JOB_NAME=`egrep '^dsjob.cpd.default-job-name' $INI_FILE | cut -d'=' -f2`
DEFAULT_RUN_NAME=`egrep '^dsjob.cpd.default-run-name' $INI_FILE | cut -d'=' -f2`
CONTEXT_TYPE=`egrep '^dsjob.cpd.context-type' $INI_FILE | cut -d'=' -f2`
PIPELINE_STATUS_PARAM=`
    egrep '^dsjob.pipelines.user-status-param' $INI_FILE | cut -d'=' -f2`
PIPELINE_OPTIMIZED=`
    egrep '^dsjob.pipelines.optimized' $INI_FILE | cut -d'=' -f2`
PIPELINE_JOB_NAME=`egrep '^dsjob.pipelines.job-name' $INI_FILE | cut -d'=' -f2`
DSJOB_RETRIES=$(egrep '^dsjob.retry_count=' $INI_FILE | cut -d= -f2)
DSJOB_RETRY_DELAY=$(egrep '^dsjob.retry_delay=' $INI_FILE | cut -d= -f2)
: "${DSJOB_RETRIES:=3}"
: "${DSJOB_RETRY_DELAY:=2}"

CPDCTL="cpdctl --cpd-config $CPDCTL_CONFIG dsjob"

PROJ=
PROJ_OPT=-p
JOB=
STAGE=
LINK=
PARAMS=
RUN_MODE=
RUN_WAIT=
RUN_WARN=
LOG_TYPE=
INVOCATION_LIST=
WAVE_NUM=
MAX_ENTRIES=

RUN_ID=
RUN_STATUS=
RUN_CREATED_AT=
FLOW_NAME=
INVOCATION_ID=
MULTI_INSTANCE=
JOB_STATUS=N
USER_STATUS=N
EVENT_TYPE=
ENTRY_ID=

export CPDCTL_ENABLE_DSJOB=true
export CPDCTL_ENABLE_DATASTAGE=true
export CPDCTL_ENABLE_VOLUMES=1
export CPDCTL_ENCRYPTION_KEY_PATH=$CPDCTL_ENC_KEY

ARGS=$#
ARG_ARRAY=("${@}")

# Per-call overrides:
# retry_cmd <retries> <delay> <cmd...>
# simply retry_cmd <cmd...> if you have dsjob.retry_count and dsjob.retry_delay in dsjob.ini
retry_cmd() {
    local retries delay 
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        retries="$1"; shift
        delay="$1"; shift
    else
        retries="$DSJOB_RETRIES"
        delay="$DSJOB_RETRY_DELAY"
    fi

    local attempt=1
    local stderr tmp rc

    tmp=$(mktemp)
    while true; do
        "$@" 2>"$tmp"
        rc=$?

        if [[ $rc -eq 0 ]]; then
            rm -f "$tmp"
            return 0
        fi

       echo "Command: $@" >&2
       echo "Command failed with exit code $rc. Attempt $attempt of $retries." >&2
       if [[ $attempt -ge $retries ]]; then
            cat "$tmp" 
            rm -f "$tmp"
            return $rc
        fi

        sleep "$delay"
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done
}

# Check the type of job. This function returns the values below
# 1: DataStage flow
# 2: Pipeline
function check_job_object_type()
{
    #local type_flow=

    #type_flow=`$CPDCTL list-pipelines ${PROJ_OPT} "$PROJ" |
    #           grep -E "^${FLOW_NAME}$" | wc -l`


    assetFile=$(mktemp)
    retry_cmd $CPDCTL get-asset-info ${PROJ_OPT} "$PROJ" --name "${FLOW_NAME}" --with-metadata --output json -t "(data_intg_flow OR orchestration_flow)" > $assetFile
    rc=$?

    cat $assetFile
    if [[ $rc -ne 0 ]]; then
        rm -f "$assetType"
        echo "ERROR: Failed to open job" >&2
        echo >&2
        echo "Status code = -1004" >&2
        exit 255
    fi

    # Step 2: Safely extract asset type
    asset_type=$(jq -r '.metadata.asset_type // empty' "$assetFile")

    rm -f "$assetFile"

    # Step 3: Determine job type
    case "$asset_type" in
        data_intg_flow)
            return 1
            ;;
        orchestration_flow)
            return 2
            ;;
        *)
            echo "ERROR: Unknown asset type: $asset_type" >&2
            echo >&2
            echo "Status code = -1004" >&2
            exit 255
            ;;
    esac
}

function run_job()
{
    local jobrun_out=/tmp/jobrun.$$.tmp
    local run_status=
    local status_code=
    local job_status=
    local user_status=
    local run_id=
    local jobtp=

    #if [[ $RUN_MODE == "RESET" || $RUN_MODE == "VALIDATE" ]]
    if [ "$RUN_MODE" == "VALIDATE" ]
    then
        echo >&2
        echo "Status code = 0" >&2
        return
    fi

    #local flow_name=`echo $JOB | cut -d'.' -f1`
    #FLOW_NAME=`echo $JOB | cut -d'.' -f1`
    local invocation_id=`echo $JOB | cut -d'.' -f2`
    local multi_instance=`echo $JOB | grep "\." | wc -l`

    if [ "$multi_instance" == "1" ]
    then
        INVOCATION_ID="$invocation_id"
    else
        INVOCATION_ID="$DEFAULT_RUN_NAME"
    fi

    check_job_object_type
    jobtp=$?


    PARAMS="$@"

    if [ "$RUN_WAIT" != "" ]
    then
        echo "Waiting for job..."
    fi


    if [[ "$jobtp" == "1" ||
          "$jobtp" == "2" && "$PIPELINE_OPTIMIZED" != "Y" ]]
    then
        eval $CPDCTL run \
            ${PROJ_OPT} \"$PROJ\" --name \"${FLOW_NAME}.${DEFAULT_JOB_NAME}\" \
            $RUN_WAIT $RUN_WARN "$PARAMS" \
            --run-name \"$INVOCATION_ID\" > $jobrun_out
    else
	eval $CPDCTL run-pipeline --optimize --skip-compile \
    	    ${PROJ_OPT} \"$PROJ\" --name \"${FLOW_NAME}\" \
	    --job-suffix \".${PIPELINE_JOB_NAME}\" \
	    $RUN_WAIT $PARAMS \
	    --run-name \"$INVOCATION_ID\" > $jobrun_out
    fi

    cat $jobrun_out
    run_status=`tail -1 $jobrun_out | grep "Status code" |
                tr -d " " | cut -d'=' -f2`

    if [ -z "$run_status" ]
    then
        cat $jobrun_out
        rm -f $jobrun_out
        #return
        exit 255
    fi

    # Alter the status code. At this point, the job has been executed and
    # we will set the status code to 0 no matter what the result is.
    # In the futre, may need to set different value if the job was not executed.
    # For eg, the job doesn't exist or not in a runnable state.
    status_code=0

    # Success
    if [ "$run_status" == "0" ]
    then
        job_status=1
    # Success with warning
    elif [ "$run_status" == "1" ]
    then
        job_status=2
    # Completed with error (not sure what this is)
    elif [ "$run_status" == "3" ]
    then
        job_status=2
    # Failed
    elif [ "$run_status" == "4" ]
    then
        job_status=3
    # Cancelled
    elif [ "$run_status" == "5" ]
    then
        job_status=-1
    elif [ "$run_status" == "-1" ]
    then
        job_status=0
    else
        echo "Unexpected Status code returned from cpdctl $run_status"
        job_status=-1
    fi

    # Print the output except the final line which indicates 'Status code'
    #sed '$d' $jobrun_out

    # Print Job Status if -jobstatus option was specified.
    if [ "$JOB_STATUS" == "Y" ]
    then
        # If -jobstatus is on, print the job status and status code with
        # the value of job status
        echo "Job Status      :  (${job_status})"
        echo >&2
        echo "Status code = ${job_status}" >&2
        rm -f $jobrun_out
        exit $job_status
    fi

    if [ "$USER_STATUS" == "Y" ]
    then
        run_id=`cat $jobrun_out | grep "^Job Run ID:" |
                tr -d " " | cut -d':' -f 2`

	    tmp=$(mktemp)
        retry_cmd $CPDCTL get-jobrun ${PROJ_OPT} "$PROJ" \
                     --name "${FLOW_NAME}.${DEFAULT_JOB_NAME}" \
                     --run-id $run_id --output json --with-metadata \
		    > $tmp
        user_status=$(jq -r '.entity.job_run.configuration.userStatus' "$tmp")
        rm -f "$tmp"

        if [ "$user_status" == "" ]
        then
            echo "User Status     : not available"
        else
            echo "User Status     : $user_status"
        fi

        echo

        # If -userstatus is specified, return it if the status is number.
        if [[ "$user_status" != "" && "$user_status" =~ ^[0-9]+$ ]]
        then
            echo "Status code = $user_status" >&2
            exit $user_status
        else
            echo "Status code = -1007" >&2
            exit -1
        fi
    fi

    # Print the Status code
    rm -f $jobrun_out
    echo >&2
    echo "Status code = ${status_code}" >&2
    exit 0
}

set -- "${ARG_ARRAY[@]}"

# Now use shift as shown above
PROJ="$1"
JOB="$2"
shift 2
FLOW_NAME=`echo $JOB | cut -d'.' -f1`
RUN_WAIT="--wait ${MAX_RUN_WAIT}"
run_job "$@"

