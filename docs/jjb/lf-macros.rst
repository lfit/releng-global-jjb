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

    :DOCKER_REGISTRY : Optional
        Jenkins global variable should be defined
        If set, then this is the FQDN that will be used
        for logging into the custom docker registry
        ex: nexus3.example.com

    :REGISTRY_PORTS  : Required if DOCKER_REGISTRY is set
        Jenkins global variable should be defined (space separated)
        Listing of all the registry ports to login to
        ex: 10001 10002 10003 10004

    :DOCKERHUB_REGISTRY: Optional
        Set global Jenkins variable to `docker.io`
        Additionally you will need to add as an entry
        to your projects mvn-settings file with username
        and password creds.  If you are using docker version
        < 17.06.0 you will need to set DOCKERHUB_EMAIL
        to auth to docker.io

    :desired-settings-file: Job level variable with settings file location.
                            The defualt is the project maven settings file,
                            $SETTINGS_FILE.  You can opt to set this to
                            $GLOBAL_SETTINGS_FILE
                            
    :GLOBAL_SETTINGS_FILE : Job level variable with global settings file location.
        You will define a setting for docker.io login here.

    :DOCKERHUB_EMAIL : Optional
        Jenkins global variable that defines the email address that
        should be used for logging into DockerHub
        Note that this will not be used if you are using
        docker version >=17.06.0.


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

On the `branch` variable you can assign `$sha1` or `$ghprbActualCommit`
as the value.  This will require that the job be triggered via
the GHPRB plugin and not manually.

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

This wrapper requires that a managed file called `npmrc` exists in the Jenkins.  The main use
case here is to point to a npm proxy, on Nexus for example.
The type of the file should be "Custom file".  You can set various npmrc settings in it.
Documentation on npm configuration can be found at https://docs.npmjs.com/files/npmrc.
If you are not using npm then it is fine for the file to be empty.

Example npmrc:

.. code-block:: bash

   registry=https://nexus3.onap.org/repository/npm.public/
