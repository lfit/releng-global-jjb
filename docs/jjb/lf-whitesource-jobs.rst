################
WhiteSource Jobs
################

Macros
======

lf-infra-wss-mvn-clean-install
------------------------------

Run maven clean install. Applicable to Maven based repos.

lf-infra-wss-unified-agent-scan
-------------------------------

Run WhiteSource Unified Agent for a project.

Job Templates
=============

WhiteSource Unified Agent scan
------------------------------

Trigger WhiteSource code scans using Unified Agent. For more details:
https://whitesource.atlassian.net/wiki/spaces/WD/pages/33718339/Unified+Agent

The WhiteSource Unified Agent scanner runs using a configuration file:
https://s3.amazonaws.com/unified-agent/wss-unified-agent.config

:Template Names:

    - {project-name}-whitesource-scan-{stream}
    - gerrit-whitesource-scan
    - github-whitesource-scan

:Comment Trigger: run-whitesource

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Set in defaults.yaml)
    :wss-product-name: Product to asociate the WhiteSource report in the dashboard.
    :wss-unified-agent-config: Path to wss-unifed-agent.config.

:Optional parameters:

    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
    :git-url: URL clone project from. (default: $GIT_URL/$PROJECT)
    :java-version: Version of Java to use for the build. (default: openjdk8)
    :mvn-clean-install: Run maven clean install before the code scan. (default: false)
    :mvn-global-settings: The name of the Maven global settings to use for
        Maven configuration. (default: global-settings)
    :mvn-version: Version of maven to use. (default: mvn35)
    :pom: Path of the pom.xml file.
    :stream: Keyword used to represent a release code-name.
        Often the same as the branch. (default: master)
    :submodule-recursive: Whether to checkout submodules recursively.
        (default: true)
    :submodule-timeout: Timeout (in minutes) for checkout operation.
        (default: 10)
    :submodule-disable: Disable submodule checkout operation.
        (default: false)
    :wss-unified-agent-version: WhiteSource Unified Agent version package to download
        and use.
    :gerrit_trigger_file_paths: Override file paths which used to filter which
        file modifications will trigger a build. Refer to JJB documentation for
        "file-path" details.
        https://docs.openstack.org/infra/jenkins-job-builder/triggers.html#triggers.gerrit
    :gerrit_wss_triggers: Override Gerrit Triggers.
