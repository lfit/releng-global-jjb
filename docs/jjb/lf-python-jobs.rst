###########
Python Jobs
###########

Job Groups
==========

.. include:: ../job-groups.rst

Below is a list of Python job groups:

.. literalinclude:: ../../jjb/lf-python-job-groups.yaml
   :language: yaml


Macros
======

lf-infra-nexus-iq-python-cli
----------------------------

Runs Nexus IQ command-line interface CLM scan on Python package requirements.

:Required Parameters:

    :nexus-iq-project-name: Project name in Nexus IQ to send results to.
    :requirements-file: File name with output of pip freeze.

lf-infra-tox-install
--------------------

Installs Tox into a virtualenv.

:Required Parameters:

    :python-version: Version of Python to invoke the pip install of the tox-pyenv
        package that creates a virtual environment, either "python2" or "python3".

lf-infra-tox-run
----------------

Creates a Tox virtual environment and invokes tox.

:Required Parameters:

    :parallel: If different from false, try pass this parameter to tox option
        "--parallel" to parallelize jobs in the envlist (and then activate the
        option "--parallel-live" to display output in logs).
        Possible values are "auto" (equivalent to "true" for legacy),
        "all" or any integer. Any other value is equivalent to "false".


Job Templates
=============

Tox Nexus IQ CLM
----------------

The Nexus IQ job invokes tox and the Nexus IQ scanner to analyze packages for
component lifecycle management (CLM).  Runs tox to discover the required packages,
downloads the command-line interface (CLI) scanner, runs the scanner on the package
list, then uploads the results to a Nexus IQ server. The project's tox.ini file must
define a test environment that runs 'pip freeze' and captures the output; that
environment does not need to execute any tests. For example:

.. code-block:: bash

    [testenv:clm]
    # use pip to report dependencies with versions
    whitelist_externals = sh
    commands = sh -c 'pip freeze > requirements.txt'


This job runs on the master branch because the basic Nexus IQ configuration
does not support multi-branch.

:Template Names:

    - {project-name}-tox-nexus-iq-clm
    - gerrit-tox-nexus-iq-clm
    - github-tox-nexus-iq-clm

:Comment Trigger: ``run-clm``

:Required parameters:

    :build-node: The node to run the build on.
        (Commonly in defaults.yaml)
    :jenkins-ssh-credential: Credential to use for SSH.
        (Commonly in defaults.yaml)
    :project: The git repository name.
    :project-name: Prefix used to name jobs.

:Optional Parameters:

    :archive-artifacts: Pattern for files to archive to the logs server
        (default: '\*\*/\*.log')
    :branch: Git branch, should be master (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via the YAML pipe | character to allow
        more than 1 cron timer.  (default: @weekly)
    :disable-job: Whether to disable the job (default: false)
    :gerrit_nexusiq_triggers: Override Gerrit Triggers.
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :github-url: URL for Github. (default: https://github.com)
    :java-version: Version of Java to use for the scan. (default: openjdk8)
    :nexus-iq-cli-version: Nexus IQ CLI package version to download and use.
        (default is a string like 1.89.0-02, see file lf-python-jobs.yaml)
    :nexus-iq-namespace: Insert a namespace to project AppID for projects that
        share a Nexus IQ system to avoid project name collision. We recommend
        inserting a trailing - dash if using this parameter.
        For example 'odl-'. (default: '')
    :pre-build-script: Shell script to run before tox. Useful for setting up
        dependencies. (default: a string with a shell comment)
    :python-version: Python version to invoke pip install of tox-pyenv
        (default: python3)
    :requirements-file: Name of file with output of pip freeze.
        (default: requirements.txt)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. The default uses tox.ini at the project root.
        (default: '.')
    :tox-envs: Tox environment with the appropriate pip freeze invocation.
        (default: 'clm')


Python Sonar with Tox
---------------------

Sonar scans for Python based repos. This job invokes tox to run tests
and gather coverage statistics from the test results, then invokes
Maven to publish the results to either a Sonar server or SonarCloud.

**Deprecated**, new projects should use Tox Sonarqube.

To get the Sonar coverage results, file tox.ini must exist and contain
coverage commands to run.

The coverage commands define the code that gets executed by the test
suites.  Checking coverage does not guarantee that the tests execute
properly, but it identifies code that is not executed by any test.

This job reuses the Sonar builders used for Java/Maven projects which
run maven twice. The first invocation does nothing for Python
projects, so the job uses the goal ``validate`` by default. The second
invocation publishes results using the goal ``sonar:sonar`` by default.

For example:

.. code-block:: bash

    [testenv:py3]
    commands =
            coverage run --module pytest --junitxml xunit-results.xml
            coverage xml --omit=".tox/py3/*","tests/*"
            coverage report --omit=".tox/py3/*","tests/*"

For more details refer to coverage and sonar documentation:

https://coverage.readthedocs.io/

https://docs.sonarqube.org/display/PLUG/Python+Coverage+Results+Import

:Template Names:

    - {project-name}-tox-sonar
    - gerrit-tox-sonar
    - github-tox-sonar

:Comment Trigger: **run-sonar** post a comment with the trigger to launch
    this job manually. Do not include any other text or vote in the
    same comment.

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        get configured in defaults.yaml)
    :mvn-settings: The name of the settings file with credentials for the project.

.. comment Start ignoring WriteGoodLintBear

:Optional parameters:

    :branch: Git branch, should be master (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer.  (default: H 11 * * *
        to run once a day)
    :disable-job: Whether to disable the job (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :github-url: URL for Github. (default: https://github.com)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use
    :mvn-goals: The Maven goal to run first. (default: validate)
    :mvn-version: Version of maven to use. (default: mvn35)
    :parallel: If different from false, try pass this parameter to tox option
        "--parallel" to parallelize jobs in the envlist (and then activate the
        option "--parallel-live" to display output in logs).
        Possible values are "auto" (equivalent to "true" for legacy),
        "all" or any integer. Any other value is equivalent to "false".
        (default: false, in series)
    :pre-build-script: Shell script to execute before the Sonar builder.
        For example, install prerequisites or move files to the repo root.
        (default: a string with a shell comment)
    :python-version: Python version to invoke pip install of tox-pyenv
        (default: python2)
    :sonarcloud: Boolean indicator to use SonarCloud ``true|false``.
        (default: false)
    :sonarcloud-project-key: SonarCloud project key. (default: '')
    :sonarcloud-project-organization: SonarCloud project organization.
        (default: '')
    :sonarcloud-api-token: SonarCloud API Token. (default: '')
    :sonar-mvn-goal: The Maven goal to run the Sonar plugin. (default: sonar:sonar)
    :stream: Keyword used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. The default uses tox.ini at the project root.
        (default: '.')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_sonar_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths used to filter which file
        modifications trigger a build. Refer to JJB documentation for "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit

.. comment Stop ignoring


Tox SonarQube
-------------

The SonarQube job invokes tox to run tests and generate code-coverage
statistics, then runs the SonarQube Scanner Jenkins plug-in to analyze
code, gather coverage data, and upload the results to a SonarQube server
such as SonarCloud.io. Optionally runs a shell script before tox.

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

    - {project-name}-tox-sonarqube
    - gerrit-tox-sonarqube
    - github-tox-sonarqube

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
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer.  (default: @weekly)
    :disable-job: Whether to disable the job (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :github-url: URL for Github. (default: https://github.com)
    :parallel: If different from false, try pass this parameter to tox option
        "--parallel" to parallelize jobs in the envlist (and then activate the
        option "--parallel-live" to display output in logs).
        Possible values are "auto" (equivalent to "true" for legacy),
        "all" or any integer. Any other value is equivalent to "false".
        (default: false, in series)
    :pre-build-script: Shell script to run before tox. Useful for setting up
        dependencies. (default: a string with a shell comment)
    :python-version: Python version to invoke pip install of tox-pyenv
        (default: python3)
    :sonar-additional-args: Command line arguments. (default: '')
    :sonar-java-opts: JVM options. For example, use option -Xmx
        to increase the memory size limit.  (default: '')
    :sonar-project-file: The file name with Sonar configuration properties
        (default: sonar-project.properties)
    :sonar-properties: Sonar configuration properties. (default: '')
    :sonar-task: Sonar task to run. (default: '')
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. The default uses tox.ini at the project root.
        (default: '.')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')

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

The following example defines a job for a basic Python project. This definition
uses configuration parameters in the umbrella project's defaults.yaml file.

.. code-block:: yaml

    - project:
        name: my-package-sonar
        project: my/package
        project-name: my-package
        sonar-project-file: ""
        sonar-properties: |
            sonar.login={sonarcloud_api_token}
            sonar.projectKey={sonarcloud_project_organization}_{project-name}
            sonar.projectName={project-name}
            sonar.organization={sonarcloud_project_organization}
            sonar.sourceEncoding=UTF-8
            sonar.sources=mypackage
            sonar.exclusions=tests/*,setup.py
            sonar.python.coverage.reportPaths=coverage.xml
        jobs:
          - gerrit-tox-sonarqube


Tox Verify
----------

Tox runner to verify a project on creation of a patch set.  This job
is pyenv aware so if the image contains an installation of pyenv at
/opt/pyenv it will pick it up and run Python tests with the
appropriate Python versions. This job will set the following pyenv
variables before running.

.. code:: bash

   export PYENV_ROOT="/opt/pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"

:Template Names:

    - {project-name}-tox-verify-{stream}
    - gerrit-tox-verify
    - github-tox-verify

:Comment Trigger: **recheck|reverify** post a comment with one of the
    triggers to launch this job manually. Do not include any other
    text or vote in the same comment.

:Required Parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional Parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :pre-build-script: Shell script to execute before the Tox builder.
        For example, install prerequisites or move files to the repo root.
        (default: a string with a shell comment)
    :parallel: If different from false, try pass this parameter to tox option
        "--parallel" to parallelize jobs in the envlist (and then activate the
        option "--parallel-live" to display output in logs).
        Possible values are "auto" (equivalent to "true" for legacy),
        "all" or any integer. Any other value is equivalent to "false".
        (default: false, in series)
    :python-version: Python version to invoke pip install of tox-pyenv
        (default: python2)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. The default uses tox.ini at the project root.
        (default: '.')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_trigger_file_paths: Override file paths used to filter which file
        modifications trigger a build. Refer to JJB documentation for "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


Tox Merge
---------

Tox runner to verify a project after merge of a patch set.  This job
is pyenv aware so if the image contains an installation of pyenv at
/opt/pyenv it will pick it up and run Python tests with the
appropriate Python versions. This job will set the following pyenv
variables before running.

.. code:: bash

   export PYENV_ROOT="/opt/pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"

:Template Names:

    - {project-name}-tox-merge-{stream}
    - gerrit-tox-merge
    - github-tox-merge

:Comment Trigger: **remerge** post a comment with the trigger to launch
    this job manually. Do not include any other text or vote in the
    same comment.

:Required Parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional Parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :pre-build-script: Shell script to execute before the CLM builder.
        For example, install prerequisites or move files to the repo root.
        (default: a string with a shell comment)
    :python-version: Python version to invoke pip install of tox-pyenv
        (default: python2)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. The default uses tox.ini at the project root.
        (default: '.')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_trigger_file_paths: Override file paths used to filter which file
        modifications trigger a build. Refer to JJB documentation for "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


PyPI Merge
----------

Creates and uploads package distribution files on merge of a patch set.
Runs tox, builds a source distribution and (optionally) a binary
distribution, and uploads the distribution(s) to a PyPI repository.
The project git repository must have a setup.py file
with configuration for packaging the component.

Projects can choose **either** this template to publish on merge,
**or** the Stage template to publish on command.

This job should use a staging repository like testpypi.python.org,
which sets up use of release jobs to promote the distributions later.
This job can also use a public release area like the global PyPI
repository if the release process is not needed. These PyPI
repositories allow upload of a package at a specific version once,
they do not allow overwrite of a package.  This means that a merge job
will fail in the upload step if the package version already exists in
the target repository.

The tox runner is pyenv aware so if the image contains an installation
of pyenv at /opt/pyenv it will pick it up and run Python tests with
the appropriate Python versions. The tox runner sets the following
pyenv variables before running.

.. code:: bash

   export PYENV_ROOT="/opt/pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"

See the recommended directory layout documented in the PyPI Verify job.

Jobs using this PyPI template depend on a .pypirc configuration file
in the Jenkins builder home directory. An example appears next that uses
API tokens. Note that in the [pypi] entry the repository key-value pair
is optional, it defaults to pypi.org.

.. code-block:: bash

    [distutils] # this tells distutils what package indexes you can push to
    index-servers = pypi-test pypi

    [pypi-test]
    repository: https://test.pypi.org/legacy/
    username: __token__
    password: pypi-test-api-token-goes-here

    [pypi]
    username: __token__
    password: pypi-api-token-goes-here


:Template Names:

    - {project-name}-pypi-merge-{stream}
    - gerrit-pypi-merge
    - github-pypi-merge

:Comment Trigger: **remerge** post a comment with the trigger to launch
    this job manually. Do not include any other text or vote in the
    same comment.

:Required Parameters:

    :build-node: The node to run the build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :mvn-settings: The settings file with credentials for the project
    :project: Git repository name
    :project-name: Jenkins job name prefix

:Optional Parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :cron: Cron schedule when to trigger the job. Supports regular builds.
        Not useful when publishing to pypi.org because that rejects a package
        if the version exists. (default: empty)
    :disable-job: Whether to disable the job (default: false)
    :dist-binary: Whether to build a binary wheel distribution. (default: true)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :mvn-opts: Sets MAVEN_OPTS to start up the JVM running Maven. (default: '')
    :mvn-params: Parameters to pass to the mvn CLI. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :parallel: If different from false, try pass this parameter to tox option
        "--parallel" to parallelize jobs in the envlist (and then activate the
        option "--parallel-live" to display output in logs).
        Possible values are "auto" (equivalent to "true" for legacy),
        "all" or any integer. Any other value is equivalent to "false".
        (default: false, in series)
    :pre-build-script: Shell script to execute before the tox builder. For
        example, install system prerequisites. (default: a shell comment)
    :pypi-repo: Key for the PyPI target repository in the .pypirc file,
        ideally a server like test.pypi.org. (default: pypi-test)
    :python-version: Python version to invoke pip install of tox-pyenv
        (default: python3)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. The default uses tox.ini at the project root.
        (default: '.')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_trigger_file_paths: Override file paths used to filter which file
        modifications trigger a build. Refer to JJB documentation for "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


PyPI Stage
----------

Creates and uploads package distribution files on receipt of a comment.
Runs tox, builds a source distribution and (optionally) a binary
distribution, and uploads the distribution(s) to a PyPI repository.
The project git repository must have a setup.py file with configuration
for packaging the component.

Projects can choose **either** this template to publish on command,
**or** the Merge template to publish on merge.

This job should use a staging repository like testpypi.python.org,
which sets up use of release jobs to promote the distributions later.
This job can also use a public release area like the global PyPI
repository if the release process is not needed. These PyPI
repositories allow upload of a package at a specific version once,
they do not allow overwrite of a package.  This means that a job
will fail in the upload step if the package version already exists in
the target repository.

The tox runner is pyenv aware so if the image contains an installation
of pyenv at /opt/pyenv it will pick it up and run Python tests with
the appropriate Python versions. The tox runner sets the following
pyenv variables before running.

.. code:: bash

   export PYENV_ROOT="/opt/pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"

See the recommended directory layout documented in the PyPI Verify job.

Jobs using this PyPI template depend on a .pypirc configuration file
in the Jenkins builder home directory. An example appears next that uses
API tokens. Note that in the [pypi] entry the repository key-value pair
is optional, it defaults to pypi.org.

.. code-block:: bash

    [distutils] # this tells distutils what package indexes you can push to
    index-servers = pypi-test pypi

    [pypi-test]
    repository: https://test.pypi.org/legacy/
    username: __token__
    password: pypi-test-api-token-goes-here

    [pypi]
    username: __token__
    password: pypi-api-token-goes-here


:Template Names:

    - {project-name}-pypi-stage-{stream}
    - gerrit-pypi-stage
    - github-pypi-stage

:Comment Trigger: **stage-release** post a comment with the trigger to launch
    this job manually. Do not include any other text or vote in the
    same comment.

:Required Parameters:

    :build-node: The node to run the build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :mvn-settings: The settings file with credentials for the project
    :project: Git repository name
    :project-name: Jenkins job name prefix

:Optional Parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :cron: Cron schedule when to trigger the job. Supports regular builds.
        Not useful when publishing to pypi.org because that rejects a package
        if the version exists. (default: empty)
    :disable-job: Whether to disable the job (default: false)
    :dist-binary: Whether to build a binary wheel distribution. (default: true)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :mvn-opts: Sets MAVEN_OPTS to start up the JVM running Maven. (default: '')
    :mvn-params: Parameters to pass to the mvn CLI. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :parallel: If different from false, try pass this parameter to tox option
        "--parallel" to parallelize jobs in the envlist (and then activate the
        option "--parallel-live" to display output in logs).
        Possible values are "auto" (equivalent to "true" for legacy),
        "all" or any integer. Any other value is equivalent to "false".
        (default: false, in series)
    :pre-build-script: Shell script to execute before the tox builder. For
        example, install system prerequisites. (default: a shell comment)
    :pypi-repo: Key for the PyPI target repository in the .pypirc file,
        ideally a server like test.pypi.org. (default: pypi-test)
    :python-version: Python version to invoke pip install of tox-pyenv
        (default: python3)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. The default uses tox.ini at the project root.
        (default: '.')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_trigger_file_paths: Override file paths used to filter which file
        modifications trigger a build. Refer to JJB documentation for "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit

PyPI Verify
-----------

Verifies a Python library project on creation of a patch set. Runs tox
then builds a source distribution and (optionally) a binary
distribution. The project repository must have a setup.py file with
configuration for packaging the component.

Installable package projects should use the directory layout shown
below. All Python files are in a repo subdirectory separate from
non-Python files like documentation. This layout allows highly
specific build-job triggers in Jenkins using the subdirectory
paths. For example, a PyPI publisher job should not run on a non-Python
file change such as documentation, because the job cannot upload the
same package twice.

To make the document files available for building a Python package
long description in setup.py, add a symbolic link "docs" in the
package subdirectory pointing to the top-level docs directory.

.. code-block:: bash

    git-repo-name/
    │
    ├── docs/
    │   ├── index.rst
    │   └── release-notes.rst
    │
    ├── helloworld-package/
    │   │
    │   └── helloworld/
    │   │   ├── __init__.py
    │   │   ├── helloworld.py
    │   │   └── helpers.py
    │   │
    │   ├── tests/
    │   │   ├── helloworld_tests.py
    │   │   └── helloworld_mocks.py
    │   │
    │   ├── requirements.txt
    │   └── setup.py
    │   └── tox.ini
    │
    ├── releases/
    │   └── pypi-helloworld.yaml
    │
    ├── .gitignore
    ├── LICENSE
    └── README.md


The tox runner is pyenv aware so if the image contains an installation
of pyenv at /opt/pyenv it will pick it up and run Python tests with
the appropriate Python versions. The tox runner sets the following
pyenv variables before running.

.. code:: bash

   export PYENV_ROOT="/opt/pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"

:Template Names:

    - {project-name}-pypi-verify-{stream}
    - gerrit-pypi-verify
    - github-pypi-verify

:Comment Trigger: **recheck|reverify** post a comment with one of the
    triggers to launch this job manually. Do not include any other
    text or vote in the same comment.

:Required Parameters:

    :build-node: The node to run the build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :mvn-settings: The settings file with credentials for the project
    :project: Git repository name
    :project-name: Jenkins job name prefix

:Optional Parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :disable-job: Whether to disable the job (default: false)
    :dist-binary: Whether to build a binary wheel distribution. (default: true)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :mvn-opts: Sets MAVEN_OPTS to start up the JVM running Maven. (default: '')
    :mvn-params: Parameters to pass to the mvn CLI. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :parallel: If different from false, try pass this parameter to tox option
        "--parallel" to parallelize jobs in the envlist (and then activate the
        option "--parallel-live" to display output in logs).
        Possible values are "auto" (equivalent to "true" for legacy),
        "all" or any integer. Any other value is equivalent to "false".
        (default: false, in series)
    :pre-build-script: Shell script to execute before the tox builder. For
        example, install system prerequisites. (default: a shell comment)
    :python-version: Python version to invoke pip install of tox-pyenv
        (default: python3)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. The default uses tox.ini at the project root.
        (default: '.')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_trigger_file_paths: Override file paths used to filter which file
        modifications trigger a build. Refer to JJB documentation for "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit
