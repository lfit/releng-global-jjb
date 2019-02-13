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

lf-docker-get-container-tag
---------------------------

Calls docker-get-git-describe.sh or docker-get-yaml-tag.sh (depending on the
'docker-use-params-from' condition) to obtain the tag to build.

lf-docker-build
---------------

Calls docker build to build the container.

lf-docker-push
--------------

Calls docker-push.sh script to push docker images.

Job Templates
=============

Docker Verify
-------------

Executes a docker build task.

:Template Names:

    - {project-name}-docker-verify-{stream}
    - gerrit-docker-verify
    - github-docker-verify

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :container-public-registry: Docker registry source with base images.
    :docker-name: Name of the Docker image.
    :docker-use-params-from: Used to select the source of the tag information.
        Options are "git-describe-params" or "yaml-file-params". (yaml-file-params
        expects the tag to be defined in a local file "container-tag.yaml").
    :mvn-settings: Maven settings.xml file containing credentials to use.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :docker-build-args: Additional arguments for the docker build command.
    :docker-root: Path of the Dockerfile within the repo.
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :pre_docker_build_script: Optional build script to execute before the main verify
        builder steps.
    :post_docker_build_script: Optional build script to execute after the main verify
        builder steps.
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.

container-tag.yaml example:

.. code-block:: yaml

   ---
   tag: 1.0.0

Docker Merge
------------

Executes a docker build task and publishes the resulting images to a specified Docker registry.

:Template Names:

    - {project-name}-docker-merge-{stream}
    - gerrit-docker-merge
    - github-docker-merge

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :container-public-registry: Docker registry source with base images.
    :container-push-registry: Docker registry target for the deploy action.
    :docker-name: Name of the Docker image.
    :docker-use-params-from: Used to select the source of the tag information.
        Options are "git-describe-params" or "yaml-file-params". (yaml-file-params
        expects the tag to be defined in a local file "container-tag.yaml").
    :mvn-settings: Maven settings.xml file containing credentials to use.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :docker-build-args: Additional arguments for the docker build command.
    :docker-root: Path of the Dockerfile within the repo.
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :pre_docker_build_script: Optional build script to execute before the main merge
        builder steps.
    :post_docker_build_script: Optional build script to execute after the main merge
        builder steps.
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.

container-tag.yaml example:

.. code-block:: yaml

   ---
   tag: 1.0.0
