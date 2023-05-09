# DataStage Remote Engine

The `dsengine.sh` script can be invoked from the `docker` folder of this project.
Usage:
```bash
# create/start a local remote engine instance
./dsengine.sh start -n 'remote_engine_name_01' \
                    -a "$IBMCLOUD_STAGING_APIKEY" \
                    -e "$ENCRYPTION_KEY" \
                    -i "$ENCRYPTION_IV" \
                    -p "$IBMCLOUD_PRODUCTION_APIKEY" \
                    --project-id "$PROJECT_ID"

# stop a local remote engine instance
./dsengine.sh stop -n 'remote_engine_name_01'

# restart a local remote engine instance
./dsengine.sh restart -n 'remote_engine_name_01'

# cleanup a remote engine instance and its registration with DataPlatform
./dsengine.sh cleanup -n 'remote_engine_name_01' \
                      -a $IBMCLOUD_STAGING_APIKEY \
                      -d "$PROJECT_ID"
```

### Generating an Encryption Key:

`openssl` can be used to generate an Encryption key and iv. Eg.
```bash
$ openssl enc -aes-256-cbc -k secret -P -md sha1
salt=5334474DF6ECB3CC
key=2A928E95489FCC163D46872040B9B24DC44E28A734B7681C8A3F0168F23E2A13
iv =45990395FEB2B39C34B51D998E0E2E1B
```
The `key` can be used with the `-e` flag (eg. `-e '2A928E95489FCC163D46872040B9B24DC44E28A734B7681C8A3F0168F23E2A13'`) and the `iv` can be used with the `-i` flag (eg. `-i '45990395FEB2B39C34B51D998E0E2E1B'`) in the `dsengine.sh start` command as shown above.

### Not supported
At this time, following features are not supported:
1. S/M/L Parameterization
1. MPP Support

## Pre-Requisites
1. Software that must be installed on the system.
    1. `docker`
    1. `jq`
