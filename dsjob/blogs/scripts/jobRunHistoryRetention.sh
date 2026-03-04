#!/bin/bash
# Prereq: cpdctl must be configured
# Updates retention policy for Datastage jobs

PROJECT=""
RUNS=""
DAYS=""
RETENTION_FLAG=""
VALUE=""
JOB_NAME=""

INPUT_FILE=""
SAVE_FAILURES=false

MAX_RETRY=3
CURRENT_RETRY=0

TOTAL_JOBS=0
SUCCESS_COUNT=0
FAILED_COUNT=0

JOB_LIST=""
FAILED_JOBS=()

EXIT_SUCCESS=0
EXIT_FAILURE=1

usage() {
    echo "Usage:"
    echo "  $0 <project> --runs <number> [--job \"job name\"] [--input-file file] [--save-failures]"
    echo "  $0 <project> --days <number> [--job \"job name\"] [--input-file file] [--save-failures]"
    exit $EXIT_FAILURE
}

validate_inputs() {

    [[ $# -lt 3 ]] && usage

    PROJECT=$1
    shift

    while [[ $# -gt 0 ]]; do

        case "$1" in

            --runs)
                RUNS="$2"
                shift 2
                ;;

            --days)
                DAYS="$2"
                shift 2
                ;;

            --job)
                JOB_NAME="$2"
                shift 2
                ;;

            --input-file)
                INPUT_FILE="$2"
                shift 2
                ;;

            --save-failures)
                SAVE_FAILURES=true
                shift
                ;;

            *)
                echo "ERROR: Unknown argument $1"
                usage
                ;;
        esac
    done

    if [[ -n "$RUNS" && -n "$DAYS" ]]; then
        echo "ERROR: --runs and --days are mutually exclusive"
        exit $EXIT_FAILURE
    fi

    if [[ -z "$RUNS" && -z "$DAYS" ]]; then
        echo "ERROR: Either --runs or --days must be provided"
        exit $EXIT_FAILURE
    fi

    if [[ -n "$JOB_NAME" && -n "$INPUT_FILE" ]]; then
        echo "ERROR: --job and --input-file cannot be used together"
        exit $EXIT_FAILURE
    fi

    if [[ -n "$RUNS" ]]; then
        RETENTION_FLAG="--jobrun-retention-runs"
        VALUE="$RUNS"
    else
        RETENTION_FLAG="--jobrun-retention-days"
        VALUE="$DAYS"
    fi
}

fetch_jobs() {

    if [[ -n "$JOB_NAME" ]]; then
        JOB_LIST="$JOB_NAME"

    elif [[ -n "$INPUT_FILE" ]]; then
        JOB_LIST=$(cat "$INPUT_FILE")

    else
        JOB_LIST=$(cpdctl dsjob list-jobs -p "$PROJECT" 2>/dev/null | \
            grep -v "^Total:" | \
            grep -v "^Status code" | \
            grep -v "^\.\.\." | \
            sed '/^$/d')
    fi

    [[ -z "$JOB_LIST" ]] && {
        echo "No jobs found."
        return
    }

    TOTAL_JOBS=$(echo "$JOB_LIST" | wc -l | tr -d ' ')
    echo "Found $TOTAL_JOBS jobs."
}

update_retention() {

    FAILED_JOBS=()

    while IFS= read -r JOB; do

        echo "Updating: $JOB"

        echo "Executing: cpdctl dsjob update-job -p \"$PROJECT\" -n \"$JOB\" $RETENTION_FLAG $VALUE"
        cpdctl dsjob update-job -p "$PROJECT" -n "$JOB" $RETENTION_FLAG "$VALUE"

        STATUS=$?

        if [[ $STATUS -ne 0 ]]; then
            FAILED_JOBS+=("$JOB")
        else
            ((SUCCESS_COUNT++))
        fi

    done <<< "$JOB_LIST"
}

handle_failures() {

    while [[ ${#FAILED_JOBS[@]} -ne 0 && $CURRENT_RETRY -lt $MAX_RETRY ]]; do

        ((CURRENT_RETRY++))

        echo "Retry attempt $CURRENT_RETRY..."

        JOB_LIST=$(printf "%s\n" "${FAILED_JOBS[@]}")

        FAILED_JOBS=()

        update_retention
    done

    FAILED_COUNT=${#FAILED_JOBS[@]}

    if [[ $FAILED_COUNT -ne 0 ]]; then

        echo "Final failed jobs:"
        printf " - %s\n" "${FAILED_JOBS[@]}"

        if [[ -n "$INPUT_FILE" ]]; then

            printf "%s\n" "${FAILED_JOBS[@]}" > "$INPUT_FILE"

        elif [[ "$SAVE_FAILURES" == true ]]; then

            mkdir -p logs

            FILE="logs/failed_${PROJECT}_$(date +%s%3N).txt"

            printf "%s\n" "${FAILED_JOBS[@]}" > "$FILE"

            echo "Saved failures to $FILE"
        fi
    else
        [[ -n "$INPUT_FILE" ]] && rm -f "$INPUT_FILE"
    fi
}

print_summary() {

    echo ""
    echo "========= SUMMARY ========="
    echo "Project        : $PROJECT"
    echo "Retention Mode : $VALUE"
    echo "Total Jobs     : $TOTAL_JOBS"
    echo "Successful     : $SUCCESS_COUNT"
    echo "Failed         : $FAILED_COUNT"
    echo "Retry Attempts : $CURRENT_RETRY"
    echo "==========================="
}

main() {

    validate_inputs "$@"

    fetch_jobs

    [[ -z "$JOB_LIST" ]] && {
        print_summary
        exit $EXIT_SUCCESS
    }

    update_retention

    handle_failures

    print_summary

    [[ $FAILED_COUNT -ne 0 ]] && exit $EXIT_FAILURE || exit $EXIT_SUCCESS
}

main "$@"