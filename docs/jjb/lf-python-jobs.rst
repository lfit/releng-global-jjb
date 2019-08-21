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

lf-infra-clm-python
-------------------

Runs CLM scanning against a Python project.

:Required Parameters:

    :clm-project-name: Project name in Nexus IQ to send results to.

lf-infra-pypi-dist-build
------------------------

Builds a source distribution and optionally a binary distribution in
subdirectory "dist" using a Python virtual environment to install
required packages. The project repository must have a setup.py file
at the root with configuration for packaging the component.

:Required Parameters:

    :dist-binary: Boolean indicator whether to build a bdist_wheel file
    :python-version: Version of Python to configure as base in virtualenv

lf-infra-pypi-tag-release
-------------------------

Checks the format of the tag, checks for the tag in the git repository,
and (in a merge job) creates and pushes the tag.

:Required Parameters:

    :python-version: Version of Python to configure as base in virtualenv

lf-infra-pypi-upload
--------------------

Uploads distribution files from subdirectory "dist" to a PyPI repository
using a Python virtual enviroment to install required packages. The
Jenkins server must have a configuration file ".pypirc".

:Required Parameters:

    :pypi-repo: PyPI repository key in .pypirc; e.g., "staging" or "pypi"
    :python-version: Version of Python to configure as base in virtualenv

lf-infra-tox-install
--------------------

Installs Tox into a virtualenv.

:Required Parameters:

    :python-version: Version of Python to invoke the tox install command
        that creates the virtual environment, either "python2" or "python3".

lf-infra-tox-run
----------------

Creates a Tox virtual environment and invokes tox.

:Required Parameters:

    :parallel: Boolean. If true use detox (distributed tox);
        else use regular tox.


Job Templates
=============

Python XC CLM
-------------

CLM scans for Python based repos. This job will call the Nexus IQ CLI
directly to run the scans.

A new credential named "nexus-iq-xc-clm" needs to exist in the Jenkins
credentials.  The credential should contain the username and password
to access Nexus IQ Server.

:Template Names:

    - {project-name}-python-clm-{stream}
    - gerrit-python-xc-clm
    - github-python-xc-clm

:Comment Trigger: run-clm

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        get configured in defaults.yaml)

:Optional parameters:

    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :nexus-iq-cli-version: Nexus IQ CLI package version to download and use.
        (default: 1.44.0-01)
    :nexus-iq-namespace: Insert a namespace to project AppID for projects that
        share a Nexus IQ system to avoid project name collision. We recommend
        inserting a trailing - dash if using this parameter.
        For example 'odl-'. (default: '')
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :pre-build-script: Shell script to execute before the CLM builder.
        For example, install prerequisites or move files to the repo root.
        (default: a string with a shell comment)
    :stream: Keyword used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :gerrit_clm_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


Python Sonar with Tox
---------------------

Sonar scans for Python based repos. This job invokes tox to run tests
and gather coverage statistics from the test results, then invokes
Maven to publish the results to a Sonar server.

To get the Sonar coverage results, file tox.ini must exist and contain
coverage commands to run.

The coverage commands define the code that gets executed by the test
suites.  Checking coverage does not guarantee that the tests execute
properly, but it identifies code that is not executed by any test.

This job reuses the Sonar builder used in Java/Maven projects which
runs maven twice. The first invocation does nothing for Python
projects, so the job uses the goal 'validate' by default. The second
invocation publishes results using the goal 'sonar:sonar' by default.

For example:

.. code-block:: bash

    [testenv:py27]
    commands =
            coverage run --module pytest --junitxml xunit-results.xml
            coverage xml --omit=".tox/py27/*","tests/*"
            coverage report --omit=".tox/py27/*","tests/*"

For more details refer to coverage and sonar documentation:

https://coverage.readthedocs.io/

https://docs.sonarqube.org/display/PLUG/Python+Coverage+Results+Import

:Template Names:

    - {project-name}-tox-sonar
    - gerrit-tox-sonar
    - github-tox-sonar

:Comment Trigger: run-sonar

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        get configured in defaults.yaml)
    :mvn-settings: The name of the settings file with credentials for the project.

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
    :mvn-global-settings: The name of the Maven global settings to use for
    :mvn-goals: The Maven goal to run first. (default: validate)
    :mvn-version: Version of maven to use. (default: mvn35)
    :parallel: Boolean indicator for tox to run tests in parallel or series.
       (default: false, in series)
    :pre-build-script: Shell script to execute before the Sonar builder.
        For example, install prerequisites or move files to the repo root.
        (default: a string with a shell comment)
    :python-version: Python version (default: python2)
    :sonar-mvn-goal: The Maven goal to run the Sonar plugin. (default: sonar:sonar)
    :stream: Keyword used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :gerrit_sonar_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


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

:Comment Trigger: recheck|reverify

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
    :parallel: Boolean indicator for tox to run tests in parallel or series.
       (default: false, in series)
    :python-version: Version of Python to configure as a base in virtualenv.
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
        the workspace. Empty works if tox.ini is at project root.
        (default: '')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_trigger_file_paths: Override file paths used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
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

:Comment Trigger: remerge

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
        (default: a string with only a comment)
    :python-version: Version of Python to configure as a base in virtualenv.
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
        the workspace. Empty works if tox.ini is at project root.
        (default: '')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_trigger_file_paths: Override file paths used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


PyPI Verify
-----------

Verifies a Python library project on creation of a patch set. Runs
tox then builds a source distribution and (optionally) a binary
distribution.  The project repository must have a setup.py file
with configuration for packaging the component.

The tox runner is pyenv aware so if the image contains an installation
of pyenv at /opt/pyenv it will pick it up and run Python tests with
the appropriate Python versions. The tox runner sets the following pyenv
variables before running.

.. code:: bash

   export PYENV_ROOT="/opt/pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"

:Template Names:

    - {project-name}-pypi-verify-{stream}
    - gerrit-pypi-verify
    - github-pypi-verify

:Comment Trigger: recheck

:Required Parameters:

    :build-node: The node to run the build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional Parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :dist-binary: Whether to build a binary wheel distribution. (default: true)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :parallel: Boolean indicator for tox to run tests in parallel or series.
       (default: false, in series)
    :pre-build-script: Shell script to execute before the tox builder. For
        example, install system prerequisites. (default: a shell comment)
    :python-version: Version of Python to configure as a base in virtualenv.
        (default: python3)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :tox-dir: Directory containing the project's tox.ini, relative to
        the workspace. Leave empty if tox.ini is at the project root.
        (default: '')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_trigger_file_paths: Override file paths which used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


PyPI Merge
----------

Creates and uploads distribution files upon merge of a patch set.
Runs tox, builds a source distribution and (optionally) a binary
distribution, and pushes the distribution(s) to a named PyPI index.
This job should be configured to use a staging PyPI repository like
testpypi.python.org, not a public release area like the global
PyPI repository. Like the verify job, requires a setup.py file for
for packaging the component.

The tox runner is pyenv aware so if the image contains an installation
of pyenv at /opt/pyenv it will pick it up and run Python tests with the
appropriate Python versions. The tox runner sets the following pyenv
variables before running.

.. code:: bash

   export PYENV_ROOT="/opt/pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"


Requires a .pypirc configuration file in the Jenkins builder home
directory, an example appears next.

.. code-block:: bash

    [distutils] # this tells distutils what package indexes you can push to
    index-servers =
    staging
    pypi

    [staging]
    repository: https://testpypi.python.org/pypi
    username: your_username
    password: your_password

    [pypi]
    repository: https://pypi.python.org/pypi
    username: your_username
    password: your_password


:Template Names:

    - {project-name}-pypi-merge-{stream}
    - gerrit-pypi-merge
    - github-pypi-merge

:Comment Trigger: pypi-remerge

:Required Parameters:

    :build-node: The node to run the build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional Parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :dist-binary: Whether to build a binary wheel distribution. (default: true)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :parallel: Boolean indicator for tox to run tests in parallel or series.
       (default: false, in series)
    :pre-build-script: Shell script to execute before the tox builder. For
        example, install system prerequisites. (default: a shell comment)
    :pypi-repo: Key for PyPI repository parameters in the .pypirc file.
        Merge jobs should use a server like testpypi.python.org.  (default: staging)
    :python-version: Version of Python to configure as a base in virtualenv.
        (default: python3)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :tox-dir: Directory containing the project's tox.ini, relative to
        the workspace. Leave empty if tox.ini is at the project root.
        (default: '')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_trigger_file_paths: Override file paths which used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


PyPI Release Verify
-------------------

Verifies a Python library project on creation of a patch set with a
release yaml file. Runs runs tox, builds source and (optionally)
binary distributions, verifies that distribution file names contain
the release version from the release yaml file, and checks that no tag
exists in the code repository for the release version.

To initiate the release process, create a releases/ or .releases/
directory at the root of the project repository, add one release yaml
file to it, and submit a change set with that release yaml file. The
schema and and example for the release yaml file appear below.  The
version must be a valid Semantic Versioning (SemVer) string, matching
either the pattern "v#.#.#" or "#.#.#" where "#" is one or more
digits.

This job is similar to the PyPI verify job, but is only triggered by a
patch set with release yaml file.

The build node for PyPI release verify jobs must be CentOS, which
supports the sigul client for accessing a signing server.

.. note::

   The release file regex is: (releases\/.*\.yaml|\.releases\/.*\.yaml).
   In words, the directory name can be ".releases" or "releases"; the file
   name can be anything with suffix ".yaml".

The JSON schema for a pypi release file appears below.

.. code-block:: none

    ---
    $schema: "http://json-schema.org/schema#"
    $id: "https://github.com/lfit/releng-global-jjb/blob/master/release-pypi-schema.yaml"

    required:
      - "project"
      - "version"

    properties:
      distribution_type:
        type: "string"
      project:
        type: "string"
      version:
        type: "string"


An example of a pypi release file appears below.

.. code-block:: none

    $ cat releases/1.0.0-pypi.yaml
    ---
    distribution_type: pypi
    version: 1.0.0
    project: 'example-project'


:Template Names:

    - {project-name}-pypi-release-verify-{stream}
    - gerrit-pypi-release-verify
    - github-pypi-release-verify

:Required Parameters:

    :build-node: The node to run build on, which must be Centos.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional Parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :dist-binary: Whether to build a binary wheel distribution. (default: true)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :parallel: Boolean indicator for tox to run tests in parallel or series.
       (default: false, in series)
    :pre-build-script: Shell script to execute before the tox builder.
        For example, install prerequisites or move files to the repo root.
        (default: a string with a shell comment)
    :pypi-repo: Key for PyPI repository parameters in the .pypirc file.
        Release jobs should use a server like pypy.org.  (default: pypi)
    :python-version: Version of Python to configure as a base in virtualenv.
        (default: python3)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :tox-dir: Directory containing the project's tox.ini, relative to
        the workspace. Leave empty if tox.ini is at the project root.
        (default: '')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :use-release-file: Whether to use the release file. (default: true)
    :gerrit_trigger_file_paths: Override file paths used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


PyPI Release Merge
------------------

Publishes a Python library on merge of a patch set with a release yaml
file. Runs tox, builds source and (optionally) binary distributions,
verifies that distribution file names contain the release version
string, checks that no tag exists in the code repository for the
release version, tags the code repository with the release version,
then pushes artifacts to a named PyPI repository.

This job is similar to the PyPI merge job, but is only triggered by
merge of a release yaml file and performs additional checks
appropriate before pushing to a public repository such as PyPI.

See the PyPI Release Verify job above for documentation of the release
yaml file format.

The build node for PyPI release merge jobs must be CentOS, which
supports the sigul client for accessing a signing server.

A Jenkins user can also trigger this release job via the "Build with
parameters" action, removing the need to merge a release yaml file.
The user must enter parameters in the same way as a release yaml file,
except for the special USE_RELEASE_FILE and DRY_RUN check boxes. The
user must uncheck the USE_RELEASE_FILE check box if the job should run
with a release file, while passing the required information as build
parameters. Similarly, the user must uncheck the DRY_RUN check box to
test the job while skipping repository promotion to Nexus.

The special parameters are as follows::

    VERSION = 1.0.0
    USE_RELEASE_FILE = false
    DRY_RUN = false

:Template Names:

    - {project-name}-pypi-release-merge-{stream}
    - gerrit-pypi-release-merge
    - github-pypi-release-merge

:Required Parameters:

    :build-node: The node to run build on, which must be Centos.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional Parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :dist-binary: Whether to build a binary wheel distribution. (default: true)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :parallel: Boolean indicator for tox to run tests in parallel or series.
       (default: false, in series)
    :pre-build-script: Shell script to execute before the tox builder.
        For example, install prerequisites or move files to the repo root.
        (default: a string with a shell comment)
    :pypi-repo: Key for PyPI repository parameters in the .pypirc file.
        Release jobs should use a server like pypy.org.  (default: pypi)
    :python-version: Version of Python to configure as a base in virtualenv.
        (default: python3)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :tox-dir: Directory containing the project's tox.ini, relative to
        the workspace. Leave empty if tox.ini is at the project root.
        (default: '')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :use-release-file: Whether to use the release file. (default: true)
    :gerrit_trigger_file_paths: Override file paths used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit
