#############
Global Macros
#############

Builders
========

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

lf-jacoco-nojava-workaround
---------------------------

Workaround for Jenkins not able to find Java in JaCoCo runs.

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

ReadTheDocs verify script.

lf-sigul-sign-dir
-----------------

Use Sigul to sign a directory via {sign-dir}.

Requires ``SIGUL_BRIDGE_IP`` configured as a global envvar.

:Required Parameters:
    :sign-artifacts: Whether or not to sign artifacts with Sigul.
    :sign-dir: Directory to sign.

lf-infra-provide-docker-cleanup
-------------------------------

Forcibly removes all of the docker images.

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

lf-stack-delete
---------------

Requirements:

* lftools >= v0.17.0

Delete an openstack heat stack. Use at the end of a job that creates a stack.

This macro requires a parameter defined in the job named STACK_NAME
containing the name of the stack to delete.

SCM
===

lf-infra-gerrit-scm
-------------------

Basic SCM configuration for Gerrit based projects.

:Required parameters:

    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

lf-infra-github-scm
-------------------

Basic SCM configuration for GitHub based projects.

On the `branch` variable you can assign `$sha1` or `$ghprbActualCommit`
as the value.  This will require that the job be triggered via
the GHPRB plugin and not manually.

:Required parameters:

    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

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
