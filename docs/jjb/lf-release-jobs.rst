.. _lf-global-jjb-release:

#######################
Self Serve Release Jobs
#######################

Self serve release jobs allow a project to create a releases directory and then place a release file in it.
Jenkins will pick this up and then promote the artifact from the staging log directory (log_dir) and tag the release
with the defined version. maven_central_url is optional

.. note::

   Example of a project's release file:

.. code-block:: bash

   $ cat releases/1.0.0.yaml
   ---
   distribution_type: 'maven'
   version: '1.0.0'
   project: 'example-test-release'
   log_dir: 'example-test-release-maven-stage-master/17/'
   maven_central_url: 'oss.sonatype.org'

.. note::

   Example of a terse Jenkins job to call global-jjb macro:

.. code-block:: none

   - project:
       name: '{project-name}-gerrit-release-jobs'
       project: 'example-test-release'
       build-node: centos7-builder-2c-1g
       project-name: example-test-release
       jobs:
         - '{project-name}-gerrit-release-jobs'

.. note::

   Example of a verbose Jenkins job to call global-jjb macro:

.. code-block:: none

   - project:
       name: '{project-name}-releases-verify'
       project: 'example-test-release'
       build-node: centos7-builder-2c-1g
       project-name: example-test-release
       jobs:
         - 'gerrit-releases-verify'

.. code-block:: none

   - project:
       name: '{project-name}-releases-merge'
       project: 'example-test-release'
       build-node: centos7-builder-2c-1g
       project-name: example-test-release
       jobs:
         - 'gerrit-releases-merge'

.. note::

   Release Engineers Please follow the setup guide before adding the job definition:

Setup for LFID Nexus Jenkins and Gerrit:
========================================

LFID
====

Create an ``lfid`` and an ``ssh-key``

``RELEASE_USERNAME``
``RELEASE_EMAIL``

ssh-key example:

.. code-block:: bash

   ssh-keygen -t rsa -C "collab-it+odl-release@linuxfoundation.org"  -f /tmp/odl-release


`Create an LFID <https://identity.linuxfoundation.org>`_

Nexus
=====

Create a Nexus account called ``'jenkins-release'`` with promote privileges.

.. image:: ../_static/nexus-promote-privs.png

Gerrit
======

Log into your Gerrit with ``RELEASE_USERNAME``, upload the ``ssh-key`` you created earlier.
Log out of Gerrit and log in again with your normal account for the next steps.

In Gerrit create a new group called ``self-serve-release`` and give it direct push rights via ``All-Projects``
``push - refs/heads/*``

1. Add a push reference
2. Set the ref as refs/heads/*
3. Make sure "force push" is not checked

Add ``RELEASE_USERNAME`` to group ``self-serve-release`` and group ``Non-Interactive Users``

Give group ``self-serve-release`` Forge Committer rights on ``refs/tags/*``
Give group ``self-serve-release`` Allow on ``Create Signed Tag``
Give group ``self-serve-release`` Allow on ``Create Annotated Tag``

Jenkins
=======

Add a global credential to Jenkins called ``jenkins-release`` and set the ID: ``'jenkins-release'``
as its value insert the ``ssh-key`` that you uploaded to Gerrit.

Add Global vars in Jenkins:
Jenkins configure -> Global properties -> Environment variables

``RELEASE_USERNAME = $RELEASE_USERNAME``
``RELEASE_EMAIL = $RELEASE_EMAIL``

Jenkins configure -> Managed Files -> Custom File

id: signing-pubkey
Name: SIGNING_PUBKEY (optional)
Comment: SIGNING_PUBKEY (optional)

Content: (ask andy)
-----BEGIN PGP PUBLIC KEY BLOCK-----


Add or edit the managed file in Jenkins called ``lftoolsini``, appending a nexus section:
Jenkins Settings -> Managed files -> Add (or edit) -> Custom file

.. code-block:: none

   [nexus]
   username=jenkins-release
   password=redacted

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

Runs:

- sigul-install
- sigul-configuration
- checkout ref from taglist.log
- applies the $PROJECT.bundle
- signs, tags and pushes

.. code-block:: bash

   lftools nexus release --server $NEXUS_URL $STAGING_REPO


:Template Name:
    - {project-name}-release-merge-{stream}

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-release-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :stream: run this job against: master

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :project-pattern: Project to trigger build against. (default: \*\*)
    :tag-repo: Allow or skip Gerrit repo tagging. (default: true)

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: ANT
              pattern: 'releases/*.yaml'


Release Verify
------------------

Release verify job checks the schema and ensures that the staging-repo.txt.gz
is available on the job.

- sigul-install
- sigul-configuration
- checkout ref from taglist.log
- applies the $PROJECT.bundle
- signs and shows signature


:Template Names:
    - {project-name}-release-verify-{stream}

:Comment Trigger: recheck|reverify

:Required Parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-release-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :stream: run this job against: master

:Optional Parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-node: The node to run build on.
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :doc-dir: Directory where tox will place built docs.
        as defined in the tox.ini (default: docs/_build/html)
    :gerrit-skip-vote: Skip voting for this job. (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :project-pattern: Project to trigger build against. (default: \*\*)
    :tag-repo: Allow or skip Gerrit repo tagging. (default: true)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: ANT
              pattern: 'releases/*.yaml'
