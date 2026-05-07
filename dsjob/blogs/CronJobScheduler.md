### Runing scheduled jobs from outside the cluster.
### Using crontab

#### Prerequisites

#### configure cpdctl
Set the config file location before configuring cpdctl
`export CPD_CONFIG=/mydir/etc/config.yaml`

Use the standard script to configure cpdctl from [docs](https://github.com/IBM/DataStage/blob/main/dsjob/dsjob.5.3.1.md#resources)

source the configuration file. The config file is created at the location set by the environment variable `/mydir/etc/config.yaml`

**Important: This configuration file will be used by the script to connect to the cluster using the profile name you have used in the configuration script.**

Now we are ready to build the dsjob.ini file that will be leverage by the dsjob script to run jobs.

#### Build dsjob.ini 
```
# Specify the configuration file for the cpdctl command. A profile needs
# to be created in this config.yaml.
dsjob.cpdctl.config=/mydir/etc/config.yaml

# Name of the profile in the cpdctl configuration.
#dsjob.cpdctl.profile=saas
dsjob.cpdctl.profile=<YOUR PROFILE>

# mykey.txt is your encryption key to read config file that you used in your 
# when creating config using your configuration script
cpdctl.encryption.key.path=/mydir/etc/mykey.txt
```


Now the main execution script, this script is going to use config setup above to run the command

Main script is found here: ![dsjob.sh](dsjob.sh)

This script has mainly 4 parts
#### setup env

Read dsjob.ini to setup cpdctl config file location, profile name and encoding key to read the config file
```
CPDCTL_CONFIG=`egrep '^dsjob.cpdctl.config=' $INI_FILE | cut -d'=' -f2`
MAX_RUN_WAIT=`egrep '^dsjob.cpdctl.max-wait=' $INI_FILE | cut -d'=' -f2`
CPDCTL_PROFILE=`egrep '^dsjob.cpdctl.profile=' $INI_FILE | cut -d'=' -f2`
CPDCTL_ENC_KEY=`egrep '^cpdctl.encryption.key.path=' $INI_FILE | cut -d'=' -f2`
DEFAULT_JOB_NAME=`egrep '^dsjob.cpd.default-job-name' $INI_FILE | cut -d'=' -f2`
DEFAULT_RUN_NAME=`egrep '^dsjob.cpd.default-run-name' $INI_FILE | cut -d'=' -f2`
CONTEXT_TYPE=`egrep '^dsjob.cpd.context-type' $INI_FILE | cut -d'=' -f2`
PIPELINE_STATUS_PARAM=`
egrep '^dsjob.pipelines.user-status-param' $INI_FILE | cut -d'=' -f2`
PIPELINE_OPTIMIZED=`
egrep '^dsjob.pipelines.optimized' $INI_FILE | cut -d'=' -f2`
PIPELINE_JOB_NAME=`egrep '^dsjob.pipelines.job-name' $INI_FILE | cut -d'=' -f2`
DSJOB_RETRIES=$(egrep '^dsjob.retry_count=' $INI_FILE | cut -d= -f2)
DSJOB_RETRY_DELAY=$(egrep '^dsjob.retry_delay=' $INI_FILE | cut -d= -f2)
: "${DSJOB_RETRIES:=3}"
: "${DSJOB_RETRY_DELAY:=2}"
```
  
set the config file into the cpdctl command invocation
```
CPDCTL="cpdctl --cpd-config $CPDCTL_CONFIG dsjob"
```

expose dsjob commands and setup encryption key file
```
export CPDCTL_ENABLE_DSJOB=true
export CPDCTL_ENCRYPTION_KEY_PATH=$CPDCTL_ENC_KEY
```

#### implement support functions
retry_cmd() -- allows to try commands on errors 
check_job_object_type - identifies if the job is a datastage job or a pipeline job
run_job - uses job type to trigger `run` or `run-pipeline`

#### main body
First argument is project name 
second argument is flow/pipeline name
rest of the arguments are not interpreted and passed into the corresponding run command
use the wait time setup in the ini file to wait for job completion
```
PROJ="$1"
JOB="$2"
shift 2
FLOW_NAME=`echo $JOB | cut -d'.' -f1`
RUN_WAIT="--wait ${MAX_RUN_WAIT}"
run_job "$@"
```

Now once these scripts are copied to a directory, and path is set to this directory in the crontab entry, the job can be scheduled. An example of a crontab entry is 
First job runs every 5 mins on production project `dsjob-prod` with PROD value set, where as the second job runs every 15 mins on test project `dsjob-test` with DEV value set.
```
*/5 * * * * export PATH=/ibm/scripts:$PATH && cd /ibm/sripts && ./dsjob.sh dsjob-prod RowGenToFile --paramset TestParmSet.PROD --param TestParam=10
*/15 * * * * export PATH=/ibm/scripts:$PATH && cd /ibm/sripts && ./dsjob.sh dsjob-test RowGenToFile --paramset TestParmSet.DEV --param TestParam=10

```
