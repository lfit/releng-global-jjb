##########
Maven Jobs
##########

Job Groups
==========

.. include:: ../job-groups.rst

Below is a list of Maven job groups:

.. literalinclude:: ../../jjb/lf-maven-job-groups.yaml
   :language: yaml


Macros
======

lf-infra-maven-sonar
--------------------

Runs Sonar against a Maven project.

:Required Parameters:

    :java-version: Version of Java to execute Sonar with.
    :mvn-version: Version of Maven to execute Sonar with.
    :mvn-settings: Maven settings.xml file containing credentials to use.

lf-maven-build
--------------

Calls the maven build script to perform a maven build.

:Required parameters:

    :mvn-goals: The maven goals to perform for the build.
        (default: clean deploy)

lf-maven-common
---------------

Common Jenkins configuration for Maven jobs.

lf-maven-deploy
---------------

Calls the maven deploy script to push artifacts to Nexus.

lf-maven-stage
---------------

Calls the maven stage script to push artifacts to a Nexus staging repository.

lf-update-java-alternatives
---------------------------

Setup Java alternatives for the Distro.

:Required Parameters:

    :java-version: Version of Java to set as the default Java.
        Eg. openjdk8

Job Templates
=============

Maven CLM
---------

Produces a CLM scan of the code into Nexus IQ Server.

:Template Names:

    - {project-name}-maven-clm-{stream}
    - gerrit-maven-clm
    - github-maven-clm

:Comment Trigger: run-clm

:Required parameters:

    :build-node:    The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :nexus-iq-stage: Stage the policy evaluation will be run against on
        the Nexus IQ Server. (default: 'build')
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_merge_triggers: Override Gerrit Triggers.

Maven JavaDoc Publish
---------------------

Produces and publishes javadocs for a Maven project.

Expects javadocs to be available in $WORKSPACE/target/site/apidocs

:Template Names:

    - {project-name}-maven-javadoc-publish-{stream}
    - gerrit-maven-javadoc-publish
    - github-maven-javadoc-publish

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :javadoc-path: The path in Nexus to deploy javadoc to.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.
    :mvn-site-id: Maven Server ID from settings.xml to pull credentials from.
        (Note: This setting should be configured in defaults.yaml.)

:Optional parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_merge_triggers: Override Gerrit Triggers.

Maven JavaDoc Verify
--------------------

Produces javadocs for a Maven project.

Expects javadocs to be available in $WORKSPACE/target/site/apidocs

:Template Names:

    - {project-name}-maven-javadoc-verify-{stream}
    - gerrit-maven-javadoc-verify
    - github-maven-javadoc-verify

:Comment Trigger: recheck|reverify

:Required parameters:
    :build-node:    The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :deploy-path:    The path in Nexus to deploy javadoc to. (default: $PROJECT/$STREAM)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_verify_triggers: Override Gerrit Triggers.

Maven Merge
-----------

Merge job which runs `mvn clean deploy` to build a project.

This job pushes files to Nexus using cURL instead of allowing the Maven deploy
goal to push the upload. This is to get around the issue that Maven deploy does
not properly support uploading files at the end of the build and instead pushes
as it goes. There exists a `-Ddeploy-at-end` feature however it does not work
with extensions.

This job uses the following strategy to deploy jobs to Nexus:

1. `wget -r` to fetch maven-metadata.xml from Nexus
2. `mvn deploy -DaltDeploymentRepository` to prepare files for upload
3. Removes untouched maven-metadata.xml files before upload
4. Use lftools (cURL) upload script to push artifacts to Nexus

:Template Names:

    - {project-name}-maven-merge-{stream}
    - gerrit-maven-merge
    - github-maven-merge

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.
    :mvn-snapshot-id: Maven Server ID from settings.xml to pull credentials from.
        (Note: This setting should be configured in defaults.yaml.)
    :nexus-snapshot-repo: The repository id of the Nexus snapshot repo to deploy to.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer. (default: 'H H * * 0'
        to run weekly)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :nexus-cut-dirs: Number of directories to cut from file path for `wget -r`.
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.

Maven Stage
-----------

Produces a release candidate by creating a staging repo in Nexus.

The staging repo name is in the format PROJECT-NUMBER for example "aaa-1234",
"autorelease-2000", "odlparent-1201", etc...

This job runs a Maven build and deploys to $WORKSPACE/m2repo directory. This
directory is then used later to deploy to Nexus.

:Template Names:

    - {project-name}-maven-stage-{stream}
    - gerrit-maven-stage
    - github-maven-stage

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.
    :mvn-staging-id: Maven Server ID from settings.xml to pull credentials from.
        (Note: This setting should be configured in defaults.yaml.)
    :sign-artifacts: Sign artifacts with Sigul. (default: false)
    :staging-profile-id: Profile ID of the project's Nexus staging profile.

:Optional parameters:

    :archive-artifacts: Artifacts to archive to the logs server (default: '').
    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer. (default: '')
    :deploy-path:    The path in Nexus to deploy javadoc to. (default: $PROJECT/$STREAM)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_release_triggers: Override Gerrit Triggers.

Maven Sonar
-----------

Sonar job which runs mvn clean install then publishes to Sonar.

This job purposely only runs on the master branch as there are Additional
configuration needed to support multiple branches and there's not much
interest in that kind of support.

:Template Names:

    - {project-name}-sonar
    - gerrit-maven-sonar
    - github-maven-sonar

:Comment Trigger: run-sonar

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer.  (default: 'H H * * 6'
        to run weekly)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_sonar_triggers: Override Gerrit Triggers.

Maven Verify
------------

Verify job which runs mvn clean install to test a project build..

:Template Names:

    - {project-name}-maven-verify-{stream}-{mvn-version}-{java-version}
    - gerrit-maven-verify
    - github-maven-verify

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.

Maven Verify /w Dependencies
----------------------------

Verify job which runs mvn clean install to test a project build /w deps

This job can be used to verify a patch in conjunction to all of the
upstream patches it depends on. The user of this job can provide a list
via comment trigger.

:Template Names:

    - {project-name}-maven-verify-deps-{stream}-{mvn-version}-{java-version}
    - gerrit-maven-verify-dependencies

:Comment Trigger: recheck: SPACE_SEPERATED_LIST_OF_PATCHES

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.
