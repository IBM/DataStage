#!/bin/bash


#set -x


project_name=$1
function totalRuns()
{
   project_name=$1
   job_id=$2
   job_name=$3
   total_runs=$(cpdctl job run list --project "$project_name" --job-id "$job_id" --output json| jq .total_rows)
   echo "$job_name:$total_runs" #| column -s: -t
}


joblist=`cpdctl dsjob list-jobs -p $project_name --with-id | grep -v -e "\.\.\." -e Total -e Status -e Job -e ---`
while IFS= read -r job; do
#   echo "Processing Job ID: $job"
   jobname=$(echo $job| cut -d '|' -f1)
   jobid=$(echo $job| cut -d '|' -f2)
   totalRuns $project_name "$jobid" "$jobname"
done <<< "$joblist"
 
cpdctl job run list --project "$project_name" --job-id "$job_id" --output json| jq .total_rows
 
