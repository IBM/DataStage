


# DataStage command-line change log
The following updates and changes apply to the `dsjob` command-line
interface.

[4.8.1](#481)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.8.1.md)

[4.8.0](#480)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.8.0.md)

[4.7.4](#474)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.7.4.md)

[4.7.3](#473)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.7.3.md)

[4.7.2](#472)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.7.2.md)

[4.7.1](#471)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.7.1.md)

[4.7.0](#470)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.7.0.md)

[4.6.6](#466)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.6.6.md)

[4.6.4](#464)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.6.4.md)

[4.6.2](#462)
[Documentation](https://github.com/IBM/DataStage/tree/main/dsjob/dsjob.4.6.2.md)

## 4.8.1

### New commands

The following commands are added to enable job run analysis.

-   `list-links`  List all links to or from a stage in a DataStage job.
    
-   `list-stages`  List all stages in a DataStage job.
    
-   `get-stage-link`  Display information for a link to or from a stage in a datastage job.
    
-  `get-jobrun-report` Display job run report for a datastage job.

The following commands are added to allow fileset cleanup.

-  `truncate-fileset` Truncate File Set data from a given project by name.

### Command changes

The following commands have changed:

`run-pipeline`: 
- enhanced to take `run-name`.
- added ability to process PROJDEF parameter references.
- flag short-name for `reset-cache` changed from `-R` to `-C`

`list-jobruns`: fixed incorrect flag name from `sort-by-runid` to `sort-by-runname`.

`list-paramsets`  supports json formatted output.


## 4.8.0

### New commands

The following commands are added to manage assets in folders.

  - `list-folders`                List all folders.
  
  - `list-folder`                 List folder contents.
  
  - `create-folder`               Create a folder.
  
  - `delete-folder`               Delete a folder.
  
  - `update-folder`               Update folder name.
  
  - `move-folder`                 Move a folder.
  
  - `move-asset`                  Move asset to a folder.

The following commands are added to work with Cobol File Formats.

  - `list-cff-schemas`            List CFF Schemas.
  
  - `get-cff-schema`              Get CFF Schema.
  
  - `create-cff-schema`           Create CFF Schema.
  
  - `delete-cff-schema`           Delete CFF Schema.
  
  - `export-cff-schema`           Export CFF Schema(s).
  
The following commands are added to synchronize projects artifacts with git.

  - `git-commit`                  Git commit a Project.
  
  - `git-pull`                    Git pull a Project.
  
  - `git-status`                  Get git status of a Project.
  
  Other:
  
 - `dataset-truncate` allows truncation of data in a DataSet. 
 
 - `encrypt` allows cluster-specific encryption of text. 
 

### Command changes

The following commands have changed:

`list-active-runs`: enhanced to display run-name and duration. Users can sort on these fields.

`list-usage`: 
- asset name can be prefixed with type to avoid conflicts.
- supports data rules and data definitions.

`list-dependencies` supports data rules and data definitions.

`migrate` command added new options:
- `enable-notifications`         Enable Notifications for Migration.
- `storage-path`                      Folder path of the storage volume for routine scripts and other data assets.
- `migrate-to-send-email`         Will migrate all notification activity stages in sequence job to send email task nodes.
- `migrate_hive_impala`           Enable hive impala for migration.

`import-zip`: 
  - now import flows with or without compilations.
  - import only listed DataStage components.
  - takes a key to decrypt sensitive data, this must match the key used during export.

`export-datastage-assets`: now can exclude data files from datasets and filesets to be part of export.

`export-zip`, `export-project` will allow 'testcase' DataStage components to be specified to export.

`export-zip`, `export-project` and `export-datastage-assets` commands take an encryption key to encrypt any sensitive data before writing to the zip output file.

`list-job-status`: 
- enhanced to show all job runs and in a specified time window.
- migrate command enhanced to enable notifications,
- migrate databases connections using dsn type, 
- enables hive impala migration and enables migration of notification activities as send email nodes.
- sort by duration is added.

`run-pipeline` now allows reset-cache options to clear cache before the run.

`compile` enhanced to support pushdown materialization  policy.

`run` can now use runtime environment  and runtime language settings for each job run.

`update-ds-settings` is enhanced to set collate option on the project.

`describe-dataset` enhanced to write to a file with additional infomation on dataset size, location and last access time.
`describe-fileset` enhanced to write to a file with additional infomation on fileset size, location and last access time.

All export-<Component> commands now use unix globbing pattern with wild cards instead of regular expressions.

`create-dsparams`  changed to export user environment definitions from DSParams file from legacy into PROJDEF parameter file. It will no longer use runtime environment to export and store DSParams.

`jobrunclean` enhanced to accept timestamp to clean up jobs that started before a specific time.

`create-paramset`, `update-paramset` now validates references to PROFDEF in parameter definitions. 
`create-paramset`, `update-paramset` now support `encrypted` data type.

`upload-volume-files` enhanced to accept destination file different from the source file.



### Fixes

`export-project`, `export-datastage-assets` commands adjusted internally to accommodate for rate-limiting issues for exporting large projects on ibm-cloud.

`run` command now implements multiple retry loops to accommodate any intermittent errors and ensure completion of job runs in a high number of conncurrent runs.

`jobrunstat` fixed to handle data type changes that was causing marshaling exception. 
 
## 4.7.4

### Command changes

All `export-` commands will now use a globbing pattern to export multiple files. This includes: `export-quality-definition`,`export-quality-rule`,`export-asset`,`export-build-stage`,`export-connection`,`export-cff-schema`,`export-custom-stage`,`export-dataset`,`export-fileset`,`export-function-lib`,`export-java-library`,`export-library`,`export-match-spec`,`export-paramset`,`export-rule`,`export-subflow`,`export-tabledef`,`export-wrapped-stage`.

ex: `cpdclt dsjob export-subflow --project >PROJECTNAME> --name ab*` will export all sub flows that start with name `ab`.

`upload-volume-files`: Enhanced upload-volume-files to allow user to specify a destination file name.

`create-paramset` and `update-paramset`: added logic to verify Parameter Set fields that reference PROJDEF are valid such that PROJDEF exists and the reference exists, if not a warning message is displayed.

### Fixes

`update-env-vars`: fixed issue with update-env-vars to avoid overwriting the existing environment variables

`download-volume-files`: fixed issue to report proper error when it fails to write the downloaded file to local disk.



## 4.7.3

### Command changes

`migrate` now takes a new flag to migrate optimized connectors: `use-dsn-name`.

`compile` now takes a new flag `materialization-policy` when ELT compile is enabled with the flag `--enable-elt-mode`. This flag determines the generated output and takes the following values: OUTPUT_ONLY, TEMP_TABLES, TEMP_VIEWS, CARDINARLITY_CHANGER_TABLES. The output of the command now displays total time in the summary line.

`delete-dataset` and `delete-fileset` now have an option to delete multiple objects. A `--dry-run` option is now available to show the details of the objects that would be deleted.  

### Fixes

`list-jobruns` exits gracefully when the incorrect job run id is specified. 

`validate-flow` no longer crashes when a single flow name needs validating due to incorrect initialization of cache entries. 

## 4.7.2

### Command changes

`delete-dataset` and `delete-fileset` can now take unix-like globbing pattern to delete multiple datasets.
`delete-dataset` and `delete-fileset` can now take the `--dry-run` option to run the command without deletions.

## 4.7.1

### New commands
The following export commands are added to allow export of individual assets into a .zip file. The output .zip file is compatible with migration using the `import-zip` command.

`export-build-stage`          Export Build Stage(s).

`export-connection`            Export Connection(s).

`export-custom-stage`        Export Custom Stage(s).

`export-dataset`                  Export Data Sets(s).  

`export-fileset`                  Export File Sets(s).  

`export-java-library`        Export Java Library(s).

`export-library`                 Export XML Library(s).

`export-message-handler`  Export Message Handler(s).

`export-operational-dm`    Export Operational Decision Manager(s).

`export-subflow`                  Export Subflow(s).

`export-tabledef`                Export Table Definition(s).

`export-wrapped-stage`      Export Wrapped Stage(s).

`export-quality-definition`   Export Data Quality Definition.

`export-quality-rule`       Export Data Quality Rule.

`download-dataset`             Download a DataSet asset with dataset backend files.

`download-fileset`             Download a FileSet asset with dataset backend files.

`upload-dataset`                 Upload a DataSet asset with dataset backend files.

`upload-fileset`                 Upload a FileSet asset with dataset backend files.

### Command changes

The following commands have had semantic changes to make them compatible with other export commands. They now produce a .zip file that is compatible with the `import-zip` command.

`export-match-spec`            Export Match Specification(s).

`export-rule`                  Export Standardization Rule by name.

`update-job` now takes `--paramset` to update parameter set definitions for the job.

`list-env-vars` takes `--sort` to sort the list alphabetically.

`migrate` takes additional flag `--enable-platform-connection` to migrate optimized connectors. 

`run` has new default value for `--run-name`: "Job Run" instead of "job_run". Changed for UI compatibility. 

### Fixes

DSJob plugin commands are now organized alphabetically for easier browsing. 

`list-dependencies` and `list-usage` are enhanced to show relationships to DataStage components such as Data sets, File sets, Operational Decision Managers, Schema libraries, Standardization rules and Match specifications.

`run` and `run-pipeline` are enhanced to handle parameter sets natively in the job definitions. Also, these commands now have retry logic to wait and run jobs again if any temporary issues occur with job service. The retry waits up to 10 minutes if a job run fails and attempts to run the job periodically until it succeeds.

`migrate` command ignores `--create-connection-paramsets` when `--enable-local-connection` is set.

`get-paramset`  prints out a detailed parameter set definition by default using table format.

## 4.7.0

### New commands

- `list-message-handlers` List all Message Handlers.

-`get-message-handler` Get a Message Handler.

-`create-message-handler` Create a Message Handler.

-`delete-message-handler` Delete a Message Handler.

-`list-job-status` List Jobs with their run status.

-`export-paramset` Export Parameter Set(s).

-`list-usage` List dependencies between DataStage components.

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
