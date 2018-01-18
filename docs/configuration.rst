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

.. code::

   registry = https://nexus.opendaylight.org/content/repositories/npmjs/

pip.conf
--------

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


Jenkins CI Jobs
===============

jenkins-cfg-merge
-----------------

This job manages Jenkins Global configuration. Refer to
the :ref:`CI Documentation <lf-global-jjb-jenkins-cfg-merge>` for job
configuration details.
