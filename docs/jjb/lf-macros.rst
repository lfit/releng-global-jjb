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

lf-infra-create-netrc
---------------------

Create a ~/.netrc file from a Maven settings.xml

:Required parameters:

    :server-id: The id of a server as defined in settings.xml.

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

lf-infra-packer-build
---------------------

Run `packer build` to build system images.

lf-infra-packer-validate
------------------------

Run `packer validate` to verify packer configuration.

:Required parameters:

    :packer-cloud-settings: Cloud configuration file. Loaded on the build
        server as CLOUDENV environment variable.
    :packer-version: Version of packer to use.

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

.. _lf-provide-maven-settings

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

Parameters
==========

lf-infra-maven-parameters
-------------------------

Provides parameters needed by Maven. Should be used by any jobs that need to
call the mvn cli.

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

SCM
===

lf-infra-gerrit-scm
-------------------

Basic SCM configuration for Gerrit based projects.

lf-infra-github-scm
-------------------

Basic SCM configuration for GitHub based projects.

Triggers
========

lf-infra-github-pr-trigger
--------------------------

Provides configuration for a GitHub PR Trigger.

Wrappers
========

lf-infra-wrappers
-----------------

Provides lf-infra recommended wrappers which should be used in every
job-template.
