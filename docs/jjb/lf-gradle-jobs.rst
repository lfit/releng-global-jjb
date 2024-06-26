###########
Gradle Jobs
###########

Job Templates
=============

Gradle Build
------------

Runs a gradle build command to perform the verification.

:Template Names:

    - {project-name}-gradle-build-{stream}

:Comment Trigger: recheck|reverify

:Required parameters:
    :build-node:    The node to run build on.
    :java-version: Version of Java to execute Maven build. (default: openjdk17)
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in defaults.yaml)
    :mvn-settings: Maven settings.xml file containing credentials to use.
    :wrapper: Use the gradle wrapper (default: true)

:Optional parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :deploy-path:    The path in Nexus to deploy javadoc to. (default: $PROJECT/$STREAM)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_verify_triggers: Override Gerrit Triggers.

Gradle Publish Jar
------------------

Runs a gradle publish command to publish the jar.

:Template Names:

    - {project-name}-gradle-publish-jar-{stream}

:Comment Trigger: recheck|reverify

:Required parameters:
    :build-node:    The node to run build on.
    :java-version: Version of Java to execute Maven build. (default: openjdk17)
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in defaults.yaml)
    :mvn-settings: Maven settings.xml file containing credentials to use.
    :publish-credential: Project credential used for accessing Nexus
    :publish-directory: Location of built artifacts
    :publish-file-extension: Artifact's file extension
    :publish-url: Nexus publishing repo location

    :wrapper: Use the gradle wrapper (default: true)

:Optional parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :deploy-path:    The path in Nexus to deploy javadoc to. (default: $PROJECT/$STREAM)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :stream: Keyword that represents a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)

    :gerrit_verify_triggers: Override Gerrit Triggers.
