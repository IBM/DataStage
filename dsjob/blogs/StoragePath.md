# Working with migrate command using 'storage-path' option

We are using a directory under `/ds-storage` in the examples below. 

First you need to create the storage volume connection under the project: 

Create a new connection asset of type `storage volume` adding new volume as `ds::ds-storage` and clicking check box `Use my platform login credentials`

We can pass `storage-path` value two ways in the command as below.
 
## 1. Passing the hardcoded storage path

Run the cpdctl dsjob command as follows:
```
% cpdctl dsjob migrate --project indrani_storage_path  --storage-path /mnts/ds-storage/mystorage  --file-name routineTest1.isx
...

ID:       3ed629ff-fc6f-4798-bd02-f597b2a6b457
Created   2023-12-14T00:20:13.906Z
Summary
{
    "build_stages_total": 0,
    "connection_creation_failed": 0,
    "connections_total": 0,
    "custom_stages_total": 0,
    "data_quality_spec_total": 0,
    "deprecated": 0,
    "failed": 0,
    "flow_compilation_failed": 0,
    "flow_creation_failed": 0,
    "function_libraries_total": 0,
    "imported": 0,
    "java_libraries_total": 0,
    "job_creation_failed": 0,
    "message_handlers_total": 0,
    "parallel_jobs_total": 0,
    "parameter_sets_total": 0,
    "pending": 0,
    "renamed": 0,
    "replaced": 0,
    "routines_total": 0,
    "sequence_job_creation_failed": 0,
    "sequence_jobs_total": 0,
    "skipped": 0,
    "subflows_total": 0,
    "table_definitions_total": 0,
    "total": 0,
    "unsupported": 0,
    "wrapped_stages_total": 0,
    "xml_schema_libraries_total": 0
}

Status code = 0
```

## 2. Passing environment variable for the storage path

1. Run the cpdctl dsjob command as follows:
```
% cpdctl dsjob migrate --project indrani_storage_path  --storage-path "\$ROUTINE_DIR"  --file-name routineTest1.isx
...

ID:       24b67df8-f441-4564-8942-b2f9cb2d5d3c
Created   2023-12-14T00:23:25.981Z
Summary
{
    "build_stages_total": 0,
    "connection_creation_failed": 0,
    "connections_total": 0,
    "custom_stages_total": 0,
    "data_quality_spec_total": 0,
    "deprecated": 0,
    "failed": 0,
    "flow_compilation_failed": 0,
    "flow_creation_failed": 0,
    "function_libraries_total": 0,
    "imported": 0,
    "java_libraries_total": 0,
    "job_creation_failed": 0,
    "message_handlers_total": 0,
    "parallel_jobs_total": 0,
    "parameter_sets_total": 0,
    "pending": 0,
    "renamed": 0,
    "replaced": 0,
    "routines_total": 0,
    "sequence_job_creation_failed": 0,
    "sequence_jobs_total": 0,
    "skipped": 0,
    "subflows_total": 0,
    "table_definitions_total": 0,
    "total": 0,
    "unsupported": 0,
    "wrapped_stages_total": 0,
    "xml_schema_libraries_total": 0
}

Status code = 0
```

2. The routine activity script will get created as below:

```
# The original, untranslated routine source code (written in IBM InfoSphere DataStage BASIC language)
# and migration service generated dummy script is saved to the following invoked script file.

echo "CreateLockFile" > $command_name_PATH

echo ${CreateLockFile_InputArg} > $InputArg_PATH

sh $ROUTINE_DIR/projects/indrani_storage_path/scripts/DSU.CreateLockFile.sh 
```
 
3. You need to create an environment variable for the routine activity:
```
Environment variable: ROUTINE_DIR
value : /mnts/ds-storage/mystorage
```



Note: You can view the StoragePath.mov
