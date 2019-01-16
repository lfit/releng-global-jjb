.. _lf-global-jjb-releng-release-jobs:

####################
Releng Release Files
####################

Job Groups
==========

.. include:: ../job-groups.rst

Below is a list of Maven job groups:

.. literalinclude:: ../../jjb/lf-releng-release-job-groups.yaml
   :language: yaml


Macros
======

lf-releng-release-jobs
----------------------

:Template Name:
    - lf-releng-release-jobs

Calls releng-release-branch-or-tag.sh

Job Templates
=============

Release Merge
-------------

Merge job which triggers Creating a branch or tag.


:Template Name:
    - releng-release-merge

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :project-pattern: Project to trigger build against. (default: \*\*)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: ANT
              pattern: 'releases/**/*.yaml'
            - compare-type: ANT
              pattern: 'releases/schema.yaml'
            - compare-type: ANT
              pattern: 'releases/scripts/verify_schema.py'

Release Verify
------------------

Verify job which checks schema and checks if the branch or tag exist.

:Template Names:
    - releng-release-verify

:Comment Trigger: recheck|reverify

:Required Parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional Parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-node: The node to run build on.
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :doc-dir: Directory where tox will place built docs.
        as defined in the tox.ini (default: docs/_build/html)
    :gerrit-skip-vote: Skip voting for this job. (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :project-pattern: Project to trigger build against. (default: ci-management)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: ANT
              pattern: 'releases/**/*.yaml'
            - compare-type: ANT
              pattern: 'releases/schema.yaml'
            - compare-type: ANT
              pattern: 'releases/scripts/verify_schema.py'
            - compare-type: ANT
