.. _configuration:

#############
Configuration
#############

.. _defaults-yaml:

defaults.yaml
=============

This file lives in the ci-management repo typically under the path
``jjb/defaults.yaml``. The purpose of this file is to store default variable
values used by global-jjb templates.

**Required**

:jenkins-ssh-credential: The name of the Jenkins Credential to
    use for ssh connections. (ex: jenkins-ssh)

:lftools-version: Version of lftools to install. Can be a specific version
    like '0.6.1' or a `PEP-440 definition <https://www.python.org/dev/peps/pep-0440/>`_
    For example `<1.0.0` or `>=1.0.0,<2.0.0`.

:mvn-site-id: Maven Server ID from settings.xml containing the credentials
    to push to a Maven site repository.

:mvn-staging-id: Maven Server ID from settings.xml containing the credentials
    to push to a Maven staging repository.

**Gerrit required parameters**:

:gerrit-server-name: The name of the Gerrit Server as defined in Gerrit
    Trigger global configuration. (ex: Primary)

**GitHub required parameters**:

:git-url: Set this to the base URL of your GitHub repo. In
    general this should be <https://github.com>. If you are using
    GitHub Enterprise, or some other GitHub-style system, then it
    should be whatever your installation base URL is.

:git-clone-url: This is the clone prefix used by GitHub jobs.
    Set this to either the same thing as **git-url** or the
    'git@github.com:' including the trailing ':'

:github-org: The name of the GitHub organization interpolated
    into the scm config.

:github_pr_org: The name of the GitHub organization. All members
    of this organization will be able to trigger any job using the
    `lf-infra-github-pr` macro.

:github_pr_whitelist: List of GitHub members you wish to be able to
    trigger any job that uses the `lf-infra-github-pr-trigger` macro.

:github_pr_admin_list: List of GitHub members that will have admin
    privileges on any job using the `lf-infra-github-pr-trigger` macro.

Example Gerrit Infra:

.. code-block:: yaml

   - defaults:
       name: global

       # lf-infra defaults
       jenkins-ssh-credential: opendaylight-jenkins-ssh
       gerrit-server-name: OpenDaylight
       lftools-version: '<1.0.0'
       mvn-site-id: opendaylight-site
       mvn-staging-id: opendaylight-staging

Example GitHub Infra:

.. code-block:: yaml

   - defaults:
       name: global

       # lf-infra defaults
       jenkins-ssh-credential: jenkins-ssh
       github-org: lfit
       github_pr_whitelist:
         - jpwku
         - tykeal
         - zxiiro
       github_pr_admin_list:
         - tykeal
       lftools-version: '<1.0.0'
       mvn-site-id: opendaylight-site
       mvn-staging-id: opendaylight-staging

.. _jenkins-files:

Jenkins Files
=============

global-jjb makes use of the Jenkins Config File Provider plugin to provide some
default configurations for certain tools. This section details the files to
define in Jenkins' **Manage Files** configuration.

.. _npmrc:

npmrc
-----

This file contains default npmrc configuration and lives in $HOME/.npmrc.
Documentation for npmrc is available via the `npm project
<https://docs.npmjs.com/files/npmrc>`_.

:Required: This file MUST exist. An empty file is acceptable if a
    proxy is not available for the project.
:type: Custom file

Create a "Custom file" with contents:

.. code::

   registry = https://nexus.opendaylight.org/content/repositories/npmjs/

.. _pipconf:

pipconf
-------

This file contains default configuration for the python-pip tool and lives
in $HOME/.config/pip/pip.conf. Documentation for pip.conf is available via the
`pip project <https://pip.readthedocs.io/en/stable/user_guide/#configuration>`_.

:Required: This file MUST exist. An empty file is acceptable if a
    proxy is not available for the project.
:type: Custom file

Create a "Custom file" with contents:

.. code::

   [global]
   timeout = 60
   index-url = https://nexus3.opendaylight.org/repository/PyPi/simple

.. _jenkins-ci-jobs:

Jenkins CI Jobs
===============

.. _jenkins-cfg-merge:

jenkins-cfg-merge
-----------------

This job manages Jenkins Global configuration. Refer to
the :ref:`CI Documentation <lf-global-jjb-jenkins-cfg-merge>` for job
configuration details.

.. _log-archiving:

Log Archiving
=============

The logs account requires a Maven Settings file created called
**jenkins-log-archives-settings** with a server ID of **logs** containing the
credentials for the logs user in Nexus.
