# Migrating workloads from legacy InfoSphere Information Server to DataStage Nextgen on CP4D

When we migrate integration flows from legacy InfoSphere Information Server(IIS) to DataStage Nextgen on CP4D, dataSources can be configured in many ways. It is possible to configure  connection properties manually, using parameter sets or using global environment variables. This blog demonstrates these three scenarios for migration into CP4D environment assuming that we already have the isx file generated from IIS. 
 
## Scenario 1 

In this scenario we use an isx file built from legacy IIS that contains manually configured connection, it does not contain any parameter set. We can migrate the isx file objects into CP4D using `cpdctl dsjob` command enabling local connection or without enabling local connection. Both the cases are described below. All connection properties are migrated directly into the connection asset or the flow and there is no parameterization. This method is static in nature and works well if the number of connection assets are manageable.

### Case 1: Enabling local connection

Example `cpdctl dsjob` command to migrate is shown below. `OracleToPeek.isx` is exported from IIS which does not contain any parameter sets:
```
% cpdctl dsjob migrate --project migrate_conn_no_param --file-name OracleToPeek.isx --enable-local-connection
```
In this case, only flow gets created and no connection asset is created. In this example, the flow contains `Oracle(optimized)` as a source stage. `Oracle(optimized)` stage properties get populated as:

```
Connection -> View connection -> <Flow connection>
Connection details -> Hostname -> <hostname>  
Connection details -> Port -> <port no>
Connection details -> Servicename -> <service name>
Connection details -> Username -> <username> 
Connection details -> Password -> <password>
```

### Case 2: Without enabling local connection

Example `cpdctl dsjob` command to migrate is shown below, `OracleToPeek.isx` is exported from IIS which does not contain any parameter sets:

```
% cpdctl dsjob migrate --project migrate_conn_no_param --file-name OracleToPeek.isx
```
In this case, flow and connection asset get created. In this example, in the flow, `Oracle(optimized)` stage properties gets populated as:

```
Connection -> View connection -> <connection asset name>
```

Connection asset has all the following migrated connection properties which get populated with the values:

```
Name
Hostname
Port
Servicename
Username
Password
```

In both cases, nothing needs to be edited in the flow as well as in the connection asset. The flow can be run successfully without editing anything. 


## Scenario 2 

In this scenario a connection is parameterized such that all the connection properties are migrated into a parameter set and the parameter set is referenced by the connection itself. It provides the flexibility of changing the connections dynamically.

Example `cpdctl dsjob` command to migrate is shown below, `OracleRoPeek_Param.isx` is exported from IIS which contains :

```
% cpdctl dsjob migrate --project migrate_conn_paramset --create-connection-paramsets --file-name OracleRoPeek_Param.isx 
```

In this scenario, the assets get created are flow, parameter set and connection asset. 

In the generated flow, `Oracle(optimized)` stage properties get populated as:

```
Connection -> View connection -> <connection asset name>
```
 
Connection asset has the following migrated connection properties populated with the values referencing the parameter values of the parameter set `ORC_Pset1` in this example:

```
Hostname 	#ORC_Pset1.ORC_SVC_NAME#
Port     	#ORC_Pset1.oracle_db_port#
Servicename 	#ORC_Pset1.oracle_service_name#
Username 	#ORC_Pset1.UID#
```

The parameter set `ORC_Pset1` contains the following parameters, in this example:

```
ORC_SVC_NAME            conops-oracle21.fyre.ibm.com:1521/orclpdb
UID                     tm_ds
PWD                     ******
oracle_service_name
oracle_db_port
```
 
You need to follow these manual steps to complete the migration process before you run the flow:

### Step 1. Edit the parameter set

Edit the parameter set `ORC_Pset1` like below.

Before edit, `Default value` appears as:

```
ORC_SVC_NAME 		conops-oracle21.fyre.ibm.com:1521/orclpdb
UID          		tm_ds
PWD          		******
oracle_service_name
oracle_db_port
```

After you edit the parameter set, it should look as:

```
ORC_SVC_NAME            conops-oracle21.fyre.ibm.com
UID                     tm_ds
PWD                     ******
oracle_service_name     orclpdb
oracle_db_port          1521
```

Note the change in the values of `ORC_SVC_NAME`, `oracle_service_name` and `oracle_db_port` after edit.

### Step 2. Compile and run the flow

Now the flow can be compiled and run.
   
## Scenario 3 
In this scenario, the connection properties are migrated using global environment variables. The advantage of this method is that the parameters can be used by many datasources in the project. It becomes easy to manage all the flows by directly changing the connection in the PROJDEF. It reduces the administrative complexity when updating the connections. This scenario requires migrating the isx file along with DSFlow params file from IIS environment into CP4D.

Follow thesse steps to complete the migration:

### Step 1. Run `cpdctl dsjob migrate` command

Example `cpdctl dsjob` command to migrate is below, `OracleToPeek_Projdef.isx` is exported from IIS which contains:

```
% cpdctl dsjob migrate --project migrate_conn_paramset --create-connection-paramsets --file-name OracleToPeek_Projdef.isx
```

`OracleToPeek_Projdef.isx` contains paramset `ORC_Pset`, `PROJDEF`, connection asset and flow.

In the generated flow, `Oracle(optimized)` stage propertie gets populated as:

```
Connection -> View connection -> <connection asset name>
```

The paramset `ORC_Pset` contains:

```
$ORC_SVC_NAME		PROJDEF
$PWD			******
$UID			PROJDEF
oracle_service_name	
oracle_db_port
```

The `PROJDEF` contains:
```
$UID			UID
$ORC_SVC_NAME		ORC_SVC_NAME
```

The generated connection asset contains:

```
Hostname        #ORC_Pset.$ORC_SVC_NAME#
Port            #ORC_Pset.oracle_db_port#
Servicename     #ORC_Pset.oracle_service_name#
Username        #ORC_Pset.$UID#
```

### Step 2. Run `cpdctl dsjob create-dsparams` command 

Create dsparams by running the following command:

```
% cpdctl dsjob create-dsparams  --project migrate_conn_projdef --file-name DSParams.txt
```

Example DSParams.txt content here:
```
[serveronly-functions]
[parallelonly-beforeafter]
[system-variables]
[serveronly-system-variables]
[parallelonly-system-variables]
[EnvVarDefns]
ORC_SVC_NAME\User Defined\-1\String\\0\Project\ORC_SVC_NAME\
UID\User Defined\-1\String\\0\Project\UID\
PWD\User Defined\-1\Encrypted\\0\Project\PWD\
[PROJECT]
[InternalSettings]
[EnvVarValues]
"ORC_SVC_NAME"\1\"conops-oracle21.fyre.ibm.com:1521/orclpdb"
"UID"\1\"tm_ds"
"PWD"\1\"{iisenc}6iJys4F7fdGGGYrOx6hehQ=="

```

In this process, `PROJDEF` gets updated as:
```
$UID		tm_ds
$ORC_SVC_NAME	conops-oracle21.fyre.ibm.com:1521/orclpdb
$PWD		{dsnextenc}CkmnmfdOwoauTg2eHINZfw==
```

### Step 3. Edit `PROJDEF` 

Edit `PROJDEF` for $ORC_SVC_NAME.

Before editing, `PROJDEF` content is:
```
$UID            tm_ds
$ORC_SVC_NAME   conops-oracle21.fyre.ibm.com:1521/orclpdb
$PWD            {dsnextenc}CkmnmfdOwoauTg2eHINZfw==
```

After editing, `PROJDEF` content is::
```
$UID            tm_ds
$ORC_SVC_NAME   conops-oracle21.fyre.ibm.com
$PWD            {dsnextenc}CkmnmfdOwoauTg2eHINZfw==
```

Note, the value of $ORC_SVC_NAME after editing `PROJDEF`. 

### Step 4. Edit paramset 
In this example, edit the param set `ORC_Pset`. 

Before editing the paramet `ORC_Pset`, the values of the parameters are:
```
$ORC_SVC_NAME           PROJDEF
$PWD                    ******
$UID                    PROJDEF
oracle_service_name
oracle_db_port
```

After editing the paramset `ORC_Pset`, the values of the parameters are:
```
$ORC_SVC_NAME           PROJDEF
$PWD                    ******
$UID                    PROJDEF
oracle_service_name     orclpdb
oracle_db_port          1521
```

Note the value of `oracle_service_name` and `oracle_db_port` after editing `ORC_Pset`.

### Step 5. Compile and run the flow

Now, the flow can be compiled and run.

