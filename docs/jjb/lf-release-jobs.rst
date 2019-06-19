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

terse:

.. code-block:: bash

    ---
    - project:
        name: '{project-name}-gerrit-release-jobs'
        project: 'example-test-release'
        build-node: centos7-builder-2c-1g
        project-name: example-test-release
        jobs:
          - '{project-name}-gerrit-release-jobs'

verbose
#    - project:
#        name: '{project-name}-releases-verify'
#        project: 'example-test-release'
#        build-node: centos7-builder-2c-1g
#        project-name: example-test-release
#        jobs:
#          - 'gerrit-releases-verify'
#    - project:
#        name: '{project-name}-releases-merge'
#        project: 'example-test-release'
#        build-node: centos7-builder-2c-1g
#        project-name: example-test-release
#        jobs:
#          - 'gerrit-releases-merge'

Setup Nexus Jenkins and Gerrit:

[nexus]
1) The Nexus account will need promote priviledges.
(add pictures)

[gerrit]
Create an lfid, with a email that matches (foo) log into gerrit with it and upload ssh key.
2) In gerrit create a new group called self-serve-release and give it direct push rights via All-Projects
push against refs/heads/* (not force)
Also add to non-interactive-users (reword)

[jenkins]
#lftools.ini (where do we put this?)
#reword Look for any other docmentation about lftools.ini and link
lftools nexus release is used so there must be a lftoolsini section in jenkins
configfiles with a [nexus] section for auth.
example:
managed config file called lftoolsini

mention this:
  builders:
    - config-file-provider:
        files:
          - file-id: lftoolsini


[nexus]
username=jenkins
password=redacted

Add a global credential to jenkins called jenkins-releases and set the ID: 'jenkins-releases' as its value insert the ssh-key that you uploaded to gerrit.

Add Global vars in jenkins for all projects using self-serve release
RELEASE_USERNAME
RELEASE_EMAIL

[ci-management]
add this to your global defaults file (eg: jjb/defaults.yaml) as jenkins-ssh-release-credential: 'jenkins-releases'


Upgrade Notes: (reno)

add this to your global defaults file (eg: jjb/defaults.yaml) as jenkins-ssh-release-credential: 'jenkins-releases'

Global vars in jenkins for all projects using self-serve release
RELEASE_USERNAME
RELEASE_EMAIL

#is lftools.ini required? document ini in below
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
    *put this in yellow*
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
