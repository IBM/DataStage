# DataStage Job Run Retention and Cleanup
## Overview

Job run logs and artifacts are stored in the `file-api-claim` PVC at the following location:

**Storage Path:** `/mnt/asset_file_api/projects/<PROJECT_ID>/assets/job_run/log` in `asset-files-api`

## Important Notes

- In DataStage versions **CPD5.3.1 and earlier**, the default project job run retention is set to **"No limit"**
- Changes to project default retention settings apply **only to newly created jobs**
- Existing jobs are **not affected** by default retention changes

## Recommended Cleanup Process

To properly manage job run retention in DataStage, follow these steps in this order:

1. **Prune existing job runs** using [`pruneJobs.sh`](./scripts/pruneJobs.sh)
2. **Set retention policy** for jobs using [`jobRunHistoryRetention.sh`](./scripts/jobRunHistoryRetention.sh)
3. **Update project default retention policy** to the desired value for future jobs. 

## Setting Retention Policy

Use the [`jobRunHistoryRetention.sh`](./scripts/jobRunHistoryRetention.sh) script to configure retention policies.

**Prerequisites:** `cpdctl` must be configured before running the script.

### Usage Examples

**Set retention for all jobs in a project:**
```bash
jobRunHistoryRetention.sh <PROJECT_NAME> --runs <Number of runs to keep>
# OR
jobRunHistoryRetention.sh <PROJECT_NAME> --days <Number of days to keep>
```

**Set retention for a single job:**
```bash
jobRunHistoryRetention.sh <PROJECT_NAME> --job "<JOB_NAME>" --runs <Number of runs to keep>
# OR
jobRunHistoryRetention.sh <PROJECT_NAME> --job "<JOB_NAME>" --days <Number of days to keep>
```

**Set retention for multiple jobs from a file:**
```bash
jobRunHistoryRetention.sh <PROJECT_NAME> --input-file <FILE_WITH_LIST_OF_JOBS> --runs <Number of runs to keep>
# OR
jobRunHistoryRetention.sh <PROJECT_NAME> --input-file <FILE_WITH_LIST_OF_JOBS> --days <Number of days to keep>
```

**Save failed jobs to a log file:**
```bash
jobRunHistoryRetention.sh <PROJECT_NAME> --runs <Number> --save-failures
```

### Script Features

- **Automatic retry:** Failed operations are retried up to 3 times
- **Failure tracking:** Use `--save-failures` to save failed job names to a log file in the `logs/` directory
- **Input file updates:** When using `--input-file`, the file is automatically updated with only failed jobs after execution

### When Retention Policy Takes Effect

The retention policy is triggered in the following scenarios:
- When a job is **created** with a retention policy
- When a job is **updated** with a retention policy
- When a job run is **patched** to a finished state

## Cleanup Existing Job Runs

Use the [`pruneJobs.sh`](./scripts/pruneJobs.sh) script to clean up existing job runs.

**Prerequisites:** `cpdctl` must be configured before running the script.

### Performance Enhancement

When `cpdctl` is configured with version **1.8.145 or later**, the script supports the `--threads` option for parallel job runs cleanup. Earlier versions only supported threading for jobs, not job runs.

### Usage Examples

**Prune all jobs in a project:**
```bash
pruneJobs.sh <PROJECT_NAME> --keep-runs <Number of runs to keep>
# OR
pruneJobs.sh <PROJECT_NAME> --keep-days <Number of days to keep>
```

**Prune a single job:**
```bash
pruneJobs.sh <PROJECT_NAME> --job "<JOB_NAME>" --keep-runs <Number of runs to keep>
# OR
pruneJobs.sh <PROJECT_NAME> --job "<JOB_NAME>" --keep-days <Number of days to keep>
```

**Prune multiple jobs from a file:**
```bash
pruneJobs.sh <PROJECT_NAME> --input-file <FILE_WITH_LIST_OF_JOBS> --keep-runs <Number of runs to keep>
# OR
pruneJobs.sh <PROJECT_NAME> --input-file <FILE_WITH_LIST_OF_JOBS> --keep-days <Number of days to keep>
```

**Save failed jobs to a log file:**
```bash
pruneJobs.sh <PROJECT_NAME> --keep-runs <Number> --save-failures
```

### Script Features

- **Automatic retry:** Failed operations are retried up to 3 times
- **Failure tracking:** Use `--save-failures` to save failed job names to a log file in the `logs/` directory
- **Input file updates:** When using `--input-file`, the file is automatically updated with only failed jobs after execution
- **Validation:** Ensures positive integer values for retention parameters

## Additional Resources

For more information and the latest scripts, visit the [IBM DataStage GitHub repository](https://github.com/IBM/DataStage/tree/main/dsjob/blogs).