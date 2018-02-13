#######
CI Jobs
#######

Job Groups
==========

{project-name}-ci-jobs
----------------------

Recommended jobs that should be deployed for CI using Gerrit.

:Includes:

    - gerrit-jenkins-cfg-merge
    - gerrit-jjb-deploy-job
    - gerrit-jjb-merge
    - gerrit-jjb-verify

{project-name}-github-ci-jobs
-----------------------------

Recommended jobs that should be deployed CI using GitHub.

:Includes:

    - github-jenkins-cfg-merge
    - github-jjb-deploy-job
    - github-jjb-merge
    - github-jjb-verify

{project-name}-packer-jobs
--------------------------

Jobs related to Packer builds for CI using Gerrit.

:Includes:

    - gerrit-packer-merge
    - gerrit-packer-verify

{project-name}-github-packer-jobs
---------------------------------

Jobs related to Packer builds for CI using GitHub.

:Includes:

    - github-packer-merge
    - github-packer-verify

Macros
======

lf-jenkins-cfg-global-vars
--------------------------

Manages the Global Jenkins variables. This macro will clear all exist macros
in Jenkins and replaces them with the ones defined by the
ci-management/jenkins-config/global-vars-SILO.sh script.

.. note::

   Requires the jjbini file in Jenkins CFP to contain JJB 2.0 style
   config definitions for "production" and "sandbox" systems.

:Required parameters:

    :jenkins-silos: Space separated list of Jenkins silos to update
        configuration for as defined in ~/.config/jenkins_jobs/jenkins_jobs.ini

lf-infra-jjbini
---------------

Provides jenkins_jobs.ini configuration for Jenkins.

lf-infra-jjbini-sandbox
-----------------------

Provides jenkins_jobs.ini configuration for Jenkins sandbox.

.. todo:: This needs to be consolidated into lf-infra-jjbini when JJB 2.0 is available

lf-packer-verify-file-paths
---------------------------

Gerrit file-paths for packer verify jobs.

lf-packer-file-paths
--------------------

Gerrit file-paths for packer jobs.

lf-packer-common
----------------

Common packer configuration.

Job Templates
=============

Gerrit Branch Lock
------------------

Job submits a patch to lock or unlock a project's branch.

:Template Names:
    - {project-name}-gerrit-branch-lock-{stream}
    - gerrit-branch-lock


Jenkins Configuration Merge
---------------------------

Jenkins job to manage Global Jenkins configuration.

Global Environment Variables are managed via the
``jenkins-config/global-vars-SILO.sh`` file in ci-management. Replace SILO with
the name of the Jenkins silo the variable configuration is for.

The format for this file is ``KEY=value`` for example::

    GERRIT_URL=https://git.opendaylight.org/gerrit
    GIT_BASE=git://devvexx.opendaylight.org/mirror/$PROJECT
    GIT_URL=git://devvexx.opendaylight.org/mirror
    JENKINS_HOSTNAME=vex-yul-odl-jenkins-2
    LOGS_SERVER=https://logs.opendaylight.org
    NEXUS_URL=https://nexus.opendaylight.org
    ODLNEXUSPROXY=https://nexus.opendaylight.org
    SILO=sandbox
    SONAR_URL=https://sonar.opendaylight.org

.. note::

   Requires the jjbini file in Jenkins CFP to contain JJB 2.0 style
   config definitions for "production" and "sandbox" systems.

:Template names:

    - {project-name}-jenkins-cfg-merge
    - gerrit-jenkins-cfg-merge
    - github-jenkins-cfg-merge

:Optional parameters:

    :git-url: URL to clone project from. (default: $GIT_URL/$GERRIT_PROJECT)
    :jenkins-silos: Space separated list of Jenkins silos to update
        configuration for as defined in ~/.config/jenkins_jobs/jenkins_jobs.ini
        (default: production sandbox)

Typically this template is automatically pulled in by the
"{project-name}-ci-jobs" job-group and does not need to be explicitly called if
the job group is being used.

Miniaml Example:

.. literalinclude:: ../../.jjb-test/lf-ci-jobs/jenkins-cfg-merge-minimal.yaml
   :language: yaml

Full Example:

.. literalinclude:: ../../.jjb-test/lf-ci-jobs/jenkins-cfg-merge-full.yaml
   :language: yaml


JJB Deploy Job
--------------

Deploy jobs to jenkins-sandbox system via code review comment

This job checks out the current code review patch and then runs a
`jenkins-jobs update` to push a patch defined by the comment.

:Template names:

    - {project-name}-jjb-deploy-job
    - gerrit-jjb-deploy-job
    - github-jjb-deploy-job

:Comment Trigger: jjb-deploy JOB_NAME

    .. note::

       JOB_NAME can include the * wildcard character to push multiple jobs
       matching the pattern. For example `jjb-deploy builder-jjb-*`` will push
       all builder-jjb-* jobs to the sandbox system.

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally
        should be configured in defaults.yaml)

:Optional parameters:

    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :gerrit_jjb_deploy_job_triggers: Override Gerrit Triggers.


JJB Merge
---------

Runs `jenkins-jobs update` to update production job configuration

:Template Names:
    - {project-name}-jjb-merge
    - gerrit-jjb-merge
    - github-jjb-merge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for
        the project.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in seconds before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.
        (default defined by lf_jjb_common)


JJB Verify
----------

Runs `jenkins-jobs test` to validate JJB syntax

:Template Names:
    - {project-name}-jjb-verify
    - gerrit-jjb-verify
    - github-jjb-verify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for
        the project.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in seconds before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.
        (default defined by lf_jjb_common)


Packer Merge
------------

Packer Merge job runs `packer build` to build system images in the cloud.

:Template Names:
    - {project-name}-packer-merge-{platforms}-{templates}
    - gerrit-packer-merge
    - github-packer-merge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for
        the project.
    :platforms: Platform or distribution to build. Typically json file
        found in the packer/vars directory. (Example: centos)
    :template: System template to build. Typically shell script found in
        the packer/provision directory. (Example: java-builder)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in seconds before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :packer-cloud-settings: Name of settings file containing credentials
        for the cloud that packer will build on. (default: packer-cloud-env)
    :packer-version: Version of packer to install / use in build. (default: 1.0.2)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_verify_triggers: Override Gerrit Triggers.


Packer Verify
-------------

Packer Verify job runs `packer validate` to verify packer configuration.

:Template Names:
    - {project-name}-packer-verify
    - gerrit-packer-verify
    - github-packer-verify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for
        the project.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in seconds before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :packer-cloud-settings: Name of settings file containing credentials
        for the cloud that packer will build on. (default: packer-cloud-env)
    :packer-version: Version of packer to install / use in build. (default: 1.0.2)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.
