.. _global-jjb-configuration:

#############
Configuration
#############

Jenkins Files
=============

global-jjb makes use of the Jenkins Config File Provider plugin to provide some
default configurations for certain tools. This section details the files to
define in Jenkins' **Manage Files** configuration.

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
    user=jenkins
    password=1234567890abcdef1234567890abcdef
    url=https://jenkins.example.com
    query_plugins_info=False


jenkins-log-archives-settings
-----------------------------

See :ref:`lf-infra-ship-logs` for usage.

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


packer-cloud-env
----------------

Cloud environment configuration variables for Packer jobs. These can
contain credentials and configuration for whichever clouds packer jobs
are using.

:Required: This file MUST exist to use packer jobs.
:type: Custom file

.. code-block:: json

   {
     "cloud_foo": "bar"
   }

Jenkins CI Jobs
===============

jenkins-cfg-merge
-----------------

This job manages Jenkins Global configuration. Refer to
the :ref:`CI Documentation <lf-global-jjb-jenkins-cfg-merge>` for job
configuration details.

.. TODO: Add details about jenkins-config directory and global-vars-$SILO.sh scripts
