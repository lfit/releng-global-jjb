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
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in defaults.yaml)

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
