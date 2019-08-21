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

Run CLM scanning against a Python project.

:Required Parameters:

    :clm-project-name: Project name in Nexus IQ to send results to.

lf-infra-pypi-dist-build
------------------------

Runs a shell script that creates and uses a Python virtual environment to
build source and (optionally) binary distributions after installing required
packages. Writes distribution files to subdirectory "dist".

:Required Parameters:

    :dist-binary: Boolean indicator whether to build a bdist_wheel file

lf-infra-pypi-publish
---------------------

Runs a shell script that creates and uses a Python virtual environment to
publish distributions to a PyPI index after installing required packages.
Pushes all distribution files found in subdirectory "dist".

:Required Parameters:

    :pypi-server: PyPI server name; e.g., "staging" or "pypi"

lf-infra-tox-install
--------------------

Install Tox into a virtualenv.

:Required Parameters:

    :python-version: Version of Python to install into the Tox virtualenv.
        Eg. python2 / python3

lf-infra-tox-run
----------------

Runs a shell script that establishes a Python virtual environment.

:Required Parameters:

    :parallel: Boolean. If true use detox (distributed tox);
        else use regular tox.

lf-tox-install
--------------

Runs a shell script that installs tox in a Python virtualenv.

:Required Parameters:

    :python-version: Base Python version to use in the virtualenv. For example
        python2 or python3.


Job Templates
=============

Python XC CLM
-------------

CLM scans for Python based repos. This job will call the Nexus IQ CLI
directly to run the scans.

A new credential named "nexus-iq-xc-clm" needs to exist in the Jenkins credentials.
The credential should contain the username and password to access Nexus
IQ Server.

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

Sonar scans for Python based repos. This job invokes tox to run tests and
gather coverage statistics from the test results, then invokes Maven to
publish the results to a Sonar server.

To get the Sonar coverage results, file tox.ini must exist and contain coverage
commands to run.

The coverage commands define the code that gets executed by the test suites.
Checking coverage does not guarantee that the tests execute properly, but it
identifies code that is not executed by any test.

This job reuses the Sonar builder used in Java/Maven projects which runs maven
twice. The first invocation does nothing for Python projects, so the job uses
the goal 'validate' by default. The second invocation publishes results using
the goal 'sonar:sonar' by default.

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

Tox runner to verify a project. This job is pyenv aware so if the image
contains an installation of pyenv at /opt/pyenv it will pick it up and run
Python tests with the appropriate Python versions. This job will set the
following pyenv variables before running.

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
    :gerrit_trigger_file_paths: Override file paths which used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


PyPI Verify
-----------

Verify job which runs tox, then builds a source distribution and (optionally) a binary
distribution. Requires a setup.py file at the root of the project source repository.

This job is pyenv aware so if the image contains an installation of pyenv at /opt/pyenv
it will pick it up and run Python tests with the appropriate Python versions. This job
will set the following pyenv variables before running.

.. code:: bash

   export PYENV_ROOT="/opt/pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"

:Template Names:

    - {project-name}-pypi-verify-{stream}
    - gerrit-pypi-verify
    - github-pypi-verify

:Comment Trigger: recheck

:Required Parameters:

    :build-node: The node to run build on.
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
    :gerrit_trigger_file_paths: Override file paths which used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


PyPI Merge
----------

Merge job which runs tox, builds a source distribution and (optionally) a binary distribution,
and pushes the distribution(s) to a named PyPI index.  Requires a setup.py file at the root of
the project source repository.  Requires a .pypirc configuration file in the Jenkins builder
home directory, see sample below.

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

This job is pyenv aware so if the image contains an installation of pyenv at /opt/pyenv
it will pick it up and run Python tests with the appropriate Python versions. This job
will set the following pyenv variables before running.

.. code:: bash

   export PYENV_ROOT="/opt/pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"

:Template Names:

    - {project-name}-pypi-merge-{stream}
    - gerrit-pypi-merge
    - github-pypi-merge

:Comment Trigger: pypi-remerge

:Required Parameters:

    :build-node: The node to run build on.
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
    :pypi-server: Key for PyPI index server parameters in the .pypirc file.
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
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. Empty works if tox.ini is at project root.
        (default: '')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_trigger_file_paths: Override file paths which used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


PyPI Release
------------

Job which runs tox, builds source and binary distributions, and pushes them to a named
PyPI index. Requires a setup.py file at the root of the project source repository. Requires
a .pypirc configuration file in the Jenkins builder home directory, see sample below.

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

This job is similar to the PyPI Merge job, but uses different triggers and a different
default PyPI index name. Unlike common LF practice of releasing artifacts by moving them
from one place to another, this job re-builds the distribution artifacts.

This job is pyenv aware so if the image contains an installation of pyenv at /opt/pyenv
it will pick it up and run Python tests with the appropriate Python versions. This job
will set the following pyenv variables before running.

.. code:: bash

   export PYENV_ROOT="/opt/pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"

:Template Names:

    - {project-name}-pypi-release-{stream}
    - gerrit-pypi-release
    - github-pypi-release

:Comment Trigger: pypi-release

:Required Parameters:

    :build-node: The node to run build on.
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
    :pypi-server: Key for PyPI index server parameters in the .pypirc file.
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
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. Empty works if tox.ini is at project root.
        (default: '')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_trigger_file_paths: Override file paths which used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit
