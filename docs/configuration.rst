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
       jenkins-ssh-credential: jenkins-ssh
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

.. code-block:: ini

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

.. code-block:: ini

   [global]
   timeout = 60
   index-url = https://nexus3.opendaylight.org/repository/PyPi/simple

.. _jjbini:

jjbini
------

This file contains the Jenkins Job Builder `configuration
<https://docs.openstack.org/infra/jenkins-job-builder/execution.html#configuration-file>`_
for :doc:`jjb/lf-ci-jobs`.

:Required: This file MUST exist.
:type: Custom file

Create a "Custom file" with contents:

.. code-block:: ini

    [job_builder]
    ignore_cache=True
    keep_descriptions=False
    include_path=.:scripts:~/git/
    recursive=True

    [jenkins]
    user=jenkins-jobbuilder
    password=1234567890abcdef1234567890abcdef
    url=https://jenkins.example.org
    query_plugins_info=False

    [production]
    user=jenkins-jobbuilder
    password=1234567890abcdef1234567890abcdef
    url=https://jenkins.example.org
    query_plugins_info=False

    [sandbox]
    user=jenkins-jobbuilder
    password=1234567890abcdef1234567890abcdef
    url=https://jenkins.example.org/sandbox
    query_plugins_info=False

The last 2 sections are for the ``jenkins-cfg`` job use, they should match the
``silo`` names for the respective Jenkins systems, typically ``production`` and
``sandbox``.

.. _jenkins-log-archives-settings:

jenkins-log-archives-settings
-----------------------------

See :ref:`lf-infra-ship-logs` for usage. If not archiving logs then keep this
file with default settings, global-jjb needs the file to exist to function.

Requires a credentials named 'logs' of type 'Username and Password' created in
the Jenkins Credentials system.

#. Add Server Credentials
#. Set ``ServerId`` to ``logs``
#. Set ``Credentials`` to the ``logs`` user created in the Credentials System

:Required: This file MUST exist if using log archiving.
:type: Maven settings.xml

.. code-block:: xml

   <?xml version="1.0" encoding="UTF-8"?>
   <settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
   </settings>

.. note::

   This example is the default boilerplate generated by Jenkins with
   the comments stripped out. We can also use the default generated by Jenkins
   without modifying it.

.. _packer-cloud-env:

packer-cloud-env
----------------

Cloud environment configuration variables for Packer jobs. These can
contain credentials and configuration for whichever clouds packer jobs
are using.

:Required: This file MUST exist to use packer jobs.
:type: Custom file

.. code-block:: json

   {
     "cloud_auth_url": "https://auth.vexxhost.net/v3/",
     "cloud_tenant": "TENANT_ID",
     "cloud_user": "CLOUD_USERNAME",
     "cloud_pass": "CLOUD_PASSWORD",
     "cloud_network": "CLOUD_NETWORK",
     "ssh_proxy_host": ""
   }

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
