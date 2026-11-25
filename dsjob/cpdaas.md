# DataStage cli `dsjob` for CPDaaS
  
Last Updated: 2026-11-15

CPDCTL latest tested release:  [1.10.38](https://github.com/IBM/cpdctl/releases/tag/v1.10.38)

#### New Commands:
- dsjob `git-list` List files in a Git repository folder, heirarchically
- dsjob `git-fetch`  Fetch (import) specific files from a Git repository into a project.
- dsjob `jfrog-list` List JFrog Artifactory artifacts 
- dsjob `jfrog-fetch`  Fetch assets from a JFrog Artifactory repository.

#### Fixes/Enhancements: 
- dsjob `run` creates job runs with transactionID to avoid duplicate runs
- dsjob `update-job` adds option to update warn limit and priority queue options
- dsjob `git-pull` to properly process enc-key to pull artifacts that are encrypted
