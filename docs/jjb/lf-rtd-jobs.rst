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

Merge job which triggers a POST of the docs project to readthedocs.  There is some setup
required on read the docs to get started with this.  After you have created the
individual read the docs project (lets call it "PROJECT" here), then browse to
https://readthedocs.org/dashboard/PROJECT/integrations/ and click on
"Generic API incoming webhook".  Here you will see a custom url to trigger the job as
well as a token.  The token will need to be managed in the project Jenkins global-settings
file.  Even though it's only a token you will need to put it in a username/password
credentials type to make it available in the global-settings file.  The custom url can
be set to the variable called ```rtd-build-url``` in your job definition.  Also set the rtd-server-id
to the id you specified in the global-settings file, this will enable the script to parse the token out.
Finally, you have to set ```rtd-project``` to your read the docs project name.

:Template Names:
    - {project-name}-rtd-merge-{stream}
    - gerrit-rtd-merge
    - github-rtd-merge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :rtd-project: This is the name of the project on ReadTheDocs.org.
    :rtd-build-url: This is the generic webhook url from readthedocs.org
    :global-settings-file: This is the location of the Jenkins global settings file.
        This file contains the entry with the location for the readthedocs build token.
    :rtd-server-id: This is the id of the entry in the global-settings-file.


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
