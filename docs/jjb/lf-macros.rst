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
called DEPENDENCY_BUILD_ORDER which can be used if necessary to build
projects in the specified order. The order is determined by first patch
instance for a project in the patch list.

lf-license-check
----------------

Checks files for

:Required parameters:

    :file-patterns: Space-separated list of file patterns to scan.
        For example: \*.go \*.groovy \*.java \*.py \*.sh
    :spdx-disable: Disable the SPDX-Identifier checker.
    :lhc-version: Version of LHC to use.
    :license-exclude-paths: Comma-separated list of paths to exclude from the
        license checker. The paths used here will be matched using a contains
        rule so it is best to be as precise with the path as possible.
        For example a path of '/src/generated/' will be searched as
        '**/src/generated/**'.
        Example: org/opendaylight/yang/gen,protobuff/messages
    :licenses-allowed: Comma-separated list of allowed licenses.
        For example: Apache-2.0,EPL-1.0,MIT

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

    :REGISTRY_PORTS: Required if DOCKER_REGISTRY is set. Space separated list
        of the registry ports to login to. ex: 10001 10002 10003 10004
        (GLOBAL variable)

    :DOCKERHUB_EMAIL: If this variable is set then an attempt to login to
        DockerHub (docker.io) will be also made. It should be set to the email
        address for the credentials that will get looked up. Only _one_
        credential will ever be found in the maven settings file for DockerHub.
        (GLOBAL variable)

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

Run `packer validate` to verify packer configuration.

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

    :mvn-central: Whether or not to upload to mvn-central. (true|false)
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

Call maven-target builder with a goal of --version to force Jenkins to
install the need provided version of Maven. This is needed for any shell scripts
that want to use Maven.

:Required parameters:

    :mvn-version: Version of Maven to install.

lf-pip-install
--------------

Call pip install to install packages into a virtualenv located in
/tmp/v/VENV

.. note:: The first package listed in PIP_PACKAGES is used as the VENV name.

.. _lf-provide-maven-settings:

lf-provide-maven-settings
-------------------------

Push a global settings and user settings maven files to the build node.

lf-provide-maven-settings-cleanup
---------------------------------

Cleanup maven settings.xml configuration. This should be called at the end of
any macros that calles the
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
Jobs will run but skip verify bits until a .readthedocs.yaml is found in the root
of their repository.


check-info-votes
----------------

Calls shell script to validate votes on a change to an INFO.yaml

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
    :sign-artifacts: Whether or not to sign artifacts with Sigul.
    :sign-dir: Directory to sign.
    :sign-mode: serial|parallel

lf-infra-provide-docker-cleanup
-------------------------------

Forcibly removes all of the docker images.

lf-infra-sonar
---------------

Runs Jenkins SonarQube plug-in.

Requires ``SonarQube Scanner for Jenkins``

.. note:: Sonar properties can be set directly in the job definition by
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

Runs Jenkins SonarQube plug-in after a pre-scan builder, which is defined by
the macro's caller.

Requires ``SonarQube Scanner for Jenkins``

.. note:: Sonar properties can be set directly in the job definition by
   setting the sonar-project-file to ``""`` and adding all properties under
   ``sonar-properties``.

:Required Parameters:
    :lf-sonar-prescan: A builder that will run prior to the Sonar scan.

:Optional Parameters:
    :sonar-task: Sonar task to run. (default: "")
    :sonar-project-file: The filename for the project's properties
        (default: "sonar-project.properties")
    :sonar-properties: Sonar configuration properties. (default: "")
    :sonar-java-opts: JVM options. (default: "")
    :sonar-additional-args: Additional command line arguments. (default: "")

Parameters
==========

lf-clm-parameters
-------------------

Provides the policy evaluation stage to run against Nexus IQ Server.
Valid values include: 'build', 'stage-release', 'operate'.

lf-cmake-parameters
-------------------

Provides parameters needed by CMake. Should be used by any jobs that need to
call the ``cmake && make && make install`` pattern.

lf-infra-maven-parameters
-------------------------

Provides parameters needed by Maven. Should be used by any jobs that need to
call the mvn cli.

lf-infra-openstack-parameters
-----------------------------

Provides parameters needed by OpenStack client CLI. Use in jobs that need to
call the openstack cli.

:Required Parameters:

    :os-cloud: Configures ``OS_CLOUD`` envvar as used by openstack cli.

lf-infra-parameters
-------------------

Standard parameters used in the LF CI environments. Gerrit variables are
not used by GitHub projects, but defining them is not harmful. Should be used
in every job template.

lf-infra-node-parameters
------------------------

Provides parameters needed by NodeJS and NPM. Should be used by any jobs that
need to run NodeJS or NPM.

lf-infra-tox-parameters
-----------------------

Provides parameters needed by python-tox. Should be used by any jobs that need
to run `tox <https://tox.readthedocs.io>`.


lf-build-with-parameters-maven-release
--------------------------------------

Provides parameters needed for maven release jobs 'build with parameters'.

Properties
==========

lf-infra-properties
-------------------

Configures the build-discarder plugin for Jenkins with the recommended lf-infra
settings. Should be used in all job-templates.

Publishers
==========

lf-jacoco-report
----------------

Provides basic configuration for the JaCoCo plugin.

lf-infra-publish
----------------

Provides basic lf-infra recommended publisher configurations which should be
used in all job templates. This primary objective of this trigger is to
gather build logs and copy them to a log server.

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

On the `branch` variable you can assign `$sha1` or `$ghprbActualCommit`
as the value.  This will require that the job be triggered via
the GHPRB plugin and not manually.

:Required parameters:

    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

Wrappers
========

lf-infra-wrappers-common
------------------------

Provides lf-infra recommended wrappers which should be used in every
job-template. It's meant to be used by more specific wrappers below.

lf-infra-wrappers
-----------------

Provides lf-infra recommended wrappers which should be used in every
job-template that's run on Linux systems.

This wrapper requires that a managed file called `npmrc` exists in the Jenkins.
The main use case here is to point to a npm proxy, on Nexus for example.
The type of the file should be "Custom file".  You can set various npmrc
settings in it. Documentation on npm configuration can be found at
https://docs.npmjs.com/files/npmrc. If you are not using npm then it is fine
for the file to be empty.

Example npmrc:

.. code-block:: bash

   registry=https://nexus3.onap.org/repository/npm.public/

lf-infra-wrappers-windows
-------------------------

Provides lf-infra recommended wrappers which should be used in every
job-template that's run on Windows systems.
