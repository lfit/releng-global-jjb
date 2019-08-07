.. _lf-global-jjb-release:

#######################
Self Serve Release Jobs
#######################

Self serve release jobs allow a project to create a releases/ or .releases/ directory and then place a release yaml file in it.
Jenkins will pick this up and sign the ref extrapolated by log_dir and promote the artifact, whether maven or container.

Maven release jobs can also trigger via "Build with parameters" negating the need for a release file.
The parameters will need to be filled out in the same was as a release file's would, excepting the speacial
RELEASE_FILE parameter which will need to be set to False to inform the job that it should not expect a release file.
The Special Parameters are as follows:

GERRIT_BRANCH = master
VERSION = 1.0.0
LOG_DIR = example-project-maven-stage-master/17/
DISTRIBUTION_TYPE = maven
RELEASE_FILE = False

.. note::

   Example of a maven release file:

.. note::

   Release files regex: (releases\/.*\.yaml|\.releases\/.*\.yaml)
   directory can be .releases/ or releases/
   file can be ANYTHING.yaml


.. code-block:: bash

   $ cat releases/maven-1.0.0.yaml
   ---
   distribution_type: 'maven'
   version: '1.0.0'
   project: 'example-project'
   log_dir: 'example-project-maven-stage-master/17/'


   Example of a container release file:

.. code-block:: bash

   $ cat releases/container-1.0.0.yaml
   ---
   distribution_type: 'container'
   version: '1.0.0'
   project: 'test'
   containers:
       - name: test-backend
         version: 1.0.0-20190806T184921Z
       - name: test-frontend
         version: 1.0.0-20190806T184921Z


.. note::

   Job should be appended under gerrit-maven-stage
   Example of a terse Jenkins job to call global-jjb macro:

.. code-block:: none

    - gerrit-maven-stage:
        sign-artifacts: true
        build-node: centos7-docker-8c-8g
        maven-versions-plugin: true
    - '{project-name}-gerrit-release-jobs':
        build-node: centos7-docker-8c-8g

.. note::

   Release Engineers Please follow the setup guide before adding the job definition:


Setup for LFID Nexus Jenkins and Gerrit:
========================================

LFID
====

Create an ``lfid`` and an ``ssh-key``

``YOUR_RELEASE_USERNAME`` for example: onap-release
``YOUR_RELEASE_EMAIL`` for example: collab-it+onap-release@linuxfoundation.org

ssh-key example:

.. code-block:: bash

   ssh-keygen -t rsa -C "collab-it+odl-release@linuxfoundation.org"  -f /tmp/odl-release


`Create an LFID with the above values <https://identity.linuxfoundation.org>`_


Nexus
=====

Create a Nexus account called ``'jenkins-release'`` with promote privileges.

.. image:: ../_static/nexus-promote-privs.png

Gerrit
======

Log into your Gerrit with ``YOU_RELEASE_USERNAME``, upload the publick part of the ``ssh-key`` you created earlier.
Log out of Gerrit and log in again with your normal account for the next steps.


In Gerrit create a new group called ``self-serve-release`` and give it direct push rights via ``All-Projects``
Add ``YOUR_RELEASE_USERNAME`` to group ``self-serve-release`` and group ``Non-Interactive Users``


In All project, grant group self-serve-release the following:

.. code-block:: none

    [access "refs/heads/*"]
      push = group self-serve-release
    [access "refs/tags/*"]
      createTag = group self-serve-release
      createSignedTag = group self-serve-release
      forgeCommitter = group self-serve-release
      push = group self-serve-release


Jenkins
=======

Add a global credential to Jenkins called ``jenkins-release`` and set the ID: ``'jenkins-release'``
as its value insert the private half of the ``ssh-key`` that you created for your Gerrit user.

Add Global vars in Jenkins:
Jenkins configure -> Global properties -> Environment variables

``RELEASE_USERNAME = YOUR_RELEASE_USERNAME``
``RELEASE_EMAIL = YOUR_RELEASE_EMAIL``

Jenkins configure -> Managed Files -> Add a New Config -> Custom File

id: signing-pubkey
Name: SIGNING_PUBKEY (optional)
Comment: SIGNING_PUBKEY (optional)

Content: (Ask Andy for the public signing key)
-----BEGIN PGP PUBLIC KEY BLOCK-----


Add or edit the managed file in Jenkins called ``lftoolsini``, appending a nexus section:
Jenkins Settings -> Managed files -> Add (or edit) -> Custom file

.. code-block:: none

   [nexus.example.com]
   username=jenkins-release
   password=<plaintext password>

Ci-management
=============

Upgrade your projects global-jjb if needed
add this to your global defaults file (eg: jjb/defaults.yaml).

.. code-block:: bash

   jenkins-ssh-release-credential: 'jenkins-release'

Macros
======

lf-release
----------

Release verify and merge jobs are the same except for their scm, trigger, and
builders definition. This anchor is the common template.

Job Templates
=============

Release Merge
-------------

:Template Name:
    - {project-name}-release-merge

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-release-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :stream: run this job against: **

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: all)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :project-pattern: Project to trigger build against. (default: \*\*)

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: REG_EXP
              pattern: '(releases\/.*\.yaml|\.releases\/.*\.yaml)'


Release Verify
------------------

:Template Names:
    - {project-name}-release-verify

:Comment Trigger: recheck|reverify

:Required Parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :stream: run this job against: **

:Optional Parameters:

    :branch: Git branch to fetch for the build. (default: all)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-node: The node to run build on.
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :doc-dir: Directory where tox will place built docs.
        as defined in the tox.ini (default: docs/_build/html)
    :gerrit-skip-vote: Skip voting for this job. (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :project-pattern: Project to trigger build against. (default: \*\*)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: REG_EXP
              pattern: '(releases\/.*\.yaml|\.releases\/.*\.yaml)'
