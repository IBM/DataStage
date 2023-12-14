# Working with import-zip using option 'skip-on-replace' 

The 'skip-on-replace' option allows us to skip importing objects that is specified depending on the state of the object. For example, if you are re-importing a zip file with this option, you can skip importing a paramset if it's going to be the same. The 'skip-on-replace' option works on different Datastage asset types like parameter sets, connections, flows etc. The 'skip-on-replace' needs to be used along with conflict-resolution. If 'conflict-resolution' is not set to 'replace’, skip-on-replace is ignored. 

We will go over various use case scenarios here.

## 1. 'skip-on-replace' for parameter sets 
### Use case scenario 1: no change on parameter set
Let us consider that we have setup a flow and three parameter sets with import-zip command using paramset.zip file.
```
% cpdctl dsjob create-project -n DSJob_pset
% cpdctl dsjob import-zip --project DSJob_pset --conflict-resolution replace --file-name paramset.zip --wait 60
```
```
% cpdctl dsjob list-paramsets --project DSJob_pset --sort-by-time
...
ParamSet Name       |Updated At
-------------       |----------
peek_paramset       |2023-10-06T21:39:52Z
column_name_paramset|2023-10-06T21:39:51Z
description_paramset|2023-10-06T21:39:50Z

Total: 3 Parameter Sets

Status code = 0
```
We haven't modified the parameter sets. Let us import the same zip file with 'skip-on-replace' options.

```
% cpdctl dsjob import-zip --project DSJob_pset --conflict-resolution replace --skip-on-replace parameter_set --file-name paramset.zip --wait 60
...
2023-10-03 22:03:11: Waiting until import finishes, import id: b290f87c-c347-4f5f-a2c6-6240a170ecef
2023-10-03 22:03:33: Project import status: completed,  total: 4, completed: 4, failed: 0, skipped: 3.
Information:
	Parameter Set: column_name_paramset,	  New parameters are identical to those in the existing parameter set `column_name_paramset`, flow is updated to reference `column_name_paramset`.

	Parameter Set: description_paramset,	  New parameters are identical to those in the existing parameter set `description_paramset`, flow is updated to reference `description_paramset`.

	Parameter Set: peek_paramset,	  New parameters are identical to those in the existing parameter set `peek_paramset`, flow is updated to reference `peek_paramset`.


Status code =  1
```
Listing paramsets shows that they are not imported again as the update time didn't change.
```
 % cpdctl dsjob list-paramsets --project DSJob_pset --sort-by-time
...
ParamSet Name       |Updated At
-------------       |----------
peek_paramset       |2023-10-06T21:39:52Z
column_name_paramset|2023-10-06T21:39:51Z
description_paramset|2023-10-06T21:39:50Z

Total: 3 Parameter Sets

Status code = 0
```
### Use case scenario 2: update parameter set 
Let us follow these steps for this scenario:

**Step 1**. Before updating one parameter set 'peek_paramset', let us check the content of the parameter set and the time when it was created:
```
% cpdctl dsjob get-paramset --project DSJob_pset --name peek_paramset
...
ParamSet: peek_paramset(5b533421-2eae-448f-9a79-287bd47ad531) 
Name       |Type  |Default        |Prompt
----       |----  |-------        |------
description|string|Test peek stage|
row_count  |int64 |10             |

ValueSet: peek_valueset
Name       |Default
----       |-------
row_count  |50
description|Test peek stage

Status code = 0
```
```
% cpdctl dsjob list-paramsets --project DSJob_pset --sort-by-time
...
ParamSet Name       |Updated At
-------------       |----------
peek_paramset       |2023-10-06T21:39:52Z
column_name_paramset|2023-10-06T21:39:51Z
description_paramset|2023-10-06T21:39:50Z

Total: 3 Parameter Sets

Status code = 0
```

**Step 2**. Update the 'peek_paramset' and value sets in it by deleting value set and the parameters:
```
% cpdctl dsjob delete-paramset-valueset --project DSJob_pset --paramset peek_paramset  --name peek_valueset
...
ValueSet Deleted from Paramset ID:  5b533421-2eae-448f-9a79-287bd47ad531

Status code = 0
```
```
% cpdctl dsjob update-paramset --project DSJob_pset --name peek_paramset --delete-param description
...
ParameterSet updated for Paramset ID:  5b533421-2eae-448f-9a79-287bd47ad531

Status code = 0
```
```
% cpdctl dsjob update-paramset --project DSJob_pset --name peek_paramset --delete-param row_count
...
ParameterSet updated for Paramset ID:  5b533421-2eae-448f-9a79-287bd47ad531

Status code = 0
```

**Step 3**. After updating the parameter set 'peek_paramset', let us check the content of the parameter set and the update time:
```
% cpdctl dsjob get-paramset --project DSJob_pset --name peek_paramset
...
ParamSet: peek_paramset(5b533421-2eae-448f-9a79-287bd47ad531) 
Name|Type|Default|Prompt
----|----|-------|------

Status code = 0
```
```
% cpdctl dsjob list-paramsets --project DSJob_pset --sort-by-time
...
ParamSet Name       |Updated At
-------------       |----------
peek_paramset       |2023-10-07T03:51:51Z
column_name_paramset|2023-10-06T21:39:51Z
description_paramset|2023-10-06T21:39:50Z

Total: 3 Parameter Sets

Status code = 0
```

**Step 4**. After the update, let's import the same zip file with 'skip-on-replace' options.
```
% cpdctl dsjob import-zip --project DSJob_pset --conflict-resolution replace --skip-on-replace parameter_set --file-name paramset.zip --wait 60
...
2023-10-06 20:52:03: Waiting until import finishes, import id: 426bbcb9-dcf2-4050-9840-b14dacef8daa
2023-10-06 20:52:04: Project import status: started,  total: 4, completed: 3, failed: 0, skipped: 3.
2023-10-06 20:52:25: Project import status: completed,  total: 4, completed: 4, failed: 0, skipped: 3.
Information:
	Parameter Set: column_name_paramset,	  New parameters are identical to those in the existing parameter set `column_name_paramset`, flow is updated to reference `column_name_paramset`.

	Parameter Set: description_paramset,	  New parameters are identical to those in the existing parameter set `description_paramset`, flow is updated to reference `description_paramset`.

	Parameter Set: peek_paramset,	  New parameters are identical to those in the existing parameter set `peek_paramset`, flow is updated to reference `peek_paramset`.


Status code =  1
```

**Step 5**. After importing with 'skip-on-replace', let us check the content of the parameter set `peek_paramset` and the update time:
```
% cpdctl dsjob get-paramset --project DSJob_pset --name peek_paramset
...
ParamSet: peek_paramset(5b533421-2eae-448f-9a79-287bd47ad531) 
Name|Type|Default|Prompt
----|----|-------|------

Status code = 0
```
```
% cpdctl dsjob list-paramsets --project DSJob_pset --sort-by-time
...
ParamSet Name       |Updated At
-------------       |----------
peek_paramset       |2023-10-07T03:51:51Z
column_name_paramset|2023-10-06T21:39:51Z
description_paramset|2023-10-06T21:39:50Z

Total: 3 Parameter Sets

Status code = 0
```
Comparing the update time in step 3 and step 5, it is clear that the import with 'skip-on-replace' skipped the import.

### Use case scenario 3: rename a parameter set
Let us follow these steps:

**Step 1**: Rename the parameter set 'peek_paramset' 
```
% cpdctl dsjob update-paramset --project DSJob_pset --name peek_paramset --to-name peek_paramset_renamed
...
ParameterSet updated for Paramset ID:  5b533421-2eae-448f-9a79-287bd47ad531

Status code = 0
```
**Step 2**: Check the update time
```
% cpdctl dsjob list-paramsets --project DSJob_pset --sort-by-time
...
ParamSet Name        |Updated At
-------------        |----------
peek_paramset_renamed|2023-10-07T05:29:37Z
column_name_paramset |2023-10-06T21:39:51Z
description_paramset |2023-10-06T21:39:50Z

Total: 3 Parameter Sets

Status code = 0
```
**Step 3**: Do import-zip with --skip-on-replace
```
% cpdctl dsjob import-zip --project DSJob_pset --conflict-resolution replace --skip-on-replace parameter_set --file-name paramset.zip --wait 60
...
2023-10-06 22:29:45: Waiting until import finishes, import id: 14a4a8ab-aff2-408a-9a7c-f756ed5b3e97
2023-10-06 22:29:47: Project import status: started,  total: 4, completed: 3, failed: 0, skipped: 2.
2023-10-06 22:30:07: Project import status: completed,  total: 4, completed: 4, failed: 0, skipped: 2.
Information:
	Parameter Set: column_name_paramset,	  New parameters are identical to those in the existing parameter set `column_name_paramset`, flow is updated to reference `column_name_paramset`.

	Parameter Set: description_paramset,	  New parameters are identical to those in the existing parameter set `description_paramset`, flow is updated to reference `description_paramset`.


Status code =  1
```
**Step 4**: Check the parameter set content and update time
```
% cpdctl dsjob list-paramsets --project DSJob_pset --sort-by-time
...
ParamSet Name        |Updated At
-------------        |----------
peek_paramset        |2023-10-07T05:29:46Z
peek_paramset_renamed|2023-10-07T05:29:37Z
column_name_paramset |2023-10-06T21:39:51Z
description_paramset |2023-10-06T21:39:50Z

Total: 4 Parameter Sets

Status code = 0
```
```
% cpdctl dsjob get-paramset --project DSJob_pset --name peek_paramset
...
ParamSet: peek_paramset(b75df31b-8960-4d54-b8db-f1a414a9f5d2) 
Name       |Type  |Default        |Prompt
----       |----  |-------        |------
description|string|Test peek stage|
row_count  |int64 |10             |

ValueSet: peek_valueset
Name       |Default
----       |-------
row_count  |50
description|Test peek stage

Status code = 0

```
This scenario suggests that import with 'skip-on-replace' did not skip the parameter set 'peek_paramset' because it is renamed and hence it created the parameter set.

### Use case scenario 4: delete a parameter set
Let's follow these steps:

**Step 1**: Delete a paramset
```
% cpdctl dsjob delete-paramset --project DSJob_pset --name peek_paramset
...
Deleted Paramset:  peek_paramset

Status code =  0
```
**Step 2**: Check the parameter set update time
```
% cpdctl dsjob list-paramsets --project DSJob_pset --sort-by-time
...
ParamSet Name        |Updated At
-------------        |----------
peek_paramset_renamed|2023-10-07T05:29:37Z
column_name_paramset |2023-10-06T21:39:51Z
description_paramset |2023-10-06T21:39:50Z

Total: 3 Parameter Sets

Status code = 0
```
**Step 3**: Do import-zip with --skip-on-replace 
```
% cpdctl dsjob import-zip --project DSJob_pset --conflict-resolution replace --skip-on-replace parameter_set --file-name paramset.zip --wait 60
...
2023-10-06 22:52:55: Waiting until import finishes, import id: 73e4fb98-cb9b-4334-a2ff-838a1399cc51
2023-10-06 22:52:56: Project import status: started,  total: 4, completed: 3, failed: 0, skipped: 2.
2023-10-06 22:53:17: Project import status: completed,  total: 4, completed: 4, failed: 0, skipped: 2.
Information:
	Parameter Set: column_name_paramset,	  New parameters are identical to those in the existing parameter set `column_name_paramset`, flow is updated to reference `column_name_paramset`.

	Parameter Set: description_paramset,	  New parameters are identical to those in the existing parameter set `description_paramset`, flow is updated to reference `description_paramset`.


Status code =  1
```
Step 4: Check the parameter set update time and it's content
```
% cpdctl dsjob list-paramsets --project DSJob_pset --sort-by-time
...
ParamSet Name        |Updated At
-------------        |----------
peek_paramset        |2023-10-07T05:52:56Z
peek_paramset_renamed|2023-10-07T05:29:37Z
column_name_paramset |2023-10-06T21:39:51Z
description_paramset |2023-10-06T21:39:50Z

Total: 4 Parameter Sets

Status code = 0
```
```
% cpdctl dsjob get-paramset --project DSJob_pset --name peek_paramset
...
ParamSet: peek_paramset(59467898-8ad4-4067-8954-2f3d657a4acd) 
Name       |Type  |Default        |Prompt
----       |----  |-------        |------
description|string|Test peek stage|
row_count  |int64 |10             |

ValueSet: peek_valueset
Name       |Default
----       |-------
row_count  |50
description|Test peek stage


Status code = 0
```
In this scenario import with 'skip-on-replace' did not skip the parameter set 'peek_paramset' because it was deleted, hence created the parameter set.

This indicates that 'skip-on-replace' skips on objects already exists in the target environment.

## 2. 'skip-on-replace' for connection
We will go over various use case scenarios here.

### Use case scenario 1: no update on connection
Let us consider that we have setup a flow and a connection with import-zip command using conn.zip file.
```
% cpdctl dsjob create-project -n DSJob_conn
% cpdctl dsjob import-zip --project DSJob_conn --conflict-resolution replace --file-name conn.zip --wait 60
```

Follow these steps below to proceed:

**Step 1**: Check the connection update time.
```
% cpdctl dsjob list-connections --project DSJob_conn --sort-by-time
...
Connection Name|Updated At
---------------|----------
postgres_con   |2023-10-07T06:48:21.967Z

Total: 1 Connections

Status code = 0
```

**Step 2**: Do not update the connection. Run import-zip with 'skip-on-replace'.
```
% cpdctl dsjob import-zip --project DSJob_conn --conflict-resolution replace --skip-on-replace connection --file-name conn.zip --wait 60
...
2023-10-06 23:55:28: Waiting until import finishes, import id: fe905630-f45e-4456-8a9e-a8390908313b
2023-10-06 23:55:30: Project import status: started,  total: 2, completed: 1, failed: 0, skipped: 1.
2023-10-06 23:56:19: Project import status: completed,  total: 2, completed: 2, failed: 0, skipped: 1.
Information:
	Connection: postgres_con,	  New connection is exactly the same as an existing connection, resource is not updated.


Status code =  1
```

**Step 3**: Check the connection update time now.
```
% cpdctl dsjob list-connections --project DSJob_conn --sort-by-time
...

Connection Name|Updated At
---------------|----------
postgres_con   |2023-10-07T06:48:21.967Z

Total: 1 Connections

Status code = 0
```
Update time for the connection did not change. It skipped importing the connection.

### Use case scenario 2: rename a connection
**Step 1**: Rename the connection
```
% cpdctl dsjob update-connection --project DSJob_conn --name postgres_con --to-name postgres_con_renamed
...
{
    "database": "conndb",
    "host": "dummy",
    "password": "dummy",
    "port": "19518",
    "query_timeout": "300",
    "ssl": "false",
    "username": "dummy"
}

Status code = 0
```
**Step 2**: Check the connection update time
```
% cpdctl dsjob list-connections --project DSJob_conn --sort-by-time
...
Connection Name     |Updated At
---------------     |----------
postgres_con_renamed|2023-10-07T07:18:07.500Z

Total: 1 Connections

Status code = 0
```
**Step 3**: import-zip with --skip-on-replace
```
% cpdctl dsjob import-zip --project DSJob_conn --conflict-resolution replace --skip-on-replace connection --file-name conn.zip --wait 60
...
2023-10-07 00:18:15: Waiting until import finishes, import id: 89836dba-b5f6-48de-812b-3b92dda6fa35
2023-10-07 00:18:17: Project import status: started,  total: 2, completed: 1, failed: 0, skipped: 1.
2023-10-07 00:19:06: Project import status: completed,  total: 2, completed: 2, failed: 0, skipped: 1.
Information:
	Connection: postgres_con,	  New connection is exactly the same as an existing connection, resource is not updated.


Status code =  1
```
**Step 4**: Check the connection update time
```
% cpdctl dsjob list-connections --project DSJob_conn --sort-by-time
...
Connection Name     |Updated At
---------------     |----------
postgres_con_renamed|2023-10-07T07:18:07.500Z

Total: 1 Connections


Status code = 0
```
Update time for the connection did not change. It skipped importing the connection.

### Use case scenario 3: delete a connection
Let us follow these steps:

**Step 1**: Delete a connection
```
% cpdctl dsjob delete-connection --project DSJob_conn --name postgres_con_renamed
...
Deleted Connection:  postgres_con_renamed

Status code =  0
```
**Step 2**: Check delete time
```
% cpdctl dsjob list-connections --project DSJob_conn --sort-by-time
...

Total: 0 Connections

Status code = 0
```
**Step 3**: import-zip with --skip-on-replace
```
% cpdctl dsjob import-zip --project DSJob_conn --conflict-resolution replace --skip-on-replace connection --file-name conn.zip --wait 60
...
2023-10-07 00:39:25: Waiting until import finishes, import id: 7a06c6c7-8913-4af0-8227-1e9ca1a9fbb2
2023-10-07 00:39:26: Project import status: started,  total: 2, completed: 1, failed: 0, skipped: 0.
2023-10-07 00:40:16: Project import status: completed,  total: 2, completed: 2, failed: 0, skipped: 0.

Status code =  0
```
**Step 4**: Check the connection update time
```
% cpdctl dsjob list-connections --project DSJob_conn --sort-by-time
...
Connection Name|Updated At
---------------|----------
postgres_con   |2023-10-07T07:39:25.952Z

Total: 1 Connections

Status code = 0
```
The above data shows that import-zip with 'skip-on-replace' did not skip and imported the connection.

