CPDCTL and the dsjob plugin are command-line interfaces (CLI) you can use to manage your DataStage® resources in DataStage as a Service hosted on IBM Cloud.

This document provides latest release change to dsjob for our Cloud deployments.

**Date: Oct 25, 2025**
**CPDCTL Version: 1.8.41**

### New commands
### Command changes
Export commands such as `export-datastage-assets`,  `export-zip` and `export-project`  now takes a new flag `include-compile-metadata` which allows export to include compile time metadata on the pipelines.

`get-job run` command takes a new flag `skip-metrics` to avoid call back to get job metrics thus making it efficient.

### Fixes
`run-pipeline` command now handles creation of a job if job does not exist irunning in optimized mode.
`jobrunclean` command now attempts to  `cancel` the job run and `delete` the job run when `delete` call fails to delete a job run.
`run` and `run-pipeline` commands now read environment variable is check ENABLE_CUSTOM_EXITCODE=1 and exit the shell with return code of 254 instead of 1 when an unexpected error had occurred.

