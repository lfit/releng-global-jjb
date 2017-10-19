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

Job Templates
=============

Tox Verify
----------

Tox runner to verify a project

:Template Names:

    - {project-name}-tox-verify-{stream}
    - gerrit-tox-verify
    - github-tox-verify

:Required Parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)

:Optional Parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in seconds before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :tox-dir: Directory containing the project's tox.ini relative to
        the workspace. Empty works if tox.ini is at project root.
        (default: '')
    :tox-envs: Tox environments to run. If blank run everything described
        in tox.ini. (default: '')
