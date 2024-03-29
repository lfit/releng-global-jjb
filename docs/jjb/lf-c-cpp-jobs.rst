##########
C/C++ Jobs
##########

Job Templates
=============

Autotools PackageCloud Stage
----------------------------

Stage job which runs configure && make, then uploads all DEB/RPM files
in the build directory to PackageCloud.io. Triggered by comment.

The default configuration supplies a pre-build script that runs GNU
Autotools to generate the configure shell script. Must be overridden
if that script is in the version-control system.

The Jenkins system must have a configuration file provider that
installs files ".packagecloud" and "packagecloud_api" to the Jenkins
home directory with appropriate credentials.

The Jenkins build minion must have the Ruby gem "package_cloud"
installed.

:Template Names:

    - {project-name}-autotools-packagecloud-stage-{stream}
    - gerrit-autotools-packagecloud-stage
    - github-autotools-packagecloud-stage

:Comment Trigger: stage-release

:Required parameters:

    :build-node: The node to run build on.
    :debian-distribution-versions: list of DEB package distro/version strings
        separated by space; example: "ubuntu/bionic debian/stretch"
    :jenkins-ssh-credential: Credential to use for SSH.
        (Configure in defaults.yaml)
    :packagecloud-account: PackageCloud account ID; example: oran
    :packagecloud-repo: PackageCloud repository; example: master, staging
    :project: The git repository name.
    :project-name: Prefix used to name jobs.
    :rpm-distribution-versions: list of RPM package distro/version strings
        separated by space; example: "el/4 el/5"

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-dir: Directory with package files (default: $WORKSPACE)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :configure-opts: Parameters to pass to configure. (default: '')
    :disable-job: Whether to disable the job (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :install: Install build products to /usr/local. (default: false)
    :install-prefix: Path to use for install. (default: $BUILD_DIR/output)
    :make-opts: Parameters and targets for make. (default: '')
    :pre-build: Shell script to generate the configure file and install
        dependencies. (default: 'autoreconf --install')
    :stream: Keyword that to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

Autotools SonarQube
-------------------

The SonarQube job installs the SonarQube CXX build wrapper, runs
configure, uses the build wrapper to invoke make, then runs the
SonarQube Scanner Jenkins plug-in to analyze code for bugs, code
smells and security vulnerabilities, and to upload the result
(possibly including code-coverage statistics) to a SonarQube server or
to SonarCloud.io. Optionally runs a shell script before the build to
install prerequisites.

The default configuration supplies a pre-build script that runs GNU
Autotools to generate the configure shell script. Must be overridden
if that script is in the version-control system.

Requires ``SonarQube Scanner for Jenkins``

This job runs on the master branch because the basic Sonar
configuration does not support multi-branch.

Plug-in configurations
    Manage Jenkins --> Configure System --> SonarQube servers
        - Name: Sonar (fixed)
        - Server URL: https://sonar.project.org/ or https://sonarcloud.io
        - Server authentication token: none for local, API token (saved as
          a "secret text" credential) for Sonarcloud

    Manage Jenkins --> Global Tool Configuration --> SonarQube Scanner
        - Name: SonarQube Scanner (fixed)
        - Install automatically
        - Select latest version

:Template Names:

    - {project-name}-autotools-sonarqube
    - gerrit-autotools-sonarqube
    - github-autotools-sonarqube

:Comment Trigger: ``run-sonar``

:Required parameters:

    :build-node: The node to run the build on.
        (Commonly in defaults.yaml)
    :jenkins-ssh-credential: Credential to use for SSH.
        (Commonly in defaults.yaml)
    :project: The git repository name.
    :project-name: Prefix used to name jobs.

.. comment Start ignoring WriteGoodLintBear

:Optional Parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :build-wrap-dir: Build wrapper output subdirectory name.
        (default: $WORKSPACE/bw-output)
    :configure-opts: Parameters to pass to configure. (default: '')
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer.  (default: @weekly)
    :disable-job: Whether to disable the job (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :install-prefix: Path to use for install. (default: $BUILD_DIR/output)
    :make-opts: Parameters and targets for make. (default: '')
    :pre-build: Shell script to generate the configure file and install
        dependencies. (default: 'autoreconf --install')
    :sonar-additional-args: Command line arguments. (default: '')
    :sonar-java-opts: JVM options. For example, use option -Xmx
        to increase the memory size limit.  (default: '')
    :sonar-project-file: The file name with Sonar configuration properties
        (default: sonar-project.properties)
    :sonar-properties: Sonar configuration properties. (default: '')
    :sonar-task: Sonar task to run. (default: '')
    :stream: Keyword that to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

.. comment Stop ignoring

.. note:: A job definition must provide one of the optional parameters
    ``sonar-project-file`` and ``sonar-properties``; they cannot both be
    empty.  Set Sonar properties directly in the job definition by setting
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

The following example defines a job for a project with CXX source files
in the "src" directory, and unit tests that write coverage files in
GCOV format to the "test" directory. This definition uses configuration
parameters in the umbrella project's defaults.yaml file.

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
            sonar.sourceEncoding=UTF-8
            sonar.sources=src
            sonar.cfamily.build-wrapper-output=$WORKSPACE/bw-output
            sonar.cfamily.gcov.reportsPath=test
        jobs:
          - gerrit-autotools-sonarqube

Autotools Verify
----------------

Verify job which runs configure && make to test a project build, then
optionally runs make install, copies the build products to /usr/local
and runs ldconfig to make the shared lib(s) available. The install steps
run by default, see parameter "install".

The default configuration supplies a pre-build script that runs GNU
Autotools to generate the configure shell script. Must be overridden
if the script is in the version-control system.

:Template Names:

    - {project-name}-autotools-verify-{stream}
    - gerrit-autotools-verify
    - github-autotools-verify

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH.
        (Configure in defaults.yaml)
    :project: The git repository name.
    :project-name: Prefix used to name jobs.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :configure-opts: Parameters to pass to configure. (default: '')
    :disable-job: Whether to disable the job (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :install: Install build products to /usr/local. (default: true)
    :install-prefix: Path to use for install. (default: $BUILD_DIR/output)
    :make-opts: Parameters and targets for make. (default: 'test')
    :pre-build: Shell script to generate the configure file and install
        dependencies. (default: 'autoreconf --install')
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

CMake Sonar
-----------

The Sonar job installs the SonarQube CXX build wrapper and scanner tools,
runs cmake, uses the build wrapper to invoke make, runs the scanner to
analyze code files, then publishes the results to a SonarQube server like
SonarCloud. Optionally runs a shell script before the build to install
prerequisites. Does not support code coverage reporting.

**Deprecated**; new projects should use a CMake SonarQube template.

This job purposely runs on the master branch because the basic SonarCloud
configuration does not support multi-branch.

:Template Names:

    - {project-name}-cmake-sonar
    - gerrit-cmake-sonar
    - github-cmake-sonar

:Comment Trigger: run-sonar

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Configure in
        defaults.yaml)
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
    :sonarcloud-api-token-cred-id: Jenkins credential ID which has the SonarCloud API Token.
        This one SHOULDN'T be overwritten as per we are standarizing the credential ID for all
        projects (default: 'sonarcloud-api-token')
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_sonar_triggers: Override Gerrit Triggers.

CMake SonarQube
---------------

The SonarQube job installs the SonarQube CXX build wrapper, runs cmake, uses
the build wrapper to invoke make, then runs the SonarQube Scanner Jenkins
plug-in to analyze code for bugs, code smells and security vulnerabilities,
and to upload the result (possibly including code-coverage statistics) to
a SonarQube server or to SonarCloud.io. Optionally runs a shell script
before the build to install prerequisites.

Requires ``SonarQube Scanner for Jenkins``

This job runs on the master branch because the basic Sonar configuration
does not support multi-branch.

Plug-in configurations
    Manage Jenkins --> Configure System --> SonarQube servers
        - Name: Sonar (fixed)
        - Server URL: https://sonar.project.org/ or https://sonarcloud.io
        - Server authentication token: none for local, API token (saved as
          a "secret text" credential) for Sonarcloud

    Manage Jenkins --> Global Tool Configuration --> SonarQube Scanner
        - Name: SonarQube Scanner (fixed)
        - Install automatically
        - Select latest version

:Template Names:

    - {project-name}-cmake-sonarqube
    - gerrit-cmake-sonarqube
    - github-cmake-sonarqube

:Comment Trigger: ``run-sonar``

:Required parameters:

    :build-node: The node to run the build on.
        (Commonly in defaults.yaml)
    :jenkins-ssh-credential: Credential to use for SSH.
        (Commonly in defaults.yaml)
    :project: The git repository name.
    :project-name: Prefix used to name jobs.

.. comment Start ignoring WriteGoodLintBear

:Optional Parameters:

    :archive-artifacts: Pattern for files to archive to the logs server
        (default: '\*\*/\*.log')
    :build-wrap-dir: Build wrapper output subdirectory name.
        (default: $WORKSPACE/bw-output)
    :cmake-opts: Parameters to pass to cmake. (default: '')
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer.  (default: @weekly)
    :install-prefix: CMAKE_INSTALL_PREFIX to use for install.
        (default: $BUILD_DIR/output)
    :make-opts: Parameters to pass to make. (default: '')
    :pre-build: Shell script to run before performing build. Useful for
        setting up dependencies. (default: '')
    :sonar-additional-args: Command line arguments. (default: '')
    :sonar-java-opts: JVM options. For example, use option -Xmx
        to increase the memory size limit.  (default: '')
    :sonar-project-file: The file name with Sonar configuration properties
        (default: sonar-project.properties)
    :sonar-properties: Sonar configuration properties. (default: '')
    :sonar-task: Sonar task to run. (default: '')

.. comment Stop ignoring

.. note:: A job definition must provide one of the optional parameters
    ``sonar-project-file`` and ``sonar-properties``; they cannot both be
    empty.  Set Sonar properties directly in the job definition by setting
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

The following example defines a job for a project with CXX source files
in the "src" directory, and unit tests that write coverage files in
GCOV format to the "test" directory. This definition uses configuration
parameters in the umbrella project's defaults.yaml file.

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
            sonar.sourceEncoding=UTF-8
            sonar.sources=src
            sonar.cfamily.build-wrapper-output=$WORKSPACE/bw-output
            sonar.cfamily.gcov.reportsPath=test
        jobs:
          - gerrit-cmake-sonarqube

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
    :mvn-settings: The name of settings file containing credentials for the project.
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
    :install: Install build products to /usr/local. (default: true)
    :install-prefix: CMAKE_INSTALL_PREFIX to use for install.
        (default: $BUILD_DIR/output)
    :make-opts: Parameters to pass to make. (default: '')
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
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

CMake PackageCloud Stage
------------------------

Stage job which runs cmake && make, then uploads all DEB/RPM files in the
build directory to PackageCloud.io. Triggered by comment.

The Jenkins system must have a configuration file provider that installs
files ".packagecloud" and "packagecloud_api" to the Jenkins home directory
with appropriate credentials.

The Jenkins build minion must have the Ruby gem "package_cloud" installed.

:Template Names:

    - {project-name}-cmake-packagecloud-stage-{stream}
    - gerrit-cmake-packagecloud-stage
    - github-cmake-packagecloud-stage

:Comment Trigger: stage-release

:Required parameters:

    :build-node: The node to run build on.
    :debian-distribution-versions: list of DEB package distro/version strings
        separated by space; example: "ubuntu/bionic debian/stretch"
    :jenkins-ssh-credential: Credential to use for SSH.
        (Configure in defaults.yaml)
    :packagecloud-account: PackageCloud account ID; example: oran
    :packagecloud-repo: PackageCloud repository; example: master, staging
    :project: The git repository name.
    :project-name: Prefix used to name jobs.
    :rpm-distribution-versions: list of RPM package distro/version strings
        separated by space; example: "el/4 el/5"

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-dir: Directory to build the project in. (default: $WORKSPACE/build)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :cmake-opts: Parameters to pass to cmake. (default: '')
    :disable-job: Whether to disable the job (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :install: Install build products to /usr/local. (default: false)
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

CMake Verify
------------

Verify job which runs cmake && make to test a project build, then
runs make install, copies the build products to /usr/local and runs
ldconfig to make the shared lib(s) available. The install steps run
by default, see optional parameter "install".

:Template Names:

    - {project-name}-cmake-verify-{stream}
    - gerrit-cmake-verify
    - github-cmake-verify

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH.
        (Configure in defaults.yaml)
    :project: The git repository name.
    :project-name: Prefix used to name jobs.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-dir: Directory to build the project in. (default: $WORKSPACE/target)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :cmake-opts: Parameters to pass to cmake. (default: '')
    :disable-job: Whether to disable the job (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :install: Install build products to /usr/local. (default: true)
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
