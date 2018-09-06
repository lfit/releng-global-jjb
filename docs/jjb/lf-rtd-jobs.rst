.. _lf-global-jjb-rtd-jobs:

################
ReadTheDocs Jobs
################

Job Groups
==========

.. include:: ../job-groups.rst

Below is a list of Maven job groups:

.. literalinclude:: ../../jjb/lf-rtd-job-groups.yaml
   :language: yaml


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

Merge job which triggers a POST of the docs project to readthedocs.

To use this job first configure the ``Generic API incoming webhook`` in
ReadTheDocs. To do that follow these steps:

#. Browse to https://readthedocs.org/dashboard/PROJECT/integrations/
#. Click on ``Generic API incoming webhook``

   .. note::

      If not available click on ``Add integration`` and add the
      ``Generic API incoming webhook``.

#. Copy the custom webhook URL, this is your ``rtd-build-url``

   For example: https://readthedocs.org/api/v2/webhook/opendaylight/32321/

#. Copy the token, this is your ``rtd-token``

:Template Names:
    - {project-name}-rtd-merge-{stream}
    - gerrit-rtd-merge
    - github-rtd-merge

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :rtd-build-url: This is the generic webhook url from readthedocs.org. Refer
        to the above instructions to generate one.
        (Check Admin > Integrations > Generic API incoming webhook)
    :rtd-token: The unique token for the project Generic webhook. Refer
        to the above instructions to generate one.
        (Check Admin > Integrations > Generic API incoming webhook)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
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
