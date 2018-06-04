# Global JJB

The purpose of this repository is store generically defined, reusable JJB
templates, deployable across LF projects.

Define the following variables in the Jenkins server as
global environment variables as scripts in this repo expect these variables to
be available.

For example:

```
GERRIT_URL=https://git.opendaylight.org/gerrit
GIT_URL=ssh://jenkins-$SILO@git.opendaylight.org:29418
GIT_CLONE_URL=git@github.com:
JENKINS_HOSTNAME=jenkins092
LOGS_SERVER=https://logs.opendaylight.org
NEXUS_URL=https://nexus.opendaylight.org
SILO=releng
SONAR_URL=https://sonar.opendaylight.org
```

Note: Use **GIT_CLONE_URL** for GitHub projects as this
will be different from the URL used the poperties
configuration.

## Jenkins Plugin Requirements

**Required**

- [Config File Provider](https://plugins.jenkins.io/config-file-provider)
- [Description Setter](https://plugins.jenkins.io/description-setter)
- [Environment Injector Plugin](https://plugins.jenkins.io/envinject)
- [Git plugin](https://plugins.jenkins.io/git)
- [Post Build Script](https://plugins.jenkins.io/postbuildscript)
- [SSH Agent](https://plugins.jenkins.io/ssh-agent)
- [Workspace Cleanup](https://plugins.jenkins.io/ws-cleanup)

**Required for Gerrit connected systems**

- [Gerrit Trigger](https://plugins.jenkins.io/gerrit-trigger)

**Required for GitHub connected systems**

- [GitHub plugin](https://plugins.jenkins.io/github)
- [GitHub Pull Request Builder](https://plugins.jenkins.io/ghprb)

**Optional**

- [Mask Passwords](https://plugins.jenkins.io/mask-passwords)
- [MsgInject](https://plugins.jenkins.io/msginject)
- [OpenStack Cloud](https://plugins.jenkins.io/openstack-cloud)
- [Timestamps](https://plugins.jenkins.io/timestamper)

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

    # For production deployments:
    git submodule add https://github.com/lfit/releng-global-jjb global-jjb
    # For test deployments comment the above and uncomment the below
    # git submodule add https://gerrit.linuxfoundation.org/infra/releng/global-jjb

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

Configure the following parameters in the ci-management repo's
defaults.yaml file.

**gerrit-server-name**: The name of the Gerrit Server as defined
in Gerrit Trigger global configuration.

**jenkins-ssh-credential**: The name of the Jenkins Credential to
use for ssh connections.

If you are using GitHub then configure the following parameters
in defaults.yaml

**git-url**: Set this to the base URL of your GitHub repo. In
general this should be <https://github.com>. If you are using
GitHub Enterprise, or some other GitHub-style system, then it
should be whatever your installation base URL is.

**git-clone-url**: This is the clone prefix used by GitHub jobs.
Set this to either the same thing as **git-url** or the
'git@github.com:' including the trailing ':'

**github-org**: The name of the GitHub organization interpolated
into the scm config.

**github_pr_org**: The name of the GitHub organization. All members
of this organization will be able to trigger any job using the
`lf-infra-github-pr` macro.

**github_pr_whitelist**: List of GitHub members you wish to be able to
trigger any job that uses the `lf-infra-github-pr-trigger` macro.

**github_pr_admin_list**: List of GitHub members that will have admin
privileges on any job using the `lf-infra-github-pr-trigger`
macro.

**lftools-version**: Version of lftools to install. Can be a specific version
like '0.6.1' or a PEP-440 definition. <https://www.python.org/dev/peps/pep-0440/>
For example `<1.0.0` or `>=1.0.0,<2.0.0`.

**mvn-site-id**: Maven Server ID from settings.xml containing the credentials
to push to a Maven site repository.

**mvn-staging-id**: Maven Server ID from settings.xml containing the credentials
to push to a Maven staging repository.

defaults.yaml:

```
- defaults:
    name: global

    # lf-infra defaults
    jenkins-ssh-credential: opendaylight-jenkins-ssh
    gerrit-server-name: OpenDaylight
    github-org: lfit
    github_pr_whitelist:
      - jpwku
      - tykeal
      - zxiiro
    github_pr_admin_list:
      - tykeal
    lftools-version: '<1.0.0'
    mvn-site-id: opendaylight-site
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

## Deploying packer-jobs

The packer job group contains jobs to build custom minion images. The minimal
configuration needed to deploy the packer jobs is as follows which deploys the
**{project-name}-packer-jobs** job group as defined in **lf-ci-jobs.yaml**.

ci-management.yaml:

```
- project:
    name: packer-jobs

    jobs:
      - '{project-name}-packer-jobs'

    project: ci-management
    project-name: ci-management
    branch: master
    build-node: centos7-basebuild-2c-1g

    platforms:
      - centos
      - ubuntu-14.04
      - ubuntu-16.04

    templates:
      - devstack
      - docker
      - gbp
      - java-builder
      - mininet

    exclude:
      - platforms: centos
        templates: gbp
      - platforms: centos
        templates: mininet
```

Required parameters:

**project**: is the project repo as defined in source control.
**project-name**: is a custom name to call the job in Jenkins.
**build-node**: is the name of the builder to use when building (Jenkins label).
**platforms**: is a list of supported platforms.
**templates**: is a list of supported templates.

Optional parameters:

**branch**: is the git branch to build from.
**packer-version**: is the version of packer to install in the build minion,
when packer is not available.
**exclude**: is a combination of platforms and templates which are not required
to build.

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

## Overriding merge and verify triggers

The default trigger conditions for Merge and Verify job types are overrideable
in a project configuration by overriding the following variables:

- gerrit_merge_triggers
- gerrit_verify_triggers

These variables take a list of trigger-on values as defined in JJB docs here:
<https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit>

## Appendix

### ShellCheck

When using ShellCheck to lint global-jjb or any projects that include
global-jjb as part of their project (common with ci-management repos) then
we require version 0.4.x of ShellCheck installed on the build vms. This version
introduces annotations used by shell scripts in this repo.
