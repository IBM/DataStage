#!/usr/local/bin/bash

print_header() {
    echo "-----------------------------------------------" | tee -a $OUTFILE
    echo "# $1" | tee -a $OUTFILE
    echo "-----------------------------------------------"  | tee -a $OUTFILE
    echo ''
}

print_message() {
    echo "$1" | tee -a $OUTFILE
}

print_newline() {
    echo '' | tee -a $OUTFILE
}

TIMESTAMP=`date +"%Y-%m-%d_%H-%M-%S"`
OUTDIR="oc_$TIMESTAMP"
OUTFILE="${OUTDIR}/oc_${TIMESTAMP}.txt"

mkdir $OUTDIR

# ----------------------------------------------------------
print_header 'Basic details'
# ----------------------------------------------------------

print_message '* Listing current context'
oc config current-context | tee -a $OUTFILE
print_newline

print_message '* Listing oc version'
oc version | tee -a $OUTFILE
print_newline

# ----------------------------------------------------------
print_header 'Cluster node details:'
# ----------------------------------------------------------

print_message '* Listing nodes'
oc get nodes -o wide  | tee -a $OUTFILE
print_newline

NODE_OUT_DIR="${OUTDIR}/nodes"
mkdir $NODE_OUT_DIR

echo '* Gathering node details'
for node in `oc get nodes --no-headers -o custom-columns=:metadata.name`; do
    NODE_OUT_FILE="${NODE_OUT_DIR}/${node}"
    echo "- $node"
    oc get node $node -o json | jq '.status | {capacity: .capacity, allocatable: .allocatable}' >> $NODE_OUT_FILE  2>&1
    oc describe node $node | awk '/Allocated resources:/,/^Events:$/ {print}' | head -n -1  >> $NODE_OUT_FILE 2>&1
done
print_newline

# ----------------------------------------------------------
print_header 'Storage Class, PV and PVC details'
# ----------------------------------------------------------
print_message '* Storage class details'
oc get sc | tee -a $OUTFILE

print_message '* Cluster pv details'
    oc get pv | tee -a $OUTFILE
print_newline

print_message '* Cluster pvc details'
    oc get pv | tee -a $OUTFILE
print_newline

# ----------------------------------------------------------
print_header 'Product installation details'
# ----------------------------------------------------------
print_message '* Getting installed component details'
cr_list=("ccs" "datastage" "wspipelines" "zenservices")
for item in "${cr_list[@]}"; do
    if oc get "$item" >/dev/null 2>&1; then
        print_message "- Custom resource: $item"
        oc get $item -o yaml | grep Build | tee -a $OUTFILE
        oc get $item -o yaml | grep scaleConfig | tee -a $OUTFILE
        print_newline
    fi
done

# ----------------------------------------------------------
print_header 'Getting DataStage PXRuntime details'
# ----------------------------------------------------------
print_message '* Listing DataStage instances'
oc get pxruntime | tee -a $OUTFILE
print_newline

print_message '* Gathering DataStage instance details'
PXRUNTIME_OUT_DIR="${OUTDIR}/pxruntime"
mkdir $PXRUNTIME_OUT_DIR
for item in `oc get pxruntime --no-headers -o custom-columns=:metadata.name`; do

    INSTANCE_OUT_DIR="./${PXRUNTIME_OUT_DIR}/${item}"
    mkdir $INSTANCE_OUT_DIR

    print_message "- pxruntime: $item"
    oc get pxruntime $item -o yaml | grep ' scaleConfig' | tee -a $OUTFILE
    print_newline

    item_pxruntime_pod=`oc get pods | grep 'px-runtime' | grep $item`
    oc exec $item_pxruntime_pod -- cat '/px-storage/PXRuntime/WLM/.compute_running' >> "${INSTANCE_OUT_DIR}/compute_running"  2>&1
    oc exec $item_pxruntime_pod -- cat '/px-storage/config/wlm/wlm.config.xml' >> tee -a "${INSTANCE_OUT_DIR}/wlm.config.xml"  2>&1

    echo 'Downloading wlm log files'
    echo 'TODO'
done

# ----------------------------------------------------------
print_header 'List of all the failed pods in the current namespace'
# ----------------------------------------------------------
oc get pods --field-selector status.phase=Failed | tee -a $OUTFILE
print_newline
print_message 'Attempting to gather logs from the failed pods ...'
echo 'TODO'
# for item in `oc get pods --field-selector status.phase=Failed`; do
    # oc logs item
# done


# ----------------------------------------------------------
print_header 'Getting Job details'
# ----------------------------------------------------------

print_message 'Checking for failed jobs'
echo 'TODO'
print_newline

print_message 'Getting logs from failed jobs'
echo 'TODO'
print_newline

# ----------------------------------------------------------
echo 'Saving the output'
# ----------------------------------------------------------
tar -zcf "$OUTDIR.tar.gz" "$OUTDIR"
echo "Output saved to $OUTDIR.tar.gz"
print_message '---Done---'