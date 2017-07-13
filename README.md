# Global JJB

The purpose of this repository is store generically defined, reusable JJB
templates, deployable across LF projects.

Define the following variables in the Jenkins server as
global environment variables as scripts in this repo expect these variables to
be available.

For example:

```
GIT_URL=ssh://jenkins-$SILO@git.opendaylight.org:29418
GIT_CLONE_URL=git@github.com:
JENKINS_HOSTNAME=jenkins092
LOGS_SERVER=https://logs.opendaylight.org
NEXUS_URL=https://nexus.opendaylight.org
SILO=releng
```

Note: Use **GIT_CLONE_URL** for GitHub projects as this
will be different from the URL used the poperties
configuration.

## Jenkins Plugin Requirements

**Required**

- Config File Provider
- Description Setter
- Gerrit Trigger
- Post Build Script
- SSH Agent
- Workspace Cleanup

**Optional**

- Mask Passwords
- MsgInject
- OpenStack Cloud
- Timestamps

## Installing global-jjb

Deploy global-jjb in the ci-management repository's jjb directory as
a submodule. Installing, upgrading, and rolling back changes is simple via the
versioned git tags.

```
    # Choose a global-jjb version to install
    GLOBAL_JJB_VERSION=v0.1.0

    # Add the new submodule to ci-management's jjb directory.
    # Note: Perform once per ci-management repo.
    cd jjb/
    git submodule add https://gerrit.linuxfoundation.org/infra/releng/global-jjb

    # Checkout the version of global-jjb you wish to deploy.
    cd global-jjb
    git checkout $GLOBAL_JJB_VERSION

    # Commit global-jjb version to the ci-management repo.
    cd ../..
    git add jjb/global-jjb
    git commit -sm "Install global-jjb $GLOBAL_JJB_VERSION"

    # Push the patch to ci-management for review
    git review
```

## Parameters stored in defaults.yaml

Configure the following parameters in the ci-management repo's defaults.yaml
file.

**gerrit-server-name**: The name of the Gerrit Server as defined in Gerrit
Trigger global configuration.

**jenkins-ssh-credential**: The name of the Jenkins Credential to use for ssh
connections.

If you are using GitHub then configure the following parameters in defaults.yaml

**git-url**: Set this to the base URL of your GitHub repo. In
general this should be <https://github.com>. If you are using GitHub
Enterprise, or some other GitHub-style system, then it should be
whatever your installation base URL is.

**git-clone-url**: This is the clone prefix used by GitHub jobs. Set this to
either the same thing as **git-url** or the
'git@github.com:' including the trailing ':'

**github-org**: The name of the GitHub organization. All members of this organization
will be able to trigger the merge job.

**white-list**: List of Github members you wish to be able to trigger the merge job.

defaults.yaml:

```
- defaults:
    name: global

    # lf-infra defaults
    jenkins-ssh-credential: opendaylight-jenkins-ssh
    gerrit-server-name: OpenDaylight
    github-org: lfit
    white-list:
      - jpwku
      - tykeal
      - zxiiro
```

## Config File Management

### Logs

The logs account requires a Maven Settings file created called
**jenkins-log-archives-settings** with a server ID of **logs** containing the
credentials for the logs user in Nexus.

## Deploying ci-jobs

The CI job group contains jobs that should deploy in all LF
Jenkins infra. The minimal configuration needed to deploy the ci-management
jobs is as follows which deploys the **{project-name}-ci-jobs** job group as
defined in **lf-ci-jobs.yaml**.

ci-management.yaml:

```
- project:
    name: ci-jobs

    jobs:
      - '{project-name}-ci-jobs'

    project: ci-management
    project-name: ci-management
    build-node: centos7-basebuild-2c-1g
```

Required parameters:

**project**: is the project repo as defined in source control.
**project-name**: is a custom name to call the job in Jenkins.
**build-node**: is the name of the builder to use when building (Jenkins label).

Optional parameters:

**branch**: is the git branch to build from.
**jjb-version**: is the version of JJB to install in the build minion.

## Deploying Python jobs

We provide the following Python jobs templates:

### {project-name}-tox-verify-{stream}

Use this job to call python-tox to run builds and tests. The most common
usage of this job is to run the Coala linter against projects.

```
- project:
    name: builder
    jobs:
        - '{project-name}-tox-verify-{stream}'

    project-name: builder
    project: releng/builder
    build-node: centos7-java-builder-2c-4g
    stream: master
```

Required parameters:

**project**: is the project repo as defined in source control.
**project-name**: is a custom name to call the job in Jenkins.
**build-node**: is the name of the builder to use when building (Jenkins label).
**stream**: typically `master` or matching the build branch. This
            is a useful keywords to map a release codename to a branch. For
            example OpenDaylight uses this to map stream=carbon to
            branch=stable/carbon.

Optional parameters:

**branch**: is the git branch to build from.
**jjb-version**: is the version of JJB to install in the build minion.
**tox-dir**: directory containing tox.ini file (default: '')
**tox-envs**: tox environments to run (default: '')

## Archiving logs in Jobs

There are 2 ways supported for archiving log information:

1) Job creates $WORKSPACE/archives directory and places logs there

This method pushes the entire archives directory to the log server
in the same structure as configured in the archives directory.

2) Via job variable ARCHIVE_ARTIFACTS using globstar patterns.

In this method a job can define a globstar for example `**/*.log` which then
causes the archive script to do a globstar search for that pattern and archives
any files it finds matching.

## Appendix

### ShellCheck

When using ShellCheck to lint global-jjb or any projects that include
global-jjb as part of their project (common with ci-management repos) then
we require version 0.4.x of ShellCheck installed on the build vms. This version
introduces annotations used by shell scripts in this repo.
