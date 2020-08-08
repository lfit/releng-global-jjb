.. _lf-global-jjb-rtdv3-jobs:

##########################
ReadTheDocs Version:3 Jobs
##########################

ReadTheDocs supports the nesting of projects, by configuring a project as a
subproject of another project. This allows for documentation projects to share
a search index and a namespace or custom domain, while still maintained
independently of each other.

The master Read The Docs project files, maintained in a "docs" Git repository
should contain an index with links to all the sub-projects. Each sub-project
must maintain its documentation files in a "docs" subdirectory within that
software component's Git repository.

The RTDv3 Jenkins jobs publish documentation by triggering builds at
ReadTheDocs.io. That build process clones the appropriate repository
and transforms reStructuredText (RST) and other files into HTML.
All project's Read the Docs builds separately from sub-project builds.

The Read The Docs site supports versioned documentation for the master project
and every sub-project.  Every project should have a development branch that's
published at ReadTheDocs under the title "latest"; in Git this is the "master"
branch although can be different in some projects.  Most projects also declare
releases periodically.  ReadTheDocs automatically detects the creation of git
branches and git tags, and publishes the most recent one under the title
"stable."  For more details please see `ReadTheDocs Versions
<https://docs.readthedocs.io/en/stable/versions.html>`_.  Teams can
control this process using Jenkins job configuration parameters as
discussed below.

User setup
----------

To transform your rst documentation into a Read The Docs page, configure as
described in Admin setup below. Once this is complete, add the following files
to your repository:

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

Rather than copying and pasting these files from a set of docs here, the
following repo contains a script that will do this for you. Please refer to the
explanation presented in: <https://github.com/lfit-sandbox/test>. This is a
beta feature, so please send feedback on your experiences. Once complete, the
script ``docs_script.sh`` is not needed. You can copy the files by hand if you
prefer.

The default location of the tox.ini file is in the git repository root
directory. Optionally your documentation lead may decide to store all tox files
within the required "docs" subdirectory by setting configuration option
"tox-dir" to value "docs/" as discussed below.

If your project's tox dir is ``docs/`` and not ``.``, update the tox.ini
configuration with the correct relative paths.

You must also set the doc-dir. For example, from the default of
``doc-dir: "docs/_build/html"`` to ``doc-dir: "_build/html"``, as the relative
path in the tox run has changed.

Once configured, in your repository you can build the rst files locally to
test:

.. code-block:: bash

   tox -e docs,docs-linkcheck


Stable Branch Instructions
--------------------------

If your project does not create branches, you can skip this step.

For Read The Docs to see your new branch, trigger a build to force RTD to run
an update. Use a trivial change to any file in your project's ``/docs/``
directory on your newly minted branch to trigger a build and activate your
project's new branch on Read The Docs. This will create a new selectable
version in the bottom right corner of your project's Read The Docs page.
Once all projects have branched the process to release the documentation
(that is to change the default landing point of your docs from /latest/ to /branchname/)
is to change the default-version in the jenkins job config as follows:

From:

.. code-block:: bash

   default-version: latest

To:

.. code-block:: bash

   default-version: ReleaseBranchName


Admin setup:
------------

This part of the documentation explains how to enable this job so that It will trigger
on docs/* changes for all projects in a Gerrit instance. It leverages the
Read The Docs v3 api to create projects on the fly, as well as setting up
sub-project associations with the master doc.

A ``.readthedocs.yaml`` must exist in the root of the repository otherwise the
jobs will run but skip actual verification.

Define the master doc in jenkins-config/global-vars-{production|sandbox}.sh

This project named "doc" or "docs" or "documentation" will set all other docs
builds as a subproject of this job.

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
       tox-dir: "."
       doc-dir: "docs/_build/html"
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
       tox-dir: "."
       doc-dir: "docs/_build/html"
       build-node: centos7-builder-1c-1g
       jobs:
         - rtdv3-global-merge
       stream:
         - master:
             branch: master
         - foo:
             branch: stable/{stream}

Or add both jobs via a job group:
This real-world example also shows how to configure your builds to use
a tox.ini that lived inside your docs/ dir


.. code-block:: bash

   # Global read the docs version 3 jobs
   #
   # jobs trigger for all projects, all branches
   # on any changes to files in a docs/ directory
   # and publish subprojects to readthedocs.io
   # using credentials from Jenkins settings
   ---
   - project:
       name: rtdv3-view
       project-name: rtdv3-global
       views:
         - project-view

   - project:
       name: rtdv3-global
       default-version: latest
       tox-dir: "docs/"
       doc-dir: "_build/html"
       build-node: centos7-builder-2c-1g
       # override the default to ignore ref-updated-event (tag)
       gerrit_merge_triggers:
         - change-merged-event
         - comment-added-contains-event:
             comment-contains-value: remerge$
       jobs:
         - rtdv3-global-verify
         - rtdv3-global-merge
       stream:
         - master:
             branch: '*'

GitHub jobs must be per-project. Once proven, a different set of jobs will be available.

Job requires an lftools config section, this is to provide api access to read the docs.

.. code-block:: bash

   [rtd]
   endpoint = https://readthedocs.org/api/v3/
   token = [hidden]

Merge Job will create a project on Read The Docs if none exist.
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

Merge job which triggers a build of the docs to Read The Docs.

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
    :tox-dir: Directory containing the project's Read The Docs tox.ini
    :doc-dir: Relative directory project's docs generated by tox
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
    :tox-dir: Directory containing the project's Read The Docs tox.ini
    :doc-dir: Relative directory project's docs generated by tox
    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: REG_EXP
              pattern: '^docs\/.*'
