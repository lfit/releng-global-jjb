#############
Global Macros
#############

Builders
========

comment-to-gerrit
-----------------

This macro will post a comment to the gerrit patchset if the build
creates a file named gerrit_comment.txt
To use this macro add it to the list of builders.


lf-fetch-dependent-patches
--------------------------

Fetch all patches provided via comment trigger

This macro will fetch all patches provided via comment trigger and will
create a list of projects from those patches via environment variable
called ``DEPENDENCY_BUILD_ORDER`` to build projects in the specified order.
Order calculated by the first patch instance for a project in the patch list.

lf-license-check
----------------

Checks files for

:Required parameters:

    :file-patterns: Space-separated list of file patterns to scan.
        For example: \*.go \*.groovy \*.java \*.py \*.sh
    :spdx-disable: Disable the SPDX-Identifier checker.
    :lhc-version: Version of LHC to use.
    :license-exclude-paths: Comma-separated list of paths to exclude from the
        license checker. Matches the paths defined here using a contains rule,
        we recommend you to configure as precisely as possible. For example
        a path of '/src/generated/' will search as '**/src/generated/**'.
        Example: org/opendaylight/yang/gen,protobuff/messages
    :licenses-allowed: Comma-separated list of allowed licenses.
        For example: Apache-2.0,EPL-1.0,MIT

lf-infra-capture-instance-metadata
----------------------------------

Capture instance metadata.

lf-infra-create-netrc
---------------------

Create a ~/.netrc file from a Maven settings.xml

:Required parameters:

    :server-id: The id of a server as defined in settings.xml.

:Optional parameters:

    :ALT_NEXUS_SERVER: URL of custom nexus server.
        If set this will take precedence.
        Use this to point at nexus3.$PROJECTDOMAIN
        for example.

lf-infra-deploy-maven-file
--------------------------

Deploy files to a repository.

:Required parameters:

    :global-settings-file: Global settings file to use.
    :group-id: Group ID of the repository.
    :maven-repo-url: URL of a Maven repository to upload to.
    :mvn-version: Version of Maven to use.
    :repo-id: Repository ID
    :settings-file: Maven settings file to use.
    :upload-files-dir: Path to directory containing one or more files

lf-infra-docker-login
---------------------

Login into a custom hosted docker registry and / or docker.io

The Jenkins system should have the following global variables defined

:Environment variables:

    :DOCKER_REGISTRY: The DNS address of the registry (IP or FQDN)
        ex: nexus3.example.com (GLOBAL variable)

    :REGISTRY_PORTS: Required when setting ``DOCKER_REGISTRY``. Space-separated
        list of the registry ports to login to. ex: 10001 10002 10003 10004
        (GLOBAL variable)

    :DOCKERHUB_EMAIL: If set, then the job will attempt to login to DockerHub
        (docker.io). Set to the email address for the credentials that will
        get looked up. Returns the _first_ credential from the maven settings
        file for DockerHub. (GLOBAL variable)

lf-infra-gpg-verify-git-signature
---------------------------------

Verify gpg signature of the latest commit message in $WORKSPACE.
This command assumes that $WORKSPACE is a git repo.

lf-infra-pre-build
------------------

Macro that runs before all builders to prepare the system for job use.

lf-infra-package-listing
------------------------

Lists distro level packages.

lf-infra-packer-build
---------------------

Run `packer build` to build system images.

:Required parameters:

    :openstack: Packer template uses an OpenStack builder (true|false).
    :openstack-cloud: Sets OS_CLOUD variable to the value of this parameter.
    :packer-version: Version of packer to use.
    :platform: Build platform as found in the vars directory.
    :template: Packer template to build as found in the templates directory.

:Optional parameters:

    :update-cloud-image: Submit a change request to update new built cloud
        image to Jenkins.

lf-infra-packer-validate
------------------------

Run ``packer validate`` to verify packer configuration.

:Required parameters:

    :openstack: Packer template uses an OpenStack builder (true|false).
    :openstack-cloud: Sets OS_CLOUD variable to the value of this parameter.
    :packer-cloud-settings: Cloud configuration file. Loaded on the build
        server as CLOUDENV environment variable.
    :packer-version: Version of packer to use.

lf-infra-push-gerrit-patch
--------------------------

Push a change through a Jenkins job to a Gerrit repository in an automated
way using git-review.

:Required parameters:

    :gerrit-commit-message: Commit message to assign.
    :gerrit-host: Gerrit hostname.
    :gerrit-topic: Gerrit topic.
    :gerrit-user: Gerrit user-id used for submitting the change.
    :reviewers-email: Reviewers email. Space-separated list of
        email addresses to CC on the patch.
    :project: Gerrit project name.

.. _lf-infra-ship-logs:

lf-infra-ship-logs
------------------

Gather and deploy logs to a log server.

lf-infra-sysstat
----------------

Retrieves system stats.

lf-infra-update-packer-images
-----------------------------

Find and update the new built cloud image{s} in the ci-management source
repository.


lf-jacoco-nojava-workaround
---------------------------

Workaround for Jenkins not able to find Java in JaCoCo runs.

.. _lf-maven-central:

lf-maven-central
----------------

Publish artifacts to OSSRH (Maven Central) staging.

Requires that the project's settings.xml contains a ServerId 'ossrh' with the
credentials for the project's OSSRH account.

This macro assumes the directory ``$WORKSPACE/m2repo`` contains a Maven 2
repository which is to upload to OSSRH.

:Required parameters:

    :mvn-central: Set to ``true`` to upload to mvn-central. (true|false)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-settings: The name of settings file containing credentials for the
        project.
    :ossrh-profile-id: Nexus staging profile ID as provided by OSSRH.

.. literalinclude:: ../../.jjb-test/lf-macros/lf-maven-central-minimal.yaml
   :language: yaml

.. _lf-maven-install:

lf-maven-install
----------------

Call maven-target builder with a goal of ``--version`` to force Jenkins to
install the declared version of Maven. Use this as a preparation step for
any shell scripts that want to use Maven.

:Required parameters:

    :mvn-version: Version of Maven to install.

lf-packagecloud-file-provider
-----------------------------

Provisions files required by the Ruby gem package_cloud, namely
".packagecloud" and "packagecloud_api" in the Jenkins home directory.

lf-packagecloud-push
--------------------

Pushes DEB/RPM package files to PackageCloud using the Ruby gem package_cloud.

:Required parameters:

    :build-dir: Directory with deb/rpm files to push
    :debian-distribution-versions: list of DEB package distro/version strings
        separated by space; example: ubuntu/bionic debian/stretch
    :packagecloud-account: PackageCloud account ID; example: oran
    :packagecloud-repo: PackageCloud repository; example: master, staging
    :rpm-distribution-versions: list of RPM package distro/version strings
        separated by space; example: el/4 el/5

lf-pip-install
--------------

Call pip install to install packages into a virtualenv located in
/tmp/v/VENV

.. note:: Uses the first package listed in PIP_PACKAGES as the VENV name.

.. _lf-provide-maven-settings:

lf-provide-maven-settings
-------------------------

Push a global settings and user settings maven files to the build node.

lf-provide-maven-settings-cleanup
---------------------------------

Cleanup maven ``settings.xml`` configuration. Set at the end of any macros that
calls the
:ref:`lf-provide-maven-settings <lf-provide-maven-settings>` macro.

lf-rtd-trigger-build
--------------------

Script to trigger a build on http://readthedocs.org

lf-rtd-verify
-------------

ReadTheDocs verify script. Installs and runs tox.

:Required parameters:

    :doc-dir: Document directory.
    :python-version: Python version.

lf-rtdv3-build
---------------

Read the docs scripts that leverage the new Read the Docs v3 api
`RTD v3 API <https://docs.readthedocs.io/en/stable/api/v3.html>`_
Runs tox to verify that the docs are good and then runs the RTDv3 shell script.
This script handles creating projects as needed, assiging subprojects to the main
read the docs project and triggering builds to update the documentation.
Jobs will run but skip verify bits until a ``.readthedocs.yaml`` exists in the
root of their repository.


check-info-votes
----------------

Validates votes on a changes to ``INFO.yaml``.

lf-release
----------

releases lftools.ini (required)
needed to push to nexus.

[nexus]
username=
password=

Then runs ../shell/release-job.sh


lf-sigul-sign-dir
-----------------

Use Sigul to sign a directory via {sign-dir}.

Requires ``SIGUL_BRIDGE_IP`` configured as a global envvar.

:Required Parameters:
    :sign-artifacts: Set ``true`` to sign artifacts with Sigul.
    :sign-dir: Directory to sign.
    :sign-mode: serial|parallel

lf-infra-provide-docker-cleanup
-------------------------------

Forcefully removes all docker images.

lf-infra-sonar
---------------

Runs Jenkins SonarQube plug-in.

Requires ``SonarQube Scanner for Jenkins``

.. note::

    Optionally, set Sonar properties directly in the job definition by
    setting the sonar-project-file to ``""`` and adding all properties under
    ``sonar-properties``.

:Optional Parameters:
    :sonar-task: Sonar task to run. (default: "")
    :sonar-project-file: The filename for the project's properties
        (default: "sonar-project.properties")
    :sonar-properties: Sonar configuration properties. (default: "")
    :sonar-java-opts: JVM options. (default: "")
    :sonar-additional-args: Additional command line arguments. (default: "")

lf-infra-sonar-with-prescan
---------------------------

Runs Jenkins SonarQube plug-in after a pre-scan builder.

Requires ``SonarQube Scanner for Jenkins``

.. note::

    Optionally, set Sonar properties directly in the job definition by
    setting the sonar-project-file to ``""`` and adding all properties under
    ``sonar-properties``.

:Required Parameters:
    :lf-sonar-prescan: A builder that will run before the Sonar scan.

:Optional Parameters:
    :sonar-task: Sonar task to run. (default: "")
    :sonar-project-file: The filename for the project's properties
        (default: "sonar-project.properties")
    :sonar-properties: Sonar configuration properties. (default: "")
    :sonar-java-opts: JVM options. (default: "")
    :sonar-additional-args: Additional command line arguments. (default: "")

Parameters
==========

lf-autotools-parameters
-----------------------

Provides parameters needed by configure and make. Use in any jobs that need to
call the ``configure && make`` pattern.

lf-clm-parameters
-----------------

Provides the policy evaluation stage to run against Nexus IQ Server.
Valid values include: 'build', 'stage-release', 'operate'.

lf-cmake-parameters
-------------------

Provides parameters required by CMake. Use in any jobs that need to call the
``cmake && make && make install`` pattern.

lf-infra-maven-parameters
-------------------------

Provides parameters required by Maven. Use in any jobs that need to call the
``mvn`` CLI.

lf-infra-openstack-parameters
-----------------------------

Provides parameters needed by OpenStack client CLI. Use in jobs that need to
call the openstack cli.

:Required Parameters:

    :os-cloud: Configures ``OS_CLOUD`` envvar as used by openstack cli.

lf-infra-parameters
-------------------

Standard parameters used in the LF CI environments. GitHub projects will ignore
the Gerrit variables and vice-versa, so defining them is not harmful. Use in
every job template.

lf-infra-node-parameters
------------------------

Provides parameters needed by NodeJS and NPM. Use in any jobs that need to run
NodeJS or NPM.

lf-infra-tox-parameters
-----------------------

Provides parameters required by python-tox. Use in any jobs that need to run
`tox <https://tox.readthedocs.io>`.


lf-build-with-parameters-maven-release
--------------------------------------

Provides parameters needed for maven release jobs 'build with parameters'.

Properties
==========

lf-infra-properties
-------------------

Configures the build-discarder plugin for Jenkins with the recommended lf-infra
settings. We recommend to include in all job-templates.

Publishers
==========

lf-jacoco-report
----------------

Provides basic configuration for the JaCoCo plugin.

lf-infra-publish
----------------

Provides basic lf-infra recommended publisher configurations for use in all job
templates. The purpose of this trigger is to gather package listing, instance
metadata, sar reports, build logs and copy them to a log server.

lf-infra-publish-windows
------------------------

Windows publisher for use at the end of Windows job templates. Takes care of
cleaning out the workspace at the end of a job.

SCM
===

lf-infra-gerrit-scm
-------------------

Basic SCM configuration for Gerrit based projects.

:Required parameters:

    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

lf-infra-github-scm
-------------------

Basic SCM configuration for GitHub based projects.

On the `branch` variable you can assign ``$sha1`` or ``$ghprbActualCommit``
as the value.  This will enable the jobs to trigger via the GHPRB plugin.

:Required parameters:

    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

Wrappers
========

lf-infra-wrappers-common
------------------------

Provides lf-infra recommended wrappers for use in every job-template. Include
this wrapper when creating more specific platform wrappers to ensure they pick
up the common settings.

lf-infra-wrappers
-----------------

Provides lf-infra recommended wrappers for use in every job-template targetting
Linux systems.

This wrapper requires a managed file named ``npmrc`` to exist in Jenkins. The
main use case here is to point to a npm proxy, on Nexus for example. Set the
file type to "Custom file".  You can set any npmrc settings in it,
documentation on npm configuration is available at
<https://docs.npmjs.com/files/npmrc>. If you are not using npm then create an
empty file.

Example npmrc:

.. code-block:: bash

   registry=https://nexus3.onap.org/repository/npm.public/

lf-infra-wrappers-windows
-------------------------

Provides lf-infra recommended wrappers for use in every job-template targetting
Windows systems.
