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

Chooses a tag to label the container image based on the
'container-tag-method' parameter using the global-jjb script
docker-get-container-tag.sh. Use one of the following methods:

If ``container-tag-method: latest``, uses the literal string ``latest``.

If ``container-tag-method: stream``, uses the value of the variable ``stream``.

If ``container-tag-method: git-describe``, reads the tag from the
``git describe`` command on the repository, which requires that the repository
has a git tag. For example, if the most recent tag is 'v0.48.1', this
method yields a string like 'v0.48.1' or 'v0.48.1-25-gaee2dcb'.

If ``container-tag-method: yaml-file``, reads the tag from the YAML file
``container-tag.yaml`` in the docker-root directory using the top-level entry
'tag'. Alternately specify the directory with the YAML file in parameter
'container-tag-yaml-dir'. An example file appears next.

Example container-tag.yaml file:

.. code-block:: yaml

   ---
   tag: 1.0.0


Optionally, teams can supply their own script to choose the docker
tag. Pass the shell script path in optional configuration parameter
'docker-get-container-tag-script' which by default is the path to
file docker-get-container-tag.sh. The script must create the file
'env_docker_inject.txt' in the workspace with a line that assigns a
value to shell variable DOCKER_IMAGE_TAG, as shown next.

Example env_docker_inject.txt file:

.. code-block:: shell

    DOCKER_IMAGE_TAG=1.0.0


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

Executes a docker build task to verify an test image build and discards the
test image upon completion.

:Template Names:

    - {project-name}-docker-verify-{stream}
    - gerrit-docker-verify
    - github-docker-verify

:Comment Trigger: **recheck|reverify** post a comment with one of the
    triggers to launch this job manually. Do not include any other
    text or vote in the same comment.

:Required parameters:

    :build-node: The node to run build on.
    :container-public-registry: Docker registry source with base images.
    :docker-name: Name of the Docker image.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)
    :mvn-settings: Maven settings.xml file containing Docker credentials.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :container-tag-method: Specifies the docker tag-choosing method.
        Options are "latest", "git-describe" or "yaml-file".
        Option latest uses the "latest" tag.
        Option git-describe uses the string returned by git-describe,
        which requires a tag to exist in the repository.
        Option yaml-file uses the string from file "container-tag.yaml"
        in the repository. (default: latest)
    :container-tag-yaml-dir: Directory with container-tag.yaml. (default: $DOCKER_ROOT)
    :docker-build-args: Arguments for the docker build command.
    :docker-get-container-tag-script: Path to script that chooses docker tag.
        (default: ../shell/docker-get-container-tag.sh in global-jjb)
    :docker-root: Build directory within the repo. (default: $WORKSPACE, the repo root)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :pre_docker_build_script: Build script to execute before the main verify
        builder steps. (default: "")
    :post_docker_build_script: Build script to execute after the main verify
        builder steps. (default: "")
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override Gerrit file paths to filter which file
        modifications will trigger a build.
    :github_included_regions: Override Github file paths to filter which file
        modifications will trigger a build; must match parameter
        gerrit_trigger_file_paths


container-tag.yaml example:

.. code-block:: yaml

   ---
   tag: 1.0.0

Docker Merge
------------

Executes a docker build task and pushes the resulting image to the specified
Docker registry. If every image is a release candidate, this should use a
staging repository and occassionally run to check dependencies.

:Template Names:

    - {project-name}-docker-merge-{stream}
    - gerrit-docker-merge
    - github-docker-merge

:Comment Trigger: **remerge** post a comment with the trigger to launch
    this job manually. Do not include any other text or vote in the
    same comment.

:Required parameters:

    :build-node: The node to run build on.
    :container-public-registry: Docker registry source with base images.
    :container-push-registry: Docker registry target for the push action.
    :docker-name: Name of the Docker image.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured
        in defaults.yaml)
    :mvn-settings: Maven settings.xml file containing Docker credentials.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :container-tag-method: Specifies the docker tag-choosing method.
        Options are "latest", "git-describe" or "yaml-file".
        Option latest uses the "latest" tag.
        Option git-describe uses the string returned by git-describe,
        which requires a tag to exist in the repository.
        Option yaml-file uses the string from file "container-tag.yaml"
        in the repository. (default: latest)
    :container-tag-yaml-dir: Directory with container-tag.yaml. (default: $DOCKER_ROOT)
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer. Use '@daily' to run
        daily or '@weekly' to run weekly.  (default: @weekly)
    :docker-build-args: Arguments for the docker build command.
    :docker-get-container-tag-script: Path to script that chooses docker tag.
        (default: ../shell/docker-get-container-tag.sh in global-jjb)
    :docker-root: Build directory within the repo. (default: $WORKSPACE, the repo root)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :pre_docker_build_script: Build script to execute before the main merge
        builder steps. (default: "")
    :post_docker_build_script: Build script to execute after the main merge
        builder steps. (default: "")
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override Gerrit file paths to filter which file
        modifications will trigger a build.
    :github_included_regions: Override GitHub file paths to filter which file
        modifications will trigger a build; must match parameter
        gerrit_trigger_file_paths

Sample container-tag.yaml File
------------------------------

.. code-block:: yaml

   ---
   tag: 1.0.0
