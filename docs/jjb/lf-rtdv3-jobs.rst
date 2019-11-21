.. _lf-global-jjb-rtdv3-jobs:

##########################
ReadTheDocs Version:3 Jobs
##########################

ReadTheDocs V3 jobs support documentation that is structured as a
master documentation project plus a sub-project for each software
component.  The master project files are usually maintained in a
"docs" git repository and should contain an index with links to all
the sub-projects. Each sub-project must maintain its documentation
files in a "docs" subdirectory within that software component's git
repository.

The RTDv3 Jenkins jobs publish documentation by triggering builds at
ReadTheDocs.io. That build process clones the appropriate repository
and transforms Real Simple Text (RST) and other files into HTML.
Master project builds are performed separately from sub-project
builds.

The ReadTheDocs site supports multiple versions of documentation for
the master project and every sub-project.  Every project should have a
development branch that's published at ReadTheDocs under the title
"latest"; in git this is usually the "master" branch.  Most projects
also declare releases periodically.  ReadTheDocs automatically detects
the creation of git branches and git tags, and publishes the most
recent one under the title "stable."  For more details please see
`ReadTheDocs Versions
<https://docs.readthedocs.io/en/stable/versions.html>`_.  Teams can
control this process using Jenkins job configuration parameters as
discussed below.

User setup
----------

To transform your rst documentation into a read the docs page, this job must be
configured and created as described in Admin setup below. Once this is complete
the following files must be added to your repository:

.. code-block:: bash

   .readthedocs.yaml
   tox.ini
   docs
   docs/_static
   docs/_static/logo.png
   docs/conf.yaml
   docs/favicon.ico
   docs/index.rst
   docs/requirements-docs.txt
   docs/conf.py

Rather than have you copy and paste these files from a set of docs here, the
following repo contains a script that will do this for you. Please refer to the
explanation presented in: https://github.com/lfit-sandbox/test. This is all
currently a beta feature, so feedback is encouraged. The script
`docs_script.sh` is not needed, you can copy the files by hand if you prefer.

Once these files are correctly configured in your repository you can test
locally:

.. code-block:: bash

   tox -e docs,docs-linkcheck


Stable Branch Instructions
--------------------------

If your project does not create branches, you can skip this step.
Once you branch your project modify your conf.yaml and add the following line:

.. code-block:: bash

   version = 'ReleaseBranchName'

This will update the docs and change "master" on the top bar to your branch
name. This change should be done against your release branch, this change will
trigger a Read The Docs build which will create a new landing point for your
documentation.

This landing point is called /stable/ and is selectable as a version in the
bottom right corner of all Read The Docs pages.  Once all projects have
branched and modified their conf.py they will have available their /stable/
documentation. The process to release the documentation (that is to change the
default landing point of your docs from /latest/ to /stable/) is to change the
default-version in the jenkins job config as follows:

From:

.. code-block:: bash

   default-version: latest

To:

.. code-block:: bash

   default-version: ReleaseBranchName


Admin setup:

This is a global job that only needs to be added once to your project's ci-mangement git
repository. It leverages the read the docs v3 api to create projects on the fly, as well
as setting up subproject associations with the master doc.

Jobs will run but skip any actual verification until a .readthedocs.yaml is placed in the
root of the repository

The master doc must be defined in
jenkins-config/global-vars-{production|sandbox}.sh

Normally this project is called doc or docs or documentation and all other docs build will
be set as a subproject of this job.

examples:

.. code-block:: bash

   global-vars-sandbox.sh:
   MASTER_RTD_PROJECT=doc-test
   global-vars-production.sh:
   MASTER_RTD_PROJECT=doc

In this way sandbox jobs will create docs with a test suffix and will not stomp on production
documentation.

Example job config:

example file: ci-management/jjb/rtd/rtd.yaml

.. code-block:: bash

   ---
   - project:
       name: rtdv3-global-verify
       build-node: centos7-builder-1c-1g
       default-version: latest
       jobs:
         - rtdv3-global-verify
       stream:
         - master:
             branch: master
         - foo:
             branch: stable/{stream}

   - project:
       name: rtdv3-global-merge
       default-version: latest
       build-node: centos7-builder-1c-1g
       jobs:
         - rtdv3-global-merge
       stream:
         - master:
             branch: master
         - foo:
             branch: stable/{stream}

Or add both jobs via a job group:


.. code-block:: bash

   ---
   - project:
       name: rtdv3-global
       default-version: latest
       build-node: centos7-builder-1c-1g
       jobs:
         - rtdv3-global
       stream:
         - master:
             branch: master


Github jobs must be per project, and will be covered by a diffrent set of jobs once these are proven.

Job requires an lftools config section, this is to provide api access to read the docs.

.. code-block:: bash

   [rtd]
   endpoint = https://readthedocs.org/api/v3/
   token = [hidden]

Merge Job will create a project on read the docs if none exist.
Merge Job will assign a project as a subproject of the master project.
Merge job will trigger a build to update docs.
Merge job will change the default version if needed.

Macros
======

lf-rtdv3-common
---------------

RTD verify and merge jobs are the same except for their scm, trigger, and
builders definition. This anchor is the common template.


Job Templates
=============

ReadTheDocs v3 Merge
--------------------

Merge job which triggers a build of the docs to readthedocs.

:Template Names:
    - rtdv3-global-merge-{stream}

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :default-version: default page to redirect to for documentation (default /latest/)
    :disable-job: Whether to disable the job (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :project-pattern: Project to trigger build against. (default: \*\*)
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
              pattern: '^docs\/.*'


ReadTheDocs v3 Verify
---------------------

Verify job which runs a tox build of the docs project.
Also outputs some info on the build.

:Template Names:
    - rtdv3-global-verify-{stream}

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
              pattern: '^docs\/.*'
