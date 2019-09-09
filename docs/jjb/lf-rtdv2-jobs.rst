.. _lf-global-jjb-rtdv2-jobs:

##########################
ReadTheDocs Version:2 Jobs
##########################

This is a global job that only needs to be added once to your project's ci-mangement git repository. It leverages the read the docs v3 api to create projects on the fly, as well as set up subproject associations with the master doc.

The master doc must be defined in
jenkins-config/global-vars-{production|sandbox}.sh

examples:
global-vars-sandbox.sh:
MASTER_RTD_PROJECT=doc-test
global-vars-production.sh:
MASTER_RTD_PROJECT=doc

In this way sandbox jobs will create docs with a test suffix and will not stomp on production documentation.

Example job config:

example file: ci-management/jjb/rtd/rtd.yaml

.. code-block:: bash

    ---
    - project:
        name: rtdv2-verify-global
        build-node: centos7-builder-1c-1g
        jobs:
          - 'rtdv2-verify-global'
        stream:
          - master:
              branch: 'master'
          - foo:
              branch: 'stable/{stream}'

    - project:
        name: rtdv2-merge-global
        build-node: centos7-builder-1c-1g
        jobs:
          - 'rtdv2-merge-global'
        stream:
          - master:
              branch: 'master'
          - foo:
              branch: 'stable/{stream}'

Or add both jobs via a job group:


.. code-block:: bash

    ---
    - project:
        name: rtdv2-global
        build-node: centos7-builder-1c-1g
        jobs:
          - 'rtdv2-global'
        stream:
          - master:
              branch: 'master'


Github jobs must be per project, and will be covered by a diffrent set of jobs once these are proven.

Job requires an lftools config section, this is to provide api access to read the docs.

.. code-block:: bash

    [rtd]
    endpoint = https://readthedocs.org/api/v3/
    token = [hidden]

Verify Job will create a project on read the docs if none exist.
Merge job will trigger a build to update docs.

Macros
======

lf-rtdv2-common
---------------

RTD verify and merge jobs are the same except for their scm, trigger, and
builders definition. This anchor is the common template.


Job Templates
=============

ReadTheDocs Merge
-----------------

Merge job which triggers a build of the docs to readthedocs.

:Template Names:
    - rtdv2-merge-global-{stream}

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
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :disable-job: Whether to disable the job (default: false)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: REG_EXP
              pattern: '.*\.css'
            - compare-type: REG_EXP
              pattern: '.*\.html'
            - compare-type: REG_EXP
              pattern: '.*\.rst'
            - compare-type: REG_EXP
              pattern: '.*\/conf.py'



ReadTheDocs V2 Verify
---------------------

Verify job which runs a tox build of the docs project.
As well as outputting some info on the build

:Template Names:
    - rtdv2-verify-global-{stream}

:Comment Trigger: recheck|reverify

:Required Parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional Parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :gerrit-skip-vote: Skip voting for this job. (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :disable-job: Whether to disable the job (default: false)
    :project-pattern: Project to trigger build against. (default: \*\*)
    :stream: Keyword representing a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: REG_EXP
              pattern: '.*\.css'
            - compare-type: REG_EXP
              pattern: '.*\.html'
            - compare-type: REG_EXP
              pattern: '.*\.rst'
            - compare-type: REG_EXP
              pattern: '.*\/conf.py'
