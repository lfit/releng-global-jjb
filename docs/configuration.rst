.. _global-jjb-configuration:

#############
Configuration
#############

Jenkins Files
=============

global-jjb makes use of the Jenkins Config File Provider plugin to provide some
default configurations for certain tools.

npmrc
-----

This file contains default npmrc configuration and is copied to $HOME/.npmrc
Create a "Custom file" with contents:

.. code::

   registry = https://nexus.opendaylight.org/content/repositories/npmjs/

pip.conf
--------

This file contains default configuration for the python-pip tool.
Create a "Custom file" with contents:

.. code::

   [global]
   timeout = 60
   index-url = https://nexus3.opendaylight.org/repository/PyPi/simple
