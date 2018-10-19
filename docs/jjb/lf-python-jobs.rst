###########
Python Jobs
###########

Job Groups
==========

.. include:: ../job-groups.rst

Below is a list of Maven job groups:

.. literalinclude:: ../../jjb/lf-python-job-groups.yaml
   :language: yaml


Macros
======

lf-infra-clm-python
-------------------

Run CLM scanning against a Python project.

:Required Parameters:

    :clm-project-name: Project name in Nexus IQ to send results to.

lf-infra-tox-install
--------------------

Install Tox into a virtualenv.

:Required Parameters:

    :python-version: Version of Python to install into the Tox virtualenv.
        Eg. python2 / python3

lf-infra-tox-sonar
------------------

Runs Sonar scanning against a Python project.

:Required Parameters:

    :java-version: Version of Java to use to run Sonar.
    :mvn-version: Version of Maven to use to run Sonar.

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
    :stream: Keyword used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :gerrit_clm_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit


Python Sonar with Tox
---------------------

Sonar scans for Python based repos. This job will perform a tox call which
runs the coverage command to gather tests results. These test results get
published back into Sonar after running the Sonar goals.

To get the Sonar coverage results, tox.ini needs to exist and configured
with coverage commands to run.

The coverage commands define the code that gets executed by the test suites.
It does not guarantee that the code tests executed properly, but it will help
pointing out the code that is not tested at all.

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
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer.  (default: H 11 * * *
        to run once a day)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-version: Version of maven to use. (default: mvn35)
    :stream: Keyword used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
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
    :python-version: Version of Python to configure as a base in virtualenv.
        (default: python3)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. Empty works if tox.ini is at project root.
        (default: '')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
    :gerrit_trigger_file_paths: Override file paths which used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit
