# OpenCide
## The easiest CI/CD tool ever!
### Continuous Integration, Continuous deployment, Continuous Everything..
<p>Most of the times, what we need is just a simple tool to push our code from one development environment to another.. or to a production server, with logs, ability to rollback and to document what we've done. It doesn't have to be complicated.. but CI/CD tools are just complex.. from setup to usage, so most teams don't use any.</p>
<p>That's what OpenCide is for! Push from dev/staging to production with just three commands, and make your downtime as little as 0-10ms! </p>

___
### How to install?
___

1. Clone https://github.com/anonnion/ci to your staging server. It's recommended to place it outside your development environment, since you won't need more than one for each server.
2.   Enjoy!
3. (Optional) You can add /path/to/ci to your path, so as to make it easy to use.
___
### How to use?
___
(A) Creating a project:
1. Go to your project's directory.
2. (Assumming /path/to/ci is already added to your path) Create a new project by entering these into the terminal/shell and answer the questions:
```bash
ci init
```
3. In /path/to/ci/projects, you will see a folder that is named after your new project's alias, modify the demo .env to reflect the right values.

(B) Publishing a project:
```bash
ci publish PROJECT_ALIAS DEPLOY_TYPE PUSH_OR_STORE
```
Where:
1. `PROJECT_ALIAS` is the short name you supplied for your project during project creation.
2. `DEPLOY_TYPE` is any of `major`, `minor`, or `patch` and it determines the version naming using SemVer naming convention.
3. `PUSH_OR_STORE` is either `push` or `store`, where `push` means the production ready code will be stored in a tarball, then pushed to the production server, also, a git branch to denote the release will be created, and the code will be pushed to the branch (if it is enabled and configured in the project's .env file for ci). `store` means the code will be tarball'ed, then stored on the staging server, without moving it anywhere.


### Typing ci in terminal returns the help message below:

<pre>
Using OpenCide installed in /home/refdb/referraldb_2023/.ci
CI v0.0.1
Usage: ci [init [project_name, path_to_env, path_to_deployignore], publish [project_alias, deploy_type, push_to_prod]]
Arguments to init is optional, they will be asked if not provided.
Examples:
    ci init  - create a new project
    ci publish  - publish a project to a defined server
Examples of arguments to ci init
    ci init PROJECT_ALIAS /path/to/.env /path/to/.deployignore
Other functions of ci publish: 
    ci publish PROJECT_NAME DEPLOY_TYPE create-changelog  - creates a PROJECT_VERSION.md file in the project's root directory, which will be added to your deploy log.
    ci publish PROJECT_NAME DEPLOY_TYPE create-installer - creates an installer: PROJECT_VERSION.sh file in the project's root directory, which will run after the production server has fetched the published version.
Further publish examples of ci publish: 
    ci publish PROJECT_ALIAS major PUSH_OR_STORE_OR_GIT
    ci publish PROJECT_ALIAS minor PUSH_OR_STORE_OR_GIT
    ci publish PROJECT_ALIAS patch PUSH_OR_STORE_OR_GIT
Where: 
    DEPLOY_TYPE can be either major, minor or patch
    PROJECT_ALIAS is the alias supplied to ci init
and: 
    PUSH_OR_STORE_OR_GIT can be either `push` or `store` or `git`
    store: creates the release file only.
    git: creates the release file and push to git release branch.
    push: creates the release file, and also creates a one-time, IP restricted access for the configured server to download the release file. See the .env file of your project to configure the server that can access the release file.
</pre>