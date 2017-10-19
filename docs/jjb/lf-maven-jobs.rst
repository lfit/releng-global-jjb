##########
Maven Jobs
##########

Job Groups
==========

{project-name}-maven-jobs
-------------------------

Jobs for Maven projects using Gerrit.

:Includes:

    - gerrit-maven-clm
    - gerrit-maven-release
    - gerrit-maven-verify
    - gerrit-maven-verify-dependencies

{project-name}-github-maven-jobs
--------------------------------

Jobs for Maven projects using GitHub.

:Includes:

    - github-maven-clm
    - github-maven-release
    - github-maven-verify

{project-name}-maven-javadoc-jobs
---------------------------------

Jobs for Maven projects to generate javadoc using Gerrit.

:Includes:

    - gerrit-maven-javadoc-publish
    - gerrit-maven-javadoc-verify

{project-name}-github-maven-javadoc-jobs
----------------------------------------

Jobs for Maven projects to generate javadoc using GitHub.

:Includes:

    - github-maven-javadoc-publish
    - github-maven-javadoc-verify


Macros
======

lf-maven-common
---------------

Common Jenkins configuration for Maven jobs.


Job Templates
=============

Maven CLM
---------

Produces a CLM scan of the code into Nexus IQ Server.

:Template Names:

    - {project-name}-maven-clm-{stream}
    - gerrit-maven-clm
    - github-maven-clm

:Required parameters:

    :build-node:    The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in seconds before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn33)
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
    :build-timeout: Timeout in seconds before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn33)
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

:Required parameters:
    :build-node:    The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in seconds before aborting build. (default: 60)
    :deploy-path:    The path in Nexus to deploy javadoc to. (default: $PROJECT/$STREAM)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn33)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_verify_triggers: Override Gerrit Triggers.

Maven Release
-------------

Produces a release candidate by creating a staging repo in Nexus.

Runs a Maven build and deploys to $WORKSPACE/m2repo directory. This
directory can then be reused later to deploy to Nexus.

:Template Names:

    - {project-name}-maven-release-{stream}
    - gerrit-maven-release
    - github-maven-release

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.
    :mvn-staging-id: Maven Server ID from settings.xml to pull credentials from.
        (Note: This setting should be configured in defaults.yaml.)
    :staging-profile-id: Profile ID of the project's Nexus staging profile.

:Optional parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in seconds before aborting build. (default: 60)
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
    :mvn-version: Version of maven to use. (default: mvn33)
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

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in seconds before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn33)
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

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally should
        be configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in seconds before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn33)
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
    :build-timeout: Timeout in seconds before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn33)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.
