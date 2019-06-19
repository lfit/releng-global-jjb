.. _lf-global-jjb-release:

####################
Releng Release Files
####################

Projects can create a releases directory and then place a release file in it.
Jenkins will pick this up and then promote the artifact from the staging log
directory (log_dir) and tag the release with the defined version.
if a maven_central_url is given artifact will be pushed there as well.

example of a projects release file:

.. code-block:: bash

    $ cat releases/1.0.0.yaml
    ---
    distribution_type: 'maven'
    version: '1.0.0'
    project: 'example-test-release'
    log_dir: 'example-test-release-maven-stage-master/17/'
    maven_central_url: 'oss.sonatype.org'

example of jenkins job to call global-jjb macro: 

.. code-block:: bash

    ---
    - project:
        name: '{project-name}-releases-verify'
        project: 'example-test-release'
        build-node: centos7-builder-2c-1g
        project-name: example-test-release
        jobs:
          - 'gerrit-releases-verify'

    - project:
        name: '{project-name}-releases-merge'
        project: 'example-test-release'
        build-node: centos7-builder-2c-1g
        project-name: example-test-release
        jobs:
          - 'gerrit-releases-merge'



Setup Nexus Jenkins and Gerrit:

[nexus]
1) The Nexus account will need promote priviledges.
(add pictures)

[gerrit]
2) A new account in gerrit with direct push rights via All-Projects, we do not want the the general use account to have those.
(create an lfid, with a project appropriate email log into gerrit with it and add the ssh key.)
jenkins-{top-level-project}-release-ci jenkins{top-level-project}+lf-jobbuilder@linuxfoundation.org 

[jenkins]
lftools nexus release is used so there must be a lftoolsini section in jenkins
configfiles with a [nexus] section for auth.
example:
[nexus]
username=jenkins
password=redacted

Add a global credential to your jenkins called jenkins-releases and copy the ID: 'Example42411ac011' as its value insert the ssh-key you added to you jenkins
add this to your global/releng-defaults.yaml as jenkins-ssh-release-credential: 'Example42411ac011'

- :doc:`lftools nexus release <lftools:commands/nexus-release>`


Macros
======

lf-releases
----------------------

Release verify and merge jobs are the same except for their scm, trigger, and
builders definition. This anchor is the common template.

Job Templates
=============

Release Merge
-------------

Runs:

- sigul-install
- sigul-configuration
- checkout ref from taglist.log
- applies the $PROJECT.bundle
- signs, tags and pushes

.. code-block:: bash

   lftools nexus release --server $NEXUS_URL $STAGING_REPO


:Template Name:
    - {project-name}-releases-merge

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-release-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :stream: run this job against: master

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :project-pattern: Project to trigger build against. (default: \*\*)

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: ANT
              pattern: 'releases/*.yaml'


Release Verify
------------------

Release verify job checks the schema and ensures that the staging-repo.txt.gz
is available on the job.

- sigul-install
- sigul-configuration
- checkout ref from taglist.log
- applies the $PROJECT.bundle
- signs and shows signature


:Template Names:
    - {project-name}-releases-verify

:Comment Trigger: recheck|reverify

:Required Parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :stream: run this job against: master

:Optional Parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-node: The node to run build on.
    :build-timeout: Timeout in minutes before aborting build. (default: 15)
    :doc-dir: Directory where tox will place built docs.
        as defined in the tox.ini (default: docs/_build/html)
    :gerrit-skip-vote: Skip voting for this job. (default: false)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :project-pattern: Project to trigger build against. (default: \*\*)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths filter which checks which
        file modifications will trigger a build.
        **default**::

            - compare-type: ANT
              pattern: 'releases/*.yaml'
