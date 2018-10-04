##########
C/C++ Jobs
##########

Job Templates
=============

CMake Stage
-----------

Stage job which runs cmake && make && make install and then packages the
project into a tar.xz tarball to produce a release candidate.

:Template Names:

    - {project-name}-cmake-stage-{stream}
    - gerrit-cmake-stage
    - github-cmake-stage

:Comment Trigger: stage-release

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH.
        (Configure in defaults.yaml)
    :nexus-group-id: The Maven style Group ID for the namespace of the project
        in Nexus.
    :staging-profile-id: The unique Nexus Staging Profile ID for the project.
        Contact your infra admin if you do not know it.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-dir: Directory to build the project in. (default: $WORKSPACE/target)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :cmake-opts: Parameters to pass to cmake. (default: '')
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :install-prefix: CMAKE_INSTALL_PREFIX to use for install.
        (default: $BUILD_DIR/output)

        .. code-block:: bash
           :caption: Example

           install-prefix: |
               #!/bin/bash
               echo "Hello World."

    :make-opts: Parameters to pass to make. (default: '')
    :pre-build: Shell script to run before performing build. Useful for
        setting up dependencies. (default: '')
    :stream: Keyword that to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :version: (default: '') Project version to stage release as. There are 2
        methods for using this value:

        1) Defined explicitly here.
        2) Leave this value blank and set /tmp/artifact_version

        Use method 2 in conjunction with 'pre-build' configuration to
        generate the artifact_version automatically from files in the
        project's repository. For example with pre-build script:

        .. code-block:: bash

           #!/bin/bash
           MAJOR_VERSION="$(grep 'set(OCIO_VERSION_MAJOR' CMakeLists.txt | awk '{{print $NF}}' | awk -F')' '{{print $1}}')"
           MINOR_VERSION="$(grep 'set(OCIO_VERSION_MINOR' CMakeLists.txt | awk '{{print $NF}}' | awk -F')' '{{print $1}}')"
           PATCH_VERSION="$(grep 'set(OCIO_VERSION_PATCH' CMakeLists.txt | awk '{{print $NF}}' | awk -F')' '{{print $1}}')"
           echo "${{MAJOR_VERSION}}.${{MINOR_VERSION}}.${{PATCH_VERSION}}" > /tmp/artifact_version

CMake Verify
------------

Verify job which runs cmake && make && make install to test a project build..

:Template Names:

    - {project-name}-cmake-verify-{stream}
    - gerrit-cmake-verify
    - github-cmake-verify

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH.
        (Configure in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-dir: Directory to build the project in. (default: $WORKSPACE/target)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :cmake-opts: Parameters to pass to cmake. (default: '')
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :install-prefix: CMAKE_INSTALL_PREFIX to use for install.
        (default: $BUILD_DIR/output)

        .. code-block:: bash
           :caption: Example

           install-prefix: |
               #!/bin/bash
               echo "Hello World."

    :make-opts: Parameters to pass to make. (default: '')
    :pre-build: Shell script to run before performing build. Useful for
        setting up dependencies. (default: '')
    :stream: Keyword that to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which to filter which file
        modifications will trigger a build.
