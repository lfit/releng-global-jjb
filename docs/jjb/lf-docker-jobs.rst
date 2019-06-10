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

Chooses a container tag to label the image based on the
'container-tag-method' parameter.
If container-tag-method: default, the tag 'latest' is used.
If container-tag-method: git-describe, the tag is obtained using
the git describe command, which requires that the repository has a git tag.
If container-tag-method: yaml-file, the tag is obtained using
the yq command, which requires that the repository has a YAML file named
'container-tag.yaml'. The script checks the docker-root directory by
default or the directory specified by parameter container-tag-yaml-dir.


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
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: Maven settings.xml file containing credentials to use.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :container-tag-method: Specifies the docker tag-choosing method.
        Options are "latest", "git-describe" or "yaml-file".
        Option git-describe requires a git tag to exist in the repository.
        Option yaml-file requires a file "container-tag.yaml" to exist in the repository.
        (default: latest)
    :container-tag-yaml-dir: Directory with container-tag.yaml. (default: $DOCKER_ROOT)
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
    :gerrit_trigger_file_paths: Override Gerrit file paths which can be
        used to filter which file modifications will trigger a build.
    :github_included_regions: Override Github file paths which can be
        used to filter which file modifications will trigger a build;
        must match parameter gerrit_trigger_file_paths


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
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: Maven settings.xml file containing credentials to use.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :container-tag-method: Specifies the docker tag-choosing method.
        Options are "latest", "git-describe" or "yaml-file".
        Option git-describe requires a git tag to exist in the repository.
        Option yaml-file requires a file "container-tag.yaml" to exist in the repository.
        (default: latest)
    :container-tag-yaml-dir: Directory with container-tag.yaml. (default: $DOCKER_ROOT)
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer. No default. Use
        '@daily' to run daily or 'H H * * 0' to run weekly.
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

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override Gerrit file paths which can be
        used to filter which file modifications will trigger a build.
    :github_included_regions: Override Github file paths which can be
        used to filter which file modifications will trigger a build;
        must match parameter gerrit_trigger_file_paths

container-tag.yaml example:

.. code-block:: yaml

   ---
   tag: 1.0.0
