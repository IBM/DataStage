# IBM DataStage Remote Engine — Cross-Platform Setup

This guide describes how to set up IBM DataStage as a **cross-platform remote engine**, where jobs are orchestrated from a CP4D (Cloud Pak for Data) control plane running on x86 while the actual DataStage runtime executes on an **IBM Z (s390x)** virtual machine using Docker.

> **Note:** An s390x-specific remote engine setup is available for teams that need to run DataStage jobs natively on IBM Z hardware.  
> For the standard  Docker remote engine setup, see [RemoteEngine/docker/README.md](https://github.com/IBM/DataStage/blob/main/RemoteEngine/docker/README.md).  
> For Kubernetes-based deployment, see [RemoteEngine/kubernetes/README.md](https://github.com/IBM/DataStage/blob/main/RemoteEngine/kubernetes/README.md).

---

## Architecture Overview

```
┌─────────────────────────────────┐          ┌────────────────────────---──────────┐
│  CP4D Control Plane (x86)       │          │  Remote Engine Host (s390x / IBM Z) │
│  cpd-ds.apps.<cluster>.ibm.com  │◄────────►│  Docker container                   │
│  - Job orchestration            │  HTTPS   │  s390x CP4D Cluster                 │
│  - Project management           │          │                                     |
└─────────────────────────────────┘          └───────────────────────---───────────┘
```

In this setup:
- The **CP4D cluster** (x86) handles job definitions, project management, and scheduling.
- The **s390x VM** runs the `ds-px-runtime` Docker container, which registers itself as a remote engine and polls CP4D for work.
- Jobs submitted from CP4D are executed natively on s390x hardware inside the container.

---

## Prerequisites

### On the s390x VM

- Docker installed and running
- Access to the IBM production registry (`cp.icr.io`)
- The `dsengine.sh` script from this repository
- The following tools: `curl`, `jq`

### Credentials and Environment Variables

Gather the following before starting:

| Variable | Description |
|---|---|
| `IBM_ENTITLEMENT_KEY` | IBM container registry entitlement key |
| `APIKEY` | IBM Cloud or CP4D API key (used by the remote engine to authenticate with the control plane) |
| `PROJECT` | Comma-separated list of CP4D project IDs to register this engine with |
| `REGISTRY` | Container image registry, e.g. `cp.icr.io/cp/cpd` |
| `ENC_KEY` | Encryption key for secure communication |
| `IVSPEC` | Encryption IV specification |
| `DIGEST` | SHA256 digest of the PX-RUNTIME image  |


These are typically stored in a secrets file and sourced before running the script:

```bash
source ~/.dsengine_secrets
```

---

## Setup

### Step 1 — Set Environment Variables

```bash
source ~/.dsengine_secrets

export IBM_ENTITLEMENT_KEY=<your-entitlement-key>
export APIKEY=<your-cp4d-or-ibmcloud-apikey>
export REGISTRY="artifactory.example.com"
export DIGEST=<sha256:1d0f615945b7784d187501c5eb74e4a63f07d0abedce1be43b48c5e646a54973>
export ENC_KEY=<your-encryption-key>
export IVSPEC=<your-iv-spec>

# Single project
export PROJECT=ff0c107b-db6e-48ad-b857-95803539875e

# Or multiple projects (comma-separated)
export PROJECT="ff0c107b-db6e-48ad-b857-95803539875e,ff8b813a-1f87-48cf-821b-efcad94e4eae"
```

---

### Step 2 — Start the Remote Engine

Navigate to the `RemoteEngine/docker` directory and run the start command:

```bash
cd ~/git/DataStage/RemoteEngine/docker

./dsengine.sh start \
  --apikey $APIKEY \
  --home "cp4d" \
  --zen-url "https://cpd-ds.apps.<your-cluster>.ibm.com" \
  --cp4d-user "cpadmin" \
  --cp4d-apikey "<cp4d-api-key>" \
  --remote-engine-name s390x-remote-engine \
  -p $IBM_ENTITLEMENT_KEY \
  -e $ENC_KEY \
  -i $IVSPEC \
  --project-id $PROJECT \
  --registry "$REGISTRY" \
  -u $USER \
  --digest "$DIGEST" \
```

**Key flags for CP4D (on-prem) setup:**

| Flag | Description |
|---|---|
| `--home cp4d` | Selects CP4D mode (as opposed to IBM Cloud) |
| `--zen-url` | URL of your CP4D cluster |
| `--cp4d-user` | CP4D admin username |
| `--cp4d-apikey` | CP4D API key (distinct from the IBM Cloud API key) |
| `--remote-engine-name` | Name for this engine instance; must be unique per cluster |
| `--project-id` | Project ID where the engine will be registered |
| `--registry` | Container registry where the engine image is stored |

#### Expected Output

The script will:
1. Verify the Docker image is available locally.
2. Start the container (`s390x-remote-engine_runtime`).
3. Wait for the runtime health check to pass (can take 90–150 seconds on s390x).
4. Register the engine with CP4D and create a runtime environment for each project.

```
Started container s390x-remote-engine_runtime in 115 seconds
Got remote engine 's390x-remote-engine' registration with id: c04852fe-...
Runtime Environment 'Remote Engine s390x-remote-engine' is registered for project ff0c107b-...
Remote Engine setup completed.
```

---

### Step 3 — Verify the Container is Running

```bash
docker ps
```

You should see an entry similar to:

```
CONTAINER ID   IMAGE                                                COMMAND       CREATED         STATUS                   PORTS      NAMES
ab810559e9b2   cp.stg.icr.io/cp/cpd/ds-px-runtime:540.0.2-s390x   "/bin/bash…"  7 minutes ago   Up 7 minutes (healthy)   9443/tcp   s390x-remote-engine_runtime
```

---

### Step 4 — Configure the Project to Use This Engine

Once the engine is registered, select it in the CP4D project settings:

1. Navigate to your project in CP4D.
2. Go to **Manage → DataStage → Settings tab → Remote environments**.
3. Select **Remote Engine s390x-remote-engine** as the environment for the project.

> **Project settings URL:**  
> `https://<zen-url>/projects/<project-id>/manage/tool-configurations/datastage_admin_settings_section?context=cpdaas`

> Once a project is set to use a remote environment, it **cannot be switched back** to IBM-managed environments. Only use the remote engine for projects that require s390x execution.

---

## Registering with Multiple Projects

To register a single s390x engine across multiple CP4D projects, pass a comma-separated list to `--project-id`:

```bash
export PROJECT="ff0c107b-db6e-48ad-b857-95803539875e,ff8b813a-1f87-48cf-821b-efcad94e4eae"

./dsengine.sh start \
  ... \
  --project-id $PROJECT \
  ...
```

The script will create a separate runtime environment entry for each project and display a confirmation for each:

```
Runtime Environment 'Remote Engine s390x-remote-engine' is registered for project ff0c107b-...
Runtime Environment 'Remote Engine s390x-remote-engine' is registered for project ff8b813a-...
```

---

## Monitoring

### View Container Logs

```bash
docker logs <container-id>
```

### Tail the Runtime Log

```bash
docker exec -it <container-id> /bin/bash
cd logs/
tail -f messages.log
```

A healthy engine repeatedly logs:

```json
{"message": "Waiting for work on remote engine with id: <engine-id>", "loglevel": "INFO", ...}
```

---

## Cleanup

To stop the container, de-register the engine from CP4D, and remove persistent volumes:

```bash
./dsengine.sh cleanup \
  -n 's390x-remote-engine' \
  -a $APIKEY \
  -d '<project-id-1>,<project-id-2>'
```

This will:
- Stop and remove the Docker container.
- Delete the runtime environment entries from each specified project.
- De-register the engine from CP4D.
- Remove the persistent storage volume at `docker/volumes/s390x-remote-engine_runtime`.

> **Tip:** If you only want to restart or update the engine without losing registration, use `docker rm s390x-remote-engine_runtime` and re-run the `start` command with the same `--remote-engine-name`. The existing registration will be reused.

---
