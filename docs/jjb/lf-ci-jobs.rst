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

This job will process lock/unlock requests for all projects and all branches
and does not need to have per-project configuration.

:Template Names:
    - {project-name}-gerrit-branch-lock
    - gerrit-branch-lock

:Comment Trigger:

    * lock branch
    * unlock branch

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)

:Optional parameters:

    :git-url: URL to clone project from. (default: $GIT_URL/$GERRIT_PROJECT)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
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
you are already using the job group.

Minimal Example:

.. literalinclude:: ../../.jjb-test/lf-ci-jobs/jenkins-cfg-merge-minimal.yaml
   :language: yaml

Full Example:

.. literalinclude:: ../../.jjb-test/lf-ci-jobs/jenkins-cfg-merge-full.yaml
   :language: yaml

.. _jenkins-cfg-envvar:

Global Environment Variables
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Manage Global Environment Variables via the
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

This configuration requires the **OpenStack Cloud plugin** in Jenkins.

OpenStack Cloud plugin version supported:

* 2.30 - 2.34
* 2.35 - 2.37

Cloud configuration follows a directory structure in ci-management like this:

- jenkins-config/clouds/openstack/
- jenkins-config/clouds/openstack/**cattle**/cloud.cfg
- jenkins-config/clouds/openstack/**cattle**/centos7-builder-2c-2g.cfg
- jenkins-config/clouds/openstack/**cattle**/centos7-builder-4c-4g.cfg
- jenkins-config/clouds/openstack/**cattle**/centos7-docker-4c-4g.cfg

This job uses the directory name of the directory inside of the "openstack"
directory as the name of the cloud configuration in Jenkins. This is to support
systems that want to use more than one cloud provider. In this example "cattle"
is the cloud name.

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

        Parameters below that are not defined will inherit the ones defined in
        the default clouds configuration.

    :IMAGE_NAME: The image name to use for this template. (required)
    :HARDWARE_ID: OpenStack flavor to use. (required)

    :LABELS: Labels to assign to the vm. (default: FILE_NAME)
    :VOLUME_SIZE: Volume size to assign to vm. (default: "")
    :HARDWARE_ID: Hardware Id to assign to vm. (default: "")
    :NETWORK_ID: OpenStack network to use. (default: "")
    :USER_DATA_ID: User Data to pass into the instance.
        (default: jenkins-init-script)
    :INSTANCE_CAP: Total number of instances of this type that is available for
        use at one time. When defined in clouds.cfg it defines the total for
        the entire cloud. (default: null)
    :SANDBOX_CAP: Total number of instances of this type that is available for
        use at one time. When defined in clouds.cfg it defines the total for
        the entire cloud. This applies to "sandbox" systems and overrides the
        INSTANCE_CAP setting. (default: null)
    :FLOATING_IP_POOL: Floating ip pool to use. (default: "")
    :SECURITY_GROUPS: Security group to use. (default: "default")
    :AVAILABILITY_ZONE: OpenStack availability zone to use. (default: "")
    :START_TIMEOUT: Number of milliseconds to wait for agent provisioning.
        (default: 600000)
    :KEY_PAIR_NAME: SSH Public Key Pair to use for authentication.
        (default: jenkins-ssh)
    :NUM_EXECUTORS: Number of executors to enable for the instance.
        (default: 1)
    :JVM_OPTIONS: JVM Options to pass to Java. (default: null)
    :FS_ROOT: File system root for the workspace. (default: "/w")
    :NODE_PROPERTIES: Node properties. (default: null)
    :RETENTION_TIME: Number of minutes to wait for an idle minion before
        removing it from the system. If set to -1, the minion will stick around
        forever. (default: 0)
    :CONNECTION_TYPE: The connection type for Jenkins to connect to the build
        minion. Valid options: JNLP, SSH. (default: "SSH")
    :CONFIG_TYPE: Configuration drive. (default: null)

For a live example see the OpenDaylight project jenkins-config directory.
https://github.com/opendaylight/releng-builder/tree/master/jenkins-config

Troubleshooting
^^^^^^^^^^^^^^^

:Cloud Configuration:

    The directory ``groovy-inserts`` contains the groovy script output used by
    Jenkins to push the cloud configuration. In the event of a job failure use
    this file to debug.


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

This job is not part of the "{project-name}-ci-jobs" group and requires
separate configuration.

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
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)

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

        The JJB Deploy Job is a manual job and triggers via Gerrit comment
        which starts with the ``jjb-deploy`` keyword.

        Example of a valid command in Gerrit comment that triggers the job:

        ``jjb-deploy builder-jjb-*``

        Example of a invalid command in Gerrit comment that would _not_ trigger
        the job:

        ``Update the job. jjb-deploy builder-jjb-*``

        JOB_NAME can include the ``*`` wildcard character to push jobs matching
        the pattern. For example ``jjb-deploy builder-jjb-*`` will push all
        builder-jjb-* jobs to the sandbox system.

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)

:Optional parameters:

    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :gerrit_jjb_deploy_job_triggers: Override Gerrit Triggers.


.. _jjb-merge:

JJB Merge
---------

Runs ``jenkins-jobs update`` to update production job configuration

:Template Names:
    - {project-name}-jjb-merge
    - gerrit-jjb-merge
    - github-jjb-merge

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :jjb-cache: JJB cache location. (default: $HOME/.cache/jenkins_jobs)
    :jjb-workers: Number of threads to run **update** with. Set to 0 by default
        which will use the number of available CPU cores. (default: 0)
    :jjb-version: JJB version to install. (default: see job-template)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths to filter which file
        modifications will trigger a build.
        (default defined by lf_jjb_common)


.. _jjb-verify:

JJB Verify
----------

Runs ``jenkins-jobs test`` to verify JJB syntax. Optionally verifies
build-node labels used in templates and job definitions.

:Template Names:
    - {project-name}-jjb-verify
    - gerrit-jjb-verify
    - github-jjb-verify

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-concurrent: Set to ``true`` to allow this job to run jobs
        simultaneously. (default: true)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-node-label-check: Whether to check build-node labels in jobs
        against node names in cloud config files (default: false)
    :build-node-label-list: Space-separated list of external build-node
        labels not present in cloud config files (default: "")
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :jjb-cache: JJB cache location. (default: $HOME/.cache/jenkins_jobs)
    :jjb-version: JJB version to install. (default: see job-template)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Set to ``true`` to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :throttle_categories: List of categories to throttle by.
    :throttle-enabled: Set to ``true`` to enable throttling on the job.
        (default: true)
    :throttle-max-per-node: Max jobs to run on the same node. (default: 1)
    :throttle-max-total: Max jobs to run across the entire project. - 0
        means 'unlimited' (default: 0)
    :throttle-option: Throttle by the project or by list of categories
        defined in the throttle plugin configuration. (options: 'project',
        'category'; default: project)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths to filter which file
        modifications will trigger a build.
        (default defined by lf_jjb_common)

.. _jjb-verify-upstream-gjjb:

JJB Verify Upstream Global JJB
------------------------------

Runs ``jenkins-jobs test`` to verify JJB syntax for upstream global-jjb
patches. This job is useful to notify upstream that they may be breaking
project level jobs.

:Template Names:
    - {project-name}-jjb-verify-upstream-gjjb
    - gerrit-jjb-verify-upstream-gjjb
    - github-jjb-verify-upstream-gjjb

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :jjb-cache: JJB cache location. (default: $HOME/.cache/jenkins_jobs)
    :jjb-version: JJB version to install. (default: see job-template)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)

.. _info-yaml-verify:

Info YAML Verify
----------------

This job verifies that ``INFO.yaml`` file changes follow the schema defined in
`lfit/releng-global-jjb/schema/info-schema.yaml`.

The ``INFO.yaml`` file changes must be independent of any other files changes.

:Template Names:
    - {project-name}-info-yaml-verify
    - gerrit-info-yaml-verify
    - github-info-yaml-verify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_verify_triggers: Override Gerrit Triggers.

.. _lf_pipelines_verify:

LF Pipelines Verify
-------------------

Verify job for the LF RelEng pipeline library.

Requires the Pipelines plugins installed. This job will look for a Gerrit
system named "lf-releng" (mapped to https://gerrit.linuxfoundation.org/infra/),
and pull in the Jenkinsfile in the root directory of the repo.

:Template Names:
    - lf-pipelines-verify

:Comment Trigger: recheck|reverify

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
        license checker. Matches the paths defined here using a contains rule,
        we recommend you to configure as precisely as possible. For example
        a path of '/src/generated/' will search as '**/src/generated/**'.
        Example: org/opendaylight/yang/gen,protobuff/messages
        (default: '')
    :licenses-allowed: Comma-separated list of allowed licenses.
        (default: Apache-2.0,EPL-1.0,MIT)
    :project-pattern: The ANT based pattern for Gerrit Trigger to choose which
        projects to trigger job against. (default: '**')

.. _gjjb-openstack-cron:

OpenStack Cron
--------------

Cron job that runs on a schedule to perform periodic tasks against OpenStack.

This job requires a Config File Provider file named ``clouds-yaml`` available
containing the credentials for the cloud.

:Template Names:
    - {project-name}-openstack-cron
    - gerrit-openstack-cron
    - github-openstack-cron

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)
    :jenkins-urls: URLs to Jenkins systems to check for active builds.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 90)
    :cron: Time when the packer image should be rebuilt (default: @hourly)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :openstack-cloud: OS_CLOUD setting to pass to openstack client.
        (default: vex)
    :openstack-image-cleanup: Set ``true`` to run the image cleanup script.
        (default: true)
    :openstack-image-cleanup-age: Age in days of image before marking it for
        removal. (default: 30)
    :openstack-image-protect: Set ``true`` to run the image protect script.
        (default: true)
    :openstack-server-cleanup: Set ``true`` to run the server cleanup script.
        (default: true)
    :openstack-stack-cleanup: Set ``true`` to run the stack cleanup script.
        (default: true)
    :openstack-volume-cleanup: Set ``true`` to run the volume cleanup script.
        (default: true)
    :stream: Keyword that represents a release code-name.
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

.. _gjjb-openstack-update-cloud-image:

OpenStack Update Cloud Image
----------------------------

This job finds and updates OpenStack cloud images on the ci-management source
repository.

This job functions in 2 ways:

1. When triggered via packer-merge job, updates the image created by the job.
2. When triggered manually or via cron, updates all images.

When triggered through an upstream packer merge job, this generates a change
request for the new image built.

When triggered manually, this job finds the latest images on OpenStack cloud
and compares them with the images in use in the source ci-management source
repository. If the compared images have newer time stamps are **all** updated
through a change request.

This job requires a Jenkins configuration merge and verify job setup and
working on Jenkins.

:Template Names:
    - {project-name}-openstack-update-cloud-image
    - gerrit-openstack-update-cloud-image
    - github-openstack-update-cloud-image

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)
    :new-image-name: Name of new image name passed from packer merge job or
        set to 'all' to update all images. (default: all)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 90)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :openstack-cloud: OS_CLOUD setting to pass to openstack client.
        (default: vex)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :update-cloud-image: Submit a change request to update new built cloud
        image to Jenkins. (default: false)

Minimal Example:

.. literalinclude:: ../../.jjb-test/lf-ci-jobs/openstack-update-cloud-image-minimal.yaml

Full Example:

.. literalinclude:: ../../.jjb-test/lf-ci-jobs/openstack-update-cloud-image-full.yaml


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
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for
        the project.
    :platforms: Platform or distribution to build. Typically json file
        found in the packer/vars directory. (Example: centos-7)
    :templates: System template to build. Typically a yaml file or shell script
        found in the packer/provision directory. (Example: docker)

:Optional parameters:

    :cron: Time when the packer image should be rebuilt (default: @monthly)
    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 90)
    :gerrit_verify_triggers: Override Gerrit Triggers.
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :openstack: Packer template uses an OpenStack builder (default: true).
    :openstack-cloud: Sets OS_CLOUD variable to the value of this parameter.
        (default: vex).
    :packer-cloud-settings: Name of settings file containing credentials
        for the cloud that packer will build on. (default: packer-cloud-env)
    :packer-version: Version of packer to install / use in build. (default: 1.0.2)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :update-cloud-image: Submit a change request to update newly built cloud
        image to Jenkins. (default: false)


Test an in-progress patch
^^^^^^^^^^^^^^^^^^^^^^^^^

To test an in-progress patch from a GitHub Pull Request, upload this
job to the :doc:`Jenkins Sandbox <lfdocs:jenkins-sandbox>`. Then when manually
building the job, replace the GERRIT_REFSPEC parameter with the GitHub Pull
Request number of the patch you would like to test.

Example GitHub:

.. code-block:: none

   GERRIT_REFSPEC: origin/pr/49/merge


.. _gjjb-packer-verify:

Packer Verify
-------------

Packer Verify job runs ``packer validate`` to verify packer configuration. The
verify job checks superficial syntax of the template and other files. It does
not attempt to build an image, and cannot detect all possible build issues.

:Template Names:
    - {project-name}-packer-verify
    - gerrit-packer-verify
    - github-packer-verify

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for
        the project.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :gerrit_trigger_file_paths: Override file paths to filter which file
        modifications will trigger a build.
    :gerrit_verify_triggers: Override Gerrit Triggers.
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :openstack: Packer template uses an OpenStack builder (default: true).
    :openstack-cloud: Sets OS_CLOUD variable to the value of this parameter.
        (default: vex).
    :packer-cloud-settings: Name of settings file containing credentials
        for the cloud that packer will build on. (default: packer-cloud-env)
    :packer-version: Version of packer to install / use in build. (default: 1.0.2)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)


.. _gjjb-packer-verify-build:

Packer Verify Build
-------------------

Packer Verify Build job is essentially the same as the
:ref:`Packer Merge job <gjjb-packer-merge>`. Trigger using its keyword,
and will build a useable image. If the last patch set before a merge has a
successful verify build, the merge job will not build the same image.

:Template Names:
    - {project-name}-packer-verify-build-{platforms}-{templates}
    - gerrit-packer-verify-build
    - github-packer-verify-build

:Comment Trigger: verify-build|packer-build

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in
        defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for
        the project.
    :platforms: Platform or distribution to build. Typically json file
        found in the packer/vars directory. (Example: centos-7)
    :templates: System template to build. Typically a yaml file or shell script
        found in the packer/provision directory. (Example: docker)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :gerrit_trigger_file_paths: Override file paths to filter which file
        modifications will trigger a build.
    :gerrit_verify_triggers: Override Gerrit Triggers.
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :openstack: Packer template uses an OpenStack builder (default: true).
    :openstack-cloud: Sets OS_CLOUD variable to the value of this parameter.
        (default: vex).
    :packer-cloud-settings: Name of settings file containing credentials
        for the cloud that packer will build on. (default: packer-cloud-env)
    :packer-version: Version of packer to install / use in build. (default: 1.0.2)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :update-cloud-image: Submit a change request to update new built cloud
        image to Jenkins. (default: false)


Puppet Verify
-------------

Runs puppet-lint in the ``puppet-dir`` directory. Since ``puppet-lint`` runs
recursively, we recommend to run from the base directory.

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


Sonar
-----

Runs the Jenkins SonarQube Scanner plug-in to analyze code for bugs,
code smells and security vulnerabilities, and to upload the result
(possibly including code-coverage statistics) to a SonarQube server
or to SonarCloud.io.

Requires ``SonarQube Scanner for Jenkins``

Configuration must set one of the parameters ``sonar-project-file`` or
``sonar-properties``; they cannot both be empty.

Plug-in configurations
    Manage Jenkins --> Configure System --> SonarQube servers
        - Name: Sonar (fixed)
        - Server URL: https://sonar.server.org/ or https://sonarcloud.io
        - Server authentication token: none for local, API token (saved as a
          "secret text" credential) for Sonarcloud

    Manage Jenkins --> Global Tool Configuration --> SonarQube Scanner
        - Name: SonarQube Scanner (fixed)
        - Install automatically
        - Select latest version

.. note::

    Optionally, set Sonar properties directly in the job definition by
    setting the sonar-project-file to ``""`` and adding all properties under
    ``sonar-properties``.

:Template Names:

    - {project-name}-sonar
    - gerrit-sonar
    - github-sonar

:Optional Parameters:
    :sonar-task: Sonar task to run. (default: "")
    :sonar-project-file: The filename for the project's properties
        (default: "sonar-project.properties")
    :sonar-properties: Sonar configuration properties. (default: "")
    :sonar-java-opts: JVM options. (default: "")
    :sonar-additional-args: Additional command line arguments. (default: "")
    :sonarcloud-java-version: Version of Java to run the Sonar scan. (default: "openjdk11")


Sonar with Prescan
------------------

The same as the Sonar job above, except the caller also defines a builder
called ``lf-sonar-prescan``, in which they can put any builders that they want
to run before the Sonar scan.

.. code-block:: yaml

   - builder:
       name: lf-sonar-prescan
       builders:
         - shell: "# Pre-scan shell script"

:Template Names:

    - {project-name}-sonar-prescan
    - gerrit-sonar-prescan
    - github-sonar-prescan

:Required Parameters:
    :lf-sonar-prescan: A builder that will run before the Sonar scan.

:Optional Parameters:
    :sonar-task: Sonar task to run. (default: "")
    :sonar-project-file: The filename for the project's properties
        (default: "sonar-project.properties")
    :sonar-properties: Sonar configuration properties. (default: "")
    :sonar-java-opts: JVM options. (default: "")
    :sonar-additional-args: Additional command line arguments. (default: "")
    :sonarcloud-java-version: Version of Java to run the Sonar scan. (default: "openjdk11")


Sonar with Prescan Script
-------------------------

The same as the Sonar job above, except the caller must supply a shell script
to run before the Sonar scan. This is commonly used to install prerequisites,
build the project, execute unit tests and generate a code-coverage report.

:Template Names:

    - {project-name}-sonar-prescan-script
    - gerrit-sonar-prescan-script
    - github-sonar-prescan-script

:Required Parameters:
    :sonar-prescan-script: A shell script that will run before the Sonar scan.

:Optional Parameters:
    :sonar-task: Sonar task to run. (default: "")
    :sonar-project-file: The filename for the project's properties.
        (default: "sonar-project.properties")
    :sonar-properties: Sonar configuration properties. (default: "")
    :sonar-java-opts: JVM options. (default: "")
    :sonar-additional-args: Additional command line arguments. (default: "")
    :sonarcloud-java-version: Version of Java to run the Sonar scan. (default: "openjdk11")
