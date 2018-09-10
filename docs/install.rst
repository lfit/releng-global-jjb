#######
Install
#######

global-jjb requires configuration in 2 places; ``Jenkins`` and the
:term:`ci-management` repository.

.. _jenkins-config:

Jenkins configuration
=====================

On the Jenkins side, we need to prep ``environment variables`` and
``plugins`` required by the jobs in global-jjb before we can start our first
jobs.

.. _jenkins-install-plugins:

Install Jenkins plugins
-----------------------

Install the following required Jenkins plugins and any optional ones as
necessary by the project.

**Required**

- `Config File Provider <https://plugins.jenkins.io/config-file-provider>`_
- `Description Setter <https://plugins.jenkins.io/description-setter>`_
- `Environment Injector Plugin <https://plugins.jenkins.io/envinject>`_
- `Git plugin <https://plugins.jenkins.io/git>`_
- `Post Build Script <https://plugins.jenkins.io/postbuildscript>`_
- `SSH Agent <https://plugins.jenkins.io/ssh-agent>`_
- `Workspace Cleanup <https://plugins.jenkins.io/ws-cleanup>`_

**Required for Gerrit connected systems**

- `Gerrit Trigger <https://plugins.jenkins.io/gerrit-trigger>`_

**Required for GitHub connected systems**

- `GitHub plugin <https://plugins.jenkins.io/github>`_
- `GitHub Pull Request Builder <https://plugins.jenkins.io/ghprb>`_

**Optional**

- `Mask Passwords <https://plugins.jenkins.io/mask-passwords>`_
- `MsgInject <https://plugins.jenkins.io/msginject>`_
- `OpenStack Cloud <https://plugins.jenkins.io/openstack-cloud>`_
- `Timestamper <https://plugins.jenkins.io/timestamper>`_

.. _jenkins-envvars:

Environment Variables
---------------------

The :ref:`lf-global-jjb-jenkins-cfg-merge` job can manage environment variables
job but we must first bootstrap them in Jenkins so that the job can run and
take over.

**Required**::

    GIT_URL=ssh://jenkins-$SILO@git.opendaylight.org:29418
    JENKINS_HOSTNAME=jenkins092
    NEXUS_URL=https://nexus.opendaylight.org
    SILO=production
    SONAR_URL=https://sonar.opendaylight.org

**Gerrit**::

    GERRIT_URL=https://git.opendaylight.org/gerrit

**GitHub**::

    GIT_URL=https://github.com
    GIT_CLONE_URL=git@github.com:

.. note::

   Use ``GIT_CLONE_URL`` for GitHub projects as this will be different from the
   URL used in the properties configuration.

**Optional**::

    LOGS_SERVER=https://logs.opendaylight.org

Steps

#. Navigate to https://jenkins.example.org/configure
#. Configure the environment variables as described above
#. Configure the same environment variables in the :term:`ci-management` repo

.. _jenkins-ci-management:

ci-management
=============

:term:`ci-management` is a git repository containing :term:`JJB` configuration
files for Jenkins Jobs. Deploying Global JJB here as a submodule allows us easy
management to install, upgrade, and rollback changes via git tags. Install
Global JJB as follows:

#. Install Global JJB

   .. code-block:: bash

      GLOBAL_JJB_VERSION=v0.1.0
      git submodule add https://github.com/lfit/releng-global-jjb.git
      cd global-jjb
      git checkout $GLOBAL_JJB_VERSION
      cd ..
      git add jjb/global-jjb

      # Setup symlinks
      mkdir jjb/global-jjb
      ln -s ../../global-jjb/shell jjb/global-jjb/shell
      ln -s ../../global-jjb/jjb jjb/global-jjb/jjb
      git add jjb/global-jjb

      git commit -sm "Install global-jjb $GLOBAL_JJB_VERSION"

   .. note::

      We are purposely using github for production deploys of global-jjb so that
      uptime of LF Gerrit does not affect projects using global-jjb. In a test
      environment we can use
      https://gerrit.linuxfoundation.org/infra/releng/global-jjb if desired.

#. Setup ``jjb/defaults.yaml``

   Create and configure the following parameters in the
   ``jjb/defaults.yaml`` file as described in the
   `defaults.yaml configuration docs <defaults-yaml>`.

   Once configured commit the modifications:

   .. code-block:: bash

      git add jjb/defaults.yaml
      git commit -sm "Setup defaults.yaml"

#. Push patches to Gerrit / GitHub using your favourite push method

At this point global-jjb installation is complete in the :term:`ci-management`
repo and is ready for use.

.. _deploy-ci-jobs:

Deploy ci-jobs
==============

The CI job group contains jobs that should deploy in all LF
Jenkins infra. The minimal configuration to deploy the
**{project-name}-ci-jobs** job group as defined in **lf-ci-jobs.yaml** is as
follows:

jjb/ci-management/ci-management.yaml:

.. code-block:: yaml

   - project:
       name: ci-jobs

       jobs:
         - '{project-name}-ci-jobs'

       project: ci-management
       project-name: ci-management
       build-node: centos7-builder-2c-1g

**Required parameters**:

:project: The project repo as defined in source control.
:project-name: A custom name to call the job in Jenkins.
:build-node: The name of the builder to use when building (Jenkins label).

**Optional parameters**:

:branch: The git branch to build from. (default: master)
:jjb-version: The version of JJB to install in the build minion. (default:
    <defined by the global-jjb project>)

.. _deploy-packer-jobs:

Deploy packer-jobs
==================

The packer job group contains jobs to build custom minion images. The minimal
configuration needed to deploy the packer jobs is as follows which deploys the
**{project-name}-packer-jobs** job group as defined in **lf-ci-jobs.yaml**.

jjb/ci-management/packer.yaml:

.. code-block:: yaml

   - project:
       name: packer-builder-jobs

       jobs:
         - '{project-name}-packer-jobs'

       project: ci-management
       project-name: ci-management
       branch: master
       build-node: centos7-builder-2c-1g

       platforms:
         - centos
         - ubuntu-16.04

       templates: builder

   - project:
       name: packer-docker-jobs

       jobs:
         - '{project-name}-packer-jobs'

       project: ci-management
       project-name: ci-management
       branch: master
       build-node: centos7-builder-2c-1g

       templates: docker

       platforms:
         - centos
         - ubuntu-16.04

**Required parameters**:

:project: The project repo as defined in source control.
:project-name: A custom name to call the job in Jenkins.
:build-node: The name of the builder to use when building (Jenkins label).
:platforms: A list of supported platforms.
:templates: A list of templates to build. We recommend setting one template per
    ``project`` section so that we can control which platforms to build for
    specific templates.

**Optional parameters**:

:branch: The git branch to build from. (default: master)
:packer-version: The version of packer to install in the build minion,
    when packer is not available. (default: <defined by global-jjb>)
