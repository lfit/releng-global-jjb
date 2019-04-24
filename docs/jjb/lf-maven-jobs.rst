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

lf-infra-maven-sonarcloud
-------------------------

Runs Sonar against a Maven project and pushes results to SonarCloud.

:Required Parameters:

    :java-version: Version of Java to execute Sonar with.
    :mvn-version: Version of Maven to execute Sonar with.
    :mvn-settings: Maven settings.xml file containing credentials to use.
    :sonarcloud-project-key: SonarCloud project key.
    :sonarcloud-project-organization: SonarCloud project organization.
    :sonarcloud-api-token: SonarCloud API Token.

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

lf-maven-versions-plugin
------------------------

Conditionally calls Maven versions plugin to set, update and commit the maven `versions:set`.

:Required Parameters:

    :maven-versions-plugin: Whether to call Maven versions plugin or not. (default: false)
    :mvn-version: Version of Maven to execute Sonar with.
    :mvn-pom: Location of pom.xml.
    :maven-versions-plugin-set-version: Version number to upgrade to.
    :mvn-settings: Maven settings.xml file containing credentials to use.

lf-maven-stage
--------------

Calls the maven stage script to push artifacts to a Nexus staging repository.

:Required Parameters:

    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration.
    :mvn-settings: The name of settings file containing credentials for the project.

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
    :mvn-central: Set to 'true' to also stage to OSSRH. This is for projects
        that want to release to Maven Central. If set the parameter
        ``ossrh-profile-id`` also needs to be set. (default: false)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :nexus-iq-namespace: Insert a namespace to project AppID for projects that
        share a Nexus IQ system to avoid project name collision. We recommend
        inserting a trailing - dash if using this parameter.
        For example 'odl-'. (default: '')
    :nexus-iq-stage: Stage the policy evaluation will be run against on
        the Nexus IQ Server. (default: 'build')
    :ossrh-profile-id: Profile ID for project as provided by OSSRH.
        (default: '')
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_merge_triggers: Override Gerrit Triggers.

Maven JavaDoc Publish
---------------------

Produces and publishes javadocs for a Maven project.

Expects javadocs to be available in $WORKSPACE/target/site/apidocs

:Template Names:

    - {project-name}-maven-javadoc-publish-{stream}-{java-version}
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
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_merge_triggers: Override Gerrit Triggers.

Maven JavaDoc Verify
--------------------

Produces javadocs for a Maven project.

Expects javadocs to be available in $WORKSPACE/target/site/apidocs

:Template Names:

    - {project-name}-maven-javadoc-verify-{stream}-{java-version}
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
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

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
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.

Maven Merge for Docker
----------------------

Similar to Maven Merge as described above but: logs in to Docker
registries, runs `mvn clean deploy` to build a project, and skips the
lf-maven-deploy builder. The project POM file should invoke a plugin
to build a Docker image and deploy it to the registry in the
environment variable NEXUS3_PUSH_REGISTRY. Appropriate for projects
that do not need to deploy any POM or JAR files.

:Template Names:

    - {project-name}-maven-docker-merge-{stream}
    - gerrit-maven-docker-merge

:Required parameters:

    :nexus3-snapshot-registry: Docker registry target for the deploy action.

All other required and optional parameters are identical to the Maven Merge job
described above.

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
    :maven-versions-plugin: Whether to call Maven versions plugin or not. (default: false)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS. (default: '')
    :mvn-params: Additional mvn parameters to pass to the cli. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :maven-versions-plugin-set-version: New version to use in Maven versions plugin. (default: '')
    :sign-artifacts: Sign artifacts with Sigul. (default: false)
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :gerrit_release_triggers: Override Gerrit Triggers.

Maven Stage for Docker
----------------------

Similar to Maven Stage as described above but: logs in to Docker
registries, runs `mvn clean deploy` to build a project, and skips the
lf-maven-deploy builder. The project POM file should invoke a plugin
to build a Docker image and deploy it to the registry in the
environment variable NEXUS3_PUSH_REGISTRY. Appropriate for projects
that do not need to deploy any POM or JAR files.

:Template Names:

    - {project-name}-maven-docker-stage-{stream}
    - gerrit-maven-docker-stage

:Required parameters:

    :nexus3-staging-registry: Docker registry target for the deploy action.

All other required and optional parameters are identical to the Maven Stage job
described above.

.. _maven-sonar:

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
    :sonar-mvn-goals: Maven goals to run for sonar analysis.
        (default: sonar:sonar)
    :sonarcloud: Whether or not to use SonarCloud ``true|false``.
        (default: false)
    :sonarcloud-project-key: SonarCloud project key. (default: '')
    :sonarcloud-project-organization: SonarCloud project organization.
        (default: '')
    :sonarcloud-api-token: SonarCloud API Token. (default: '')
    :stream: Keyword that can be used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_sonar_triggers: Override Gerrit Triggers.


SonarCloud Example:

.. literalinclude:: ../../.jjb-test/lf-maven-jobs/maven-sonarcloud.yaml
   :language: yaml

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
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.

Maven Verify for Docker
-----------------------

Similar to Maven Verify as described above but: logs in to Docker
registries, then runs `mvn clean install` to build a project.  The
project POM file should invoke a plugin to build a Docker image.
Appropriate for projects that do not need to deploy any POM or JAR
files.

:Template Names:

    - {project-name}-maven-docker-verify-{stream}-{mvn-version}-{java-version}
    - gerrit-maven-docker-verify

All required and optional parameters are identical to the Maven Verify job
described above.

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
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths which can be used to
        filter which file modifications will trigger a build.
