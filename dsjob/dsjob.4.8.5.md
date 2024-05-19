# DataStage command-line tools

CPDCTL and the `dsjob` tool are command-line interfaces (CLI) you can use
to manage your DataStage resources in CPD.

Use the command-line tools to reuse any DataStage scripts that exist on your system.
You can use the following command-line
tools to run DataStage tasks:

- CPDCTL: `cpdctl dsjob` or `cpdctl datastage`

Using the CLI tools, you can work with:

- [Projects](#projects)
- [Jobs](#jobs)
- [Job logs](#job-logs)
- [Job runs](#job-runs)
- [Job migration](#job-migration)
- [Flows](#flows)
- [Pipelines](#pipelines)
- [Imports and exports](#imports-and-exports)
- [.zip files](#zip-files)
- [Connections](#connections)
- [Hardware specifications](#hardware-specifications)
- [Runtime environments](#runtime-environments)
- [Subflows](#subflows)
- [Parameter sets](#parameter-sets)
- [Table definitions](#table-definitions)
- [XML libraries](#xml-libraries)
- [Environment variables](#environment-variables)
- [Data set and File set](#data-set-and-file-set)
- [Remote engines](#remote-engines)
- [Versions](#versions)
- [User-defined stages](#user-defined-stages)
- [Assets and attachments](#assets-and-attachments)
- [Match specifications](#match-specifications)
- [Function libraries](#function-libraries)
- [Java libraries](#java-libraries)
- [Message handlers](#message-handlers)
- [Project settings](#datastage-project-settings)
- [Standardization rules](#standardization-rules)
- [Data Quality rules](#data-quality-rules)
- [User volumes](#user-volumes)
- [Dependencies](#dependencies)
- [DSParams](#dsparams)
- [Validation](#validation)
- [CFF Schemas](#complex-flat-file-schemas)
- [Folders](#folders)
- [Git integration](#git-integration)

# Resources

For installation, configuration, available commands, supported outputs, and usage scenarios,
refer to [CPDCTL Command Line Interface](https://github.com/IBM/cpdctl).

For more information on the CPDCTL command, see [CPDCTL reference](https://github.com/IBM/cpdctl/blob/master/README_command_reference.md).

For detailed information about installing, configuring, and using the DataStage jobs command-line interface, see [Installation](https://github.com/IBM/cpdctl#installation).

To create a profile and enable `dsjob` use the following scripts.

For CPDaaS:
```
#!/bin/bash
export DSJOB_URL=https://dataplatform.cloud.ibm.com
export CPDCTL_ENABLE_DSJOB=true
DSJOB_APIKEY=<YOUR APIKEY>
cpdctl config profile set ibmcloud-profile --url $DSJOB_URL --apikey $DSJOB_APIKEY --watson-studio-url https://api.dataplatform.cloud.ibm.com
```

For CPD:

```
#!/bin/bash
export DSJOB_URL=<CP4D CLUSTER URL>
export DSJOB_USER=<USER>
export DSJOB_PWD=<PASSWD>
cpdctl config user set CP4D-user --username $DSJOB_USER --password $DSJOB_PWD
cpdctl config profile set CP4D-profile --url $DSJOB_URL --user CP4D-user
cpdctl config profile use CP4D-profile
```

If you have multiple profiles, you can run a command against a specific profile with either `cpdctl project list --profile <PROFILE>` or `CPD_PROFILE=<PROFILE> cpdctl project list`. For example, to run multiple commands in a profile without changing your default profile, you can run the following commands.

```
export CPD_PROFILE=<PROFILE-1>
cpdctl project list
cpdctl ....
export CPD_PROFILE=<PROFILE-2>
cpdctl project list
cpdctl ....
unset CPD_PROFILE <go back to default profile>
```

# Commands

To enable the `cpdctl dsjob` commands, you must set the environment variable
CPDCTL_ENABLE_DSJOB to `true` in the environment where the CPD command-line interface is installed.
When you set up the `dsjob` command line environment, you must escape any
special characters ($, ") in your password with a backward slash. For example,
`myPa$$word` must be written as `myPa\$\$word`.

## Projects

### Listing projects

The following syntax displays a list of all known projects on the specified project:
```
cpdctl dsjob list-projects [--sort|--sort-by-time] [--with-id] [--output json]
```

- `with-id` when specified prints the project id and project name.
- `sort` when specified returns the list of projects sorted in alphabetical order. This field is optional.
- `sort-by-time` when specified sorts the list by create or update time. One of `sort` or `sort-by-time` can be specified.
- `output`  specifies the format of the output. This field is optional.

A list of all the projects is displayed, one per line.
A status code is printed to the
output. A status code of 0 indicates successful completion of the command.

### Creating projects
The following syntax is used to create a project:

CPD:
```
cpdctl dsjob create-project --name NAME 
```

CPDaaS:
```
cpdctl dsjob create-project --name NAME [--storage <STG>] [--storage-type bmcos_object_storage|amazon_s3]
```

- `name` is the name of the project that is being created.
- `storage` is the name of the CRN for cloud, for example:
`crn:v1:staging:public:cloud-object-storage:global:a/`.
- `type` is the storage type for cloud. The default value is `bmcos_object_storage` and the alternate value is `amazon_s3`.

The project ID of the created project is printed to the output.
A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Deleting projects

The following syntax is used to delete a project:
```
cpdctl dsjob delete-project {--project PROJECT | --project-id PROJID}
```

- `project` is the name of the project that is being deleted.
- `project-id` is the id of the project that is being deleted. One of `project` or `project-id` must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

## Jobs

### Listing jobs

The following syntax displays a list of all jobs in the specified project:
```
cpdctl dsjob list-jobs {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id] [--sched-info]
```

- `project` is the name of the project that contains the jobs to list.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `sort` when specified returns the list of jobs sorted in alphabetical order. This field is optional.
- `with-id` when specified prints the job id along with the name of the job.
- `sort-by-time` when specified sorts the list by last update time. One of `sort` or `sort-by-time` can be specified.
- `sched-info` shows schedule information for jobs that are configured to run on a schedule.

A status code is printed to the output. A status code of 0 indicates successful completion of the
command.

### Creating jobs

The following syntax creates a job in the specified project:
```
cpdctl dsjob create-job {--project PROJECT | --project-id PROJID} {--flow NAME | --flow-id ID} [--name NAME] [--description DESCRIPTION] [--schedule-start yyyy-mm-dd:hh:mm] [--schedule-end yyyy-mm-dd:hh:mm] [{--repeat every/hourly/daily/monthly} --minutes (0-59) --hours (0-23) --day-of-week (0-6) --day-of-month (1-31)]
```

- `project` is the name of the project that the job is created for.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the job to be created.
- `description` is the description of the job to be created. This field is optional.
- `flow` is the name of the flow. This field must be specified.
- `repeat` indicates frequency of job run. Permitted values are `every`, `hourly`, `daily`, `weekly`, and `monthly`. The default value is `none`.
- `minutes` indicates interval in minutes or the minutes at which to run the job. Values in the range 0-59 are accepted.
- `hours` indicates hour of the day at which to run the job. Values in the range 0-23 are accepted.
- `day-of-month` repeats on day of the month, works with minutes and hours. Values in the range 0-31 are accepted. Ex: 2 (runs on the second of the month).
- `schedule-start` is the starting time for scheduling a job.
- `schedule-end` is the ending time for scheduling a job.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Getting jobs

The following syntax fetches a job by name from the specified project:
```
cpdctl dsjob get-job {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata] 
```

- `project` is the name of the project that contains the job.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the queried job.
- `id` is the id of the job. One of `name` or `id` must be specified.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This field is optional.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Deleting jobs

The following syntax deletes a job by name from the specified project:
```
cpdctl dsjob delete-job {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```

- `project` is the name of the project that contains the job.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the job that is being deleted.
- `id` is the id of the job. One of `name` or `id` must be specified. Multiple values can be specified for `name` and `id` to delete multiple items, in the format `--name NAME1 --name NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Listing job status

The following syntax displays a list of all jobs in the specified project and the status of their last run if present.
```
cpdctl dsjob list-job-status {--project PROJECT | --project-id PROJID} {--name name | --id ID} [--sort | --sort-by-time | --sort-by-state | --sort-by-duration] [--start <YYYY-MM-DD:HH:MM:SS>] [--end <YYYY-MM-DD:HH:MM:SS>] [--with-past-runs]
```

- `project`  is the name of the project that contains the jobs to list.
- `project-id` is the id of the project. One of project or project-id must be specified.
- `sort` when specified returns the list of jobs sorted in alphabetical order. This field is optional.
- `sort-by-time` when specified returns the list of jobs sorted in chronological order. This field is optional.
- `sort-by-duration` when specified returns the list of jobs sorted in chronological order. This field is optional.
- `sort-by-state` when specified returns the list of jobs sorted as per status of last run. This field is optional. - One of sort or sort-by-time or or sort-by-duration or sort-by-state can be specified.
- `start` when specified, only jobs that started after this time are processed.
- `end` when specified, only jobs that are started before this time are processed.
- `with-past-runs` when true will process all the runs of the job if runs other than the last run of the job are processed.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Updating jobs

The following syntax updates a job by name from the specified project:
```
cpdctl dsjob update-job {--project PROJECT | --project-id PROJID} {--job NAME | --name NAME | --job-id ID | --id ID} [--run-name RUNNAME] [--param PARAM] [--param-file FILENAME] [--env ENV] [--paramset NAME]
```

- `project` is the name of the project that contains the job.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `job` or `name` is the name of the job.
- `job-id` or `id` is the id of the job. One of `job` or `job-id` must be specified.
- `run-name` is the name given to the job run.
- `param` specifies a parameter value to pass to the job. The value is in the format `name=value`, where name is the parameter name and value is the value to be set. This flag can be repeated, ex: `--param k1=v1 --param k2=v2`
- `paramfile` specifies a file that contains the parameter values to pass to the job. This field is currently not implemented.
- `env` specifies the environment in which the job is run. `env` is specified as a key=value pair. Key `env` or `env-id` can be used to choose a runtime environment. Example: `--env $APT_DUMP_SCORE=true --env env=ds-px-default`
- `paramset` is a list of parameter sets that can be used to overwrite the existing paramset values. ex: --paramset PS1=PROJDEF --paramset PS2. VS2 will override paramset PS1 values from PROJDEF and uses values from valueset VS2 for the paramset PS2.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Scheduling jobs

The following syntax schedules a job to run at a specific time or repeatedly in the specified project:
```
cpdctl dsjob schedule-job {--project PROJECT | --project-id PROJID}  {--job NAME | --name NAME | --job-id ID | --id ID} [--schedule-start yyyy-mm-dd:hh:mm] [--schedule-end yyyy-mm-dd:hh:mm] [--repeat every/hourly/daily/monthly --minutes (0-59) --hours (0-23) --day-of-week (0-6) --day-of-month (1-31)]
```

- `project` is the name of the project that the job is scheduled for.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the job to be scheduled.
- `id` is the id of the job to be scheduled.
- `repeat` indicates frequency of job run. Permitted values are `every`, `hourly`, `daily`, `weekly`, and `monthly`. The default value is `none`.
- `minutes` indicates interval in minutes or the minutes at which to run the job. Values in the range 0-59 are accepted.
- `hours` indicates hour of the day at which to run the job. Values in the range 0-23 are accepted.
- `day-of-month` repeats on day of the month, works with minutes and hours. Values in the range 0-31 are accepted. Ex: 2 (runs on the second of the month).
- `schedule-start` is the starting time for scheduling a job.
- `schedule-end` is the ending time for scheduling a job.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Cleaning up orphaned jobs

The following syntax deletes DataStage jobs that were orphaned by the deletion of their
corresponding flow:
```
cpdctl dsjob cleanup-jobs [--project PROJECT | --project-id PROJID] [--dry-run]
```

- `project` is the name of the project that contains the jobs.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `dry-run` when set to `true`, a trial run is attempted without deleting the jobs.

A status code is printed to the output. A status code of 0 indicates successful completion of the
command.

### Displaying job information

The following syntax displays the available information about a specified job:
```
cpdctl dsjob jobinfo {--project PROJECT | --project-id PROJID} {--job NAME | --name NAME | --job-id ID | --id ID} [--full] [--list-params]
```

- `project` is the name of the project that contains the job.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `job` or `name` is the name of the job.
- `job-id` is the id of the job. One of `job` or `job-id` must be specified.
- `full` displays more detailed information about the job, including information about all job runs. This field is optional.
- `list-params` displays job level configuration/local parameters and environment variables.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Running jobs

You can use the run command to start, stop, validate, and reset jobs. The run operation is asynchronous in nature and the status code indicates whether the job run is successfully submitted or not except when the --wait option is specified. Please see --wait flag description on how the behavior changes.
```
cpdctl dsjob run {--project PROJECT | --project-id PROJID} {--job NAME | --name NAME | --job-id ID | --id ID} [--run-name RUNNAME] [--param PARAM] [--param-file FILENAME] [--env ENVJSON] [--paramset PARAMSET] [--runtime-env <ENVNAME>] [--wait secs] [--warn-limit <n>] [--no-logs] [--language <LANGUAGE>]
```

- `project` is the name of the project that contains the job.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `job` is the name of the job.
- `job-id` is the id of the job. One of `job` or `job-id` must be specified.
- `run-name` is the name given to the job run.
- `param` specifies a parameter value to pass to the job. The value is in the format `name=value`, where name is the parameter name and value is the value to be set. This flag can be repeated, ex: `--param k1=v1 --param k2=v2`
- `paramfile` specifies a file that contains the parameter values to pass to the job. This field is not implemented currently.
- `env` specifies the environment in which job is run. `env` is specified as a key=value pair. Key `env` or `env-id` can be used to chose a runtime environment. Example: `--env $APT_DUMP_SCORE=true --env env=ds-px-default`
- `paramset` specifies parameter set/value set fields to be passed to the job run. There are three variations, 1. `--paramset PS1` sends all fields in parameter set PS1 as job parameters to the run, 2. `--paramset PS2.VS2` sends value set values as job parameters, 3. `--paramset PS1=PROJFDEF` overrides `paramset PS1` values from PROJDEF and send values of all fields in parameter set `PS1` as job parameters to the run.
- `runtime-env` specifies a runtime environment for the job to run in, value can be a name or an id.
- `wait` the job run waits for the specified amount of time for the job to finish. The job logs are printed to the output until the job is completed or the wait time expires. The return status indicates whether the job has finished, finished with warning, raised an error, or timed out after waiting. For example: `--wait 200` waits for a maximum of 200 secs, polling the job for completion, and if the job does not complete it returns a status code other than zero. You may specify `--wait -1` to wait indefinitely for the job to finish. This field is optional.
- `warn-limit` specifies the number of warnings after which a job is terminated.
- `language` is the locale the job run will use, ex: `--language fr`.
- `no-logs` when specified pipeline run will not produce output logs while waiting for the run to finish

When the `job` parameter starts with a `$` it will also be
added as a environment variable.
A status code is printed to the output.

- 0: successfully completed
- 1: completed with warnings
- 3: completed with error
- 4: failed
- 5: canceled
- -1: other

### Stopping jobs

You can use the stop command to stop or cancel running jobs. The stop operation is asynchronous
in nature and the status code indicates whether the job stop is successfully submitted or not.
```
cpdctl dsjob stop {--project PROJECT | --project-id PROJID} {--job NAME | --name NAME | --job-id ID | --id ID} [--run-id RUNID]
```

- `project` is the name of the project that contains the job.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `job` or `name` is the name of the job.
- `job-id` or `id` is the id of the job. One of `job` or `job-id` must be specified.
- `runid` can be specified to cancel or stop an existing job run. If `runid` is not specified, the `runid` of the latest job run that is not completed is used by default. This field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Wait For Jobs

The following syntax is used to wait for an anticipated job run and obtain status of the job.

```
cpdctl dsjob waitforjob {--project PROJECT | --project-id PROJID}  {--job NAME | --name NAME | --job-id ID | --id ID} [--run-id RUNID] --wait SEC [--logs] [--since n[s|m]] [--after TIMESTAMP]
```

- `project`  is the name of the project that contains the job.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the job.
- `id`  is the id of the job. One of  `job`  or  `job-id`  must be specified.
- `run-id` is the id of a particular job run.
- `wait` total wait time to wait for getting status on a job run.
- `logs` will show logs of a running job while waiting to finish.
- `since` only wait for job that has started in the last specified amount of time. The value should be number of seconds or minutes.
- `after` only wait for job that has started after the timestamp specified.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

## Job logs

### Displaying a specific log entry

The following syntax displays the specified entry in a job log file:
```
cpdctl dsjob logdetail {--project PROJECT | --project-id PROJID} {--job NAME | --name NAME | --job-id ID | --id ID} [--run-id RUNID] [--eventrange EVENTRANGE] [--compatible] --follow
```

- `project` is the name of the project that contains the job with the specified log entry.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `job` or `name` is the name of the job. 
- `job-id` or `id` is the id of the job. One of `job` or `job-id` must be specified.
- `runid` processes the log entry for a specific `runid`. If `runid` is not specified, the latest run is used by default. This field is optional.
- `eventrange` is the range of event numbers that is assigned to the entry that is printed to the output. The first entry in the file is 0. If `eventrange` is not specified, the full log is processed. For example, if you specify `eventrange 2-4`, the third, fourth, and fifth entries from the log are printed.
- `compatible` will output logs in the format previously used by DataStage components. This field is optional.
- `follow` when specified enables log tailing.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Displaying a short log entry

The following syntax displays a summary of entries in a job log file:
```
cpdctl dsjob logsum {--project PROJECT | --project-id PROJID} {--job NAME | --name NAME | --job-id ID | --id ID} [--run-id RUNID] [--type TYPE] [--max MAX] [--compatible]
```

- `project` is the name of the project that contains the job with the log entries that are being retrieved.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `job` or `name` is the name of the job.
- `job-id` or `id` is the id of the job. One of `job` or `job-id` must be specified.
- `runid` processes the log entry for a specific runid. If `runid` is not specified, the latest run is used by default. This field is optional.
- `type` specifies the type of log entry to retrieve. If `type` is not specified, all the entries are retrieved. `type` can be one of the following options:
- INFO: Information
- WARNING: Warning
- FATAL: Fatal error
- REJECT: Rejected rows from a Transformer stage
- STARTED: All control logs
- RESET: Job reset
- BATCH: Batch control
- ANY: All entries of any type. This option is the default if `type` is not specified.
- `compatible` will output logs in the format previously used by DataStage components. This field is optional.
- `max n` limits the number of entries that are retrieved to
`n`.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Identifying the newest log entry

The following syntax displays the ID of the newest log entry of the specified type:
```
cpdctl dsjob lognewest {--project PROJECT | --project-id PROJID} {--job NAME | --name NAME | --job-id ID | --id ID} [--run-id RUNID] [--type TYPE]
```

- `project` is the name of the project that contains the job with the log entry that is being retrieved.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `job` or `name` is the name of the job.
- `job-id` or `id` is the id of the job. One of `job` or `job-id` must be specified.
- `type` can be one of the following options:
- INFO: Information
- WARNING: Warning
- FATAL: Fatal error
- REJECT: Rejected rows from a Transformer stage
- STARTED: All control logs
- RESET: Job reset
- BATCH: Batch control

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

## Job runs

### Getting job run statistics

The following syntax gets job run statistics for a particular job run in a project:
```
cpdctl dsjob jobrunstat {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}  [--run-id RUNID] [--all] [--with-metadata]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the job.
- `id` is the id of the job. One of `name` or `id` must be specified.
- `run-id` is the run id of the particular job run. This field is optional, if omitted the last job run statistics are displayed.
- `all` causes the statistics for all runs for the job to be displayed. When using this flag `run-id` is ignored.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Pruning job runs

Prune commands can be used to delete the job runs based on age or number of runs. The following syntax can be used to prune job runs in a project:
```
cpdctl dsjob prune {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--keep-runs NUMRUNS] [--keep-days NUMDAYS] [--threads n] [--dry-run]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the job.
- `id` is the id of the job. One of `name` or `id` must be specified.
- `keep-runs` specifies the number of latest runs to keep and deletes rest of the job runs clearing up space.
- `keep-days` specifies a number of days and deletes all job runs older than that number.
- `threads` specifies the number of parallel concurrent cleanup routines to run with one per job. The value should be in the range 5-20, default value is 5. This field is optional.
- `dry-run` does a mock run without deleting the job runs.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Getting job run cleanup

It is possible to have job runs that never complete and remain stale. These jobs are stuck in a starting or running state. The following syntax cleans up job runs in a project:
```
cpdctl dsjob jobrunclean {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--run-id RUNID] [--dry-run] [--threads n] [--before TIMESTAMP]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the job.
- `id` is the id of the job. One of `name` or `id` must be specified.
- `run-id` is the run id of the particular job run to clean up. This field is optional.
- `threads` specifies the number of parallel concurrent cleanup routines to run with one per job. The value should be in the range 5-20, default value is 5. This field is optional.
- `dry-run` does a mock run without deleting the job runs.
- `before` cleans up all jobs that are before the given timestamp. Format: `YYYY-MM-DD:hh:mm:ss`

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Listing job runs

The following syntax lists job runs for the specified job:
```
cpdctl dsjob list-jobruns {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--sort-by-time | --sort-by-runname | --sort-by-duration] [--detail] [--output file|json] [--file-name FILENAME]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the job.
- `id` is the id of the job. One of `name` or `id` must be specified.
- `sort-by-time` when specified sorts the list by create or update time.
- `sort-by-runname`  when specified sorts the list by run name of the job run.
- `sort-by-duration`  when specified sorts the list by run duration of the job run. One of sort-by-runname, sort-by-time, sort-by-duration can be specified.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Getting job runs

The following syntax gets job run details from the specified job:
```
cpdctl dsjob get-jobrun {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--run-id RUNID] [--output json|file] [--file-name FILENAME] [--with-metadata]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the job.
- `id` is the id of the job. One of `name` or `id` must be specified.
- `run-id` is the id of the job run.
- `output` specifies the format of the output. You can generate a JSON or output to a file. This field is optional.
- `file-name` specifies the name of the file to which the output is written. If not specified, the job run id is used as the name.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Listing active job runs

The following syntax lists all active job runs, including incomplete, cancelled and failed jobs:
```
cpdctl dsjob list-active-runs [--sort-by-time|--sort-by-jobname|--sort-by-assettype|--sort-by-duration|--sort-by-state] [--output json|file] [--file-name FILENAME]
```

- `sort-by-time` lists jobs sorted by create or update time.
- `sort-by-jobname` lists jobs sorted by job name in alphabetical order.
- `sort-by-assettype` lists jobs sorted by job type.
- `sort-by-duration` lists jobs sorted by the duration the jobs are active.
- `sort-by-state` lists jobs sorted by the job run state.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the
command.

### Listing stages in a flow

The following syntax lists all stages in a flow:

```
cpdctl dsjob list-stages {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the flow.
- `id` is the id of the flow. One of `name` or  `id` must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Listing links associated with a stage in a flow

The following syntax lists all links associated with a stage in a flow:

```
cpdctl dsjob list-links {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}  --stage STAGE
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the flow.
- `id` is the id of the flow. One of `name` or `id` must be specified.
- `stage` is the name of a stage in the flow.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Getting information on a link associated with a stage in a job run

The following syntax can be used to get link information for a stage in a job:

```
cpdctl dsjob get-stage-link {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}  [--run-id RUNID] --stage STAGE --link LINK
```

- `project`  is the name of the project.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the job.
- `id`  is the id of the job. One of  `name`  or  `id`  must be specified.
- `run-id` is the id of the job run, this field is optional. When not specified, the latest job run is used.
- `stage` is the name of a stage in the job.
- `link` is the name of a link associated with the stage.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Get report on a job run

The following syntax generates a report for a job run:

```
get-jobrun-report {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--run-id RUNID] [--output json|file] [--file-name FILENAME]
```

- `project`  is the name of the project.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the job.
- `id`  is the id of the job. One of  `name`  or  `id`  must be specified.
- `run-id` is the id of the job run, this field is optional. When not specified, the latest job run is used.
- `output`  specifies the format of the output. This field is optional.
- `file-name`  specifies the name of the file to which the output is written. This field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

## Job migration

### Migrating jobs

The Migrate command can be used to create data flows from an exported ISX file. You can use the
command to check status or cancel a migration that is in progress.
```
cpdctl dsjob migrate {--project PROJECT | --project-id PROJID} [--on-failure ONFAILURE] [--conflict-resolution CONFLICT-RESOLUTION] [--attachment-type ATTACHMENT-TYPE] [--import-only] [--create-missing] [--enable-local-connection] [--enable-platform-connection] [--enable-dataquality-rule] [--create-connection-paramsets] [--use-dsn-name] [--migrate_hive_impala] [--enable-notifications] [--storage-path STORAGE-PATH]  [--migrate-to-send-email] [--file-name FILENAME] [--status IMPORT-ID --format csv/json] [--stop IMPORT-ID] [--hard-replace] [--wait secs]
```

- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `on-failure` indicates what action to taken if the import process fails. Possible options are either `continue` or `stop`. This field is optional.
- `conflict-resolution` specifies the resolution when the data flow to be imported has a name conflict with an existing data flow in the project or catalog. Possible resolutions are `skip`, `rename`, or `replace`. This field is optional.
- `attachment-type` is the type of attachment. The default attachment type is `isx`. This field is optional.
- `import-only` when specified imports flows without compiling them or creating a job.
- `create-missing` when specified creates missing parameter sets and job parameters.
- `enable-local-connection` enables migrating a connection into a flow as a flow connection.
- `enable-dataquality-rule` when specified migrates a data rule from Information Analyzer as a Datahub rule.
- `create-connection-paramsets` when specified creates parameter sets for missing properties in connections.
- `use-dsn-name` when specified enables migration to use dsn-type names for connections. 
- `migrate_hive_impala` when true enables Hive Impala for migration.
- `enable-notifications` when true allows notifications to be sent during migration.
- `storage-path` directory path on the storage volume for scripts and other data assets. This fields is optional.
- `migrate-to-send-email` when true, all notification activity stages in sequence job are migrated as send email task nodes.
- `file-name` is the name of the input file. This field is required for an import operation but not with options `-stop` or `-status`.
- `status` returns the status of a previously submitted import job. A value for `importid` must be specified with this option.
- `stop` cancels an import operation that is in progress. A value for `importid` must be specified with this option.
- `hard-replace` If true, fields in parameter sets will be replaced with incoming source field values. This field can be used only when conflict resolution is set to skip or replace.
- `wait`  specifies the time in seconds to wait for the command to complete. For example, `--wait 200` waits for a maximum of 200 secs, checking status of the migration, and returns an exit code other than zero if it does not complete. You can set `--wait -1` to wait for completion indefinitely.

A status code is printed to the output.

- 0: successfully completed
- 1: failed
- 2: completed with error
- 3: timed out
- 4: canceled

## Flows

### Listing flows

The following syntax displays a list of all flows in the specified project:
```
cpdctl dsjob list-flows {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time | --sort-by-compiled] [--with-id] [--with-compiled]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `sort` when specified returns the list of flows sorted in alphabetical order. This field is optional.
- `sort-by-time` when specified sorts the list by create or update time. One of `sort` or `sort-by-time` can be specified.
- `sort-by-compiled` if true, list will be sorted by most recent compile time.
- `with-id` when specified prints the flow id along with the name of the flow.
- `with-compiled` if true, displays compile status, last compile time, and whether flow needs compilation.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Creating flows

The following syntax creates a flow in the specified project:
```
cpdctl dsjob create-flow {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] --pipeline-file FILENAME
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the flow that is being created.
- `description` is the description of the flow that is being created. This field is optional.
- `pipeline-file` is the name of the file that contains the flow JSON. This field must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Getting flows

The following syntax fetches a flow by name from the specified project:
```
cpdctl dsjob get-flow {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the queried flow.
- `id` is the id of the flow. One of `name` or `id` must be specified.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This field is optional.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Deleting flows

The following syntax deletes a flow by name from the specified project:
```
cpdctl dsjob delete-flow {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the flow.
- `id` is the id of the flow. One of `name` or `id` must be specified. Multiple values can be specified for `name` and `id` to delete multiple items, in the format `--name NAME1 --name NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Compiling flows

The following syntax allows you to compile flows in the specified project:
```
cpdctl dsjob compile {--project PROJECT | --project-id PROJID} [{--name NAME | --id ID}...] [--skip] [--osh] [--threads ] [--enable-elt-mode --materialization-policy <POLICY>]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the flow.
- `id` is the id of the flow. One of `name` or `id` can be specified. Multiple values can be specified for `name` and `id` to compile multiple items, in the format `--name NAME1 --name NAME2...`. The name can be a valid regular expression, ex: `Flow.*, ^.*THIS.*` If not present, all the flows in the project are compiled.
- `skip` when specified, flows that do not need to be recompiled will be skipped.
- `osh` the output will display compiled 'osh' output. This field is optional.
- `threads` specifies the number of parallel compilations to run. The value should be in the range 5-20, default value is 5. This field is optional.
- `enable-elt-mode` compiles DataStage flow into a dbt model and executes the dbt model to perform ELT operations. The default value is false.
- `materialization-policy` can take values OUTPUT_ONLY, TEMP_TABLES, TEMP_VIEWS, or CARDINALITY_CHANGER_TABLES. This option is used along with `enable-elt-mode`.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

## Pipelines

### Listing parameters

The following syntax fetches a flow/pipeline parameters for a given flow/pipeline from the specified project:

```
cpdctl dsjob list-params {--project PROJECT | --project-id PROJID} {--name name | --id ID} [--output file|json] [--file-name FILENAME] [--detail]
```

- `project`  is the name of the project that contains the pipeline.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the flow or a pipeline.
- `id`  is the id of the flow or a pipeline. One of  `name`  or  `id`  must be specified.
- `output`  specifies the format of the output. This field is optional.
- `file-name`  specifies the name of the file to which the output is written. This field is optional.
- `detail`  when specified all the pipeline parameter sets are expanded to show their fields definitions.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Listing pipelines

The following syntax displays a list of all pipelines in the specified project:

```
cpdctl dsjob list-pipelines {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```

- `project` is the name of the project that contains the pipelines to list.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified. A list of all the pipelines in the project is displayed, one per line.
- `sort` when specified returns the list of pipelines sorted in alphabetical order. This field is optional.
- `sort-by-time` when specified the list of pipelines will be sorted by time of creation with latest at the top of the list. One of `sort` or `sort-by-time` can be specified.
- `with-id` when specified prints the pipeline id along with the name of the pipeline.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Getting pipelines

The following syntax fetches a pipeline by name from the specified project:
```
cpdctl dsjob get-pipeline {--project PROJECT | --project-id PROJID} {--name name | --id ID} [--output file|json] [--file-name <name>]
```

- `project` is the name of the project that contains the pipeline.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the pipeline.
- `id` is the id of the pipeline. One of `name` or `id` must be specified.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Deleting pipelines

The following syntax deletes a pipeline by name from the specified project:
```
cpdctl dsjob delete-pipeline {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```

- `project` is the name of the project that contains the pipeline. 
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the pipeline that is being deleted.
- `id` is the id of the pipeline. One of `name` or `id` must be specified. Multiple values can be specified for `name` and `id` to delete multiple items, in the format `--name NAME1 --name NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Importing pipelines

The following syntax imports a pipeline into a specified project:
```
cpdctl dsjob import-pipeline {--project PROJECT | --project-id PROJID} --name name [description DESCRIPTION] [--volatile] --file-name FILENAME
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the pipeline.
- `description` is the description of the pipeline.
- `volatile` when specified creates a trial version of the pipeline.
- `file-name` is the name of the file that contains the pipeline JSON. This field
must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Exporting pipelines

The following syntax exports a pipeline from a specified project to a file:
```
cpdctl dsjob export-pipeline {--project PROJECT | --project-id PROJID} {--name name | --id ID} [--format TEMPLATE|FLOW|ALL] [--output file] [--file-name <name>]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the pipeline.
- `id` is the id of the pipeline. One of `name` or `id` must be specified.
- `format` specifies whether to export the pipeline template, pipeline flow, or both.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the exported pipeline JSON is written to.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Listing pipeline versions

The following syntax displays a list of all pipeline versions in the specified project:
```
cpdctl dsjob list-pipeline-versions {--project PROJECT | --project-id PROJID} {--name name | --id ID} [--sort-by-time] [--output file] [--file-name ]
```

- `project` is the name of the project that contains the pipeline.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified. A list of all the pipeline versions in the project is displayed, one per line.
- `name` is the name of the pipeline.
- `id` is the id of the pipeline. One of `name` or `id` must be specified.
- `sort` when specified returns the list of pipeline versions sorted in alphabetical order. This field is optional.
- `sort-by-time` when specified the list of pipeline versions will be sorted by time of creation with latest at the top of the list. One of `sort` or `sort-by-time` can be specified.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Listing pipeline runs

The following syntax displays a list of all pipeline runs in the specified project:
```
cpdctl dsjob list-pipeline-runs {--project PROJECT | --project-id PROJID} {--name name | --id ID} [--sort | --sort-by-time] [--detail]
```

- `project` is the name of the project that contains the pipeline.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified. A list of all the pipeline runs in the project is displayed, one per line.
- `name` is the name of the pipeline.
- `id` is the id of the pipeline. One of `name` or `id` must be specified.
- `sort` when specified returns the list of pipeline runs sorted in alphabetical order. This field is optional.
- `sort-by-time` when specified the list of pipeline runs will be sorted by time of creation with latest at the top of the list. One of `sort` or `sort-by-time` can be specified.
- `detail` when specified prints the pipeline run details.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Creating and scheduling pipeline jobs

The following syntax creates a pipeline job in the specified project:
```
cpdctl dsjob create-pipeline-job {--project PROJECT | --project-id PROJID} {--pipeline NAME | --pipeline-id ID} [--name NAME] [--description DESCRIPTION] [--schedule-start yyyy-mm-dd:hh:mm] [--schedule-end yyyy-mm-dd:hh:mm] [{--repeat every/hourly/daily/monthly} --minutes (0-59) --hours (0-23) --day-of-week (0-6) --day-of-month (1-31)] [--version n]
```

- `project` is the name of the project that contains the pipeline.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `pipeline` is the name of the pipeline.
- `pipeline-id` is the id of the pipeline. One of `pipeline` or
`pipeline-id` must be specified.
- `name` is the name of the job to be created or used. This field is optional.
- `description` is the description of the job. This field is optional.
- `schedule-start` is the starting time for scheduling a job.
- `schedule-end`is the ending time for scheduling a job.
- `repeat` specifies how frequently the job runs. Permitted values are `every`, `hourly`, `daily`, `weekly`, and `monthly`. The default value is `none`.
- `hours` specifies hour of the day at which to run the job. Values in the range 0-23 are accepted.
- `day-of-week` repeats on a day of the week, works with minutes and hours. Values in the range 0-6 are accepted. Ex: 1,2 (runs on Monday and Tuesday, default all days).
- `day-of-month` repeats on day of the month, works with minutes and hours. Values in the range 0-31 are accepted. Ex: 2 (runs on the second of the month).

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Running pipelines

A pipeline run is triggered by creating a job for the pipeline and running it. The following syntax runs a pipeline in the specified project:
```
cpdctl dsjob run-pipeline {--project PROJECT | --project-id PROJID} {--name name | --id ID} [--job-name name] [--description description] [--version VERSION] [--run-name RUNNAME] [--param PARAM] [--param-file FILENAME] [--env ENVJSON] [--paramset PARAMSET] [--wait SEC] [--reset-cache] [--no-logs]
```

- `project` is the name of the project that contains the pipeline.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the pipeline.
- `id` is the id of the pipeline. One of `name` or `id` must be specified.
- `job-name` is the name of the job to be created or used. This field is optional. 
- `description` is the description of the job that is run.
- `version` specifies the version of the pipeline that is run.
- `run-name` provides a job run name for this pipeline job run.
- `param` specifies a parameter value to pass to the job. The value is in the format `name=value`, where name is the parameter name and value is the value to be set. This flag can be repeated, ex: `--param k1=v1 --param k2=v2`
- `paramfile` specifies a file that contains the parameter values to pass to the
job. This field is not implemented currently.
- `env` specifies the environment in which job is run. `env` is
specified as a key=value pair. Key `env` or `env-id` can be used to chose a runtime environment.
Example: `--env $APT_DUMP_SCORE=true --env env=ds-px-default`
- `paramset` when specified passes a parameter set to the pipeline.
- `wait` the job run waits for the specified amount of time for the job to finish. The job logs are printed to the output until the job is completed or the wait time expires. The return status indicates whether the job has finished, finished with warning, raised an error, or timed out after waiting. For example: `--wait 200` waits for a maximum of 200 secs, polling the job for completion, and if the job does not complete it returns a status code other than zero. You may specify `--wait -1` to wait indefinitely for the job to finish. This field is optional.
- `reset-cache` when set to true, cache is reset before the pipeline run.
- `no-logs` when this and `wait` are specified, pipeline run will not produce output logs while waiting for the run to finish. This field is optional.

A status code is printed to the output.

- 0: successfully completed
- 1: completed with warnings
- 3: completed with error
- 4: failed
- 5: canceled
- -1: other

### Printing pipeline run logs

The following syntax fetches run logs of a pipeline run in the specified project:
```
cpdctl dsjob get-pipeline-logs {--project PROJECT | --project-id PROJID} {--name name | --id ID} [--run-id RUNID]
```

- `project` is the name of the project that contains the pipeline.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the pipeline.
- `id` is the id of the pipeline. One of `name` or
`id` must be specified.
- `run-id` if specified, the logs for that run id is printed. If not specified, the
logs from the latest run are printed.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

## Imports and exports

### Importing

The following syntax imports the specified project to a file:
```
cpdctl dsjob import {--project PROJECT | --project-id PROJID} --import-file FILENAME [--wait secs]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `import-file` is the name of the file that contains previously exported assets.
- `wait` specifies the time in seconds to wait for the command to complete. For example, `--wait 200` waits for a maximum of 200 secs, checking status of the import, and returns an exit code other than zero if it does not complete. You can set `--wait -1` to wait for completion indefinitely.

A status code is printed to the output.

- 0: successfully completed
- 1: failed
- 3: timed out
- 4: canceled

### Exporting

The following syntax exports the specified project to a file:
```
cpdctl dsjob export {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] [--export-file FILENAME] [--wait secs] [--asset-type TYPE] [--asset <name,type>...] [--all]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `asset list` is a list of all the asset names to be exported. Format:
`--asset type=assetname1,assetname2`.
- `name` is the name of the export.
- `asset-type` is a list of all asset types to export, ex: `--asset-type Connection --asset-type data_flow`.
- `description` is a description of the exported assets.
- `export-file` is the file for assets to be exported to.
- `wait` specifies the time in seconds to wait for the command to complete. For example, `--wait 200` waits for a maximum of 200 secs, checking status of the export, and returns an exit code other than zero if it does not complete. You can set `--wait -1` to wait for completion indefinitely.

A status code is printed to the output.

- 0: successfully completed
- 2: failed
- 3: timed out
- 4: canceled
- 5: deleting

### Listing exports

The following syntax displays a list of all exports from the specified project:

```
cpdctl dsjob list-exports {--project PROJECT | --project-id PROJID}
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Saving exports

The following syntax saves an export to a file.
```
cpdctl dsjob save-export {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} --export-file FILENAME 
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the export.
- `id` is the id of the export. One of `name` or `id` must be specified.
- `export-file` is the name of the file that the export is saved to.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Deleting exports

The following syntax deletes an export from the specified project:
```
cpdctl dsjob delete-export {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the export. 
- `id` is the id of the export. One of `name` or `id`
must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Exporting a DataStage flow

The following syntax exports the DataStage components from a specified project to a file:

```
cpdctl dsjob export-project {--project PROJECT | --project-id PROJID} --file-name <PROJECTZIP> [--include-data-assets] [--exclude-datasets-filesets] [--enc-key <ENCODING-KEY>] [--wait secs]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `file-name` is the file for assets to be exported to. This field is used only when `wait` is specified and export is completed within specified wait timeout.
-  `wait` specifies the time in seconds to wait for the command to complete. For example, `--wait 200` waits for a maximum of 200 secs, checking status of the export, and returns an exit code other than zero if it does not complete. You can set `--wait -1` to wait for completion indefinitely.
- `include-data-assets` includes the project's data assets as part of the export.
- `exclude-datasets-filesets` when specified, datasets and filesets are exported but the data is excluded.
- `enc-key` specifies the encryption key used to encrypt exported sensitive data. This key must be a string that will be used during import process to decrypt and must be saved securely.

A status code is printed to the output.

- 0: successfully completed
- 1: failed
- 2: completed with error
- 3: timed out
- 4: canceled

### Checking flow export status

The following syntax gets the status of an export operation in progress.

```
cpdctl dsjob get-export-project {--project PROJECT | --project-id PROJID} [--with-metadata]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion of the
command.

### Saving export to a file

The following syntax saves the export from a specified project to a file:

```
cpdctl dsjob save-export-project {--project PROJECT | --project-id PROJID} --file-name FILENAME
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `file-name` is the file to which the project export contents are written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Canceling an export

The following syntax stops the export operation on a specified project:
```
cpdctl dsjob stop-export-project {--project PROJECT | --project-id PROJID}
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of the
command.

## .ZIP files

### Importing .zip files

The following syntax imports DataStage flows from a .zip file into a specified project:
```
cpdctl dsjob import-zip {--project PROJECT | --project-id PROJID} [--on-failure ONFAILURE] [--conflict-resolution CONFLICT-RESOLUTION] [--skip-on-replace LIST] [--hard-replace] [--asset-type LIST] [--no-compile] [--enable-notification] --file-name FILE-NAME [--wait secs] [--enc-key <ENCODING KEY>]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or `project-id` must be specified.
- `on-failure` indicates what action to take if the import fails. This field is optional. The default option is continue, the other option is stop.
- `conflict-resolution` specifies the resolution when the data flow to be imported has the same name as an existing data flow in the project or catalog. This field is optional. The default option is skip, the others are rename and replace.
- `skip-on-replace` specifies a list of object types to skip. The following values are valid for object types: `connection, data_intg_subflow, data_definition, parameter_set, data_asset, ds_message_handler, data_intg_build_stage, data_intg_custom_stage, data_intg_wrapped_stage, standardization_rule, ds_xml_schema_library, custom_stage_library, function_library, ds_routine, ds_match_specification, data_intg_parallel_function, data_intg_java_library, data_quality_rule, data_quality_definition`.
- `hard-replace` If true, fields in parameter sets will be replaced with incoming source field values. This field can be used only when conflict resolution is set to skip or replace.
- `asset-type` if specified only asset types in this list are imported ex: data_intg_subflow.
- `no-compile` if true, flows imported will not be compiled.
- `enable-notification` when true, allows notifications to be sent during import.
- `file-name` is the name of the .zip file that contains all the DataStage flows and DataStage components to be imported. This field is mandatory.
- `wait`  specifies the time in seconds to wait for the command to complete. For example, `--wait 200` waits for a maximum of 200 secs, checking status of the import, and returns an exit code other than zero if it does not complete. You can set `--wait -1` to wait for completion indefinitely.
- `enc-key` specifies the encryption key used to encrypt exported sensitive data. This key must be the same string that is used during the export process. To decrypt and import to run successfully, this is is required if export is run with --enc-key option.

A status code is printed to the output.

- 0: successfully completed
- 1: failed
- 2: completed with error
- 3: timed out
- 4: canceled

### Getting status of import requests from .zip files

The following syntax gets the status of an import request using import-zip:
```
cpdctl dsjob get-import-zip {--project PROJECT | --project-id PROJID} --import-id [--format json|csv] [--file-name FILENAME] 
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `import-id` is the id of the import. This field is mandatory.
- `format` specifies the format of the output file. This field is optional. The
default value is json. The other option is csv.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Exporting .zip files

The following syntax exports a DataStage flow and dependent DataStage components to a .zip file
from a specified project:
```
cpdctl dsjob export-zip {--project PROJECT | --project-id PROJID} {--name FLOW | --id ID}... {--pipeline SEQFLOWNAME | --pipeline-id SEQFLOWID}... {--testcase TESTCASENAME | --testcase-id TESTCASEID}... --file-name FILENAME [--no-secrets] [--no-deps] [--include-data-assets] [--exclude-datasets-filesets] [--enc-key <ENCODING KEY>]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of project or project-id must be specified.
- `name` is the name of the flow.
- `id` is the id of the flow. One of name or id must be specified.
- `pipeline` is the name of the pipeline.
- `pipeline-id` is the id of the pipeline. One of name or id must be specified.
- `testcase` is the name of the testcase.
- `testcase-id` is the id of the testcase. One of name or id must be specified.
- `no-deps` specifies that flow dependencies will not be exported. This field is optional. The default option is false.
- `no-secrets` specifies that secrets will not be exported. This field is optional. The default option is false.
- `file-name` specifies the name of the .zip file to which the flow is exported.
- `include-data-assets` includes the project's data assets as part of the export.
- `exclude-datasets-filesets` when specified datasets and filesets are exported but the data is excluded.
- `enc-key` specifies encryption key used to encrypt exported sensitive data. This key must be a string that will be used during import process to decrypt and must be saved securely.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Exporting DataStage components
The following syntax will export all DataStage components in a specified project to a .zip file:
```
cpdctl dsjob export-datastage-assets {--project PROJECT | --project-id PROJID} [--file-name <FILENAME>] [--include-data-assets] [-exclude-datasets-filesets] [--enc-key <ENCODING KEY>]
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `file-name` specifies the name of the .zip file to which the assets are exported. 
- `include-data-assets` includes the project's data assets as part of the export.
- `exclude-datasets-filesets` when specified datasets and filesets are exported but the data is excluded.
- `enc-key` specifies encryption key used to encrypt exported sensitive data. This key must be a string that will be used during import process to decrypt and must be saved securely.

This call is synchronous and prints out the status of the export progress, as well as a
summary of independent components written to the output file.
A status code is printed to the
output. A status code of 0 indicates successful completion of the command.

## Connections

### Listing connections

The following syntax displays a list of all connections in the specified project:

```
cpdctl dsjob list-connections {--project PROJECT | --project-id PROJID} [--sort|--sort-by-time] [--with-id]
```

- `project` is the name of the project that contains the connections to list.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the DataStage connections in the project is displayed, one per
line.
- `sort` when specified returns the list of connections sorted in alphabetical
order. This field is optional.
- `sort-by-time` when specified sorts the list by create or update time. One of
`sort` or `sort-by-time` can be specified.
- `with-id` when specified prints the connection id along with the name of the
connection.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Creating connections

The following syntax creates a flow in the specified project:
```
cpdctl dsjob create-connection {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] --datasource-type TYPE [--country COUNTRY] [--no-test] --property-file FILENAME
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the connection being created.
- `description` is the description of the connection being created. This field is
optional.
- `datasource-type` is the data source type for the connection ex: MySQL, DB2,
AzureBlobStorage, etc.
- `country` is the country of origin for the connection. The default is "us."
- `property-file` is the name of the file that contains the connection properties.
This field must be specified.
- `no-test` if true, connection is added without validation.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Getting connections

The following syntax fetches a connection by name from the specified project:

```
cpdctl dsjob get-connection {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata]
```

- `project` is the name of the project that the connection is fetched from.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the queried connection.
- `id` is the id of the connection. One of `name` or
`id` must be specified.
- `output` specifies the format of the output. This field is optional.
- `file-name` is the name of the output file to which the output is written. This
field is optional.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Deleting connections

The following syntax deletes a connection by name from the specified project:

```
cpdctl dsjob delete-connection {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```

- `project` is the name of the project that the connection is deleted from.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the connection. 
- `id` is the id of the connection. One of `name` or
`id` must be specified. Multiple values can be specified for `name`
and `id` to delete multiple items, in the format `--name NAME1 --name
NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Updating connections

The following syntax updates a connection by name from the specified project:

```
cpdctl dsjob update-connection {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--to-name NAME] [--property name=value]... [--file-name PROPERTYFILE] [--make-personal]
```

- `project` is the name of the project that contains the connection.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the connection.
- `id` is the id of the connection. One of `name` or
`id` must be specified.
- `to-name` renames the connection to a specified new name.
- `property` specifies a specific property to be updated. The value is in the
format `name=value`, where `name` is the name of the connection
property and `value` is the value to be set. This flag can be repeated, ex:
`--property k1=v1 --property k2=v2`
- `file-name` specifies a file that contains the property values to pass to update
the connection.
- `make-personal` changes the connection settings from shared to personal.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Exporting connections

The following syntax exports connections by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-connection {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the connection.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


## Hardware specifications

### Listing hardware specifications
The following syntax displays a list of all hardware specifications in the specified project: 
```
cpdctl dsjob list-hardware-specs {--project PROJECT | --project-id PROJID} [--full] [--all] [--sort | --sort-by-time] [--with-id]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the DataStage Hardware Specifications in the project are
displayed, one per line.
- `all` displays list of all hardware specifications in the project for the
specified type, ex: DataStage, Spark, and Nodes. 
- `full` provides full configuration details of each hardware specification. This
field is optional.
- `sort` when specified returns the list of hardware specifications sorted in
alphabetical order. This field is optional.
- `sort-by-time` when specified sorts the list by create or update time. One of
`sort` or `sort-by-time` can be specified.
- `with-id` when specified prints the hardware specification id along with the name
of the hardware specification.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Creating hardware specifications
The following syntax creates a hardware specification for the specified project: 
```
cpdctl dsjob create-hardware-spec {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] [--body BODY-JSON] [--file-name FILENAME]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. 
- `name` is the name of the hardware specification being created. 
- `description` is the description of the hardware specification being created.
This field is optional.
- `body` should contain the hardware specification in json format. Alternatively,
the hardware specification can be provided in a file by using `--filename`.
- `filename` is the name of the file that contains the hardware specification.
Alternatively, the hardware specification can be provided inline by using --body. Either --body or
--filename must be specified. 


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Getting hardware specifications
The following syntax fetches a hardware specification by name from the specified project:
```
cpdctl dsjob get-hardware-spec {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the hardware specification.
- `id` is the id of the hardware specification. One of `name` or
`id` must be specified.
- `file-name` is the name of the output file to which the hardware specification is
written.
- `with-metadata` when specified adds metadata to the output.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


## Runtime environments

### Listing runtime environments
The following syntax displays a list of all Environments in the specified project: 
```
cpdctl dsjob list-envs {--project PROJECT | --project-id PROJID} [--types TYPE] [--full] [--sort] [--with-id]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the DataStage Environments in the project are displayed, one per
line.
- `type` displays list of all environments in the project specified by the type.
The value should be one of `notebook`, `wml_flow`,
`rstudio`, `default_spark`, `remote_spark`,
`jupyterlab`, `remote_yarn`, `datastage`,
`profiling`, `modeler`, or `data_privacy`. This field
is optional. 
- `full` provides full configuration details of each environment. This field is
optional.
- `sort` when specified returns the list of environments sorted in alphabetical
order. This field is optional.
- `with-id` when specified prints the environment id along with the name of the
environment.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Creating runtime environments
The following syntax creates a runtime environment for the specified project: 
```
cpdctl dsjob create-env {--project PROJECT | --project-id PROJID} --name NAME --display-name DISPLAY-NAME [--type TYPE] [--location LOCATION] [--hwspec HWSPEC-NAME] [--file-name FILENAME]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the environment that is being created. Used when
`file-name` is not specified. 
- `display-name` is the long name of the environment being created. Used when
`file-name` is not specified. 
- `type` is the type of environment to create, ex: `datastage`. Used
when `filename` is not specified.
- `location` if specified is the JSON-formatted location information needed to
access the environment. Used when `filename` is not specified.
- `hwspec` is the name of the hardware specification used to create the
environment. Used when `filename` is not specified.
- `file-name` is the name of the file that contains the hardware specification,
location and other attributes. When specified, all other options are ignored. 


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Getting runtime environments
The following syntax fetches a runtime environment by name from the specified project:
```
cpdctl dsjob get-env {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata]
```


- `project` is the name of the project that the environment is fetched from.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the queried environment. 
- `id` is the id of the environment. One of `name` or
`id` must be specified.
- `file-name` is the name of the output file to which the environment is
written.
- `with-metadata` when specified adds metadata to the output.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


## Subflows

### Listing subflows
The following syntax displays a list of all subflows in the specified project: 
```
cpdctl dsjob list-subflows {--project PROJECT | --project-id PROJID} [--sort|--sort-by-time] [--with-id]
```


- `project` is the name of the project that contains the subflows to list. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the subflows in the project is
displayed, one per line.
- `sort` when specified returns the list of subflows sorted in alphabetical order.
This field is optional.
- `sort-by-time` when specified sorts the list by create or update time. One of
`sort` or `sort-by-time` can be specified.
- `with-id` when specified prints the subflow id along with the name of the
subflow.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Creating subflows
The following syntax creates a subflow in the specified project:
```
cpdctl dsjob create-subflow {--project PROJECT | --project-id PROJID} --name NAME --pipeline-file FILENAME
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the subflow. 
- `id` is the id of the subflow. One of `name` or
`id` must be specified.
- `pipeline-file` is the name of the file that contains the subflow JSON. This
field must be specified.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Getting subflows
The following syntax fetches a subflow by name from the specified project:
```
cpdctl dsjob get-subflow {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output file|json] [--file-name FILENAME] [--with-metadata]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the subflow. 
- `id` is the id of the subflow. One of `name` or
`id` must be specified.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.
- `with-metadata` when specified adds metadata to the output.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Deleting subflows
The following syntax deletes a subflow by name from the specified project:
```
cpdctl dsjob delete-subflow {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the subflow. 
- `id` is the id of the subflow. One of `name` or
`id` must be specified. Multiple values can be specified for `name`
and `id` to delete multiple items, in the format `--name NAME1 --name
NAME2...`.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Exporting subflows

The following syntax exports subflows by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-subflow {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the subflows.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


## Parameter sets

### Listing parameter sets
The following syntax displays a list of all parameter sets in the specified project: 
```
cpdctl dsjob list-paramsets {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time]  [--output json] [--with-id]

```


- `project` is the name of the project that contains the parameter sets to list. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the parameter sets in the project is
displayed, one per line.
- `sort` when specified returns the list of parameter sets sorted in alphabetical
order. This field is optional.
- `sort-by-time` when specified sorts the list by create or update time. One of
`sort` or `sort-by-time` can be specified.
- `output` specifies the format of the output. This field is optional.
- `with-id` when specified prints the parameter set id along with the name of the
parameter set.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Creating parameter sets
The following syntax creates a parameter set in the specified project:
```
cpdctl dsjob create-paramset {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] [--file-name FILENAME] [--param type:name:[value]...]
```


- `project` is the name of the project that contains the parameter sets to list. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the parameter set being created. This field is
mandatory.
- `description` is a detailed description of the parameter set being created. This
field is optional.
- `file-name` is the name of the file that contains the definitions of the
parameter set.
- `param` is used to specify parameters at the command line instead of using the
`file-name` option.



One of `file-name` or `param` must be specified. Sample file
content shown below: 
```
[
  {
    "name": "parm3",
    "prompt": "parm3",
    "type": "int64",
    "value": 33
  },
  {
    "name": "parm33",
    "prompt": "parm33",
    "type": "string",
  },
  {
    "name": "parm333",
    "prompt": "parm333",
    "type": "Float64",
    "value": 33.3
  }
]
```


Sample command line content using `param` shown below:

```
"--param", "int64:parm1:12", "-param", "sfloat:parm2:12.3", "-param", "string:parm3:abc", "-param", "time:ptime:12:12:12", "-param", "date:pdate:11/06/2021", "-param", "timestamp:pts:11/06/2021:12:12:12"
```
The format is type:name:value and type may be one of time, timestamp, date, int64, sfloat, string,
list, path.

A status code is printed to the output. A status code of 0 indicates successful completion of the
command.


### Getting parameter sets
The following syntax fetches a parameter set by name from the specified project:
```
cpdctl dsjob get-paramset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output file|json] [--file-name FILENAME] [--with-metadata]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the parameter set. 
- `id` is the id of the parameter set. One of `name` or
`id` must be specified.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.
- `with-metadata` when specified adds metadata to the output.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Deleting parameter sets
The following syntax deletes a parameter set by name from the specified project:
```
cpdctl dsjob delete-paramset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the parameter set. 
- `id` is the id of the parameter set. One of `name` or
`id` must be specified. Multiple values can be specified for `name`
and `id` to delete multiple items, in the format `--name NAME1 --name
NAME2...`.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Updating parameter sets
The following syntax updates an existing parameter set in the specified project:
```
cpdctl dsjob update-paramset {--project PROJECT | --project-id PROJID} --name NAME [--file-name FILENAME] [--to-name RENAME] [--param type:name:[value] ...] [--delete-param name ...]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the parameter set being updated. 
- `file-name` is the name of the file that contains the parameter set definitions. 
- `to-name` when specified renames the parameter set to the specified name.
- `param` specifies parameter set definitions at the command line. One of
`file-name` or `param` must be specified.
- `delete-param` when specified deletes a specific field from the parameter
set.


Sample file content:
```
[
{
"name": "parm3",
"prompt": "parm3",
"type": "int64",
"value": 33
},
{
"name": "parm33",
"prompt": "parm33",
"type": "string",
},
{
"name": "parm333",
"prompt": "parm333",
"type": "Float64",
"value": 33.3
}
]
```
Sample command line content to rename a parameter set while adding three fields
and deleting two fields:

```
cpdctl dsjob update-paramset --project PROJ1 --name paramset1 --param int64:parm1:12 -param sfloat:parm2:12.3 -param string:parm3:abc -delete-param ptime -delete-param pdate --to-name newparamset1 
```
The format for `param` is `type:name:value` and `type` may
be time, timestamp, date, int64, sfloat, string, list, or path.
A status code is printed to
the output. A status code of 0 indicates successful completion of the command.


### Exporting parameter sets
The following syntax exports parameter sets by name from the specified project. The exported zip file is compatible with import-zip format. Please refer to the `import-zip` command to import as desired into a different project.
```
cpdctl dsjob export-paramset {--project PROJECT | --project-id PROJID} {--name NAME...} --file-name ZIPFile
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the parameter set. `name`  can be a regular expression or a list. Example: `--name abc.*` exports all names that start with abc and `--name ps1 --name ps2` will export two parameter sets named `ps1` and `ps2`.
-  `file-name` name of the zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Listing value sets in a parameter set:
The following syntax displays a list of all value sets in the specified parameter set: 
```
cpdctl dsjob list-paramset-valuesets {--project PROJECT | --project-id PROJID} {--paramset PARAMSET | --paramset-id PARAMSETID}
```


- `project` is the name of the project that contains the parameter set. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the value sets in the parameter set is
displayed, one per line.
- `paramset` is the name of the parameter set.
- `paramset-id` is the id of the parameter set. One of `paramset` or
`paramset-id` must be specified.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Creating value sets in a parameter set:
The following syntax creates a value set in the specified parameter set: 
```
cpdctl dsjob create-paramset-valueset {--project PROJECT | --project-id PROJID} {--paramset PARAMSET | --paramset-id PARAMSETID} --name NAME [--file-name FILENAME] [--value name=value ...]
```


- `project` is the name of the project that contains the parameter set. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. 
- `paramset` is the name of the parameter set.
- `paramset-id` is the id of the parameter set. One of `paramset` or
`paramset-id` must be specified.
- `name` is the name of the value set being created.
- `file-name` is the name of the file that contains the definitions of the value
set.
- `value` is used to specify parameters values for the value set at the command
line instead of using the `file-name` option.


A file containing value set definitions for value set `vset1` for a parameter
set with three fields `parm33`, `parm333` and
`parm3`:
```
{
"name": "vset1",
"values": [
{
"name": "parm33",
"value": "vset3333"
},
{
"name": "parm333",
"value": "33.3333333"
},
{
"name": "parm3",
"value": "33333"
}
]
}
```
A command line alternative:
```
cpdctl dsjob create-paramset-valueset --project PROJ1 --paramset pset1 --name vset1 --value parm22="vset3333" --value parm333=33.333333 --value parm3=33333
```
A
status code is printed to the output. A status code of 0 indicates successful completion of the
command.


### Getting value sets in a parameter set:
The following syntax gets a value set by name from the specified parameter set: 
```
cpdctl dsjob get-paramset-valueset {--project PROJECT | --project-id PROJID} {--paramset PARAMSET | --paramset-id PARAMSETID} --name NAME [--output file|json] [--file-name FILENAME]
```


- `project` is the name of the project that contains the parameter set. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `paramset` is the name of the parameter set.
- `paramset-id` is the id of the parameter set. One of `paramset` or
`paramset-id` must be specified.
- `name` is the name of the value set being retrieved.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Deleting value sets in a parameter set:
The following syntax deletes a value set by name from the specified parameter set: 
```
cpdctl dsjob delete-paramset-valueset {--project PROJECT | --project-id PROJID} {--paramset PARAMSET | --paramset-id PARAMSETID} --name NAME
```


- `project` is the name of the project that contains the parameter set. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. 
- `paramset` is the name of the parameter set.
- `paramset-id` is the id of the parameter set. One of `paramset` or
`paramset-id` must be specified.
- `name` is the name of the value set being deleted.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Updating value sets in a parameter set:
The following syntax updates an existing value set in the specified parameter set: 
```
cpdctl dsjob update-paramset-valueset {--project PROJECT | --project-id PROJID} {--paramset PARAMSET | --paramset-id PARAMSETID} --name NAME [--to-name RENAME] [--value name=value ...] [--file-name FILENAME]
```


- `project` is the name of the project that contains the parameter set. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `paramset` is the name of the parameter set.
- `paramset-id` is the id of the parameter set. One of `paramset` or
`paramset-id` must be specified.
- `name` is the name of the value set being updated.
- `to-name` when specified renames the value set.
- `file-name` specifies the name of the file that contains the parameter set
definitions.
- `value` is used to specify values for the value set at the command line instead
of using the `file-name` option. One of `file-name` or
`value` must be specified.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


## Table definitions

### Listing TableDefinitions
The following syntax displays a list of all TableDefinitions in the specified project: 
```
cpdctl dsjob list-tabledefs {--project PROJECT | --project-id PROJID} [--sort|--sort-by-time] [--with-id]
```


- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the TableDefinitions in the project is
displayed, one per line.
- `sort` when specified returns the list of TableDefinitions sorted in alphabetical
order. This field is optional.
- `sort-by-time` when specified sorts the list by create or update time. One of
`sort` or `sort-by-time` can be specified.
- `with-id` when specified prints the table definition id along with the name of
the table definition.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Creating TableDefinitions
The following syntax creates a TableDefinition in the specified project:
```
cpdctl dsjob create-tabledef {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] [--file-name FILENAME] [--column type:name:columnattribute ...]
```


- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. 
- `name` is the name of the TableDefinition being created. This field is
mandatory.
- `description` is a detailed description of the TableDefinition being created.
This field is optional.
- `file-name` is the name of the file that contains the definitions of the
Table.
- `column` is used to specify columns at the command line instead of using the
`file-name` option.



One of `file-name` or `column` must be specified. Sample file
content shown below: 
```
{
	"column_info": {},
	"data_asset": {
		"additionalProperties": {},
		"columns": [
			{
				"name": "CreditCardID",
				"type": {
					"length": 10,
					"nullable": false,
					"scale": 0,
					"signed": true,
					"type": "INTEGER"
				}
			},
			... more columns follow
		],
		"dataset": true,
		"mime_type":  "application/json"
	},
	"data_definition": {},
	"ds_info": {}
}
```


Sample command line content using `column` shown below:
```
"--column", "Numeric:parm1:length=6", "--column", "Decimal:parm2:scale=2", "--column", "String:parm3:nullable=true,length=120", "--column", "Time:ptime", "--column", "Date:pdate", "--column", "Timestamp:pts:nullable=true""
```
The format is type:name:value and type may be one of Date, Decimal, General, Numeric, String, Time,
Timestamp.

A status code is printed to the output. A status code of 0 indicates successful completion of the
command.


### Getting TableDefinitions
The following syntax fetches a TableDefinition by name from the specified project:
```
cpdctl dsjob get-tabledef {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output file|json] [--file-name FILENAME] [--with-metadata]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the TableDefinition. 
- `id` is the id of the TableDefinition. One of `name` or
`id` must be specified.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.
- `with-metadata` when specified adds metadata to the output.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Deleting TableDefinitions
The following syntax deletes a TableDefinition by name from the specified project:
```
cpdctl dsjob delete-tabledef {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the TableDefinition. 
- `id` is the id of the TableDefinition. One of `name` or
`id` must be specified. Multiple values can be specified for `name`
and `id` to delete multiple items, in the format `--name NAME1 --name
NAME2...`.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Exporting TableDefinitions

The following syntax exports TableDefinitions by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-tabledef {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the TableDefinition.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


## XML Libraries

### Listing XML libraries
The following syntax displays a list of all XML libraries in the specified project: 
```
cpdctl dsjob list-libraries {--project PROJECT | --project-id PROJID} [--sort|--sort-by-time] [--with-id]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the XML libraries in the project is
displayed, one per line.
- `sort` when specified returns the list of XML libraries sorted in alphabetical
order. This field is optional.
- `sort-by-time` when specified sorts the list by create or update time. One of
`sort` or `sort-by-time` can be specified.
- `with-id` when specified prints the XML library id along with the name of the XML
library.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Creating XML libraries
The following syntax creates an XML library in the specified project:
```
cpdctl dsjob create-library {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] [--folder FOLDER]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. 
- `name` is the name of the XML library that is being created. This field is
mandatory.
- `description` is detailed description of the XML Library that is being created.
This field is optional.
- `folder` is the name of the folder for the XML library that is being
created.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Getting XML libraries
The following syntax fetches an XML library by name from the specified project:
```
cpdctl dsjob get-library {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--folder folder] [--output json|file] [--file-name FILENAME] [--with-metadata]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the XML library. 
- `id` is the id of the XML library. One of `name` or
`id` must be specified.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.
- `with-metadata` when specified adds metadata to the output.
- `folder` is the fully qualified path of the folder name.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Deleting XML libraries
The following syntax deletes a library by name from the specified project:
```
cpdctl dsjob delete-library {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}... [--folder FOLDER]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the XML library. 
- `id` is the id of the XML library. One of `name` or
`id` must be specified. Multiple values can be specified for `name`
and `id` to delete multiple items, in the format `--name NAME1 --name
NAME2...`.
- 

`folder` is the name of the folder of the XML library that is deleted.



A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Exporting XML libraries

The following syntax exports XML libraries by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-library {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the XML library.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Uploading an XML library file
The following syntax uploads a .zip file to an existing DataStage XML schema library by name in
a specified project: 
```
cpdctl dsjob upload-library-file {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--folder folder] --file-name FILENAME
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the XML library. 
- `id` is the id of the XML library. One of `name` or
`id` must be specified.
- `folder` is the fully qualified path of the folder name.
- `file-name` is the name of the .zip file that contains the schema definitions.
This field is mandatory.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Downloading an XML library file
The following syntax downloads a .zip file of an existing DataStage XML schema library by name
in a specified project: 
```
cpdctl dsjob download-library-file {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--folder folder] --file-name FILENAME
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the XML library. 
- `id` is the id of the XML library. One of `name` or
`id` must be specified.
- `file-name` is the name of the output file that the XML library's schema
definitions are written in. This field is mandatory.
- `folder` is the fully qualified path of the folder name.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Deleting an XML library file
The following syntax deletes a set of files from an existing DataStage XML schema library by
name in a specified project: 
```
cpdctl dsjob delete-library-file {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--folder folder] --file-name FILENAME
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the XML library. 
- `id` is the id of the XML library. One of `name` or
`id` must be specified.
- `file-name` is the names of the files to be deleted from the XML library. This
field is mandatory.
- `folder` is the fully qualified path of the folder name.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


## Environment variables

### Listing environment variables
The following syntax lists all environment variables defined in a specified project environment:
```
cpdctl dsjob list-env-vars {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--type TYPE] [--sort]
```

- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the environment.
- `id` is the id of the environment. One of `name` or
`id` must be specified. 
- `type` is the type of the environment. 
- `sort` when set, sorts the environment variables alphabetically.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Updating environment variables
The following syntax updates the environment variables defined in a specified project environment:
```
cpdctl dsjob update-env-vars {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--type TYPE] [--env k=v...] [--file-name FILENAME]
```

- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the environment.
- `id` is the id of the environment. One of `name` or
`id` must be specified. 
- `type` is the type of the environment. 
- `env` is a list of environment variables and their values to update or create.


A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Deleting environment variables
The following syntax deletes the environment variables that are defined in a specified project environment:
```
cpdctl dsjob delete-env-vars {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--type TYPE] [--env ENV...] [--file-name FILENAME]
```

- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the environment.
- `id` is the id of the environment. One of `name` or
`id` must be specified. 
- `type` is the type of the environment. 
- `env` is the name of the environment variable to delete. List all variables to
delete: the field is repeated.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


## Data set and file set

### Get dataset schema definition

The following syntax provides a description of the dataset schema definition in a given project.

```
cpdctl dsjob describe-dataset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME]
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the dataset.
-   `id`  is the asset id of the dataset. One of  `name`  or  `id`  must be specified.
-   `output` specifies the format of the output. This field is optional.
-   `file-name` specifies the name of the file to which the output is written. This field is optional.


A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### View dataset

The following syntax provides the metadata and sample data of a dataset in the given project.

```
cpdctl dsjob view-dataset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} 
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the dataset.
-   `id`  is the asset id of the dataset. One of  `name`  or  `id`  must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Listing datasets

The following syntax lists all datasets in a given project.

```
cpdctl dsjob list-datasets {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id] 
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `sort`  when specified returns the list of datasets sorted in alphabetical order. This field is optional.
-   `sort-by-time`  when specified returns the list of datasets sorted in chronological order. This field is optional. Only one of  `sort`,  `sort-by-time`   can be specified.
- `with-id` prints the asset id of the dataset
 
A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Deleting datasets

The following syntax deletes datasets. Note that currently it only deletes the asset associated with the dataset and does not delete the underlying dataset.

```
cpdctl dsjob delete-dataset {--project PROJECT | --project-id PROJID}  {--name NAME | --id ID}... [--dry-run]
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the dataset. Name can be repeated multiple times and can be used like a unix style wildcard pattern to match multiple items, ex: `--name *.ds --name myDS*`.
-   `id`  is the asset id of the dataset. Multiple values can be specified for `name` and `id` to delete multiple items, in the format `--name NAME1 --name NAME2... --id <ID> --id <ID>`.
-   `dry-run` when set to true, the command is run without actually deleting the asset.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Get dataset

The following syntax is used to fetch the asset definition for a dataset.
```
cpdctl dsjob get-dataset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata]
```

-   `project`  is the name of the project that contains the dataset.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the dataset.
-   `id`  is the id of the dataset. One of  `name`  or  `id`  must be specified.
-   `output`  specifies the format of the output. This field is optional.
-   `file-name`  specifies the name of the file to which the output is written. This field is optional.
-   `with-metadata`  when specified adds metadata to the output.

### Exporting dataset

The following syntax exports datasets by name from the specified project. The exported zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-dataset {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the dataset.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Download dataset

The following syntax downloads a dataset to a file. This downloads the dataset along with the backend dataset schema and data files. 

```
cpdctl dsjob download-dataset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the dataset.  
-   `id` is the asset id of the dataset. One of  name or  id must be specified.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Upload dataset

The following syntax uploads a dataset to a project. The dataset along with schema and data is created on the target project. 

```
 cpdctl dsjob upload-dataset {--project PROJECT | --project-id PROJID} --file-name ZIPFile

```

- `project`  is the name of the project.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `file-name`  name of the .zip file to which exported content is written.

The asset id of the newly created dataset is printed to the output.
A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Truncating dataset

The following syntax truncates data from a dataset in the specified project. 
```
cpdctl dsjob truncate-dataset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the dataset.
-   `id`  is the asset id of the dataset. One of  `name`  or  `id`  must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Renaming dataset

The following syntax renames a dataset in the specified project.
```
cpdctl dsjob rename-dataset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}  --to-name NEWNAME
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the dataset.
-   `id`  is the asset id of the dataset. One of  `name`  or  `id`  must be specified.
-   `to-name` is the new name to which the dataset is renamed.
A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Get fileset schema definition
The following syntax provides a description of the fileset schema definition in a given project.
```
cpdctl dsjob describe-fileset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}
```

- `project`  is the name of the project.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the fileset.
- `id`  is the asset id of the fileset. One of  `name`  or  `id`  must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### View fileset
The following syntax provides the metadata and sample data of a fileset in the given project.

```
cpdctl dsjob view-fileset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}
```

- `project`  is the name of the project.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the fileset.
- `id`  is the asset id of the fileset. One of  `name`  or  `id`  must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Listing filesets
The following syntax lists all filesets in a given project.
```
cpdctl dsjob list-filesets {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```

- `project`  is the name of the project.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `sort`  when specified returns the list of filesets sorted in alphabetical order. This field is optional.
- `sort-by-time`  when specified returns the list of filesets sorted in chronological order. This field is optional. Only one of  `sort`,  `sort-by-time` can be specified.
- `with-id` prints the asset id of the fileset

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Deleting filesets
The following syntax deletes filesets. Note that currently it only deletes the asset associated with the fileset and does not delete the underlying fileset.

```
cpdctl dsjob delete-fileset {--project PROJECT | --project-id PROJID}  {--name NAME | --id ID}... [--dry-run]
```

- `project`  is the name of the project.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the fileset. Name can be repeated multiple times and can be used like a unix style wildcard pattern to match multiple items, ex: `--name *.ds --name myFS*`
-   `id`  is the asset id of the fileset. Multiple values can be specified for `name` and `id` to delete multiple items, in the format `--name NAME1 --name NAME2... --id <ID> --id <ID>`
-   `dry-run` when set to true, the command is run without actually deleting the asset.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Get fileset

The following syntax is used to fetch the asset definition for a fileset.
```
cpdctl dsjob get-fileset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata]
```

- `project`  is the name of the project that contains the fileset.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the fileset.
- `id`  is the id of the fileset. One of  `name`  or  `id`  must be specified.
- `output`  specifies the format of the output. This field is optional.
- `file-name`  specifies the name of the file to which the output is written. This field is optional.
- `with-metadata`  when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Exporting fileset

The following syntax exports filesets by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-fileset {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the fileset.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Download fileset

The following syntax downloads a fileset to a file. This downloads the fileset along with the backend fileset schema and data files. 

```
cpdctl dsjob download-fileset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the fileset.  
-   `id` is the asset id of the fileset. One of  name or  id must be specified.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Upload fileset

The following syntax uploads a fileset to a project. The fileset along with schema and data is created on the target project. 

```
 cpdctl dsjob upload-fileset {--project PROJECT | --project-id PROJID}  --file-name ZIPFile

```

- `project`  is the name of the project.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `file-name`  name of the zip file to which exported content is written.

The asset id of the newly created fileset is printed to the output.
A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Truncating fileset

The following syntax truncates data from a fileset in the specified project.

```
cpdctl dsjob truncate-fileset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the fileset.
-   `id`  is the asset id of the fileset. One of  `name`  or  `id`  must be specified. 


A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Renaming fileset

The following syntax renames a fileset in the specified project.
```
cpdctl dsjob rename-fileset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}  --to-name NEWNAME
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the fileset.
-   `id`  is the asset id of the fileset. One of  `name`  or  `id`  must be specified.
-   `to-name` is the new name to which the fileset is renamed.
A status code is printed to the output. A status code of 0 indicates successful completion of the command.


## Remote engines

### List remote engines
The following syntax lists remote engines registered in a given DataStage
instance.
```
cpdctl dsjob list-remote-engines
```
A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Remove remote engine
The following syntax unregisters a remote engines from a given DataStage
instance.
```
cpdctl dsjob remove-remote-engine {--name name | --id ID}
```

- `name` is the name of the remote engine.
- `id` is the id of the remote engine. One of `name` or
`id` must be specified.
A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


## Versions

### Printing versions
The following command prints all the versions of the DataStage components that are installed in
the cluster.
```
cpdctl dsjob version 
```


## User-defined stages

### Listing build stages
The following syntax displays a list of all build stages in the specified project:
```
cpdctl dsjob list-build-stages {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```

- `project` is the name of the project that contains the build stages to list.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the build stages in the project is
displayed, one per line.
- `sort` when specified returns the list of build stages sorted in alphabetical
order. This field is optional.
- `sort-by-time` when specified the list of build stages will be sorted by time of
creation with latest at the top of the list. One of `sort` or
`sort-by-time` can be specified. 
- `with-id` when specified prints the build stage id along with the name of the
build stage.


A status code is printed to the output. A status code of 0 indicates successful completion of the
command.


### Creating build stages
The following syntax creates a build stage in the specified project:
```
cpdctl dsjob create-build-stage {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] --file-name ENTITYFILE
```


- `project` is the name of the project that the build stage is created for. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the build stage being created.
- `description` is the description of the build stage being created.
- `file-name` is the name of the file that contains the build stage JSON. The JSON
contains the name, description and all other stage details. This field must be specified.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Getting build stages
The following syntax fetches a build stage by name from the specified project:
```
cpdctl dsjob get-build-stage {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata] 
```

- `project` is the name of the project that contains the build stage. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the build stage.
- `id` is the id of the build stage. One of `name` or
`id` must be specified. 
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Deleting build stages
The following syntax deletes a build stage by name from the specified project:
```
cpdctl dsjob delete-build-stage {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```

- `project` is the name of the project that contains the build stage. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the build stage that is being deleted.
- `id` is the id of the build stage. One of `name` or
`id` must be specified. Multiple values can be specified for `name`
and `id` to delete multiple items, in the format `--name NAME1 --name
NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Generating build stages
The following syntax generates and compiles the code for a build stage:
```
cpdctl dsjob generate-build-stage {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}
```

- `project` is the name of the project that contains the build stage. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the build stage that is being generated.
- `id` is the id of the build stage. One of `name` or
`id` must be specified. 

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Exporting build stages

The following syntax exports build stages by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-build-stage {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the build stage.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.



### Listing custom stages
The following syntax displays a list of all custom stages in the specified project:
```
cpdctl dsjob list-custom-stages {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```

- `project` is the name of the project that contains the custom stages to
list.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the custom stages in the project is
displayed, one per line.
- `sort` when specified returns the list of custom stages sorted in alphabetical
order. This field is optional.
- `sort-by-time` when specified the list of custom stages will be sorted by time of
creation with latest at the top of the list. One of `sort` or
`sort-by-time` can be specified. 
- `with-id` when specified prints the custom stage id along with the name of the
custom stage.


A status code is printed to the output. A status code of 0 indicates successful completion of the
command.


### Creating custom stages
The following syntax creates a custom stage in the specified project:
```
cpdctl dsjob create-custom-stage {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] --file-name ENTITYFILE
```


- `project` is the name of the project that the custom stage is created for. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the custom stage being created.
- `description` is the description of the custom stage being created.
- `file-name` is the name of the file that contains the custom stage JSON. The JSON
contains the name, description and all other stage details. This field must be specified.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Getting custom stages
The following syntax fetches a custom stage by name from the specified project:
```
cpdctl dsjob get-custom-stage {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata] 
```

- `project` is the name of the project that contains the custom stage. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the custom stage.
- `id` is the id of the custom stage. One of `name` or
`id` must be specified. 
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.
- `with-metadata `when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Deleting custom stages
The following syntax deletes a custom stage by name from the specified project:
```
cpdctl dsjob delete-custom-stage {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```

- `project` is the name of the project that contains the custom stage. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the custom stage that is being deleted.
- `id` is the id of the custom stage. One of `name` or
`id` must be specified. Multiple values can be specified for `name`
and `id` to delete multiple items, in the format `--name NAME1 --name
NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Exporting custom stages

The following syntax exports custom stages by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-custom-stage {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the custom stage.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name` name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.



### Listing wrapped stages
The following syntax displays a list of all wrapped stages in the specified project:
```
cpdctl dsjob list-wrapped-stages {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```

- `project` is the name of the project that contains the wrapped stages to
list.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the wrapped stages in the project is
displayed, one per line.
- `sort` when specified returns the list of wrapped stages sorted in alphabetical
order. This field is optional.
- `sort-by-time` when specified the list of wrapped stages will be sorted by time
of creation with latest at the top of the list. One of `sort` or
`sort-by-time` can be specified. 
- `with-id` when specified prints the wrapped stage id along with the name of the
wrapped stage.


A status code is printed to the output. A status code of 0 indicates successful completion of the
command.


### Creating wrapped stages
The following syntax creates a wrapped stage in the specified project:
```
cpdctl dsjob create-wrapped-stage {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] --file-name ENTITYFILE
```


- `project` is the name of the project that the wrapped stage is created for. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the custom stage being created.
- `description` is the description of the custom stage being created.
- `file-name` is the name of the file that contains the wrapped stage JSON. The
JSON contains the name, description and all other stage details. This field must be specified.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Getting wrapped stages
The following syntax fetches a wrapped stage by name from the specified project:
```
cpdctl dsjob get-wrapped-stage {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata] 
```

- `project` is the name of the project that contains the wrapped stage. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the wrapped stage.
- `id` is the id of the wrapped stage. One of `name` or
`id` must be specified. 
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Deleting wrapped stages
The following syntax deletes a wrapped stage by name from the specified project:
```
cpdctl dsjob delete-wrapped-stage {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```

- `project` is the name of the project that contains the wrapped stage. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the wrapped stage that is being deleted.
- `id` is the id of the wrapped stage. One of `name` or
`id` must be specified. Multiple values can be specified for `name`
and `id` to delete multiple items, in the format `--name NAME1 --name
NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Generating wrapped stages
The following syntax generates and compiles the code for a build
stage:
```
cpdctl dsjob generate-wrapped-stage {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}
```

- `project` is the name of the project that contains the wrapped stage. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the wrapped stage that is being generated.
- `id` is the id of the wrapped stage. One of `name` or
`id` must be specified. 

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Exporting wrapped stages

The following syntax exports wrapped stages by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-wrapped-stage {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the wrapped stage.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the `zip` file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


## Assets and attachments

### Listing assets
The following syntax displays a list of all assets in the specified project:
```
cpdctl dsjob list-assets {--project PROJECT | --project-id PROJID} [-asset-type ASSETTYPE] [--sort | --sort-by-time] [--with-id]
```

- `project` is the name of the project that contains the assets to list.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the assets in the project is displayed,
one per line.
- `asset-type` is the type of asset to list. If not specified, all assets are
listed.
- `sort` when specified returns the list of assets sorted in alphabetical order.
This field is optional.
- `sort-by-time` when specified the list of assets will be sorted by time of
creation with latest at the top of the list. One of `sort` or
`sort-by-time` can be specified. 
- `with-id` when specified prints the asset id along with the name of the
asset.


A status code is printed to the output. A status code of 0 indicates successful completion of the
command.

### Exporting Operational Decision Managers

The following syntax exports Operational Decision Managers by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-operational-dm {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the Operational Decision Manager.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Getting attachments
The following syntax fetches an attachment by name from the specified project:
```
cpdctl dsjob get-attachment {--project PROJECT | --project-id PROJID} {--asset-name NAME | --asset-id ID} {--name NAME | --id ID} --file-name FILENAME
```

- `project` is the name of the project that contains the asset. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `asset-name` is the name of the asset. This field must be specified. 
- `asset-id` is the id of the asset. One of `asset-name` or
`asset-id` must be specified.
- `name` is the name of the attachment.
- `id` is the id of the attachment. One of `name` or
`id` must be specified. 
- `file-name` specifies the name of the file to which the output is written. This
field is optional.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


## Match specifications

### Listing match specifications
The following syntax displays a list of all match specifications in the specified project:
```
cpdctl dsjob list-match-specs {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```

- `project` is the name of the project that contains the match specifications to
list.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the match specifications in the project
is displayed, one per line.
- `sort` when specified returns the list of match specifications sorted in
alphabetical order. This field is optional.
- `sort-by-time` when specified the list of match specifications will be sorted by
time of creation with latest at the top of the list. One of `sort` or
`sort-by-time` can be specified. 
- `with-id` when specified prints the match specification id along with the name of
the match specification.


A status code is printed to the output. A status code of 0 indicates successful completion of the
command.


### Getting match specifications
The following syntax fetches a match specification by name from the specified project:
```
cpdctl dsjob get-match-spec {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata] 
```

- `project` is the name of the project that contains the match specification. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the match specification.
- `id` is the id of the match specification. One of `name` or
`id` must be specified. 
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Deleting match specifications
The following syntax deletes a match specification by name from the specified project:
```
cpdctl dsjob delete-match-spec {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```

- `project` is the name of the project that contains the match specification. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the match specification that is being deleted.
- `id` is the id of the match specification. One of `name` or
`id` must be specified. Multiple values can be specified for `name`
and `id` to delete multiple items, in the format `--name NAME1 --name
NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.

### Exporting match specifications

The following syntax exports match specifications by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-match-spec {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the match specification.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Copying match specifications
The following syntax copies a match specification.
```
cpdctl dsjob copy-match-spec {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} 
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the match specification. 
- `id` is the id of the match specification. One of `name` or
`id` must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


## Function libraries

Function ibraries provide a means to execute user-defined C++ functions, delivered as shared libraries, when running a parallel DataStage job.

### Listing function libraries

The following syntax displays a list of all function libraries in the specified project:
```
cpdctl dsjob list-function-libs {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```

- `project`  is the name of the project that contains the function libraries to list.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. A list of all the function libraries in the project is displayed, one per line.
- `sort`  when specified returns the list of function libraries sorted in alphabetical order. This field is optional.
- `sort-by-time`  when specified sorts the list of function libraries by time of creation with latest at the top of the list. One of  `sort`  or  `sort-by-time`  can be specified.
- `with-id`  when specified prints the function library id along with the name of the function library.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

  

### Creating function libraries
The following syntax creates a function library in the specified project:
```
cpdctl dsjob create-function-lib {--project PROJECT | --project-id PROJID} --name NAME --file-name FILENAME [--return-type-file RETTYPEFILE | --return-type method1=double...] [--dep-libs <FILENAME>]...
```

- `project`  is the name of the project that the function library is created for.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the function library being created.
- `file-name`  is the name of the shared library binary file. 
- `return-type-file` is the name of the file that contains function names and their associated return type and alias separated by a comma. Each line in the file  has the format `MyFunc="unsigned char*",MyFuncAlias` where alias is optional.  
- `return-type` this flag can be used to represent a single line in the `return-type-file` using the same format mentioned above. The field is repeatable.
- `dep-libs` is the list of shared library binaries required. This flag is repeatable.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

  

### Getting function libraries

The following syntax fetches a function library by name from the specified project:
```
cpdctl dsjob get-function-lib {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output file|json] [--file-name FILENAME] [--with-metadata]
```
  
- `project` is the name of the project that contains the function library.
- `project-id`  is the id of the project. One of `project` or `project-id` must be specified.
- `name` is the name of the function library.
- `id` is the id of the function library. One of `name` or `id` must be specified.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This field is optional.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

  

### Deleting function libraries

The following syntax deletes a function library by name from the specified project:
```
cpdctl dsjob delete-function-lib {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```
 
- `project`  is the name of the project that contains the function library.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the function library that is being deleted.
- `id`  is the id of the function library. One of  `name`  or  `id`  must be specified. Multiple values can be specified for  `name`  and  `id`  to delete multiple items, in the format  `--name NAME1 --name NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Exporting function libraries

The following syntax exports function libraries by name from the specified project. The exported zip file is compatible with import-zip format. Please refer to the `import-zip` command to import as desired into a different project.

```
cpdctl dsjob export-function-lib {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile
```

- `project`  is the name of the project.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the function library. `name` can be a regular expression. Example: `abc.*` exports all names that start with abc.
-  `file-name` name of the zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Updating function libraries

The following syntax updates a function library in the specified project:
```
cpdctl dsjob update-function-lib {--project PROJECT | --project-id PROJID} --name NAME --file-name FILENAME [--return-type-file RETTYPEFILE | --return-type method1=double...] [--dep-libs <FILENAME>]...
```

- `project`  is the name of the project that the function library is created for.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the function library being created.
- `file-name`  is the name of the shared library binary file. 
- `return-type-file` name of the file that contains function names and their associated return type and alias separated by a comma. Each line in the file  has the format `MyFunc="unsigned char*",MyFuncAlias` where alias is optional.  
- `return-type` this flag can be used to represent a single line in the `return-type-file` using the same format mentioned above. The field is repeatable.
- `dep-libs` is the list of other shared library binary required and the main library is dependent on. This flag is repeatable.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

## Java libraries

Java libraries provide a means to execute user-defined java libraries when running a parallel DataStage job.

### Listing java Libraries

The following syntax displays a list of all java libraries in the specified project:
```
cpdctl dsjob list-java-libraries {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]

```

- `project`  is the name of the project that contains the java libraries to list.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. A list of all the java libraries in the project is displayed, one per line.
- `sort`  when specified returns the list of java libraries sorted in alphabetical order. This field is optional.
- `sort-by-time`  when specified, the list of java libraries will be sorted by time of creation with latest at the top of the list. One of  `sort`  or  `sort-by-time`  can be specified.
- `with-id`  when specified prints the java library id along with the name of the java library.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

  
### Creating java libraries

The following syntax creates a java library in the specified project:

```
cpdctl dsjob create-java-library {--project PROJECT | --project-id PROJID} --name NAME --jar-file FILENAME [--dep-jar <FILENAME>]...
```

- `project`  is the name of the project that the java library is created for.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the java library being created.
- `jar-file`  is the name of the java jar file.
- `dep-jar` is the list of other java library jar files required and the main library is dependent on. This flag is repeatable.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.  

### Getting java libraries

The following syntax fetches a java library by name from the specified project:
```
cpdctl dsjob get-java-library {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output file|json] [--file-name FILENAME] [--with-metadata]
```

- `project`  is the name of the project that contains the java library.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the java library.
- `id`  is the id of the java library. One of  `name`  or  `id`  must be specified.
- `output`  specifies the format of the output. This field is optional.
- `file-name`  specifies the name of the file to which the output is written. This field is optional.
- `with-metadata`  when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Deleting java libraries

The following syntax deletes a java library by name from the specified project:
```
cpdctl dsjob delete-java-library {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```

- `project`  is the name of the project that contains the java library.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the java library that is being deleted.
- `id`  is the id of the java library. One of  `name`  or  `id`  must be specified. Multiple values can be specified for  `name`  and  `id`  to delete multiple items, in the format  `--name NAME1 --name NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Exporting java libraries

The following syntax exports java libraries by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-java-library {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the java library.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

## Message handlers

Message handlers define rules about how to handle messages generated when a parallel job is running. 

### Listing message handlers

The following syntax displays a list of all message handlers in the specified project:

```
cpdctl dsjob list-message-handlers {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```

- `project`  is the name of the project that contains the message handlers to list.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. A list of all the message handlers in the project is displayed, one per line.
- `sort`  when specified returns the list of message handlers sorted in alphabetical order. This field is optional.
- `sort-by-time`  when specified, the list of message handlers will be sorted by time of creation with latest at the top of the list. One of  `sort`  or  `sort-by-time`  can be specified.
- `with-id`  when specified prints the message handler id along with the name of the message handler.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.
  

### Creating message handlers

The following syntax creates a message handler in the specified project:
```
cpdctl dsjob create-message-handler {--project PROJECT | --project-id PROJID} --name NAME [--description Description] [--default] [--rule name:action:description] [--file-name FILENAME]
```

- `project`  is the name of the project that the message handler is created for.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the message handler being created.
- `description` is the description for the message handler.
- `default` when set, the message handler is used as default message handler for the project.
- `rule` defines rules of the message handler. Each rule must have a name, action and description. ex: `IIS-DSEEE-CEID-00001:{promote|promotefatal|demote|suppress}:<DESCR>`.
- `file-name`  is the name of the file that contains message handler definition.
  
A status code is printed to the output. A status code of 0 indicates successful completion of the command.

  
### Getting message handlers

The following syntax fetches a message handler by name from the specified project:

```
cpdctl dsjob get-message-handler {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output file|json] [--file-name FILENAME] [--with-metadata]
```

- `project`  is the name of the project that contains the message handler.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the message handler.
- `id`  is the id of the message handler. One of  `name`  or  `id`  must be specified.
- `output`  specifies the format of the output. This field is optional.
- `file-name`  specifies the name of the file to which the output is written. This field is optional.
- `with-metadata`  when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

  
### Deleting message handlers

The following syntax deletes a message handler by name from the specified project:

```
cpdctl dsjob delete-message-handler {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```

- `project`  is the name of the project that contains the message handler.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the message handler that is being deleted.
- `id`  is the id of the message handler. One of  `name`  or  `id`  must be specified. Multiple values can be specified for  `name`  and  `id`  to delete multiple items, in the format  `--name NAME1 --name NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Exporting message handlers

The following syntax exports message handlers by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-message-handler {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the message handlers.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


## DataStage project settings

Users can read and update project settings using the `dsjob` plugin. These settings affect how DataStage jobs are run and managed at the project level.

### Get DataStage project settings

The following syntax gets the DataStage settings from the specified project:

```
cpdctl dsjob get-ds-settings {--project PROJECT | --project-id PROJID} [--output json|file] [--file-name FILENAME] [--with-metadata]
```

- `project`  is the name of the project.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `output`  specifies the format of the output. This field is optional.
-   `file-name`  specifies the name of the file to which the output is written. This field is optional.
-   `with-metadata`  when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Setting DataStage project settings

The following syntax is used to set the DataStage settings in the specified project:

```
cpdctl dsjob update-ds-settings {--project PROJECT | --project-id PROJID} [--priority <Low, Medium or High>] [{--env ENVNAME | --env-id ENVID}] [--msg-handler <MESSAGEHANDLER>] [--separator <, or .>] [--keep-runs <N>] [--keep-days <N>] [--time-format <hh:nn:ss>] [-date-format <yyyy-mm-dd>] [--timestamp-format <yyyy:mm:dd hh:nn:ss>] [--nls-format <NLSFORMAT>] [--nls-collate <LANGUAGE>]
```

- `project`  is the name of the project.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `priority` sets the priority on the DataStage job. Valid values are Low, Medium and High. This field is optional. 
- `env` sets the default environment for the project by name. This field is optional.
- `env-id` sets the default environment for the project by id. This field is optional.
- `msg-handler` sets a default message handler for the project. This field is optional.
- `separator` sets the decimal separator for the project to be `.` or `,`. This field is optional.
- `keep-runs` keeps only the specified number of job runs, deleting older job runs. This field is optional.
- `keep-days` keeps job runs for a specified number of days, deleting older runs. This field is optional.
- `time-format` specifies the time format used by the project. This field is optional.
- `data-format` specifies the date format used by the project. This field is optional.
- `timestamp-format` specifies the timestamp format used by the project. This field is optional.
- `nls-format` specifies the NLS settings for the project. This field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


## Standardization rules

### Listing standardization rules
The following syntax displays a list of all standardization rules in the specified project:
```
cpdctl dsjob list-rules {--project PROJECT | --project-id PROJID} [--custom-only]
```

- `project` is the name of the project that contains the standardization rules to
list.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the standardization rules in the
project is displayed, one per line.
- `custom-only` if true, shows only custom rules.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Creating standardization rules
The following syntax creates a standardization rule in the specified project:
```
cpdctl dsjob create-rule {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] [--location LOCATION]
```


- `project` is the name of the project that the standardization rule is created
for. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the standardization rule. 
- `description` is the description of the rule. 
- `location` is the location folder where the rule is created. Rules can only be
created in the folder Customized Standardization Rules.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Getting standardization rules
The following syntax fetches a standardization rule by name from the specified project:
```
cpdctl dsjob get-rule {--project PROJECT | --project-id PROJID} --name NAME --location LOCATION [--output file|json] [--file-name FILENAME]
```

- `project` is the name of the project that contains the standardization rule. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the standardization rule.
- `location` is the location of the rule.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Deleting standardization rules
The following syntax deletes a standardization rule by name from the specified project:
```
cpdctl dsjob delete-rule {--project PROJECT | --project-id PROJID} --name NAME --location LOCATION
```

- `project` is the name of the project that contains the standardization rule. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the standardization rule that is being deleted.
- `location` is the location of the rule.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Exporting standardization rules

The following syntax exports standardization rules by name from the specified project. The exported .zip file is compatible with `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-rule {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile

```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the standardization rule.  `name`  can be a regular expression. Example:  `abc.*`  exports all names that start with abc.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


### Copying standardization rules
The following syntax copies a standardization rule.
```
cpdctl dsjob copy-rule {--project PROJECT | --project-id PROJID} --name NAME --location LOCATION [--dest NAME] [--dest-location LOCATION]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the standardization rule. 
- `location` is the location of the rule.
- `dest` is the new name of the standardization rule. This is optional and if not
specified a default name will be provided.
- `dest-location` is the location of the copied rule. If not specified the location
defaults to Customized Standardization Rules.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

## Data Quality rules

### List Data Quality Rules
The following syntax displays a list of all quality rules in the specified project.

```
cpdctl dsjob list-quality-rules {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```

-   `project`  is the name of the project that contains the quality rules.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. A list of all the quality rules in the project is displayed, one per line.
-   `sort`  when specified returns the list of quality rules sorted in alphabetical order. This field is optional.
-   `sort-by-time`  when specified sorts the list by create or update time. One of  `sort`  or  `sort-by-time`  can be specified.
-   `with-id`  when specified prints the rule id and name.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Get Data Quality Rule
The following syntax fetches a quality rule by name from the specified project.

```
cpdctl dsjob get-quality-rule {--project PROJECT | --project-id PROJID} [--name rulename | --id ruleid] [--output json/file] [--file-name OUTPUT]
```

-   `project`  is the name of the project that contains the quality rules.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `name`  is the name of the quality rule.
-   `id`  is the id of the quality rule. One of  `name`  or  `id`  must be specified.
-   `output`  specifies the format of the output. This field is optional.
-   `file-name`  specifies the name of the file to which the output is written. This field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Import Data Quality Rule
The following syntax imports a quality rule by name to the specified project.

```
cpdctl dsjob import-quality-rule {--project PROJECT | --project-id PROJID} [--name rulename] [--def <DEFINITION> | --def-id <DEFINITIONID>] --file-name IMPORTFILE
```

-   `project`  is the name of the project that contains the quality rules.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `name`  is the name of the quality rule.
-   `id`  is the id of the quality rule. One of  `name`  or  `id`  must be specified.
-   `output`  specifies the format of the output. This field is optional.
-  `def` name of the quality rule definition
-   `def-id`  is the id of the quality rule definition. One of  `def`  or  `def-id`  must be specified.
-   `file-name`  specifies the name of the file from which rule is imported. 

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Export Data Quality Rule
The following syntax exports a quality rule by name from the specified project.

```
cpdctl dsjob export-quality-rule {--project PROJECT | --project-id PROJID} [--name rulename | --id ruleid] --file-name EXPORTFILE
```

-   `project`  is the name of the project that contains the quality rules.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `name`  is the name of the quality rule.
-   `id`  is the id of the quality rule. One of  `name`  or  `id`  must be specified.
-   `file-name`  specifies the name of the file to which rule is exported. 

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Delete Data Quality Rule

The following syntax deletes a quality rule by name from the specified project.

```
cpdctl dsjob delete-quality-rule {--project PROJECT | --project-id PROJID} [--name rulename | --id ruleid]
```

-   `project`  is the name of the project that contains the quality rules.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `name`  is the name of the quality rule.
-   `id`  is the id of the quality rule. One of  `name`  or  `id`  must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.
  


### List Data Quality Rule Definitions
The following syntax displays a list of all quality rule definitions in the specified project.

```
cpdctl dsjob list-quality-definitions {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```

-   `project`  is the name of the project that contains the quality rule definitions.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. A list of all the quality rule definitions in the project is displayed, one per line.
-   `sort`  when specified returns the list of quality rule definitions sorted in alphabetical order. This field is optional.
-   `sort-by-time`  when specified sorts the list by create or update time. One of  `sort`  or  `sort-by-time`  can be specified.
-   `with-id`  when specified prints the rule id and name.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Get Data Quality Rule Definition
The following syntax fetches a quality rule definition by name from the specified project.

```
cpdctl dsjob get-quality-definition {--project PROJECT | --project-id PROJID} [--name definitionname | --id definitionid] [--output json/file] [--file-name OUTPUT]
```

-   `project`  is the name of the project that contains the quality rule definitions.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `name`  is the name of the quality rule definition.
-   `id`  is the id of the quality rule definition. One of  `name`  or  `id`  must be specified.
-   `output`  specifies the format of the output. This field is optional.
-   `file-name`  specifies the name of the file to which the output is written. This field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Import Data Quality Rule Definition
The following syntax imports a quality rule definition by name to the specified project.

```
cpdctl dsjob import-quality-definition {--project PROJECT | --project-id PROJID} [--name definitionname]  --file-name IMPORTFILE
```

-   `project`  is the name of the project that contains the quality rule definition.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `name`  is the name of the quality rule definition.
-   `file-name`  specifies the name of the file from which rule is imported. 

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Export Data Quality Rule
The following syntax exports a quality rule definition by name from the specified project.

```
cpdctl dsjob export-quality-definition {--project PROJECT | --project-id PROJID} [--name definitionname | --id definitionid] --file-name EXPORTFILE
```

-   `project`  is the name of the project that contains the quality rule definitions.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `name`  is the name of the quality rule definition.
-   `id`  is the id of the quality rule definition. One of  `name`  or  `id`  must be specified.
-   `file-name`  specifies the name of the file to which rule is exported. 

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Delete Data Quality Rule

The following syntax deletes a quality rule by name from the specified project.

```
cpdctl dsjob delete-quality-definition {--project PROJECT | --project-id PROJID} [--name definitionname | --id definitionid]
```

-   `project`  is the name of the project that contains the quality rules.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `name`  is the name of the quality rule definition.
-   `id`  is the id of the quality rule definition. One of  `name`  or  `id`  must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


## User volumes


### Listing user volumes
The following syntax lists user volumes in a
cluster:
```
cpdctl dsjob list-volumes [--sort | --sort-by-time | --sort-by-size]
```

- `sort` sorts by name of the volume.
- `sort-by-time` sorts by time of the volume's creation.
- `sort-by-size` sorts by size of the volume. Only one sort flag may be specified.




A status code is printed to the output. A status code of 0 indicates successful completion of the
command.



### Creating directories on a user volume
The following syntax creates a directory on a
volume:
```
cpdctl dsjob create-volume-dir --name VOLNAME --dir-name DIRNAME
```

- `name` is the name of the volume.
- `dir-name` is the name of the directory being created. 



A status code is printed to the output. A status code of 0 indicates successful completion of the
command.



### Deleting directories on a user volume
The following syntax deletes a directory on a
volume:
```
cpdctl dsjob delete-volume-dir --name VOLNAME --dir-name DIRNAME
```

- `name` is the name of the volume.
- `dir-name` is the name of the directory being deleted. 



A status code is printed to the output. A status code of 0 indicates successful completion of the
command.



### Listing files on a user volume
The following syntax lists files on a
volume:
```
cpdctl dsjob list-volume-files -- name VOLNAME [--path DIRPATH]
```

- `name` is the name of the volume.
- `path` is a path on the volume. This field is optional. 



A status code is printed to the output. A status code of 0 indicates successful completion of the
command.



### Uploading files to a user volume
The following syntax uploads files to a
volume:
```
cpdctl dsjob upload-volume-files --name VOLNAME --path DIRPATH --file-name LOCALFILENAME [--to-file TARGETFILENAME] [--extract]
```

- `name` is the name of the volume.
- `path` is a path on the volume. This field is optional. 
- `file-name` is the name of the file to upload.
- `to-file` if specified this value will be the target file name, if not the name of the target file will be the same as value specified for file-name.
- `extract` specifies that `file-name` is a .zip file that needs to be extracted.

A status code is printed to the output. A status code of 0 indicates successful completion of the
command.



### Downloading files from a user volume
The following syntax downloads files from a
volume:
```
cpdctl dsjob download-volume-files -- name VOLNAME [--path DIRPATH] [--file-name <FILETODOWNLOAD>] [--output-file <OUTPUTFILE>]
```

- `name` is the name of the volume.
- `path` is a path on the volume. This field is optional. 
- `file-name` is the name of the file to download.
- `output-file` is the name of the file that the output is written to.

A status code is printed to the output. A status code of 0 indicates successful completion of the
command.


## Dependencies

### Listing dependencies

The following syntax displays a list of all dependencies between DataStage components:

```
cpdctl dsjob list-dependencies {--project PROJECT | --project-id PROJID} [--file-name FILENAME] [--deep] [--usedby] [--sort | --sort-by-time]
```

-   `project`  is the name of the project that contains the pipelines to list.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `sort`  when specified returns the list sorted in alphabetical order. This field is optional.
-   `sort-by-time`  when specified the list will be sorted by time of creation with latest at the top of the list. One of  `sort`or  `sort-by-time`  can be specified.
-   `usedby`  when specified prints the dependency using the used by relationship, for examples `job uses flow` vs `flow used by job`. This field is optional.
-  `deep`  will traverse the dependency tree exhaustively and print the dependencies tree fully. This field is optional.
-   `file-name`  specifies the name of the file to which the output is written. This field is optional.

### Listing usages

The following syntax displays a list of all usages  for a given list of DataStage components:

```
cpdctl dsjob list-usage {--project PROJECT | --project-id PROJID}  {--name ASSETNAME | --id ASSETID}... [--deep] [--usedby]
```

-   `project`  is the name of the project that contains the pipelines to list.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `asset-name`  is the name of the asset. This field must be specified and repeatable.
-   `asset-id`  is the id of the asset. One of  `asset-name`  or  `asset-id`  must be specified. 
-   `usedby`  when specified prints the dependency using the used by relationship, for examples  `job uses flow`  vs  `flow used by job`. This field is optional.
-   `deep`  when specified traverses the dependency tree exhaustively and print the dependencies tree fully. This field is optional.


## DSParams

### Moving DSParams from Information Server

The following syntax transfers environment variables from DSParams file into a runtime environment in a project:

```
cpdctl dsjob create-dsparams {--project PROJECT | --project-id PROJID} [--file-name FILENAME] -load-env-var-defs
```

-   `project`  is the name of the project that contains the pipelines to list.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `file-name`  specifies the name of the DSParams file . 
-   `load-env-var` when set to true, all entries in EnvVarDefns are processed except names that start with APT_. If not true, only entries in EnvVarValues section will be processed.

Note: If the PROJDEF does not exist it will be created and every entry in the EnvVarValues section of the DSParams will be added to PROJDEF. If PROJDEF exists then it will be patched with these parameters. If any field is encoded its value will then be converted into an encoded string.

## Validation


### Validating pipelines
The following syntax validates pipelines in a specified project to verify that the pipeline
references DataStage correctly:
```
cpdctl dsjob validate-pipeline {--project PROJECT | --project-id PROJID} {--name name | --id ID} [--detail]
```

- `project` is the name of the project that contains the pipeline. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the pipeline. 
- `id` is the id of the pipeline. One of `name` or
`id` can be specified. If neither is specified, all pipelines in the project are
validated.
- `detail` when specified produces a detailed output. This field is optional.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Validating connections
The following syntax validates a connection in the specified project:
```
cpdctl dsjob validate-connection {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}
```

- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the connection. 
- `id` is the id of the connection. If both `name` and
`id` are not specified, all connections in the project are validated.

This command also identifies duplicate connections with the same properties and lists them in the summary.

A status code is printed to the output. A status code of 0 indicates successful completion of
the command.

### Validating flows
The following syntax validates a flow and checks if all the flow's references to connections, parameter sets and subflows are valid. 

```
cpdctl dsjob validate-flow {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}
```

-   `project`  is the name of the project that contains the flow.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `name`  is the name of the flow. 
-  `id`  is the id of the flow. One of of `name` or `id` must be specified. 

If name or id of the flow is not specified, the command will validate all flows in a given project. 

### Validating subflows
The following syntax validates a subflow and checks if all the subflow's references to connections, parameter sets and subflows are valid. 

```
cpdctl dsjob validate-subflow {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}
```

-   `project`  is the name of the project that contains the subflow.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `name`  is the name of the subflow. 
-  `id`  is the id of the flow. One of of `name` or `id` must be specified. 

If name or id of the subflow is not specified, the command will validate all subflows in a given project. 

### Validating jobs
The following syntax validates a job. 

```
cpdctl dsjob validate-job {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. 
-   `name`  is the name of the job.
-  `id`  is the id of the job. One of of `name` or `id` must be specified. 

If name or id of the job is not specified, the command will validate all jobs in a given project. 

## Complex Flat File Schemas

### Listing CFF Schema

The following syntax displays a list of all CFF Schemas in the specified project:

```
cpdctl dsjob list-cff-schemas {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```

-   `project`  is the name of the project that contains the CFF Schemas to list.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. A list of all the CFF Schemas in the project is displayed, one per line.
-   `sort`  when specified returns the list of CFF Schemas sorted in alphabetical order. This field is optional.
-   `sort-by-time`  when specified, the list of CFF Schemas will be sorted by time of creation with latest at the top of the list. One of  `sort`  or  `sort-by-time`  can be specified.
-   `with-id`  when specified prints the CFF Schema id along with the name of the CFF Schema.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Creating CFF Schema
The following syntax creates a CFF Schema in the specified project:
```
cpdctl dsjob create-cff-schema {--project PROJECT | --project-id PROJID} --name NAME [--description Description] --file-name SCHEMAFILENAME
```

-   `project`  is the name of the project that the CFF Schema is created for.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the CFF Schema being created.
-   `description`  is the description for the CFF Schema.
-   `file-name`  is the name of the file that contains COBOL copybook definition.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Getting CFF Schema

The following syntax fetches a CFF Schema by name from the specified project:
```
cpdctl dsjob get-cff-schema {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output file|json] [--file-name FILENAME] [--schema-file SCHEMAFILE] [--with-metadata]
```

-   `project`  is the name of the project that contains the CFF Schema.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the CFF Schema.
-   `id`  is the id of the CFF Schema. One of  `name`  or  `id`  must be specified.
-   `output`  specifies the format of the output. This field is optional.
-   `file-name`  specifies the name of the file to which the output is written. This field is optional.
-   `with-metadata`  when specified adds metadata to the output. This field is optional.
-  `schema-file` file to which schema will be written. This field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Deleting CFF Schema

The following syntax deletes a CFF Schema by name from the specified project:
```
cpdctl dsjob delete-cff-schema {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```

-   `project`  is the name of the project that contains the CFF Schema.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the CFF Schema that is being deleted.
-   `id`  is the id of the CFF Schema. One of  `name`  or  `id`  must be specified. Multiple values can be specified for  `name`  and  `id`  to delete multiple items, in the format  `--name NAME1 --name NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Exporting CFF Schema

The following syntax exports CFF Schema by name from the specified project. The exported .zip file is compatible with  `import-zip`. Please refer to the  `import-zip`  command to import as desired into a different project.

```
cpdctl dsjob export-cff-schema {--project PROJECT | --project-id PROJID} --name NAME --file-name ZIPFile
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the CFF Schema.  `name`  can be a regular expression. Example:  `abc*`  exports all names that start with abc.
-   `file-name`  name of the .zip file to which exported content is written.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


## Folders

The following commands can be used to work with folders.

### Listing folders

The following syntax displays a list of all folders in the specified project:

```
cpdctl dsjob list-folders {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```

-   `project`  is the name of the project that contains the folders to list.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. A list of all the folders in the project is displayed, one per line.
-   `sort`  when specified returns the list of folders sorted in alphabetical order. This field is optional.
-   `sort-by-time`  when specified, the list of folders will be sorted by time of creation with latest at the top of the list. One of  `sort`  or  `sort-by-time`  can be specified.
-   `with-id`  when specified prints the folder id along with the name of the folder.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Listing folder contents

The following syntax displays a list of the contents of a folder in the specified project:

```
cpdctl dsjob list-folder {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}  [--deep]

```

-   `project`  is the name of the project that contains the folders to list.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified. A list of all the folders in the project is displayed, one per line.
-   `name`  is the name of the folder.
-   `id`  is the id of the folder. One of  `name`  or  `id`  must be specified.
-  `deep` will travel through folders and its subfolders until leaf nodes are reached.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Creating folders
The following syntax creates a folder in the specified project:
```
cpdctl dsjob create-folder {--project PROJECT | --project-id PROJID} --name NAME
```

-   `project`  is the name of the project that the folder is created for.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the folder being created.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Updating folders

The following syntax updates a folders' name in the specified project:
```
cpdctl dsjob update-folder {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}  {--to-name <FOLDER NAME>}
```

-   `project`  is the name of the project that contains the folder.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the folder.
-   `id`  is the id of the folder. One of  `name`  or  `id`  must be specified.
-  `to-name` new name of the folder.

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Deleting folders

The following syntax deletes a folder by name from the specified project:
```
cpdctl dsjob delete-folder {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--include-content]
```

-   `project`  is the name of the project that contains the folder.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the folder that is being deleted.
-   `id`  is the id of the folder. One of  `name`  or  `id`  must be specified. 
-  `include-content` when true, will delete folder and all its contents.
A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Moving folders

The following syntax moves folder to a different location

```
cpdctl dsjob move-folder {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}  {--to-name <FOLDER PATH> | --to-id <FOLDER ID>}
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the folder. 
-   `id`  is the id of the folder. One of  `name`  or  `id`  must be specified. 
-   `to-name`  is the name of the folder under which the folder will be moved.
-   `to-id`  is the id of the folder under which the folder will be moved. One of  `to-name`  or  `to-id`  must be specified. 

A status code is printed to the output. A status code of 0 indicates successful completion of the command.

### Exporting folders

The following syntax exports folder assets and optionally all subfolders into a zip file that can be imported into a project.

```
cpdctl dsjob export-folder {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}  [--deep] [--file-name <EXPORTFILE>]
```

- `project`  is the name of the project.
- `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
- `name`  is the name of the asset.
- `id`  is the id of the asset. One of  `name`  or  `id`  must be specified.
- `file-name`  specifies the name of the file to which the output is written.
- `deep` If true, exports all objects under the folder and its subfolders, recursively. Default value is false. 

A status code is printed to the output. A status code of 0 indicates successful completion of the command. 

### Moving folder assets

The following syntax moves folder assets to a different folder

```
cpdctl dsjob move-asset {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}  {--to-name <FOLDER PATH> | --to-id <FOLDER ID>}
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `name`  is the name of the asset. 
-   `id`  is the id of the asset. One of  `name`  or  `id`  must be specified. 
-   `to-name`  is the name of the folder under which the asset will be moved.
-   `to-id`  is the id of the folder under which the asset will be moved. One of  `to-name`  or  `to-id`  must be specified. 

A status code is printed to the output. A status code of 0 indicates successful completion of the command.


## Git integration

### Committing project to Git 
The following command exports an existing projects and persists to a git repo.
```
cpdctl dsjob git-commit {--project PROJECT | --project-id PROJID} [--repo <REPONAME>] [--branch <BRANCH>] [--in-folder <FOLDERNAME>] [--commit-message <MSG>] [--use-zip] <ZIPFILE>] [--include-data-assets] [--exclude-datasets-filesets] [--enc-key <ENCODING KEY>]
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-  `repo` name of the git repo.
-  `branch`  branch to which project will be uploaded. This field is optional.
-  `in-folder` name of a folder in a Git Repo where the project content are stored. This field is optional. 
-  `commit-message` commit message for this commit of the project.
- `use-zip` use zip file that contains the project export. This field is optional.
-  `include-data-assets` includes the project's data assets as part of the export.
- - `exclude-datasets-filesets` when specified datasets and filesets are exported  but the data is excluded.
- `enc-key`  specifies encryption key used to encrypt exported sensitive data. This key must be a string that will be used during import process to decrypt and must be saved securely.

### Importing project from Git 
The following command imports content from a git repo into a project.

```
cpdctl dsjob git-pull {--project PROJECT | --project-id PROJID} [--repo <REPONAME>] [--in-folder <FOLDERNAME>] [--branch <BRANCH>] [--name ASSETNAME | --id ASSETID]... [--on-failure ONFAILURE] [--conflict-resolution CONFLICT-RESOLUTION]
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-  `repo` name of the git repo.
-  `in-folder` name of a folder in a Git Repo where the project content are stored. This field is optional. 
-  `branch` is the name of the branch from which project artifacts are pulled. This field is optional.
-  `name`  is the name of the asset. This field must be specified and repeatable. Asset name can optionally be prefixed with type, ex: `data_intg_flow/flow_name`.
-   `id`  is the id of the asset. One of  `name`  or  `id`  must be specified.
-   `on-failure`  indicates what action to take if the import fails. This field is optional. The default option is `continue`, the other option is `stop`.
-   `conflict-resolution`  specifies the resolution when the data flow to be imported has the same name as an existing data flow in the project. This field is optional. The default option is `skip`, the others values are `rename` and `replace`.

### Get status on your Git project
The following command can be used to obtain status on what has changed between your project and git repo.
```
cpdctl dsjob git-status {--project PROJECT | --project-id PROJID} [--repo <REPONAME>] [--in-folder <FOLDERNAME>] 
```

-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-  `repo` name of the git repo.
-  `in-folder` name of a folder in a Git Repo where the project content are stored. This field is optional. 

### Encrypt sensitive data
The following command can be used to encrypt a plain text string or a legacy encoded string to a Cloud Pak for Data cluster specific encoded string.
```
cpdctl dsjob encrypt {--text <input>} 
```

-   `text` is any text that is plain or encoded, the input will be converted to an encoded string that can be used on the cluster you are connected to. 
