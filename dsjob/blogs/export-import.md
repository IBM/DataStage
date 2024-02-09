## Project Level Export

#### Export Project with all assets including DataStage
```
cpdctl dsjob export --project dsjob --name test-export 
--export-file demo-project-export.zip --wait 200
```

#### Find if export has completed
```
$    cpdctl dsjob list-exports --project dsjob
...
Name       |Export ID                           |State    |Created At              |Updated At
---------- |----------                          |-------- |-----------             |-----------
test-export|3cce517b-8073-437f-bef3-095c39cf3b80|completed|2023-04-18T05:57:21.752Z|2023-04-18T05:57:31.528Z
test-export|2889506e-1c6f-4b76-9f5e-cd51fed51252|completed|2023-04-19T04:49:42.458Z|2023-04-19T04:49:55.568Z
test-export|e6b386f7-0920-44f2-9288-7bececd61954|completed|2023-04-26T00:11:09.503Z|2023-04-26T00:11:25.154Z
```

#### Save the export to a zip file
```
$ cpdctl dsjob save-export --project dsjob --name test-export 
--export-file abc.zip
```

#### Cleanup the export
```
cpdctl dsjob delete-export --name test-export
```

#### Import the project into a New Project
```
cpdctl dsjob import --project DSJOB-PROJECT-EXPORT 
--import-file demo-project-export.zip --wait 200
```


---
---
## Export DataStage Assets
Three ways we can import DataStage assets
export-zip 
export-project
export-datastage-assets

#### export-zip : Export individual assets
export-zip can be used to export individual flows or pipelines and also their dependencies by default.
```
cpdctl dsjob export-zip --project dsjob --name Test-DataStage-Flow --file-name test-export-project.zip
or
cpdctl dsjob export-zip --project dsjob --pipeline=testloop2 --file-name test-export-project.zip
```

You can export a flow or pipeline without dependencies if you chose to now not to export connection or parameter sets that the flow or pipeline depends on using a `--no-dep` option
Also important to note that `--no-secrets` lets you skip exporting secrets such as passwords.
```
cpdctl dsjob export-zip --project dsjob --name Test-DataStage-Flow --file-name test-export-project.zip --no-deps --no-secrets
```

If you have developed multiple flows and pipelines and want to export them all into a zip file, please use the following options to do so and export the flows and pipelines with their depedencies

```
cpdctl dsjob export-zip --project dsjob --name={fsTarget,dsTarget}  --pipeline={testloop2,testPipe} --file-name test-export-project.zip
or 
cpdctl dsjob export-zip --project dsjob --name fsTarget --name dsTarget --pipeline testloop2 --pipeline testPipe --file-name test-export-project.zip
```

#### export-zip : Export individual assets include pipelines and flow.


#### export-project : Export the DataStage flows and pipelines in a project with dependencies
```
cpdctl dsjob export-project --project DSJob_Test 
--file-name DSJob_Test-project.zip --wait 200
```
If wait not used...
get-export-project : Check Status if the export
```
$ cpdctl dsjob get-export-project --project dsjob
```
Once export is completed...
save-export-project: Save the exported project to local disk
```
cpdctl dsjob save-export-project --project dsjob --file-name 
test-export-project.zip
```
Stop the export if something is not right...
```
cpdctl dsjob stop-export-project --project dsjob
```

#### export-datastage-assets : Export all DataStage Assets
Export every DataStage asset in the project.
```
cpdctl dsjob export-datastage-assets --project DSJob_Test 
--file-name DSJob_Test.zip 
```

#### import-zip :  Import a DataStage artifact file
Control how you import 
```
cpdctl dsjob import-zip --project DSJob_Test 
--file-name test-dependencies2.zip 
--conflict-resolution replace 
--skip-on-replace connection --wait 200 
```
If wait not used...
get-import-zip : Check Status if the import
```
cpdctl dsjob get-import-zip --project DSJob_Test
--import-id f95e4ba8-d64d-4c5c-aa14-b0a3671fccb9
``` 

