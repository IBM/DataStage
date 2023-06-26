# Debug information on IBM DataStage CP4D clusters

## Pre-Requisites
1. Software that must be installed on the system.
    1. `oc`
    1. `jq`

## Requirements
1. Clone this repo: `git clone git@github.com:IBM/DataStage.git` OR `git clone https://github.com/IBM/DataStage.git`.
    1. If you already have this repo cloned, go to the root directory and run `git pull` to get the latest changes.

## Usage
1. Login to the cluster using OpenShift Cli (`oc`)
    ```
    oc login -u kubeadmin -p NSLzF-INVI2-fXGbd-7sj2b https://api.tahoetest421.cp.fyre.ibm.com:6443
    ```
1. Switch to the namespace/project that hosts DataStage setup.
    ```
    oc project <project_name>
    ```
1. Run the `dsdebug` script from this folder
    ```
    cd /path/to/DataStage/OCDebug
    ./dsdebug.sh
    ```
