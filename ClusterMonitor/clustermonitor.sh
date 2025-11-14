#!/usr/bin/env bash
# ----------------------------------------------------------------------------------------------------
# IBM Confidential
# (C) Copyright IBM Corp. 2025  All Rights Reserved.
#
# This script is a utility to monitor CPD cluster for DataStage runtime pods

set -e

#######################################################################
# constants and variables
#######################################################################
SLEEP_TIME=10
CORDONED_WORKER_DIR="/px-storage/PXRuntime/WLM/"
LOCAL_CORDONED_WORKER_FILE="/tmp/.cordonedWorkers"
LOCAL_CORDONED_WORKER_FILE_BACK="$LOCAL_CORDONED_WORKER_FILE.back"
NODE_STATUS_SCHEDULINGDISABLED_STR="SchedulingDisabled"
DATASTAGE_POD_STR="datastage-px"
DATASTAGE_PX_RUNTIME_POD_STR="ibm-datastage-px-runtime"
POD_STATUS_RUNNING="Running"
kubernetesCLI=""

#######################################################################
# Utilities
#######################################################################

contains_runtime() {
    local input_string="$1"
    
    if [[ "$input_string" == *"ibm-datastage-px-runtime"* ]]; then
        return 0  
    else
        return 1  
    fi
}

get_last_chars() {
    local str="$1"
    local num="${2:-5}"
    echo "${str: -$num}"
}

#######################################################################
# CLI Detection
#######################################################################

set_cli() {
    if which kubectl &>/dev/null; then
        kubernetesCLI="kubectl"
    elif which oc &>/dev/null; then
        kubernetesCLI="oc"
    else
        echo "ERROR: Unable to locate oc nor kubectl cli in execution path."
    fi
    echo "Setting Kubernetes cli to '${kubernetesCLI}'"
}

#######################################################################
# Print
#######################################################################

print_header() {
    clear
    echo ""
    echo "Continuous cluster monitoring"
    echo "Press Ctrl+C to stop the monitoring or kill the application"
    echo "==============================================================================================================================================="
    printf "%-50s %-25s %-25s %-17s %-20s\n" "NODE_NAME" "NODE_STATUS" "DATASTAGE_RUNTIME_PODS" "DATASTAGE_PROCS" "DATASTAGE_JOBS"
    echo "-----------------------------------------------------------------------------------------------------------------------------------------------"
    echo ""
}

print_node_summary() {
    local node_name="$1"
    local node_status="$2"
    local datastage_pods="$3"
    local total_osh_procs="$4"
    local total_queued_jobs="$5"
    local total_running_jobs="$6"
    local all_pods=("${@:7}")  
    

    local job_counts=""
    
    if [[ -n "$total_running_jobs" && "$total_running_jobs" =~ ^[0-9]+$ && "$total_running_jobs" -ne 0 ]]; then
        job_counts="$job_counts $total_running_jobs Running"
    fi
    
    if [[ -n "$total_queued_jobs" && "$total_queued_jobs" =~ ^[0-9]+$ && "$total_queued_jobs" -ne 0 ]]; then
        if [[ "$job_counts" == *"Running"* ]]; then
            job_counts="$job_counts, $total_queued_jobs Queued"
        else
            job_counts="$job_counts $total_queued_jobs Queued"
        fi
    fi
    
    printf "%-50s %-25s %-25s %-17s %-10s\n" "$node_name" "$node_status" "$datastage_pods" "$total_osh_procs" "$job_counts"
    
    if [ "$datastage_pods" -gt 0 ]; then
        for pod in "${all_pods[@]}"; do
            printf "       %-25s\n" "$pod"
        done
    fi
}

#######################################################################
# Pod Processing 
#######################################################################

count_queued_jobs() {
    local pod_name="$1"
    local ends_with=$(get_last_chars "$pod_name" 5)
    local directory="/px-storage/PXRuntime/queuedJobs"
     
    # Execute command in pod and count files
    local count=$($kubernetesCLI exec "$pod_name" -- \
        sh -c "find '$directory' -maxdepth 1 -type f -name '*$ends_with' 2>/dev/null | wc -l" 2>/dev/null)
    
    echo "${count:-0}"
}
count_running_jobs() {
    local pod_name="$1"
    local ends_with=$(get_last_chars "$pod_name" 5)
    local directory="/px-storage/PXRuntime/runningJobs"
     
    local count=$($kubernetesCLI exec "$pod_name" -- \
        sh -c "find '$directory' -maxdepth 1 -type f -name '*$ends_with' 2>/dev/null | wc -l" 2>/dev/null)
    
    echo "${count:-0}"
}

get_pod_process_count() {
    local namespace="$1"
    local pod_name="$2"
    
    local proc_count=$($kubernetesCLI exec -n "$namespace" "$pod_name" -- \
        sh -c "ps aux 2>/dev/null | grep -E 'osh|python' | grep -v grep | wc -l" 2>/dev/null || echo "0")
    
    echo "$proc_count"
}

process_cordoned_node_pods() {
    local node_name="$1"
    local datastage_pods="$2"
    local datastage_pods_info="$3"
    
    if [ "$datastage_pods" -gt 0 ]; then
        while read -r pod_line; do
            pod_name=$(echo "$pod_line" | awk '{print $2}')
            echo "$node_name:$pod_name" >> "$LOCAL_CORDONED_WORKER_FILE_BACK"
        done <<< "$datastage_pods_info"
    fi
}

process_datastage_pods() {
    local datastage_pods_info="$1"
    
    local total_osh_procs=0
    local total_queued_jobs=0
    local total_running_jobs=0
    local all_pods=()
    
    if [ -n "$datastage_pods_info" ]; then
        while read -r pod_line; do
            namespace=$(echo "$pod_line" | awk '{print $1}')
            pod_name=$(echo "$pod_line" | awk '{print $2}')
            pod_status=$(echo "$pod_line" | awk '{print $4}')
            
            all_pods+=("$pod_name")
            
            if [[ "$pod_status" == *"$POD_STATUS_RUNNING"* ]]; then
                proc_count=$(get_pod_process_count "$namespace" "$pod_name")
                total_osh_procs=$((total_osh_procs + proc_count))

                if contains_runtime "$pod_name"; then
                    queued_jobs_count=$(count_queued_jobs "$pod_name")
                    running_jobs_count=$(count_running_jobs "$pod_name")
                    total_queued_jobs=$((total_queued_jobs + queued_jobs_count))
                    total_running_jobs=$((total_running_jobs + running_jobs_count))
                fi
            fi
        done <<< "$datastage_pods_info"
    fi

    echo "$total_osh_procs:$total_queued_jobs:$total_running_jobs:${all_pods[*]}"
}

#######################################################################
# File Management
#######################################################################

update_cordoned_workers_file() {
    if ! cmp -s "$LOCAL_CORDONED_WORKER_FILE" "$LOCAL_CORDONED_WORKER_FILE_BACK"; then
        datastage_px_runtime_pods_info=$($kubernetesCLI get pods --all-namespaces --no-headers 2>/dev/null | grep "$DATASTAGE_PX_RUNTIME_POD_STR")
        datastage_px_runtime_pods_count=$(echo "$datastage_px_runtime_pods_info" | wc -l)
        
        if [ "$datastage_px_runtime_pods_count" -gt 0 ]; then
            while read -r px_pod_line; do
                px_pod_name=$(echo "$px_pod_line" | awk '{print $2}')
                px_pod_status=$(echo "$px_pod_line" | awk '{print $4}')
                
                if [[ "$px_pod_status" == *"$POD_STATUS_RUNNING"* ]]; then
                    echo "Copying $LOCAL_CORDONED_WORKER_FILE to $px_pod_name:$CORDONED_WORKER_DIR"
                    cp "$LOCAL_CORDONED_WORKER_FILE_BACK" "$LOCAL_CORDONED_WORKER_FILE"
                    echo " $kubernetesCLI cp $LOCAL_CORDONED_WORKER_FILE $px_pod_name:$CORDONED_WORKER_DIR"   
                    $kubernetesCLI cp "$LOCAL_CORDONED_WORKER_FILE" "$px_pod_name:$CORDONED_WORKER_DIR"
                fi
            done <<< "$datastage_px_runtime_pods_info"
        fi
    fi
}

initialize_working_files() {
    echo -n > "$LOCAL_CORDONED_WORKER_FILE_BACK"
}

#######################################################################
# Node Processing 
#######################################################################

process_node() {
    local node_line="$1"
    
    local node_name=$(echo "$node_line" | awk '{print $1}')
    local node_status=$(echo "$node_line" | awk '{print $2}')
    
    local datastage_pods_info=$($kubernetesCLI get pods --all-namespaces --field-selector spec.nodeName="$node_name" --no-headers 2>/dev/null | grep "$DATASTAGE_POD_STR")
    local datastage_pods=$(echo "$datastage_pods_info" | awk 'NF' | wc -l)
    
    if [[ "$node_status" == *"$NODE_STATUS_SCHEDULINGDISABLED_STR"* ]]; then
        process_cordoned_node_pods "$node_name" "$datastage_pods" "$datastage_pods_info"
    fi
    
    local pod_metrics=$(process_datastage_pods "$datastage_pods_info")
    
    local total_osh_procs=$(echo "$pod_metrics" | cut -d: -f1)
    local total_queued_jobs=$(echo "$pod_metrics" | cut -d: -f2)
    local total_running_jobs=$(echo "$pod_metrics" | cut -d: -f3)
    local all_pods_str=$(echo "$pod_metrics" | cut -d: -f4-)
    local all_pods=()
    if [ -n "$all_pods_str" ]; then
        IFS=' ' read -r -a all_pods <<< "$all_pods_str"
    fi
    
    print_node_summary "$node_name" "$node_status" "$datastage_pods" "$total_osh_procs" "$total_queued_jobs" "$total_running_jobs" "${all_pods[@]}"
}


#######################################################################
# Monitoring Loop
#######################################################################

monitor_cluster() {
    while true; do
        print_header
        initialize_working_files
        
        $kubernetesCLI get nodes --no-headers  | grep -v master| while read -r node_line; do
            process_node "$node_line"
        done
        
        update_cordoned_workers_file
        sleep "$SLEEP_TIME"
    done
}

#######################################################################
# Start Script execution
#######################################################################

main() {
    set_cli
    monitor_cluster
}

# Run the script
main "$@"
