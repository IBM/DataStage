# Git Integration

Git Integration is a mechanism to write your project contents to a Git repository and maintain version control and integrate with your CI/CD pipelines.

DataStage customers would like to use Git as means for version control their project assets in CloudPak projects. It will also help them promote their Development work into higher environments by integrating Git into their CI/CD process.

DataStage implements Git Integration as part of ds-migration service. Currently ds-migration service hosts all export and import functionality for the projects. New Api are added to the ds-migration service to allow users to commit and pull their work from git.

Before invoking the API, project needs to be Git enabled. This will setup initial configuration for the project and can be overridden by individual operations to Git.
This functionality will allow you to update incremental changes from your project where you collaborate and build functionality and sync to Git repo. It is then possible to promote your tested projects to higher environments such as QA and eventually to Production.

Git Integration provides three commands:
- `git-commit`: Allow CPD Project resources to push and commit to Git repository
- `git-pull`: Allow project artifacts from Git repository to pull and update into CPD Projects
- `git-status`: Provides status on resource to identify the differences between the CPD Project the the Git repository

A bit of background...
- Git Integration is also available before 5.x releases and was implemented as a CLI side functionality. It did not require user to configure the projects with Git Integration
- CLI tooling has limitations and other scalability issues. We now have Git Integration  implemented into DataStage Migration service. This now require additional steps to configure.
- Git repositories used before 5.x releases are still backward compatible

#### Setting up Git Integration for the project
For allowing project to be aware of Git Integration we need to enable them to track changes internally of all the resources in a project. This requires to explicitly configure the project for Git Integration using the following command
```
cpdctl dsjob git-configure {--project PROJECT | --project-id PROJID} [--git-enable] [--git-url URL] [--git-owner OWNER] [--git-token TOKEN] [--git-org ORG] [--git-email EMAIL] [--git-provider GITPROVIDER]  [--git-branch GITBRANCH]  [--git-folder GITFOLDER]
``` 
-   `project`  is the name of the project.
-   `project-id`  is the id of the project. One of  `project`  or  `project-id`  must be specified.
-  `git-enable` allows project to be git enabled and starts tracking resource changes
-  `git-url`  git repo url. ex: `https://github.company.com/username/git-dsjob.git`
-  `git-owner`  owner of the git repository ex: `username`. This field is optional.
-  `git-token`  token used for authentication. This field is encrypted when stored.
-  `git-org`   Git organization, this field is optional. 
-  `git-provider` Integrate to specific provider, must be `git` or `gitlab` currently.
-  `git-branch` Default branch used for git operations
-  `git-folder` Folder to which this project will be committed or fetched from. This is optional

Git URL is the destination of your organizations git URL. Git owner is the user who commits to Git and the Git token is the user’s token used for auth. Fields `git-owner`, `git-org` are deducible to the URL and can be removed from the command eventually. 
Currently git is configurable with Auth Token but will support SSL certs in the future

Git can also be configured from UI
![GitConfiguration](https://github.com/IBM/DataStage/tree/main/dsjob/blogs/gitconfiguration.png)

Once git is configured, Migration service starts collecting data on all assets that are added, modified or deleted so that we tally these assets to allow user to accurately get status on the CPD Project against Git repo. This will consume some cluster resource and can be managed using the [tracking](https://github.com/IBM/DataStage/blob/main/dsjob/dsjob.5.1.0.md#managing-git-project-tracking-data) api.

Use the provided [git-operations](https://github.com/IBM/DataStage/blob/main/dsjob/dsjob.5.1.0.md#git-integration) to integrate your CPD project with Git.

#### Git Commit
This Api allows users to commit their project as a whole or incrementally into Git. When an entire project is committed to Git, it maintains a specific structure of this project in Git.

Each action is a single signed commit.
Commit takes assets from project and writes to Git repo under a branch and a folder. User must make sure that each project is maintained into a separate folder to make sure that project data is not overlapped.

Commit can be invoked from UI as shown
![Git commit entire project](https://github.com/IBM/DataStage/tree/main/dsjob/blogs/gitbulkcommit.png)
![Add commit message to the PR](https://github.com/IBM/DataStage/tree/main/dsjob/blogs/gitbulkcommit2.png)

Once committed to git the repo structure would look like below
![Folder structure of a project](https://github.com/IBM/DataStage/tree/main/dsjob/blogs/gitrepo.png)
Assets of each type are assigned to their respective folders. All parameter sets are shown below are stored as json types. Some assets are stored in binary form.
![Parameter Sets](https://github.com/IBM/DataStage/tree/main/dsjob/blogs/gitrepo2.png)

Context based commits are available from UI
![Context based commits](https://github.com/IBM/DataStage/tree/main/dsjob/blogs/gitcontextcommit.png)

In this image you can see two projects committed into one branch but into two different folders.

The commit is based on the structure of the DataStage export API. Each asset is stored into a folder designated by its type. For example, all flows are stored as Json files under `data_intg_flow`. Files are named after asset names.

Git commit also maintains and updates `  DataStage-README.json` at the root of the folder with a manifest of all assets it operated on. Also, Git commit writes `DataStage-DirectoryAsset.json` into repo as is to restore folder structure when Git repo is imported.
Note `project.json` is a special file that is added at the root of each folder and maintained by Git API. This file will help determine project level changes with respect to Git. This file along side the project tracking data in the Migration service helps in determining what assets are changes between Project and Git.


#### Git Pull
This Api allows users to pull their Git project as a whole or incrementally some had picked assets from Git repository into CloudPak Project. Git pull is backed by ds-migration import service. Apart from specifying repo, branch and folder user can control which assets can be replaced, skipped when promoting to higher environment using conflict resolution, hard-replace and skip-on-replace switches.

Pull can be invoked from UI as shown:
![Pull the Git Repo to a Project](https://github.com/IBM/DataStage/tree/main/dsjob/blogs/gitpull.png)

#### Git Status
Git Integration provides platform specific computations to determine if the resource in Git repository is same as the resource in CloudPak Project.

Status is displayed which is context based, during commit the source of truth is the project which means `created` refers to a resource in project but not in Git repository and vice versa. Object that are modified in the Project are shown as `updated`. During pull the source of truth comes from Git repository, a `created` object is an object that exists in Git repository and is ready to be pulled and created in the Project. 
![See status of Project Resources](https://github.com/IBM/DataStage/tree/main/dsjob/blogs/gitstatus.png)


Currently this functionality is available only on CPD platforms and we are working in bring it to Saas soon.
