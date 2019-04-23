#######
CI Jobs
#######

Job Groups
==========

.. include:: ../job-groups.rst

Below is a list of CI job groups:

.. literalinclude:: ../../jjb/lf-ci-job-groups.yaml
   :language: yaml


Macros
======

lf-infra-jjb-parameters
-----------------------

:Required Parameters:

    :jjb-cache: Location of Jenkins Job Builder (JJB) cache used for jjb
        jobs.
    :jjb-version: Version of Jenkins Job Builder (JJB) to install and use in
        the jjb jobs.

lf-jenkins-cfg-clouds
---------------------

Deploys Jenkins Cloud configuration read from the ``jenkins-clouds`` directory
in ci-management repositories.

.. note::

   Requires the jjbini file in Jenkins CFP to contain JJB 2.0 style
   config definitions for "production" and "sandbox" systems.

:Required Parameters:

    :jenkins-silos: Space-separated list of Jenkins silos to update
        configuration for as defined in ~/.config/jenkins_jobs/jenkins_jobs.ini

lf-jenkins-cfg-global-vars
--------------------------

Manages the Global Jenkins variables. This macro will clear all exist macros
in Jenkins and replaces them with the ones defined by the
ci-management/jenkins-config/global-vars-SILO.sh script.

.. note::

   Requires the jjbini file in Jenkins CFP to contain JJB 2.0 style
   config definitions for "production" and "sandbox" systems.

:Required parameters:

    :jenkins-silos: Space-separated list of Jenkins silos to update
        configuration for as defined in ~/.config/jenkins_jobs/jenkins_jobs.ini

lf-infra-jjbini
---------------

Provides jenkins_jobs.ini configuration for Jenkins.

lf-infra-jjbini-sandbox
-----------------------

Provides jenkins_jobs.ini configuration for Jenkins sandbox.

.. todo:: This needs to be consolidated into lf-infra-jjbini when JJB 2.0 is available

lf-packer-common
----------------

Common packer configuration.

lf-packer-file-paths
--------------------

Gerrit file-paths for packer jobs.

lf-packer-parameters
--------------------

Parameters useful for packer related tasks.

:Parameters:

    :packer-version: Version of packer to install / use.
        (shell: PACKER_VERSION)

lf-packer-verify-file-paths
---------------------------

Gerrit file-paths for packer verify jobs.

lf-puppet-parameters
--------------------

Parameters useful for Puppet related tasks.

:Parameters:

    :puppet-lint-version: Version of puppet-lint to install / use.
        (shell: PUPPET_LINT_VERSION)

Job Templates
=============

.. _gerrit-branch-lock:

Gerrit Branch Lock
------------------

Job submits a patch to lock or unlock a project's branch.

:Template Names:
    - {project-name}-gerrit-branch-lock-{stream}
    - gerrit-branch-lock

:Comment Trigger:

    * lock branch
    * unlock branch

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally
        should be configured in defaults.yaml)

:Optional parameters:

    :branch: Git branch to build against. (default: master)
    :git-url: URL to clone project from. (default: $GIT_URL/$GERRIT_PROJECT)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :gerrit_merge_triggers: Override Gerrit Triggers.

.. _lf-global-jjb-jenkins-cfg-merge:

Jenkins Configuration Merge
---------------------------

Jenkins job to manage Global Jenkins configuration.

.. note::

   Requires the jjbini file in Jenkins CFP to contain JJB 2.0 style
   config definitions for "production" and "sandbox" systems.

:Template names:

    - {project-name}-jenkins-cfg-merge
    - gerrit-jenkins-cfg-merge
    - github-jenkins-cfg-merge

:Optional parameters:

    :branch: Git branch to build against. (default: master)
    :cron: How often to run the job on a cron schedule. (default: @daily)
    :git-url: URL to clone project from. (default: $GIT_URL/$GERRIT_PROJECT)
    :jenkins-silos: Space separated list of Jenkins silos to update
        configuration for as defined in ~/.config/jenkins_jobs/jenkins_jobs.ini
        (default: production sandbox)

Typically this template is automatically pulled in by the
"{project-name}-ci-jobs" job-group and does not need to be explicitly called if
the job group is being used.

Minimal Example:

.. literalinclude:: ../../.jjb-test/lf-ci-jobs/jenkins-cfg-merge-minimal.yaml
   :language: yaml

Full Example:

.. literalinclude:: ../../.jjb-test/lf-ci-jobs/jenkins-cfg-merge-full.yaml
   :language: yaml

.. _jenkins-cfg-envvar:

Global Environment Variables
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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

Cloud Configuration
^^^^^^^^^^^^^^^^^^^

This configuration requires the OpenStack Cloud plugin in Jenkins and is
currently the only cloud plugin supported.

OpenStack Cloud plugin version supported:

* 2.30 - 2.34
* 2.35 - 2.37

Cloud configuration are managed via a directory structure in ci-management as
follows:

- jenkins-config/clouds/openstack/
- jenkins-config/clouds/openstack/cattle/cloud.cfg
- jenkins-config/clouds/openstack/cattle/centos7-builder-2c-2g.cfg
- jenkins-config/clouds/openstack/cattle/centos7-builder-4c-4g.cfg
- jenkins-config/clouds/openstack/cattle/centos7-docker-4c-4g.cfg

The directory name inside of the "openstack" directory is used as the name of
the cloud configuration. In this case "cattle" is being used as the cloud name.

The ``cloud.cfg`` file is a special file used to configure the main cloud
configuration in the format ``KEY=value``.

:Cloud Parameters:

    :CLOUD_URL: API endpoint URL for Keystone.
        (default: "")
    :CLOUD_IGNORE_SSL: Ignore unverified SSL certificates. (default: false)
    :CLOUD_ZONE: OpenStack region to use. (default: "")
    :CLOUD_CREDENTIAL_ID: Credential to use for authentication to OpenStack.
        (default: "os-cloud")
    :INSTANCE_CAP: Total number of instances the cloud will allow spin up.
        (default: null)
    :SANDBOX_CAP: Total number of instances the cloud will allow to
        spin up. This applies to "sandbox" systems and overrides the
        INSTANCE_CAP setting. (default: null)

:Template Parameters:

    .. note::

       In the case of template definitions of a parameter below is not passed
       the one defined in default clouds will be inherited.

    :IMAGE_NAME: The image name to use for this template.
        (required)
    :HARDWARE_ID: OpenStack flavor to use. (required)

    :LABELS: Labels to assign to the vm. (default: FILE_NAME)
    :NETWORK_ID: OpenStack network to use. (default: "")
    :USER_DATA_ID: User Data to pass into the instance.
        (default: jenkins-init-script)
    :INSTANCE_CAP: Total number of instances of this type that can be launched
        at one time. When defined in clouds.cfg it defines the total for the
        entire cloud. (default: null)
    :SANDBOX_CAP: Total number of instances of this type that can be launched
        at one time. When defined in clouds.cfg it defines the total for the
        entire cloud. This applies to "sandbox" systems and overrides the
        INSTANCE_CAP setting. (default: null)
    :FLOATING_IP_POOL: Floating ip pool to use. (default: "")
    :SECURITY_GROUPS: Security group to use. (default: "default")
    :AVAILABILITY_ZONE: OpenStack availability zone to use. (default: "")
    :START_TIMEOUT: Number of milliseconds to wait for the agent to be
        provisioned and connected. (default: 600000)
    :KEY_PAIR_NAME: SSH Public Key Pair to use for authentication.
        (default: jenkins)
    :NUM_EXECUTORS: Number of executors to enable for the instance.
        (default: 1)
    :JVM_OPTIONS: JVM Options to pass to Java. (default: "")
    :FS_ROOT: File system root for the workspace. (default: "/w")
    :RETENTION_TIME: Number of minutes to wait for an idle slave to be used
        again before it's removed. If set to -1, the slave will be kept
        forever. (default: 0)
    :CONNECTION_TYPE: The connection type for Jenkins to connect to the build
        minion. Valid options: JNLP, SSH. (default: "SSH")

For a live example see the OpenDaylight project jenkins-config directory.
https://github.com/opendaylight/releng-builder/tree/master/jenkins-config

Troubleshooting
^^^^^^^^^^^^^^^

:Cloud Configuration:

    The directory ``groovy-inserts`` contains the groovy script output that is
    used to push to Jenkins. In the event of a job failure this file can be
    inspected.

 .. _lf-global-jjb-jenkins-cfg-verify:

Jenkins Configuration Verify
----------------------------

Jenkins job to verify the Global Jenkins configuration.

Requires the ``clouds-yaml`` file to be setup on the Jenkins host.

:Template names:

    - {project-name}-jenkins-cfg-verify
    - gerrit-jenkins-cfg-verify
    - github-jenkins-cfg-verify

:Optional parameters:

    :branch: Git branch to build against. (default: master)
    :git-url: URL to clone project from. (default: $GIT_URL/$GERRIT_PROJECT)

This job is not part of the "{project-name}-ci-jobs" group. It must be called
explicitly.

Example:

.. literalinclude:: ../../.jjb-test/lf-ci-jobs/jenkins-cfg-verify.yaml
   :language: yaml


.. _jenkins-sandbox-cleanup:

Jenkins Sandbox Cleanup
-----------------------

Cleanup Jenkins Sandbox of jobs and views periodically.

:Template names:

    - {project-name}-jenkins-sandbox-cleanup
    - gerrit-jenkins-sandbox-cleanup
    - github-jenkins-sandbox-cleanup

:Comment Trigger: NONE

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally
        should be configured in defaults.yaml)

:Optional parameters:

    :cron: Schedule to run job. (default: '0 8 * * 6')


.. _jjb-deploy:

JJB Deploy Job
--------------

Deploy jobs to jenkins-sandbox system via code review comment.

This job checks out the current code review patch and then runs a
``jenkins-jobs update`` to push a patch defined by the comment.

:Template names:

    - {project-name}-jjb-deploy-job
    - gerrit-jjb-deploy-job
    - github-jjb-deploy-job

:Comment Trigger: jjb-deploy JOB_NAME

    .. note::

       The JJB Deploy Job is configured to trigger only if the Gerrit comment
       starts with the `jjb-deploy` keyword.

       Example of a valid command in Gerrit comment that triggers the job:

       ``jjb-deploy builder-jjb-*``

       Example of a invalid command in Gerrit comment that would _not_ trigger
       the job:

       ``Update the job. jjb-deploy builder-jjb-*``

       JOB_NAME can include the * wildcard character to push multiple jobs
       matching the pattern. For example ``jjb-deploy builder-jjb-*`` will push
       all builder-jjb-* jobs to the sandbox system.

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally
        should be configured in defaults.yaml)

:Optional parameters:

    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :gerrit_jjb_deploy_job_triggers: Override Gerrit Triggers.


.. _jjb-merge:

JJB Merge
---------

Runs `jenkins-jobs update` to update production job configuration

:Template Names:
    - {project-name}-jjb-merge
    - gerrit-jjb-merge
    - github-jjb-merge

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :jjb-cache: JJB cache location. (default: $HOME/.cache/jenkins_jobs)
    :jjb-workers: Number of threads to run **update** with. Set to 0 by default
        which is equivalent to the number of available CPU cores. (default: 0)
    :jjb-version: JJB version to install. (default: see job-template)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.
        (default defined by lf_jjb_common)


.. _jjb-verify:

JJB Verify
----------

Runs `jenkins-jobs test` to validate JJB syntax

:Template Names:
    - {project-name}-jjb-verify
    - gerrit-jjb-verify
    - github-jjb-verify

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-concurrent: Whether or not to allow this job to run multiple jobs
        simultaneously. (default: true)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :jjb-cache: JJB cache location. (default: $HOME/.cache/jenkins_jobs)
    :jjb-version: JJB version to install. (default: see job-template)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :throttle_categories: List of categories to throttle by.
    :throttle-enabled: Whether or not to enable throttling on the job.
        (default: true)
    :throttle-max-per-node: Max jobs to run on the same node. (default: 1)
    :throttle-max-total: Max jobs to run across the entire project. - 0
        means 'unlimited' (default: 0)
    :throttle-option: Throttle by the project or by list of categories
        defined in the throttle plugin configuration. (options: 'project',
        'category'; default: project)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.
        (default defined by lf_jjb_common)

.. _jjb-verify-upstream-gjjb:

JJB Verify Upstream Global JJB
------------------------------

Runs ``jenkins-jobs test`` to validate JJB syntax for upstream global-jjb
patches. This job is useful to notify upstream that they may be breaking
project level jobs.

:Template Names:
    - {project-name}-jjb-verify-upstream-gjjb
    - gerrit-jjb-verify-upstream-gjjb

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :jjb-cache: JJB cache location. (default: $HOME/.cache/jenkins_jobs)
    :jjb-version: JJB version to install. (default: see job-template)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)

.. _info-yaml-verify:

Info YAML Verify
----------------

Info YAML Verify job validates that INFO.yaml file changes are kept isolated from
other file changes. Verifies INFO.yaml files follow the schema defined in
`global-jjb/info-schema`.

:Template Names:
    - {project-name}-info-yaml-verify
    - gerrit-info-yaml-verify
    - github-info-yaml-verify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_verify_triggers: Override Gerrit Triggers.

.. _license-checker:

License Checker
---------------

Job to scan projects for files missing license headers.

:Template Names:
    - {project-name}-license-check
    - gerrit-license-check
    - github-license-check

:Optional parameters:

    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :file-patterns: Space-separated list of file patterns to scan.
        (default: \*.go \*.groovy \*.java \*.py \*.sh)
    :spdx-disable: Disable the SPDX-Identifier checker. (default: false)
    :lhc-version: Version of LHC to use. (default: 0.2.0)
    :license-exclude-paths: Comma-separated list of paths to exclude from the
        license checker. The paths used here will be matched using a contains
        rule so it is best to be as precise with the path as possible.
        For example a path of '/src/generated/' will be searched as
        '**/src/generated/**'.
        Example: org/opendaylight/yang/gen,protobuff/messages
        (default: '')
    :licenses-allowed: Comma-separated list of allowed licenses.
        (default: Apache-2.0,EPL-1.0,MIT)
    :project-pattern: The ANT based pattern for Gerrit Trigger to choose which
        projects to trigger job against. (default: '**')

.. _gjjb-openstack-cron:

OpenStack Cron
--------------

Cron job that runs regularly to perform periodic tasks against OpenStack.

This job requires a Config File Provider file named ``clouds-yaml`` available
containing the credentials for the cloud.

:Template Names:
    - {project-name}-openstack-cron
    - gerrit-openstack-cron
    - github-openstack-cron

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :jenkins-urls: URLs to Jenkins systems to check for active builds.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 90)
    :cron: Time when the packer image should be rebuilt (default: @hourly)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :openstack-cloud: OS_CLOUD setting to pass to openstack client.
        (default: vex)
    :openstack-image-cleanup: Whether or not to run the image cleanup script.
        (default: true)
    :openstack-image-cleanup-age: Age in days of image before marking it for
        removal. (default: 30)
    :openstack-image-protect: Whether or not to run the image protect script.
        (default: true)
    :openstack-server-cleanup: Whether or not to run the server cleanup script.
        (default: true)
    :openstack-stack-cleanup: Whether or not to run the stack cleanup script.
        (default: true)
    :openstack-volume-cleanup: Whether or not to run the volume cleanup script.
        (default: true)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

Minimal Example:

.. literalinclude:: ../../.jjb-test/lf-ci-jobs/openstack-cron-minimal.yaml

Full Example:

.. literalinclude:: ../../.jjb-test/lf-ci-jobs/openstack-cron-full.yaml


.. _gjjb-packer-merge:

Packer Merge
------------

Packer Merge job runs `packer build` to build system images in the cloud.

:Template Names:
    - {project-name}-packer-merge-{platforms}-{templates}
    - gerrit-packer-merge
    - github-packer-merge

:Comment Trigger: remerge

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

    :cron: Time when the packer image should be rebuilt (default: @monthly)
    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 90)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :openstack: Packer template uses an OpenStack builder (default: true).
    :openstack-cloud: Sets OS_CLOUD variable to the value of this parameter.
        (default: vex).
    :packer-cloud-settings: Name of settings file containing credentials
        for the cloud that packer will build on. (default: packer-cloud-env)
    :packer-version: Version of packer to install / use in build. (default: 1.0.2)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_verify_triggers: Override Gerrit Triggers.

Test an in-progress patch
^^^^^^^^^^^^^^^^^^^^^^^^^

To test an in-progress patch from a GitHub Pull Request. Upload this
job to the :doc:`Jenkins Sandbox <lfdocs:jenkins-sandbox>`. Then when manually
building the job replace the GERRIT_REFSPEC parameter with the GitHub Pull
Request number of the patch you would like to test.

Example GitHub:

.. code-block:: none

   GERRIT_REFSPEC: origin/pr/49/merge

.. _gjjb-packer-verify:

Packer Verify
-------------

Packer Verify job runs `packer validate` to verify packer configuration.

:Template Names:
    - {project-name}-packer-verify
    - gerrit-packer-verify
    - github-packer-verify

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for
        the project.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :openstack: Packer template uses an OpenStack builder (default: true).
    :openstack-cloud: Sets OS_CLOUD variable to the value of this parameter.
        (default: vex).
    :packer-cloud-settings: Name of settings file containing credentials
        for the cloud that packer will build on. (default: packer-cloud-env)
    :packer-version: Version of packer to install / use in build. (default: 1.0.2)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.


Puppet Verify
-------------

Runs puppet-lint in the ``puppet-dir`` directory. puppet-lint runs recursively,
the base directory is usually the best place to run from.

:Template Names:

    - {project-name}-puppet-verify
    - gerrit-puppet-verify
    - github-puppet-verify

:Comment Trigger: recheck|reverify

:Required Parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional Parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :gerrit_trigger_file_paths: Override file paths which used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit
    :git-url: URL clone project from. (default: $GIT_URL/$GERRIT_PROJECT)
    :puppet-dir: Directory containing the project's puppet module(s) relative
        to the workspace.
        (default: '')
    :puppet-lint-version: Version of puppet-lint to use for testing.
        (default: 2.3.6)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
