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

    :java-version: Version of Java to execute Maven build. (default: openjdk8)
    :mvn-version: Version of Maven to execute Sonar with.
    :mvn-settings: Maven settings.xml file containing credentials to use.
    :sonarcloud-project-key: SonarCloud project key.
    :sonarcloud-project-organization: SonarCloud project organization.
    :sonarcloud-api-token: SonarCloud API Token.
    :sonarcloud-java-version: Version of Java to run the Sonar scan.

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
    :version-properties-file: Name and path of the version properties file.
        (default: version.properties)
    :mvn-version: Version of Maven to execute Sonar with.
    :mvn-pom: Location of pom.xml.
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

lf-infra-sonatype-clm
---------------------

Runs a Sonatype CLM scan against a Maven project and pushes results to
Nexus IQ server.

:Optional parameters:
    :mvn-goals: The maven goals to perform for the build.
        (default: clean install)

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
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-goals: The maven goals to perform for the build.
        (default: clean install)
    :mvn-opts: Sets MAVEN_OPTS to start up the JVM running Maven. (default: '')
    :mvn-params: Parameters to pass to the mvn CLI. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :nexus-iq-namespace: Insert a namespace to project AppID for projects that
        share a Nexus IQ system to avoid project name collision. We recommend
        inserting a trailing - dash if using this parameter.
        For example 'odl-'. (default: '')
    :nexus-iq-stage: Sets the **stage** which the policy evaluation will run
        against on the Nexus IQ Server. (default: 'build')
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_merge_triggers: Override Gerrit Triggers.

Maven JavaDoc Publish
---------------------

Produces and publishes javadocs for a Maven project.

Expects javadocs to be available in ``$WORKSPACE/target/site/apidocs``, but
overrideable with the ``mvn-dir`` parameter. If set, will search for javadocs
in ``$WORKSPACE/{mvn-dir}/target/site/apidocs``.

:Template Names:

    - {project-name}-maven-javadoc-publish-{stream}-{java-version}
    - gerrit-maven-javadoc-publish
    - github-maven-javadoc-publish

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :javadoc-path: The path in Nexus to deploy javadoc to.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.
    :mvn-site-id: Maven Server ID from settings.xml to pull credentials from.
        (Note: This setting is generally configured in ``defaults.yaml``.)

:Optional parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-dir: Directory supplied as argument to -f option (default: '.')
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS to start up the JVM running Maven. (default: '')
    :mvn-params: Parameters to pass to the mvn CLI. (default: '')
        Must not include a "-f" option; see parameter mvn-dir.
    :mvn-version: Version of maven to use. (default: mvn35)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_merge_triggers: Override Gerrit Triggers.

Maven JavaDoc Verify
--------------------

Produces javadocs for a Maven project.

Expects javadocs to be available in ``$WORKSPACE/target/site/apidocs``, but
overrideable with the ``mvn-dir`` parameter. If set, will search for javadocs
in ``$WORKSPACE/{mvn-dir}/target/site/apidocs``.

:Template Names:

    - {project-name}-maven-javadoc-verify-{stream}-{java-version}
    - gerrit-maven-javadoc-verify
    - github-maven-javadoc-verify

:Comment Trigger: recheck|reverify

:Required parameters:
    :build-node:    The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :deploy-path:    The path in Nexus to deploy javadoc to. (default: $PROJECT/$STREAM)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-dir: Directory supplied as argument to -f option (default: '.')
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS to start up the JVM running Maven. (default: '')
    :mvn-params: Parameters to pass to the mvn CLI. (default: '')
        Must not include a "-f" option; see parameter mvn-dir.
    :mvn-version: Version of maven to use. (default: mvn35)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_verify_triggers: Override Gerrit Triggers.

Maven Merge
-----------

Merge job which runs `mvn clean deploy` to build a project.

This job pushes files to Nexus using cURL instead of allowing the Maven deploy
goal to push the upload. This is to get around the issue that Maven deploy does
not properly support uploading files at the end of the build and instead pushes
as it goes. There exists a ``-Ddeploy-at-end`` feature but it does not work
with extensions.

This job uses the following strategy to deploy jobs to Nexus:

1. ``wget -r`` to fetch maven-metadata.xml from Nexus
2. ``mvn deploy -DaltDeploymentRepository`` to prepare files for upload
3. Removes untouched maven-metadata.xml files before upload
4. Use lftools (cURL) upload script to push artifacts to Nexus

:Template Names:

    - {project-name}-maven-merge-{stream}
    - gerrit-maven-merge
    - github-maven-merge

:Comment Trigger: remerge

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.
    :mvn-snapshot-id: Maven Server ID from settings.xml to pull credentials from.
        (Note: This setting is generally configured in ``defaults.yaml``.)
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
    :mvn-opts: Sets MAVEN_OPTS to start up the JVM running Maven. (default: '')
    :mvn-params: Parameters to pass to the mvn CLI. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :nexus-cut-dirs: Number of directories to cut from file path for `wget -r`.
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_merge_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths to filter which file
        modifications will trigger a build.

Maven Merge for Docker
----------------------

Produces a snapshot docker image in a Nexus registry. Appropriate for
Java projects that do not need to deploy any POM or JAR files.

Like the Maven Merge job as described above but logs in to Docker
registries first and skips the lf-maven-deploy builder. The project
POM file should invoke a plugin to build and push a Docker image.
This pulls the base image from the registry in the environment
variable ``CONTAINER_PULL_REGISTRY`` and pushes new image into the
registry in the environment variable ``CONTAINER_PUSH_REGISTRY``.

:Template Names:

    - {project-name}-maven-docker-merge-{stream}
    - gerrit-maven-docker-merge
    - github-maven-docker-merge

:Required parameters:

    :container-public-registry: Docker registry source with base images.
    :container-snapshot-registry: Docker registry target for the deploy action.

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

:Comment Trigger: "stage-release" or "stage-maven-release"

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.
    :mvn-staging-id: Maven Server ID from settings.xml to pull credentials from.
        (Note: This setting is generally configured in ``defaults.yaml``.)
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
    :mvn-central: Set to ``true`` to also stage to **OSSRH**. This is for projects
        that want to release to Maven Central. If set, then also set the parameter
        ``ossrh-profile-id``. (default: false)
    :maven-versions-plugin: Whether to call Maven versions plugin or not. (default: false)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS to start up the JVM running Maven. (default: '')
    :mvn-params: Parameters to pass to the mvn CLI. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :ossrh-profile-id: Profile ID for project as provided by OSSRH.
        (default: '')
    :sign-artifacts: Sign artifacts with Sigul. (default: false)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :version-properties-file: Name and path of the version properties file.
        (default: version.properties)

    :gerrit_release_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths to filter which file
        modifications will trigger a build.

Maven Stage for Docker
----------------------

Produces a release candidate docker image in a Nexus registry.
Appropriate for Java projects that do not need to deploy any POM or
JAR files.

Like the Maven Stage job as described above but logs in to Docker
registries first and skips the lf-maven-deploy builder. The project
POM file should invoke a plugin to build and push a Docker image.
This pulls the base image from the registry in the environment
variable ``CONTAINER_PULL_REGISTRY`` and pushes new image into the
registry in the environment variable ``CONTAINER_PUSH_REGISTRY``.

:Template Names:

    - {project-name}-maven-docker-stage-{stream}
    - gerrit-maven-docker-stage
    - github-maven-docker-stage

:Comment Trigger: "stage-release" or "stage-docker-release"

:Required parameters:

    :container-public-registry: Docker registry source with base images.
    :container-staging-registry: Docker registry target for the deploy action.

:Optional parameters:

    :gerrit_release_docker_triggers: Override Gerrit Triggers.

All other required and optional parameters are identical to the Maven Stage job
described above.

.. _maven-sonar:

Maven Sonar
-----------

Sonar job which runs mvn clean install then publishes to Sonar.

This job purposely runs on the ``master`` branch and does not support
multi-branch configuration.

:Template Names:

    - {project-name}-sonar
    - gerrit-maven-sonar
    - github-maven-sonar
    - {project-name}-sonar-prescan-script
    - gerrit-maven-sonar-prescan-script
    - github-maven-sonar-prescan-script

:Comment Trigger: run-sonar

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.
    :sonar-prescan-script: (maven-sonar-prescan-script jobs) A shell script to run before
        sonar scans.

:Optional parameters:

    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :cron: Cron schedule when to trigger the job. This parameter also
        supports multiline input via YAML pipe | character in cases where
        one may want to provide more than 1 cron timer.  (default: 'H H * * 6'
        to run weekly)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the Maven build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-goals: The maven goals to perform for the build.
        (default: clean install)
    :mvn-opts: Sets MAVEN_OPTS to start up the JVM running Maven. (default: '')
    :mvn-params: Parameters to pass to the mvn CLI. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :sonar-mvn-goals: Maven goals to run for sonar analysis.
        (default: sonar:sonar)
    :sonarcloud: Set to ``true`` to use SonarCloud ``true|false``.
        (default: false)
    :sonarcloud-project-key: SonarCloud project key. (default: '')
    :sonarcloud-project-organization: SonarCloud project organization.
        (default: '')
    :sonarcloud-api-token: SonarCloud API Token. (default: '')
    :sonarcloud-java-version: Version of Java to use for the Sonar scan. (default: openjdk11)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

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
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS to start up the JVM running Maven. (default: '')
    :mvn-params: Parameters to pass to the mvn CLI. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths to filter which file
        modifications will trigger a build.

Maven Verify for Docker
-----------------------

Like the Maven Verify job as described above but logs in to Docker
registries first. The project POM file should invoke a plugin to build
a Docker image. This pulls the base image from the registry in the environment
variable ``CONTAINER_PULL_REGISTRY``.

:Template Names:

    - {project-name}-maven-docker-verify-{stream}-{mvn-version}-{java-version}
    - gerrit-maven-docker-verify
    - github-maven-docker-verify

:Required parameters:

    :container-public-registry: Docker registry source with base images.

All other required and optional parameters are identical to the Maven Verify job
described above.

Maven Verify w/ Dependencies
----------------------------

Verify job which runs mvn clean install to test a project build /w deps

This job's purpose is to verify a patch in conjunction to a list of upstream
patches it depends on. The user of this job can provide a list of patches via
comment trigger.

:Template Names:

    - {project-name}-maven-verify-deps-{stream}-{mvn-version}-{java-version}
    - gerrit-maven-verify-dependencies

:Comment Trigger: recheck: SPACE_SEPARATED_LIST_OF_PATCHES

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in defaults.yaml)
    :mvn-settings: The name of settings file containing credentials for the project.

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-opts: Sets MAVEN_OPTS to start up the JVM running Maven. (default: '')
    :mvn-params: Parameters to pass to the mvn CLI. (default: '')
    :mvn-version: Version of maven to use. (default: mvn35)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_verify_triggers: Override Gerrit Triggers.
    :gerrit_trigger_file_paths: Override file paths to filter which file
        modifications will trigger a build.
