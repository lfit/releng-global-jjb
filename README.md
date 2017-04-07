# Global JJB

The purpose of this repository is store generically define reusable JJB
templates that can be deployed across LF projects.

The following variables are necessary to be defined in the Jenkins server as
global environment variables as scripts in this repo expect these variables to
be available.

For example:

```
GIT_URL=ssh://jenkins-$SILO@git.opendaylight.org:29418
JENKINS_HOSTNAME=jenkins092
LOGS_SERVER=https://logs.opendaylight.org
NEXUS_URL=https://nexus.opendaylight.org
SILO=releng
```

## Deploying ci-jobs

The CI job group contains multiple jobs that should be deployed in all LF
Jenkins infra. The minimal configuration needed to deploy the ci-management
jobs is as follows which deploys the **{project-name}-ci-jobs** job group as
defined in **lf-ci-jobs.yaml**.

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

**project**: is the project repo as defined in Gerrit.
**project-name**: is a custom name to call the job in Jenkins.
**build-node**: is the name of the builder to use when building (Jenkins label).

Optional parameters:

**branch**: is the git branch to build from.
**jjb-version**: is the version of JJB to install in the build minion.
