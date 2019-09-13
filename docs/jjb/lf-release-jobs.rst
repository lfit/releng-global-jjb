.. _lf-global-jjb-release:

#######################
Self-Serve Release Jobs
#######################

Self-serve release jobs allow a project team to direct Jenkins to
promote a jar file or container image from a staging area to a release
area.  To trigger the action, create a releases/ or .releases/
directory, add a release yaml file to it, and submit a change set with
one release yaml file to Gerrit.  Upon merge of the change, Jenkins will
sign the reference extrapolated by log_dir and promote the artifact. The
expected format of the release yaml file appears in schemas and examples
below.

The build node for maven and container release jobs must be CentOS,
which supports the sigul client for accessing a signing server. The
build node for container release jobs must have Docker installed.

A Jenkins user can also trigger a release job via the "Build with
parameters" action, removing the need for a release yaml file. The
user must enter parameters in the same way as a release yaml file,
except for the special USE_RELEASE_FILE and DRY_RUN check boxes. The
user must uncheck the USE_RELEASE_FILE check box if the job should
run with a release file, while passing the required information as
build parameters. Similarly, the user must uncheck the DRY_RUN check
box to test the job while skipping repository promotion to Nexus.

The special parameters are as follows::

    GERRIT_BRANCH = master
    VERSION = 1.0.0
    LOG_DIR = example-project-maven-stage-master/17/
    DISTRIBUTION_TYPE = maven
    USE_RELEASE_FILE = false
    DRY_RUN = false

.. note::

   The release file regex is: (releases\/.*\.yaml|\.releases\/.*\.yaml).
   In words, the directory name can be ".releases" or "releases"; the file
   name can be anything with suffix ".yaml".

The JSON schema for a maven release job appears below.

.. code-block:: none

    ---
    $schema: "http://json-schema.org/schema#"
    $id: "https://github.com/lfit/releng-global-jjb/blob/master/release-schema.yaml"

    required:
      - "distribution_type"
      - "log_dir"
      - "project"
      - "version"

    properties:
      distribution_type:
        type: "string"
      log_dir:
        type: "string"
      project:
        type: "string"
      version:
        type: "string"


Example of a maven release file:

.. code-block:: bash

    $ cat releases/1.0.0-maven.yaml
    ---
    distribution_type: 'maven'
    version: '1.0.0'
    project: 'example-project'
    log_dir: 'example-project-maven-stage-master/17/'


The JSON schema for a container release job appears below.

.. code-block:: none

    ---
    $schema: "http://json-schema.org/schema#"
    $id: "https://github.com/lfit/releng-global-jjb/blob/master/release-container-schema.yaml"

    required:
      - "containers"
      - "distribution_type"
      - "project"
      - "container_release_tag"
      - "ref"

    properties:
      containers:
        type: "array"
        properties:
          name:
            type: "string"
          version:
            type: "string"
        additionalProperties: false
      distribution_type:
        type: "string"
      project:
        type: "string"
      container_release_tag:
        type: "string"
      container_pull_registry"
        type: "string"
      container_push_registry"
        type: "string"
      ref:
        type: "string"


An example of a container release file appears below.  The job applies the
container_release_tag string to all released containers.  The job uses the
per-container version strings to pull images from the container registry.

.. code-block:: bash

    $ cat releases/1.0.0-container.yaml
    ---
    distribution_type: 'container'
    container_release_tag: '1.0.0'
    container_pull_registry: 'nexus.onap.org:10003"
    container_push_registry: 'nexus.onap.org:10002"
    project: 'test'
    containers:
        - name: test-backend
          version: 1.0.0-20190806T184921Z
        - name: test-frontend
          version: 1.0.0-20190806T184921Z


.. note::

   Job should appear under gerrit-maven-stage

Example of a terse Jenkins job to call the global-jjb macro:

.. code-block:: none

    - gerrit-maven-stage:
        sign-artifacts: true
        build-node: centos7-docker-8c-8g
        maven-versions-plugin: true
    - '{project-name}-gerrit-release-jobs':
        build-node: centos7-docker-8c-8g

.. note::

   Release Engineers: please follow the setup guide below before adding the job definition.


Setup for LFID, Nexus, Jenkins and Gerrit
=========================================

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

Log into your Gerrit with ``YOUR_RELEASE_USERNAME``, upload the public
part of the ``ssh-key`` you created earlier. Log out of Gerrit and log
in again with your normal account for the next steps.


In Gerrit create a new group called ``self-serve-release`` and give it
direct push rights via ``All-Projects`` Add ``YOUR_RELEASE_USERNAME``
to group ``self-serve-release`` and group ``Non-Interactive Users``


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

Add a global credential to Jenkins called ``jenkins-release`` and set
the ID: ``'jenkins-release'`` as its value insert the private half of
the ``ssh-key`` that you created for your Gerrit user.

Add Global vars in Jenkins:
Jenkins configure -> Global properties -> Environment variables

``RELEASE_USERNAME = YOUR_RELEASE_USERNAME``
``RELEASE_EMAIL = YOUR_RELEASE_EMAIL``


.. note::

    These also need to be added to your global-vars-$SILO.sh
    or they will be overwritten.

Jenkins configure -> Managed Files -> Add a New Config -> Custom File

id: signing-pubkey
Name: SIGNING_PUBKEY (optional)
Comment: SIGNING_PUBKEY (optional)

Content: (Ask Andy for the public signing key)
-----BEGIN PGP PUBLIC KEY BLOCK-----


Add or edit the managed file in Jenkins called ``lftoolsini``,
appending a nexus section: Jenkins Settings -> Managed files -> Add
(or edit) -> Custom file

.. code-block:: none

   [nexus.example.com]
   username=jenkins-release
   password=<plaintext password>

Ci-management
=============

Upgrade your project's global-jjb if needed, then add the following to
your global defaults file (e.g., jjb/defaults.yaml).

.. code-block:: none

   jenkins-ssh-release-credential: 'jenkins-release'

Macros
======

lf-release
----------

Release verify and merge jobs are the same except for their scm,
trigger, and builders definition. This anchor is the common template.

Job Templates
=============

Release Merge
-------------

:Template Name: {project-name}-release-merge

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

:Template Name: {project-name}-release-verify

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
