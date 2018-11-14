##############
OpenStack Heat
##############

This section contains a series of macros for projects that need to spin up full
test labs using HEAT scripts.

Job Setup
=========

The 2 macros :ref:`lf-stack-create` & :ref:`lf-stack-delete` are companion
macros and are meant to be deployed together when constructing a job template
that needs to spin up a full integration lab using Heat Orchestration Templates
(HOT).

Example Usage:

.. code-block:: yaml

   - job-template:
       name: csit-test

       #####################
       # Default variables #
       #####################

       openstack-cloud: vex
       openstack-heat-template: csit-2-instance-type.yaml
       openstack-heat-template-dir: 'openstack-hot'

       odl_system_count: 1
       odl_system_flavor: odl-highcpu-4
       odl_system_image: ZZCI - CentOS 7 - builder - x86_64 - 20181010-215635.956
       tools_system_count: 1
       tools_system_flavor: odl-highcpu-2
       tools_system_image: ZZCI - Ubuntu 16.04 - mininet-ovs-25 - 20181029-223449.514

       #####################
       # Job configuration #
       #####################

       builders:
         - lf-infra-pre-build
         - lf-stack-create:
             openstack-cloud: '{openstack-cloud}'
             openstack-heat-template: '{openstack-heat-template}'
             openstack-heat-template-dir: '{openstack-heat-template-dir}'
             openstack-heat-parameters: |
                 vm_0_count: '{odl_system_count}'
                 vm_0_flavor: '{odl_system_flavor}'
                 vm_0_image: '{odl_system_image}'
                 vm_1_count: '{tools_system_count}'
                 vm_1_flavor: '{tools_system_flavor}'
                 vm_1_image: '{tools_system_image}'

       publishers:
         - lf-stack-delete:
             openstack-cloud: '{openstack-cloud}'


Macros
======

.. _lf-stack-create:

lf-stack-create
---------------

Creates an OpenStack stack as configured by the job. Name pattern of stack is
``$SILO-$JOB_NAME-$BUILD_NUMBER``.

Requires a Config File Provider configuration for clouds.yaml named
``clouds-yaml``.

:Required Parameters:

    :openstack-cloud: The ``OS_CLOUD`` variable to pass to OpenStack client.
        (Docs: https://docs.openstack.org/python-openstackclient)
    :openstack-heat-template: Name of template file to use when running stack
        create.
    :openstack-heat-template-dir: Directory in the ci-management repo
        containing the OpenStack heat templates.

.. _lf-stack-delete:

lf-stack-delete
---------------

Deletes the stack associated with this job. Name pattern of stack is
``$SILO-$JOB_NAME-$BUILD_NUMBER``.

Requires a Config File Provider configuration for clouds.yaml named
``clouds-yaml``.

:Required Parameters:

    :openstack-cloud: The ``OS_CLOUD`` variable to pass to OpenStack client.
        (Docs: https://docs.openstack.org/python-openstackclient)
