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
- [Standardization rules](#standardization-rules)
- [User volumes](#user-volumes)



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
DSJOB_APIKEY=&lt;YOUR APIKEY>
cpdctl config profile set ibmcloud-profile --url $DSJOB_URL --apikey $DSJOB_APIKEY --watson-studio-url https://api.dataplatform.cloud.ibm.com
```

For CPD:

```
#!/bin/bash
export DSJOB_URL=&lt;CP4D CLUSTER URL>
export DSJOB_USER=&lt;USER>
export DSJOB_PWD=&lt;PASSWD>


cpdctl config user set CP4D-user --username $DSJOB_USER --password $DSJOB_PWD
cpdctl config profile set CP4D-profile --url $DSJOB_URL --user CP4D-user
cpdctl config profile use CP4D-profile
```

If you have multiple profiles, you can run a command against a specific profile with either
`cpdctl project list --profile &lt;PROFILE>` or `CPD_PROFILE=&lt;PROFILE>
cpdctl project list`. For example, to run multiple commands in a profile without changing
your default profile, you can run the following commands.

```
export CPD_PROFILE=&lt;PROFILE-1>
cpdctl project list
cpdctl ....
export CPD_PROFILE=&lt;PROFILE-2>
cpdctl project list
cpdctl ....
unset CPD_PROFILE &lt;go back to default profile>
```

Starting with release 1.3.0, all passwords/API keys are encrypted with AES-256. The default encryption key is not stored in GitHub. The recommended option is setting the variable CPDCTL_ENCRYPTION_KEY_PATH to point to a file containing your own encryption key. If the variable is set, it has precedence over the default encryption key hardcoded in cpdctl binary, so on your machine the encryption key is always the same (taken from the file) and you won't lose access to your config. The key can be a string of any length or format.
For more information, see https://github.com/IBM/cpdctl#aes-256-encryption-of-credentials-stored-in-configuration-file.

You may have to recreate your configuration due to the key change. Once you have the key set up, you can read your configuration by upgrading the `cpdctl` binary and using the same key to read the configuration file. 
For example: 
```
# create a file <SOMELOCATION On disk>/mykey.txt
#content of mikes.txt can a simple string ex: `this-is-my-dsjob-key`
export CPDCTL_ENCRYPTION_KEY_PATH=<SOMLOCATION On disk>/mykey.txt
```



# Commands


To enable the `cpdctl dsjob` commands, you must set the environment variable
CPDCTL_ENABLE_DSJOB to `true` in the environment where the <ph
conref="../ds-conrefs.dita#ds_conrefs/cpd"/> command-line interface is installed.
When you set up the `dsjob` command line environment, you must escape any
special characters ($, ") in your password with a backward slash. For example,
`myPa$$word` must be written as `myPa\$\$word`.



## Projects

### Listing projects
The following syntax displays a list of all known projects on the specified project:
```
cpdctl dsjob list-projects [--sort|--sort-by-time] [--with-id] 
```

- `with-id` when specified prints the project id and project name.
- `sort` when specified returns the list of projects sorted in alphabetical order.
This field is optional.
- `sort-by-time` when specified sorts the list by create or update time. One of
`sort` or `sort-by-time` can be specified.


A list of all the projects is displayed, one per line.
A status code is printed to the
output. A status code of 0 indicates successful completion of the command.


### Creating projects
The following syntax is used to create a project:

CPD:
```
cpdctl dsjob create-project -n NAME 
```
CPDaaS:
```
cpdctl dsjob create-project -n NAME [--storage &lt;STG>] [--storage-type bmcos_object_storage|amazon_s3]
```
- `name` is the name of the project that is being created.
- `storage` is the name of the CRN for cloud, for example:
`crn:v1:staging:public:cloud-object-storage:global:a/`.
- `type` is the storage type for cloud. The default value is
`bmcos_object_storage` and the alternate value is `amazon_s3`.

The project ID of the created project is printed to the output.
A status code is
printed to the output. A status code of 0 indicates successful completion of the command.


### Deleting projects
The following syntax is used to delete a project:
```
cpdctl dsjob delete-project {--project PROJECT | --project-id PROJID}

```
- `project` is the name of the project that is being deleted.
- `project-id` is the id of the project that is being deleted. One of
`project` or `project-id` must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


## Jobs

### Listing jobs
The following syntax displays a list of all jobs in the specified project:
```
cpdctl dsjob list-jobs {--project PROJECT | --project-id PROJID} [--sort] [--with-id]
```

- `project` is the name of the project that contains the jobs to list.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `sort` when specified returns the list of jobs sorted in alphabetical order. This
field is optional.
- `with-id` when specified prints the job id along with the name of the job.


A status code is printed to the output. A status code of 0 indicates successful completion of the
command.


### Creating jobs
The following syntax creates a job in the specified project:
```
cpdctl dsjob create-job {--project PROJECT | --project-id PROJID} {--flow NAME | --flow-id ID} [--name NAME] [--description DESCRIPTION] [--schedule-start yyyy-mm-dd:hh:mm] [--schedule-end yyyy-mm-dd:hh:mm] [--repeat every/hourly/daily/monthly --minutes (0-59) --hours (0-23) --day-of-week (0-6) --day-of-month (1-31)]
```


- `project` is the name of the project that the job is created for. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the job to be created.
- `description` is the description of the job to be created. This field is
optional.
- `flow` is the name of the flow. This field must be specified.
- `repeat` indicates frequency of job run. Permitted values are
`every`, `hourly`, `daily`, `weekly`,
and `monthly`. The default value is `none`.
- `minutes` indicates interval in minutes or the minutes at which to run the job.
Values in the range 0-59 are accepted.
- `hours` indicates hour of the day at which to run the job. Values in the range
0-23 are accepted.
- `day-of-month` repeats on day of the month, works with minutes and hours. Values
in the range 0-31 are accepted. Ex: 2 (runs on the second of the month).
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
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the queried job.
- `id` is the id of the job. One of `name` or `id`
must be specified. 
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Deleting jobs
The following syntax deletes a job by name from the specified project:
```
cpdctl dsjob delete-job {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```
- `project` is the name of the project that contains the job. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the job that is being deleted.
- `id` is the id of the job. One of `name` or `id`
must be specified. Multiple values can be specified for `name` and
`id` to delete multiple items, in the format `--name NAME1 --name
NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Updating jobs
The following syntax updates a job by name from the specified project:
```
cpdctl dsjob update-job {--project PROJECT | --project-id PROJID} {--job NAME | --job-id ID} [--run-name RUNNAME] [--param PARAM] [--param-file FILENAME] [--env ENV]
```


- `project` is the name of the project that contains the job. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `job` is the name of the job. 
- `job-id` is the id of the job. One of `job` or
`job-id` must be specified.
- `run-name` is the name given to the job run. 
- `param` specifies a parameter value to pass to the job. The value is in the
format `name=value`, where name is the parameter name and value is the value to be
set. This flag can be repeated, ex: `--param k1=v1 --param k2=v2`
- `paramfile` specifies a file that contains the parameter values to pass to the
job.
- `env` specifies the environment in which the job is run. `env` is
specified as a key=value pair. Key `env` or `env-id` can be used to choose a runtime environment.
Example: `--env $APT_DUMP_SCORE=true --env env=ds-px-default`


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Cleaning up orphaned jobs
The following syntax deletes DataStage jobs that were orphaned by the deletion of their
corresponding flow :
```
cleanup-jobs [--project PROJECT | --project-id PROJID] --dry-run"
```

- `project` is the name of the project that contains the jobs.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `dry-run` when set to `true`, a trial run is attempted without
deleting the jobs.


A status code is printed to the output. A status code of 0 indicates successful completion of the
command.


### Displaying job information
The following syntax displays the available information about a specified job:
```
cpdctl dsjob jobinfo {--project PROJECT | --project-id PROJID} {--job NAME | --job-id ID}  [--full] [--list-params]
```


- `project` is the name of the project that contains the job. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `job` is the name of the job. 
- `job-id` is the id of the job. One of `job` or
`job-id` must be specified.
- `full` displays more detailed information about the job, including information
about all job runs. This field is optional.
- `list-params` displays job level configuration/local parameters and environment
variables.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Running jobs
You can use the run command to start, stop, validate, and reset jobs. The run operation is
asynchronous in nature and the status code indicates whether the job run is successfully submitted
or not except when the --wait option is specified. Please see --wait flag description on how the
behavior changes.
```
cpdctl dsjob run {--project PROJECT | --project-id PROJID} {--job NAME | --job-id ID} --run-name RUNNAME] [--param PARAM] [--param-file FILENAME] [--env ENVJSON] [--paramset PARAMSET] [--wait secs] [--warn-limit &lt;n>] 
```


- `project` is the name of the project that contains the job. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `job` is the name of the job. 
- `job-id` is the id of the job. One of `job` or
`job-id` must be specified.
- `run-name` is the name given to the job run. 
- `param` specifies a parameter value to pass to the job. The value is in the
format `name=value`, where name is the parameter name and value is the value to be
set. This flag can be repeated, ex: `--param k1=v1 --param k2=v2`
- `paramfile` specifies a file that contains the parameter values to pass to the
job.
- `env` specifies the environment in which job is run. `env` is
specified as a key=value pair. Key `env` or `env-id` can be used to chose a runtime environment.
Example: `--env $APT_DUMP_SCORE=true --env env=ds-px-default`
- `paramset` specifies parameter set/value set fields to be passed to the job run.
There are three variations, 1. `--paramset PS1` sends all fields in parameter set PS1
as job parameters to the run, 2. `--paramset PS2.VS2` sends value set values as job
parameters, 3. `--paramset PS1=PROJFDEF` overrides `paramset PS1`
values from PROJDEF and send values of all fields in parameter set `PS1` as job
parameters to the run.
- `wait` the job run waits for the specified amount of time for the job to finish.
The job logs are printed to the output until the job is completed or the wait time expires. The
return status indicates whether the job has finished, finished with warning, raised an error, or
timed out after waiting. This field is optional.
- `warn-limit` specifies the number of warnings after which a job is
terminated.


When the `job` parameter starts with a `$` it will also be
added as a environment variable.
A status code is printed to the output. 
- 0: successfully completed
- 1: completed with warnings
- 2: completed with error
- 3: failed
- 4: canceled
- -1: other



### Stopping jobs
You can use the stop command to stop or cancel running jobs. The stop operation is asynchronous
in nature and the status code indicates whether the job stop is successfully submitted or not. 
```
cpdctl dsjob stop {--project PROJECT | --project-id PROJID} {--job NAME | --job-id ID} [--run-id RUNID]
```


- `project` is the name of the project that contains the job. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `job` is the name of the job. 
- `job-id` is the id of the job. One of `job` or
`job-id` must be specified.
- `runid` can be specified to cancel or stop an existing job run. If
`runid` is not specified, the `runid` of the latest job run that is
not completed is used by default. This field is optional.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


## Job logs

### Displaying a specific log entry
The following syntax displays the specified entry in a job log file:
```
cpdctl dsjob logdetail {--project PROJECT | --project-id PROJID} {--job NAME | --job-id ID} [--run-id RUNID] [--eventrange EVENTRANGE] [--compatible] --follow
```


- `project` is the name of the project that contains the job with the specified log
entry. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `job` is the name of the job. 
- `job-id` is the id of the job. One of `job` or
`job-id` must be specified.
- `runid` processes the log entry for a specific `runid`. If
`runid` is not specified, the latest run is used by default. This field is
optional.
- `eventrange` is the range of event numbers that is assigned to the entry that is
printed to the output. The first entry in the file is 0. If `eventrange` is not
specified, the full log is processed. For example, if you specify `eventrange 2-4`,
the third, fourth, and fifth entries from the log are printed.
- `compatible` will output logs in the format previously used by DataStage components. This field is optional.
- `follow` when specified enables log tailing.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Displaying a short log entry
The following syntax displays a summary of entries in a job log file:
```
cpdctl dsjob logsum {--project PROJECT | --project-id PROJID} {--job NAME | --job-id ID} [--run-id RUNID] [--type TYPE] [--max MAX] [--compatible]
```


- `project` is the name of the project that contains the job with the log entries
that are being retrieved. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `job` is the name of the job. 
- `job-id` is the id of the job. One of `job` or
`job-id` must be specified.
- `runid` processes the log entry for a specific runid. If `runid`
is not specified, the latest run is used by default. This field is optional.
- `type` specifies the type of log entry to retrieve. If `type` is
not specified, all the entries are retrieved. `type` can be one of the following options:
- INFO: Information
- WARNING: Warning
- FATAL: Fatal error
- REJECT: Rejected rows from a Transformer stage
- STARTED: All control logs
- RESET: Job reset
- BATCH: Batch control
- ANY: All entries of any type. This option is the default if `type` is not
specified.

- `compatible` will output logs in the format previously used by DataStage components. This field is optional. 
- `max n` limits the number of entries that are retrieved to
`n`.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Identifying the newest log entry
The following syntax displays the ID of the newest log entry of the specified type:
```
cpdctl dsjob lognewest {--project PROJECT | --project-id PROJID} {--job NAME | --job-id ID} [--run-id RUNID] [--type TYPE]
```


- `project` is the name of the project that contains the job with the log entry
that is being retrieved. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `job` is the name of the job. 
- `job-id` is the id of the job. One of `job` or
`job-id` must be specified.
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
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the job. 
- `id` is the id of the job. One of `name` or `id`
must be specified.
- `run-id` is the run id of the particular job run. This field is optional, if
omitted the last job run statistics are displayed.
- `all` causes the statistics for all runs for the job to be displayed. When using
this flag `run-id` is ignored.
- `with-metadata` when specified adds metadata to the output.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Pruning job runs
Prune commands can be used to delete the job runs based on age or number of runs. The following
syntax can be used to prune job runs in a project: 
```
cpdctl dsjob prune {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--keep-runs NUMRUNS] [--keep-days NUMDAYS] [--threads n] [--dry-run]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the job. 
- `id` is the id of the job. One of `name` or `id`
must be specified.
- `keep-runs` specifies the number of latest runs to keep and deletes rest of the
job runs clearing up space.
- `keep-days` specifies a number of days and deletes all job runs older than that
number.
- `threads` specifies the number of parallel concurrent cleanup routines to run
with one per job. The value should be in the range 5-20, default value is 5. This field is
optional.
- `dry-run` does a mock run without deleting the job runs.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Getting job run cleanup
It is possible to have job runs that never complete and remain stale. These jobs are stuck in a
starting or running state. The following syntax cleans up job runs in a project: 
```
cpdctl dsjob jobrunclean {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--run-id RUNID] [--dry-run] [--threads n]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the job. 
- `id` is the id of the job. One of `name` or `id`
must be specified.
- `run-id` is the run id of the particular job run to clean up. This field is
optional.
- `threads` specifies the number of parallel concurrent cleanup routines to run
with one per job. The value should be in the range 5-20, default value is 5. This field is
optional.
- `dry-run` does a mock run without deleting the job runs.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Listing job runs
The following syntax lists job runs for the specified job:
```
cpdctl dsjob list-jobruns {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--detail] [--output file|json] [--file-name FILENAME]
```
- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the job.
- `id` is the id of the job. One of `name` or `id`
must be specified. 
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Getting job runs
The following syntax gets job run details from the specified job:
```
cpdctl dsjob get-jobrun {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--run-id RUNID] [--output json|file] [--file-name FILENAME] [--with-metadata]
```
- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the job.
- `id` is the id of the job. One of `name` or `id`
must be specified. 
- `run-id` is the id of the job run.
- `output` specifies the format of the output. You can generate a JSON or output to
a file. This field is optional.
- `file-name` specifies the name of the file to which the output is written. If not
specified, the job run id is used as the name.
- `with-metadata` when specified adds metadata to the output.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Listing active job runs
The following syntax lists all active job runs, including incomplete, cancelled and failed
jobs:
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



## Job migration

### Migrating jobs
The Migrate command can be used to create data flows from an exported ISX file. You can use the
command to check status or cancel a migration that is in progress.
```
cpdctl dsjob migrate {--project PROJECT | --project-id PROJID} [--on-failure ONFAILURE] [--conflict-resolution CONFLICT-RESOLUTION] [--attachment-type ATTACHMENT-TYPE] [--import-only] [--create-missing] [--enable-local-connection] [--enable-dataquality-rule] [--file-name FILENAME] [--status IMPORT-ID --format csv/json] [--stop IMPORT-ID] --wait secs
```


- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `on-failure` indicates what action to taken if the import process fails. Possible
options are either `continue` or `stop`. This field is optional.
- `conflict-resolution` specifies the resolution when the data flow to be imported
has a name conflict with an existing data flow in the project or catalog. Possible resolutions are
`skip`, `rename`, or `replace`. This field is
optional.
- `attachment-type` is the type of attachment. The default attachment type is
`isx`. This field is optional.
- `import-only` when specified imports flows without compiling them or creating a
job.
- `create-missing` when specified creates missing parameter sets and job
parameters.
- `enable-local-connection` enables migrating a connection into a flow as a flow
connection.
- `enable-dataquality-rule` when specified migrates a data rule from Information
Analyzer as a <keyword conref="../../dsnav/ds-conrefs.dita#ds_conrefs/datahub"/> rule.
- `file-name` is the name of the input file. This field is required for an import
operation but not with options `-stop` or `-status`.
- `status` returns the status of a previously submitted import job. A value for
`importid` must be specified with this option.
- `stop` cancels an import operation that is in progress. A value for
`importid` must be specified with this option.
- `wait` specifies the time in seconds to wait for the command to complete.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


## Flows

### Listing flows
The following syntax displays a list of all flows in the specified project: 
```
cpdctl dsjob list-flows {--project PROJECT | --project-id PROJID} [--sort|--sort-by-time] [--with-id]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `sort` when specified returns the list of flows sorted in alphabetical order.
This field is optional.
- `sort-by-time` when specified sorts the list by create or update time. One of
`sort` or `sort-by-time` can be specified.
- `with-id` when specified prints the flow id along with the name of the flow.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Creating flows
The following syntax creates a flow in the specified project:
```
cpdctl dsjob create-flow {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] [--pipeline-file FILENAME]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the flow that is being created. 
- `description` is the description of the flow that is being created. This field is
optional.
- `pipeline-file` is the name of the file that contains the flow JSON. This field
must be specified.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Getting flows
The following syntax fetches a flow by name from the specified project:
```
cpdctl dsjob get-flow {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the queried flow.
- `id` is the id of the flow. One of `name` or `id`
must be specified.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.
- `with-metadata` when specified adds metadata to the output.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Deleting flows
The following syntax deletes a flow by name from the specified project:
```
cpdctl dsjob delete-flow {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the flow.
- `id` is the id of the flow. One of `name` or `id`
must be specified. Multiple values can be specified for `name` and
`id` to delete multiple items, in the format `--name NAME1 --name
NAME2...`.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Compiling flows
The following syntax allows you to compile flows in the specified project: 
```
cpdctl dsjob compile {--project PROJECT | --project-id PROJID} [{--name NAME | --id ID}...] [--osh] [--threads &lt;n>]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the flow.
- `id` is the id of the flow. One of `name` or `id`
can be specified. Multiple values can be specified for `name` and `id`
to compile multiple items, in the format `--name NAME1 --name NAME2...`. If not present, all the flows
in the project are compiled. 
- `osh` the output will display compiled 'osh' output. This field is optional.
- `threads` specifies the number of parallel compilations to run. The value should
be in the range 5-20, default value is 5. This field is optional.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


## Pipelines

### Listing pipelines
The following syntax displays a list of all pipelines in the specified project:
```
cpdctl dsjob list-pipelines {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time] [--with-id]
```
- `project` is the name of the project that contains the pipelines to list.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the pipelines in the project is
displayed, one per line.
- `sort` when specified returns the list of pipelines sorted in alphabetical order.
This field is optional. 
- `sort-by-time` when specified the list of pipelines will be sorted by time of
creation with latest at the top of the list. One of `sort` or
`sort-by-time` can be specified. 
- `with-id` when specified prints the pipeline id along with the name of the
pipeline.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Getting pipelines
The following syntax fetches a pipeline by name from the specified project:
```
cpdctl dsjob get-pipeline [--project PROJECT | --project-id PROJID] [--name name | --id ID] [--output file] [--file-name &lt;name>]
```
- `project` is the name of the project that contains the pipeline. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the pipeline.
- `id` is the id of the pipeline. One of `name` or
`id` must be specified. 
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Deleting pipelines
The following syntax deletes a pipeline by name from the specified project:
```
cpdctl dsjob delete-pipeline {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}...
```
- `project` is the name of the project that contains the pipeline. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the pipeline that is being deleted.
- `id` is the id of the pipeline. One of `name` or
`id` must be specified. Multiple values can be specified for `name`
and `id` to delete multiple items, in the format `--name NAME1 --name
NAME2...`.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Importing pipelines
The following syntax imports a pipeline into a specified project: 
```
cpdctl dsjob import-pipeline [--project PROJECT | --project-id PROJID] --name name [description DESCRIPTION] [--volatile] --file-name FILENAME
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
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
cpdctl dsjob export-pipeline [--project PROJECT | --project-id PROJID] [--name name | --id ID] [--format TEMPLATE|FLOW|ALL] [--output file] [--file-name &lt;name>]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the pipeline. 
- `id` is the id of the pipeline. One of `name` or
`id` must be specified. 
- `format` specifies whether to export the pipeline template, pipeline flow, or
both.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the exported pipeline JSON is
written to. 


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Listing pipeline versions
The following syntax displays a list of all pipeline versions in the specified project:
```
cpdctl dsjob list-pipeline-versions {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time]
```
- `project` is the name of the project that contains the pipeline.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the pipeline versions in the project is
displayed, one per line.
- `name` is the name of the pipeline.
- `id` is the id of the pipeline. One of `name` or
`id` must be specified. 
- `sort` when specified returns the list of pipeline versions sorted in
alphabetical order. This field is optional. 
- `sort-by-time` when specified the list of pipeline versions will be sorted by
time of creation with latest at the top of the list. One of `sort` or
`sort-by-time` can be specified. 
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Listing pipeline runs
The following syntax displays a list of all pipeline runs in the specified project:
```
cpdctl dsjob list-pipeline-runs [--project PROJECT | --project-id PROJID] [--name name | --id ID] [--sort | --sort-by-time] [--detail] [--output file|json] [--file-name FILENAME]
```
- `project` is the name of the project that contains the pipeline.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the pipeline runs in the project is
displayed, one per line.
- `name` is the name of the pipeline.
- `id` is the id of the pipeline. One of `name` or
`id` must be specified. 
- `sort` when specified returns the list of pipeline runs sorted in alphabetical
order. This field is optional. 
- `sort-by-time` when specified the list of pipeline runs will be sorted by time of
creation with latest at the top of the list. One of `sort` or
`sort-by-time` can be specified. 
- `detail` when specified prints the pipeline run details.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Running pipelines

A pipeline run is triggered by creating a job for the pipeline and running it. The following
syntax runs a pipeline in the specified project:
```
cpdctl dsjob run-pipeline [--project PROJECT | --project-id PROJID] [--name name | --id ID] [--job-name name] [--description description] [--version VERSION] [--param PARAM] [--param-file FILENAME] [--env ENVJSON] [--paramset PARAMSET] [--wait SEC]
```


- `project` is the name of the project that contains the pipeline. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the pipeline. 
- `id` is the id of the pipeline. One of `name` or
`id` must be specified.
- `job-name` is the name of the job to be created or used. This field is optional. 
- `description` is the description of the job that is run.
- `version` specifies the version of the pipeline that is run.
- `param` specifies a parameter value to pass to the job. The value is in the
format `name=value`, where name is the parameter name and value is the value to be
set. This flag can be repeated, ex: `--param k1=v1 --param k2=v2`
- `paramfile` specifies a file that contains the parameter values to pass to the
job.
- `env` specifies the environment in which job is run. `env` is
specified as a key=value pair. Key `env` or `env-id` can be used to chose a runtime environment.
Example: `--env $APT_DUMP_SCORE=true --env env=ds-px-default`
- `paramset` when specified passes a parameter set to the pipeline.
- `wait` the job run waits for the specified amount of time for the job to finish.
The job logs are printed to the output until the job is completed or the wait time expires. The
return status indicates whether the job has finished, finished with warning, raised an error, or
timed out after waiting. This field is optional.

A status code is printed to the output. 
- 0: successfully completed
- 1: completed with warnings
- 2: completed with error
- 3: failed
- 4: canceled
- -1: other



### Printing pipeline run logs
The following syntax fetches run logs of a pipeline run in the specified project:
```
cpdctl dsjob get-pipeline-logs [--project PROJECT | --project-id PROJID] [--name name | --id ID] [--run-id RUNID] [--output file] [--file-name &lt;name>]
```


- `project` is the name of the project that contains the pipeline. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the pipeline. 
- `id` is the id of the pipeline. One of `name` or
`id` must be specified.
- `run-id` if specified, the logs for that run id is printed. If not specified, the
logs from the latest run are printed.
- `output` specifies the format of the output. This field is optional.
- `file-name` specifies the name of the file to which the output is written. This
field is optional.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


## Imports and exports

### Importing
The following syntax imports the specified project to a file:
```
cpdctl dsjob import {--project PROJECT | --project-id PROJID} --import-file FILENAME 
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `import-file` is the name of the file that contains previously exported
assets.


A status code is printed to the output. 
- 0: successfully completed
- 1: completed with warnings
- 2: completed with error
- 3: failed
- 4: canceled
- -1: other



### Exporting
The following syntax exports the specified project to a file:
```
cpdctl dsjob export {--project PROJECT | --project-id PROJID} [--name NAME] [--description DESCRIPTION] [--export-file FILENAME] [--wait secs] [--asset-type TYPE] [--asset &lt;name,type>...] [--all] 
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `asset list` is a list of all the asset names to be exported. Format:
`--asset type=assetname1,assetname2`.
- `name` is the name of the export.
- `asset-type` is a list of all asset types to export, ex: `--asset-type
Connection --asset-type data_flow`.
- `description` is a description of the exported assets.
- `export-file` is the file for assets to be exported to.


A status code is printed to the output. 
- 0: successfully completed
- 1: completed with warnings
- 2: completed with error
- 3: failed
- 4: canceled
- -1: other



### Listing exports
The following syntax displays a list of all exports from the specified project:
```
cpdctl dsjob list-exports {--project PROJECT | --project-id PROJID}
```
- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Saving exports
The following syntax saves an export to a file.
```
cpdctl dsjob save-export {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} --export-file FILENAME 
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the export. 
- `id` is the id of the export. One of `name` or `id`
must be specified.
- `export-file` is the name of the file that the export is saved to.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Deleting exports
The following syntax deletes an export from the specified project:
```
cpdctl dsjob delete-export {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the export. 
- `id` is the id of the export. One of `name` or `id`
must be specified.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Exporting a DataStage flow 


The following syntax exports the DataStage components from a specified project to a file:

```
cpdctl dsjob export-project {--project PROJECT | --project-id PROJID} [--wait &lt;n>, --file-name &lt;PROJECTZIP>] [--include-data-assets]
```



- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `file-name` is the file for assets to be exported to. This field is used only
when `wait` is specified and export is completed within specified wait timeout.
- `wait` is the time in seconds to wait for completion of the export.
- `include-data-assets` includes the project's data assets as part of the
export.



A status code is printed to the output. 
- 0: successfully completed
- 1: completed with warnings
- 2: completed with error
- 3: failed
- 4: canceled
- 5: in deleting state
- -1: other




### Checking flow export status


The following syntax gets the status of an export operation in progress.

```
cpdctl dsjob get-export-project {--project PROJECT | --project-id PROJID} [--with-metadata]
```



- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `with-metadata` when specified adds metadata to the output.



A status code is printed to the output. A status code of 0 indicates successful completion of the
command.



### Saving export to a file


The following syntax saves the export from a specified project to a file:

```
cpdctl dsjob save-export-project {--project PROJECT | --project-id PROJID} --file-name FILENAME
```



- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `file-name` is the file to which the project export contents are written.



A status code is printed to the output. A status code of 0 indicates successful completion of the
command.



### Canceling an export


The following syntax stops the export operation on a specified
project:
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
cpdctl dsjob import-zip {--project PROJECT | --project-id PROJID} [--on-failure ONFAILURE] [--conflict-resolution CONFLICT-RESOLUTION] [--skip-on-replace LIST] [--file-name FILE-NAME] [--wait-sec]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `on-failure` indicates what action to take if the import fails. This field is
optional. The default option is continue, the other option is stop.
- `conflict-resolution` specifies the resolution when the data flow to be imported
has the same name as an existing data flow in the project or catalog. This field is optional. The
default option is skip, the others are rename and replace.
- `skip-on-replace` specifies a list of object types to skip. The following values
are valid for object types: `connection, data_intg_subflow, data_definition, parameter_set,
data_asset, ds_message_handler, data_intg_build_stage, data_intg_custom_stage,
data_intg_wrapped_stage, standardization_rule, ds_xml_schema_library, custom_stage_library,
function_library, ds_routine, ds_match_specification, data_intg_parallel_function,
data_intg_java_library, data_quality_rule, data_quality_definition`.
- `file-name` is the name of the .zip file that contains all the DataStage flows
and DataStage components to be imported. This field is mandatory.
- `wait-sec` waits for a specified time and prints the status of the import
periodically. A value of -1 indicates an indefinite wait until the command completes. 


A status code is printed to the output. 
- 0: successfully completed
- 1: completed with warnings
- 2: completed with error
- 3: failed
- 4: canceled
- -1: other



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
cpdctl dsjob export-zip {--project PROJECT | --project-id PROJID} {--name FLOW | --id ID} {--pipeline SEQFLOWNAME | --pipeline-id SEQFLOWID} [--file-name FILENAME] [--no-secrets] [--no-deps] [--include-data-assets]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the flow. 
- `id` is the id of the flow. One of `name` or `id`
must be specified.
- `pipeline` is the name of the flow. 
- `pipeline-id` is the id of the flow. One of `name` or
`id` must be specified.
- `no-deps` specifies that flow dependencies will not be exported. This field is
optional. The default option is false.
- `no-secrets` specifies that secrets will not be exported. This field is optional.
The default option is false.
- `file-name` specifies the name of the .zip file to which the flow is
exported.
- 

`include-data-assets` includes the project's data assets as part of the export.




A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Exporting DataStage components
The following syntax will export all DataStage components in a specified project to a .zip file:
```
cpdctl dsjob export-datastage-assets {--project PROJECT | --project-id PROJID} [--file-name &lt;FILENAME>] [--include-data-assets]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `file-name` specifies the name of the .zip file to which the assets are exported. 
- `include-data-assets` includes the project's data assets as part of the export.



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
cpdctl dsjob create-connection  {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] [--datasource-type TYPE] [--country COUNTRY] [--property-file FILENAME]
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
cpdctl dsjob update-connection {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--property name=value]... [--file-name PROPERTYFILE] [--make-personal]
```


- `project` is the name of the project that contains the connection. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the connection. 
- `id` is the id of the connection. One of `name` or
`id` must be specified.
- `property` specifies a specific property to be updated. The value is in the
format `name=value`, where `name` is the name of the connection
property and `value` is the value to be set. This flag can be repeated, ex:
`--property k1=v1 --property k2=v2`
- `file-name` specifies a file that contains the property values to pass to update
the connection.
- `make-personal` changes the connection settings from shared to personal.


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


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


## Hardware specifications

### Listing hardware specifications
The following syntax displays a list of all hardware specifications in the specified project: 
```
cpdctl dsjob list-hardware-specs {--project PROJECT | --project-id PROJID} [--full FULL] [--all] [--sort|--sort-by-time] [--with-id]
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
cpdctl dsjob create-hardware-spec {--project PROJECT | --project-id PROJID} [[--name NAME] [--description DESCRIPTION] [--body BODY-JSON]] [--file-name FILENAME]
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
cpdctl dsjob get-hardware-spec {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--file-name FILENAME] [--with-metadata]
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
pdctl dsjob create-env {--project PROJECT | --project-id PROJID} [--name NAME] [--display-name DISPLAY-NAME] [--type TYPE] [--location LOCATION] [--hwspec HWSPEC-NAME]] [--file-name FILENAME]
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
cpdctl dsjob get-env {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--file-name FILENAME] [--with-metadata]
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
cpdctl dsjob create-subflow {--project PROJECT | --project-id PROJID} --name NAME [--pipeline-file FILENAME]
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


## Parameter sets

### Listing parameter sets
The following syntax displays a list of all parameter sets in the specified project: 
```
cpdctl dsjob list-paramsets {--project PROJECT | --project-id PROJID} [--sort|--sort-by-time] [--with-id]
```


- `project` is the name of the project that contains the parameter sets to list. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the parameter sets in the project is
displayed, one per line.
- `sort` when specified returns the list of parameter sets sorted in alphabetical
order. This field is optional.
- `sort-by-time` when specified sorts the list by create or update time. One of
`sort` or `sort-by-time` can be specified.
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
cpdctl dsjob create-tabledef {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] [--file-name FILENAME] [--column type:name:columnattribute...]
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
cpdctl dsjob get-library {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--output json|file] [--file-name FILENAME] [--with-metadata]
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


### Uploading an XML library file
The following syntax uploads a .zip file to an existing DataStage XML schema library by name in
a specified project: 
```
cpdctl dsjob upload-library-file {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} --file-name FILENAME
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the XML library. 
- `id` is the id of the XML library. One of `name` or
`id` must be specified.
- `file-name` is the name of the .zip file that contains the schema definitions.
This field is mandatory.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Downloading an XML library file
The following syntax downloads a .zip file of an existing DataStage XML schema library by name
in a specified project: 
```
cpdctl dsjob download-library-file {--project PROJECT | --project-id PROJID} {--name NAME | --id ID}  --file-name FILENAME
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the XML library. 
- `id` is the id of the XML library. One of `name` or
`id` must be specified.
- `file-name` is the name of the output file that the XML library's schema
definitions are written in. This field is mandatory.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Deleting an XML library file
The following syntax deletes a set of files from an existing DataStage XML schema library by
name in a specified project: 
```
cpdctl dsjob delete-library-file {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} --file-name FILENAME
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the XML library. 
- `id` is the id of the XML library. One of `name` or
`id` must be specified.
- `file-name` is the names of the files to be deleted from the XML library. This
field is mandatory.


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


## Environment variables

### Listing environment variables
The following syntax lists all environment variables defined in a specified project environment:
```
cpdctl dsjob list-env-vars {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--type TYPE]
```
- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the environment.
- `id` is the id of the environment. One of `name` or
`id` must be specified. 
- `type` is the type of the environment. 

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

### Get data set schema definition
The following syntax provides a description of the data set schema definition in a given
project.
```
cpdctl dsjob describe-dataset {--project PROJECT | --project-id PROJID} --pxname NAME --name &lt;DATASET>
```
```
 cpdctl dsjob describe-fileset {--project PROJECT | --project-id PROJID} --pxname NAME --name &lt;FILESET>
```
- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `pxname` is the name of the runtime to which this data set or file set
belongs.
- `name` is the name of the data set or file set.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### View data set metadata
The following syntax provides the metadata of a data set in the given
project.
```
cpdctl dsjob view-dataset {--project PROJECT | --project-id PROJID} --pxname NAME --name &lt;DATASET> 
```
```
cpdctl dsjob view-fileset {--project PROJECT | --project-id PROJID} --pxname NAME --name &lt;FILESET>
```
- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `pxname` is the name of the runtime to which this data set or file set
belongs.
- `name` is the name of the data set or file set.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### View data set data
The following syntax gets the data of a data set in the given
project.
```
cpdctl dsjob get-dataset {--project PROJECT | --project-id PROJID} --pxname NAME --name &lt;DATASET> 
```
```
cpdctl dsjob get-fileset {--project PROJECT | --project-id PROJID} --pxname NAME --name &lt;FILESET>
```
- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `pxname` is the name of the runtime to which this data set or file set
belongs.
- `name` is the name of the data set or file set.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Listing data sets and file sets
The following syntax lists all data sets or file sets in a given
project.
```
cpdctl dsjob list-datasets {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time | --sort-by-size] --all 
```
```
cpdctl dsjob list-filesets {--project PROJECT | --project-id PROJID} [--sort | --sort-by-time | --sort-by-size] [--all]
```
- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `sort` when specified returns the list of data sets or file sets sorted in
alphabetical order. This field is optional.
- `sort-by-time` when specified returns the list of data sets or file sets sorted
in chronological order. This field is optional.
- `sort-by-time` when specified returns the list of data sets or file sets sorted
by size. This field is optional. Only one of `sort`, `sort-by-time` or
`sort-by-size` can be specified.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Deleting data sets and file sets
The following syntax deletes a data set or file
set.
```
cpdctl dsjob delete-dataset {--project PROJECT | --project-id PROJID} --pxname NAME --name &lt;DATASET|FILESET>
```
- `project` is the name of the project. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `pxname` is the name of the runtime to which this data set or file set
belongs.
- `name` is the name of the data set or file set.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


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
cpdctl dsjob remove-remote-engine [--name name | --id ID]
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
cpdctl dsjob create-build-stage {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] [--file-name ENTITYFILE]
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
cpdctl dsjob create-custom-stage {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] [--file-name ENTITYFILE]
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
cpdctl dsjob create-wrapped-stage {--project PROJECT | --project-id PROJID} --name NAME [--description DESCRIPTION] [--file-name ENTITYFILE]
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


### Getting attachments
The following syntax fetches an attachment by name from the specified project:
```
cpdctl dsjob get-attachment {--project PROJECT | --project-id PROJID} {--asset-name NAME | --asset-id ID}  {--name NAME | --id ID} [--file-name FILENAME]
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


### Importing match specifications
The following syntax imports a match specification into a specified project: 
```
cpdctl dsjob import-match-spec {--project PROJECT | --project-id PROJID} [--file-name FILENAME]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `file-name` is the name of the file that contains the match specification. 


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Exporting match specifications
The following syntax exports a match specification from a specified project to a file: 
```
cpdctl dsjob export-match-spec {--project PROJECT | --project-id PROJID} {--name NAME | --id ID} [--file-name FILENAME]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the match specification. 
- `id` is the id of the match specification. One of `name` or
`id` must be specified.
- `file-name` specifies the name of the .zip file to which the match specification
is written. If not specified, the name or id of the match specification is the name of the file.



A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


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


## Standardization rules

### Listing standardization rules
The following syntax displays a list of all standardization rules in the specified project:
```
cpdctl dsjob list-rules {--project PROJECT | --project-id PROJID} [--sort]
```
- `project` is the name of the project that contains the standardization rules to
list.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified. A list of all the standardization rules in the
project is displayed, one per line.
- `sort` when specified returns the list of standardization rules sorted in
alphabetical order. This field is optional. 

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
cpdctl dsjob get-rule {--project PROJECT | --project-id PROJID} [--name NAME] [--location LOCATION] [--output json|file] [--file-name FILENAME]
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
cpdctl dsjob delete-rule {--project PROJECT | --project-id PROJID} [--name NAME] [--location LOCATION} 
```
- `project` is the name of the project that contains the standardization rule. 
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the standardization rule that is being deleted.
- `location` is the location of the rule.

A status code is printed to the output. A status code of 0 indicates successful completion
of the command.


### Importing standardization rules
The following syntax imports a standardization rule into a specified project: 
```
cpdctl dsjob import-rule {--project PROJECT | --project-id PROJID} [--name NAME] [--location LOCATION] [--file-name FILENAME]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the standardization rule. 
- `location` is the location of the rule.
- `file-name` is the name of the file that contains the rule information. 


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Exporting standardization rules
The following syntax exports a standardization rule from a specified project to a file: 
```
cpdctl dsjob export-rule {--project PROJECT | --project-id PROJID} [--name NAME] [--location LOCATION] [--file-name FILENAME]
```


- `project` is the name of the project.
- `project-id` is the id of the project. One of `project` or
`project-id` must be specified.
- `name` is the name of the standardization rule. 
- `location` is the location of the rule.
- `file-name` specifies the name of the file to which the rule is exported in .zip
format. 


A status code is printed to the output. A status code of 0 indicates successful completion of
the command.


### Copying standardization rules
The following syntax copies a standardization rule.
```
cpdctl dsjob copy-rule {--project PROJECT | --project-id PROJID} [--name NAME] [--location LOCATION] [--dest NAME] [--dest-location LOCATION]
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


## User volumes

<dt/>
<dd/>


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
cpdctl dsjob list-volume-files --name [--path]
```
- `name` is the name of the volume.
- `path` is a path on the volume. This field is optional. 



A status code is printed to the output. A status code of 0 indicates successful completion of the
command.



### Uploading files to a user volume
The following syntax uploads files to a
volume:
```
cpdctl dsjob upload-volume-files --name --path --file-name [--extract]
```
- `name` is the name of the volume.
- `path` is a path on the volume. This field is optional. 
- `file-name` is the name of the file to upload.
- `extract` specifies that `file-name` is a .zip file that needs to
be extracted.



A status code is printed to the output. A status code of 0 indicates successful completion of the
command.



### Downloading files from a user volume
The following syntax downloads files from a
volume:
```
cpdctl dsjob download-volume-files [name] [path] [--file-name &lt;FILETODOWNLOAD>] [--output-file &lt;OUTPUTFILE>]
```
- `name` is the name of the volume.
- `path` is a path on the volume. This field is optional. 
- `file-name` is the name of the file to download.
- `output-file` is the name of the file that the output is written to.



A status code is printed to the output. A status code of 0 indicates successful completion of the
command.







