###########
Python Jobs
###########

Job Groups
==========

{project-name}-python-jobs
--------------------------

Jobs for Python projects using Gerrit.

:Includes:

    - gerrit-tox-verify

{project-name}-github-python-jobs
---------------------------------

Jobs for Python projects using GitHub.

:Includes:

    - github-tox-verify


Macros
======

lf-tox-install
--------------

Runs a shell script that installs tox in a Python virtualenv.

:Required Parameters:

    :python-version: Base Python version to use in the virtualenv. For example
        python2 or python3.


Job Templates
=============

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

:Required Parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional Parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in seconds before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :python-version: Version of Python to configure as a base in virtualenv.
        (default: python3)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. Empty works if tox.ini is at project root.
        (default: '')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
