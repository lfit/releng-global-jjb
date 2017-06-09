# Global JJB

The purpose of this repository is store generically define reusable JJB
templates that can be deployed across LF projects.

The following variables are necessary to be defined in the Jenkins server as
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
Note: **GIT_CLONE_URL** is only used by Github projects as this
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

global-jjb should be deployed in the ci-management repository's jjb directory as
a submodule. global-jjb is versioned and tagged in Gerrit so installing,
upgrading, and rolling back changes should be simple via the Gerrit tag system.

```
    # Choose a global-jjb version to install
    GLOBAL_JJB_VERSION=v0.1.0

    # Add the new submodule to ci-management's jjb directory.
    # Note: Only needs to be performed once per ci-management repo.
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

There are a few project specific parameters that should be stored in the
ci-management repo's defaults.yaml file.

**gerrit-server-name**: The name of the Gerrit Server as defined in Gerrit
Trigger global configuration.

**jenkins-ssh-credential**: The name of the Jenkins Credential to use for ssh
connections.

If you are using GitHub then there is one more parameter which
will need to be placed in the defaults.yaml

**github-org**: The name of the GitHub organization.

defaults.yaml:

```
- defaults:
    name: global

    # lf-infra defaults
    jenkins-ssh-credential: opendaylight-jenkins-ssh
    gerrit-server-name: OpenDaylight
    github-org: lfit
```

## Config File Management

### Logs

The logs account requires a Maven Settings file created called
**jenkins-log-archives-settings** with a server ID of **logs** containing the
credentials for the logs user in Nexus.

## Deploying ci-jobs

The CI job group contains multiple jobs that should be deployed in all LF
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

This job can be used to call python-tox to run builds and tests. The most common
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
**stream**: typically `master` or matching whatever branch is being built. This
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

In this method the entire archives directory will be pushed to the log server
in the same structure as configured in the archives directory.

2) Via job variable ARCHIVE_ARTIFACTS using globstar patterns.

In this method a job can define a globstar for example ``**/*.log`` which then
causes the archive script to do a globstar search for that pattern and archives
any files it finds matching.
