###########
Docker Jobs
###########

Job Groups
==========

.. include:: ../job-groups.rst

Below is a list of Docker job groups:

.. literalinclude:: ../../jjb/lf-docker-job-groups.yaml
   :language: yaml


Macros
======

lf-docker-build
----------------

Calls docker-build-param-version.sh or docker-build-pom-version.sh
(depending on the conditions) to perform a docker build and
tag construction.

lf-docker-push
--------------

Calls docker-push.sh script to push docker images.

Job Templates
=============

Docker Verify
-------------

Executes a docker build task.

:Template Names:

    - {project-name}-{stream}-verify-docker

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :docker-tag: Docker tag (or image version) for docker build. (default: latest)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.

Docker Merge
------------

Executes a docker build task and publishes to a SNAPSHOT registry the resulting images.

:Template Names:

    - {project-name}-{stream}-merge-docker

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :docker-tag: Docker tag (or image version) for docker build. (default: latest)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.

