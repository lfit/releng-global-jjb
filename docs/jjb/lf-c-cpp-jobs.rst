##########
C/C++ Jobs
##########

Job Templates
=============

CMake Sonar
-----------

Sonar job which runs cmake && make then publishes to Sonar.

This job purposely runs on the master branch as there are configuration needed
to support multi-branch.

:Template Names:

    - {project-name}-cmake-sonar
    - gerrit-cmake-sonar
    - github-cmake-sonar

:Comment Trigger: run-sonar

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Configure in
        defaults.yaml)
    :sonar-scanner-version: Version of sonar-scanner to install.
    :sonarcloud-project-key: SonarCloud project key.
    :sonarcloud-project-organization: SonarCloud project organization.
    :sonarcloud-api-token: SonarCloud API Token.

:Optional parameters:

    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
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
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_sonar_triggers: Override Gerrit Triggers.

CMake SonarCloud
----------------

The SonarCloud job installs the SonarQube CXX build wrapper, uses the build
wrapper to invoke cmake && make, then runs the SonarQube Scanner Jenkins
plug-in to analyze code for bugs, code smells and security vulnerabilities,
and to upload the result (possibly including code-coverage statistics) to
a SonarQube server or to SonarCloud.io. Optionally runs a shell script
before the build to install prerequisites.

Requires ``SonarQube Scanner for Jenkins``

A job definition must provide one of the optional parameters sonar-project-file
and sonar-properties; they cannot both be empty.

This job runs on the master branch because the basic SonarCloud configuration
does not support multi-branch.

Plug-in configurations
    Manage Jenkins --> Configure System --> SonarQube servers
        - Name: Sonar (fixed)
        - Server URL: https://sonar.server.org/ or https://sonarcloud.io
        - Server authentication token: none for local, API token (saved as a
          "secret text" credential) for Sonarcloud

    Manage Jenkins --> Global Tool Configuration --> SonarQube Scanner
        - Name: SonarQube Scanner (fixed)
        - Install automatically
        - Select latest version

:Template Names:

    - {project-name}-cmake-sonarcloud
    - gerrit-cmake-sonarcloud
    - github-cmake-sonarcloud

:Comment Trigger: ``run-sonar``

:Required parameters:

    :build-node: The node to run the build on.
        (Commonly in defaults.yaml)
    :jenkins-ssh-credential: Credential to use for SSH.
        (Commonly in defaults.yaml)
    :project: The git repository name.
    :project-name: Prefix used to name jobs.

:Optional Parameters:

    :build-wrap-dir: Build wrapper output subdirectory name.
        (default: $WORKSPACE/bw-output)
    :cmake-opts: Parameters to pass to cmake. (default: '')
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer.  (default: @weekly)
    :install-prefix: CMAKE_INSTALL_PREFIX to use for install.
        (default: $BUILD_DIR/output)
    :make-opts: Parameters to pass to make. (default: '')
    :sonar-add\ itional-args: Command line arguments. (default: '')
    :sonar-java-opts: JVM options. (default: '')
    :sonar-prescan-script: A shell script to run before the build and scan.
         Useful for setting up dependencies. (default: '')
    :sonar-project-file: The filename for the project's properties
        (default: sonar-project.properties)
    :sonar-properties: Sonar configuration properties. (default: '')
    :sonar-task: Sonar task to run. (default: '')

.. the backslash in the sonar-add line above hides a word that Coala hates!

.. note:: Set Sonar properties directly in the job definition by setting
    the ``sonar-project-file`` property to ``""`` and adding all properties
    under ``sonar-properties``.

:Required Sonar Properties:

    - sonar.login: The API token for authentication at SonarCloud.
      Commonly defined as key "sonarcloud_api_token" in defaults.yaml.
    - sonar.organization: The umbrella project name; e.g., "opendaylight".
      Commonly defined as key "sonarcloud_project_organization" in defaults.yaml.
    - sonar.projectName: The git repository name without slashes; e.g., "infrautils".
    - sonar.projectKey: The globally unique key for the report in SonarCloud. Most
      teams use the catenation of sonar.organization, an underscore, and
      sonar.projectName; e.g., "opendaylight_infrautils".

:Optional Sonar Properties:

    - sonar.cfamily.gcov.reportsPath: directory with GCOV output files
    - Documentation of SonarQube properties is here:
      https://docs.sonarqube.org/latest/analysis/overview/


Example job definition
^^^^^^^^^^^^^^^^^^^^^^

The following example defines a Sonar job for a Python repository using
configuration parameters from the umbrella project's defaults.yaml file.

.. code-block:: yaml

    - project:
        name: my-project-sonar
        project: my/project
        project-name: my-project
        sonar-project-file: ""
        sonar-properties: |
            sonar.login={sonarcloud_api_token}
            sonar.projectKey={sonarcloud_project_organization}_{project-name}
            sonar.projectName={project-name}
            sonar.organization={sonarcloud_project_organization}
            sonar.build.sourceEncoding=UTF-8
            sonar.language=py
            sonar.sources=subdir-name
            sonar.inclusions=subdir-name/*.py
            sonar.exclusions=tests/*
            sonar.python.coverage.reportPaths=coverage.xml
        jobs:
          - gerrit-cmake-sonarcloud


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
        project's repository. An example pre-build script appears below.


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
