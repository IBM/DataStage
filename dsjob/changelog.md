


# DataStage command-line change log
The following updates and changes apply to the `dsjob` command-line
interface.

[4.7.0](#470)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.7.0.md)

[4.6.6](#466)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.6.6.md)

[4.6.4](#464)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.6.4.md)

[4.6.2](#462)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.6.2.md)


## 4.7.0

### New commands

`list-message-handlers` List all Message Handlers.

`get-message-handler` Get a Message Handler.

`create-message-handler` Create a Message Handler.

`delete-message-handler` Delete a Message Handler.

`list-job-status` List Jobs with their run status.

`export-paramset` Export Parameter Set(s).

`list-usage` List dependencies between DataStage components.

`update-function-lib` Update User Defined Function.

`export-function-lib` Export User Defined Function(s).

### Command changes
The following function library commands are renamed, adding `-lib`.

`list-function-libs` List function libraries.

`get-function-lib` Get function libraries.

`create-function-lib` Create function libraries.

`delete-function-lib` Delete function libraries.

`migrate` and `import-zip` commands now take a new parameter `hard-replace`. This allows for reconciliation when importing parameter sets that conflict with existing parameter sets.

`list-job-runs` now can sort using `sort-by-runid` to sort job runs using their `run-name` or `invocation-id`.

`list-job`s modified to allow users to `sort-by-time` to list jobs chronologically based on job update timestamp. Also `list jobs` takes a new flag `sched-info` to print schedule information if the job has scheduled runs.

### Fixes

All the list commands that have `sort-by-time` option will now use `updatedAt` timestamp of the object to sort the list.

Following commands will now produce a nonzero exit command upon failure, that can be checked on parent shell using $?
`compile`, `run`, `log detail`, `import`, `export`, `import-zip`, `export-project` and all delete commands.

Fixed `create-function-lib` command to take additional arguments to configure return types and aliases.

Changed output format to table format for `jobrunstat` and `list-jobruns`.

## 4.6.6

### New commands
`validate-connection` Validate connections.

`validate-flow` Validate flow references.

`validate-subflow`  Validate subflow references.

`validate-job`  Validate job references.

`validate-pipeline` Validate pipelines.

`waitforjob`  Wait for Job.

`list-dependencies` List dependencies between DataStage components.

`create-dsparams` Create DSParams as environment variables.

### Commmand changes
`update-connection` allows user to rename a connection using the new flag `to-name`.

### Fixes
Fixed `logdetail`, `logsum` and `lognewest` to use raw logs to parse logs to generate output. 

Allow `export` command to export assets specified, fix validates export types specified at command line correctly to the name of the asset.

## 4.6.4

### New commands
`create-pipeline-job` with `schedule` options is added to help scheduled runs for pipelines

`validate-pipeline` is added to validate flows or pipelines referenced in a pipeline

### Command changes

`migrate` adds `--create-connection-paramsets` option to create parameter sets for missing properties in connections

`migrate` when used with `--wait` option prints consolidated Errors, Warnings and Unsupported sections that are alphabetically sorted.

`jobrunclean` command now cleans up job runs from a specific job or across projects or spaces. It also takes `--before TIMESTAMP` to cleanup based on timestamp.

DataSet operations now take advantage of new asset api. Currently following operations are supported and their command options are changed to make use of new api.
```
 list-datasets               List DataSets.
 get-dataset                 Get DataSet data.
 delete-dataset              Delete a Dataset.
 describe-dataset            Describe the DataSet.
 view-dataset                View DataSet.
 list-filesets               List FileSets.
 get-fileset                 Get FileSet data.
 delete-fileset              Delete a FileSet.
 describe-fileset            Describe the FileSet
 view-fileset                View FileSet.
```

`dsjob version`
This command now prints component versions in alphabetic order. Added canvas and pipeline to the list.

`compile` command now allows user to specify regular expression to compile multiple flows.
`compile` flag  `--enable-elt-mode` is used to compile dbt model to perform ELT operations.

Retry logic is tuned to handle http errors and properly exit if backend cannot progress. Commands that are affected are `migrate`, `export-project`, `import-zip` with wait options and also `export-datastage-assets`.

### Fixes

Fixed `update-paramset` to keep the prompt field unaffected by the update operation.

Fixed issue with `import-quality-rule` to take the definitions id and optionally name to appropriately allow rule to be added to the target project.

Fixed `run-pipeline` to accept parameter sets, previously `--paramset` are ignored when there are no job parameters specified using `--param`.


## 4.6.2


### New job commands


- `cleanup-jobs`


### New Java Library commands

- `list-java-libraries`
- `get-java-library`
- `create-java-library`
- `delete-java-library`


### New User-defined function commands


- `list-functions`
- `get-function`
- `create-function`
- `delete-function `


### New Data Quality Rule and Data Quality Definition commands


- `list-quality-rules`

- `get-quality-rule`

- `import-quality-rule `

- `export-quality-rule `

- `delete-quality-rule`

- `list-quality-definitions`

- `get-quality-definition`

- `import-quality-definition`

- `export-quality-definition`

- `delete-quality-definition`






### Fixed issues
Fixed issue with pagination while fetching job runs. The following commands are affected.
- `list-jobruns`
- `jobrunstat `
- `jobrunclean `
- `prune`





### Command changes


- `run` command takes new flag `--warn-limit` to specify number of warning allowed in a run. 
- `import-zip` now prints sorted list of objects that failed to import, also added errors sections to print errors for each failed object import. 
- `export-zip` takes additional flag `--include-data-assets` to export data assets into the export.
- `export-project` takes additional flag `--include-data-assets` to export data assets into the export. 
- Added an `export-datastage-assets` command that uses `export-project` and then adds missing DataStage components into the export. This
command also supports flag `--include-data-assets` to export data assets.






### Shorthand flag changes
The shorthand flags for string `name` and `ID` of a parameter set
have changed from `-s` to `-t` for `name `and
`-S` to `-T` for `ID`. This affects the following commands:
`list-paramset-valuesets,get-paramset-valueset,create-paramset-valueset,delete-paramset-valueset,update-paramset-valueset`.

The shorthand flags for stringArray `name` and `ID` of a pipeline
have changed from `-s` to `-l` for `name `and
`-S` to `-L` for `ID`. This affects the command
`export-zip`.

The `migrate` command no longer supports the short flag `-s` as a
replacement for `--stop`.

The `compile` command now takes multiple flows/flow-ids to compile, listed as
`--name Flow1 --name Flow2...`.
