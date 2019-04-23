###########
NodeJS Jobs
###########

Job Groups
==========

.. include:: ../job-groups.rst

Below is a list of Node job groups:

.. literalinclude:: ../../jjb/lf-node-job-groups.yaml
   :language: yaml


Job Templates
=============

Node Verify
-----------

Verify job for NodeJS projects

:Template Names:

    - {project-name}-node-verify-{stream}
    - gerrit-node-verify
    - github-node-verify

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
    :node-version: Version of NodeJS to install. Default defined in job-group.

:Optional parameters:

    :branch: The branch to build against. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 10)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :node-dir: Path to a NodeJS project to run node test against
        (default: '')
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
