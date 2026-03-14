# Why caching for dsjob
dsjob plugin will provide its own caching mechanism to write the fetched get api calls data into a local file. On subsequent calls we try to read the cached data in the local file to match the request and avoid making a backend call to fetch this data.
As an example, if customer runs the below command, we fetch projectID and use it in getting list of jobs.
` cpdctl dsjob list-jobs --project myProject` 
The relevant information from `myproject` such as project ID are writtent to local file
When next call such as below happend we look into the existing local file to match the project and get the ID instead of going to invoke backend api to fetch projectID.
`cpdctl dsjob run --project myProject --name myJob`

# Configuring cache for dsjob
To enable cache for dsjob we require two step process
1. Set environment variable in your script to provide cache-path. This can be a directory accessible by cpdctl, either a local disk or mounted disk path.
`export CPDCTL_CACHE_PATH=/my/path/cache`
This allows us to write cached data to the directory `/my/path/cache`. Make sure the user running cpdctl has write access to the directory.

2. Set the encryption key. The encryption key is passphrase specified by user, example `this is my secure key passphrase` stored in mykey.txt, then the encryption algorithm will use that key to encrypt the data stored on disk. You might want to keep this file securely and provide read access to the user running the cpdct binary. If the content of this file is changed then the existing cache cannot be read and we will end up wirting new cache file using the new key in the file.
`export DSJOB_ENCRYPTION_KEY_PATH=~/dsjob/mykey.txt`

Once we have both these environment variable set, local caching is enabled and the cache data is written to disk. This can make subsequent call faster and also avoind rate limit issues. 
Note that is this a incremental approach and more calls will be planned to use caching in future releases of cpdctl.
Cache file in the cache directory will look like this...
```
$ ls -l
-rw-r--r--@ 1 user1  staff  43792 Mar 13 10:08 U:1000331001-P:list-projects.cache
```