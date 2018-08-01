##########
C/C++ Jobs
##########

Job Templates
=============

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

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which to filter which file
        modifications will trigger a build.
