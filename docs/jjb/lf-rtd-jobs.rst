.. _lf-global-jjb-rtd-jobs:

################
ReadTheDocs Jobs
################

Job Groups
==========

{project-name}-rtd-jobs
-----------------------

Jobs to deploy for a project producing ReadTheDocs using Gerrit.

:Includes:

    - gerrit-rtd-merge
    - gerrit-rtd-verify

{project-name}-github-rtd-jobs
------------------------------

Jobs to deploy for a project producing ReadTheDocs using GitHub.

:Includes:

    - github-rtd-merge
    - github-rtd-verify


Macros
======

lf-rtd-common
-------------

RTD verify and merge jobs are the same except for their scm, trigger, and
builders definition. This anchor is the common template.


Job Templates
=============

ReadTheDocs Merge
-----------------

Merge job which triggers a POST of the docs project to readthedocs

:Template Names:
    - {project-name}-rtd-merge-{stream}
    - gerrit-rtd-merge
    - github-rtd-merge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :rtd-project: This is the name of the project on ReadTheDocs.org.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in seconds before aborting build. (default: 15)
    :git-url: base URL of git project. (default: https://github.com)
    :project-pattern: Project to trigger build against. (default: \*\*)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: ANT
              pattern: '**/*.rst'
            - compare-type: ANT
              pattern: '**/conf.py'


ReadTheDocs Verify
------------------

Verify job which runs a tox build of the docs project

:Template Names:
    - {project-name}-rtd-verify-{stream}
    - gerrit-rtd-verify
    - github-rtd-verify

:Required Parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional Parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-node: The node to run build on.
    :build-timeout: Timeout in seconds before aborting build. (default: 15)
    :doc-dir: Directory where tox will place built docs.
        as defined in the tox.ini (default: docs/_build/html)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :project-pattern: Project to trigger build against. (default: \*\*)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: ANT
              pattern: '**/*.rst'
            - compare-type: ANT
              pattern: '**/conf.py'
