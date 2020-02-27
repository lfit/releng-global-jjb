##########
C/C++ Jobs
##########

Job Templates
=============

CMake Sonar
-----------

The Sonar job installs a Sonar Scanner and a Sonar build wrapper, runs
cmake && make with the build wrapper, runs the scanner, and publishes
the results to SonarCloud. Optionally runs a shell script before the
build to allow installing prerequisites.

This job purposely runs on the master branch only because the basic
SonarCloud configuration does not support multi-branch.

:Template Names:

    - {project-name}-cmake-sonar
    - gerrit-cmake-sonar
    - github-cmake-sonar

:Comment Trigger: run-sonar

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Configure in
        defaults.yaml)
    :sonarcloud-api-token: SonarCloud API Token.
    :sonarcloud-organization: SonarCloud project organization.
    :sonarcloud-project-key: SonarCloud project key.

:Optional parameters:

    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :cmake-opts: Parameters to pass to cmake. (default: '')
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer.  (default: '@daily')
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :install-prefix: CMAKE_INSTALL_PREFIX to use for install.
        (default: $BUILD_DIR/output)
    :make-opts: Parameters to pass to make. (default: '')
    :pre-build: Shell script to run before performing build. Useful for
        setting up dependencies. (default: '')
    :sonar-scanner-version: Version of sonar-scanner to install.
        (see YAML for default value; e.g., 3.3.0.1492)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_sonar_triggers: Override Gerrit Triggers.

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
    :make-opts: Parameters to pass to make. (default: '')
    :pre-build: Shell script to run before performing build. Useful for
        setting up dependencies. (default: '')
    :stream: Keyword that to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
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
    :make-opts: Parameters to pass to make. (default: '')
    :pre-build: Shell script to run before performing build. Useful for
        setting up dependencies. (default: '')
    :stream: Keyword that to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which to filter which file
        modifications will trigger a build.
