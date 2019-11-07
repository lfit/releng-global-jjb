#############################
OpenStack Magnum (Kubernetes)
#############################

This section contains a series of macros for projects that need to spin up
kubernetes clusters using JJB.

Job Setup
=========

The two macros :ref:`lf-kubernetes-create` & :ref:`lf-kubernetes-delete` are
companion macros and used together when constructing a job template that needs
a kubernetes cluster.

Example Usage:

.. code-block:: yaml

   - job-template:
       name: k8s-test

       #####################
       # Default variables #
       #####################

       base-image: Fedora Atomic 29 [2019-08-20]
       boot-volume-size: 10
       cluster-settle-time: 1m
       docker-volume-size: 10
       fixed-network: ecompci
       fixed-subnet: ecompci-subnet1
       keypair: jenkins
       kubernetes-version: v1.16.0
       master-count: 1
       master-flavor: v2-standard-1
       node-count: 2
       node-flavor: v2-highcpu-8
       openstack-cloud: vex

       #####################
       # Job configuration #
       #####################

       builders:
         - lf-infra-pre-build
         - lf-kubernetes-create:
             openstack-cloud: "{openstack-cloud}"
             base-image: "{base-image}"
             boot-volume-size: "{boot-volume-size}"
             cluster-settle-time: "{cluster-settle-time}"
             docker-volume-size: "{docker-volume-size}"
             fixed-network: "{fixed-network}"
             fixed-subnet: "{fixed-subnet}"
             keypair: "{keypair}"
             kubernetes-version: "{kubernetes-version}"
             master-count: "{master-count}"
             master-flavor: "{master-flavor}"
             node-count: "{node-count}"
             node-flavor: "{node-flavor}"
       publishers:
         - lf-kubernetes-delete


Macros
======

.. _lf-kubernetes-create:

lf-kubernetes-create
--------------------

Creates an OpenStack Kubernetes cluster as configured by the job. Name pattern
of stack is ``$SILO-$JOB_NAME-$BUILD_NUMBER``.

Requires ``lf-infra-pre-build`` macro to run first to install the
``openstack`` and ``lftools`` packages.

Requires a Config File Provider configuration for clouds.yaml named
``clouds-yaml``.

:Required Parameters:

    :openstack-cloud: The ``OS_CLOUD`` variable to pass to OpenStack client.
        (Docs: https://docs.openstack.org/python-openstackclient)
    :base-image: The base image to use for building the cluster. LF is
        using the Fedora Atomic images.
    :boot-volume-size: The size of the operating system disk for each node.
    :cluster-settle-time: A parameter that controls the buffer time after
        cluster creation before we start querying the API for status.
    :docker-volume-size: The size of the Docker volume.
    :fixed-network: The private network to build the cluster on.
    :fixed-subnet: The subnet to use from the above private network
    :keypair: The ssh keypair to inject into the nodes for access.
    :kubernetes-version: The version of kubernetes to use for the cluster.
        Available versions are v1.14, v1.15, and v1.16
    :master-count: The number of masters for the cluster (configuring more than
        one master automatically triggers the creation of a load-balancer).
    :master-flavor: The flavor (size) of the master node.
    :node-count: The number of kubernetes nodes for the cluster.
    :node-flavor: The flavor (size) of the worker nodes.


lf-kubernetes-delete
--------------------

Deletes the stack associated with this job. Name pattern of stack is
``$SILO-$JOB_NAME-$BUILD_NUMBER``.

Requires ``lf-infra-pre-build`` macro to run first to install the
``openstack`` and ``lftools`` packages.

Requires a Config File Provider configuration for clouds.yaml named
``clouds-yaml``.
