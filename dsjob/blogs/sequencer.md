
To Run a pipeline  pipeline using optimized runner engine.
#### Compile Pipeline as sequencer job.
This step allows fetching the existing pipeline, analyze and compile to code that can be run as sequencer job.

The following syntax fetches a flow/pipeline parameters for a given flow/pipeline from the specified project:
```
cpdctl dsjob compile-pipeline {--project PROJECT | --project-id PROJID} {--pipeline PIPELINE | --pipeline-id PIPELINEID} [--code] [--threads <n>]
```

-   `project`  is the name of the project that contains the pipeline.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-   `pipeline`  is the name of the flow or a pipeline.
-   `pipeline-id`  is the id of the flow or a pipeline. One of  `name`  or  `id`  must be specified.
- `code` will output the details on the code it generates
- `threads` specifies the number of parallel compilations to run. The value should be in the range 5-20, default value is 5. This field is optional.

#### Run Pipeline as sequencer job
To run the pipeline as sequencer job you must use two new options to configure and run the `run-pipeline` command. For general syntax on the `run-pipeline` command please refer to [documentation](https://github.com/IBM/DataStage/blob/main/dsjob/dsjob.5.0.2.md#running-pipelines)

Syntax for running the pipeline is as shown below. Please note that the two new options `--optimize` and `--skip-compile`  will be available using the cpdctl release version [1.6.62]([https://github.com/IBM/cpdctl/releases/tag/v1.6.62](https://github.com/IBM/cpdctl/releases/tag/v1.6.62)) 

`optimize` when true the pipeline is run as sequencer job. If not specified then the pipeline is run as a normal pipeline execution.
`skip-compile` when true the pipeline is not compiled, if not the pipeline is compiled as part of the run. This flag is only effective when `optimize` flag is set to run, i.e. in optimized runner mode.
 
Following are some examples :

##### Run pipeline as sequencer job
```
cpdctl dsjob run-pipeline --project dsjob-test --name testbashds --optimize --wait 200
or 
cpdctl dsjob run-pipeline --project dsjob-test --name testbashds --optimize=true --wait 200
or 
cpdctl dsjob run-pipeline --project dsjob-test --name testbashds --optimize --skip-compile=true --wait 200
```

##### Run pipeline without compiling
```
cpdctl dsjob run-pipeline --project dsjob-test --name testbashds --optimize --skip-compile --wait 200
or 
cpdctl dsjob run-pipeline --project dsjob-test --name testbashds --optimize=true --skip-compile=true --wait 200
```


##### Some internals

When you run the pipeline using the above command, a job gets created with name  `<PIPELINENAME>.DataStage sequence job`  
If you want to configure the job further, you can chose to use cpdctl job  `update-job`  or  `schedule-job`  commands here  [update-job](https://github.com/IBM/DataStage/blob/main/dsjob/dsjob.5.0.0.md#updating-jobs)   and [schedule-job](https://github.com/IBM/DataStage/blob/main/dsjob/dsjob.5.0.2.md#scheduling-jobs)
You can also use UI to update the job from Jobs Dashboard.

Note: You cannot analyze the run through UI when running the pipeline as a sequencer job
