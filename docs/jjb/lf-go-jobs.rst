#######
Go Jobs
#######

Macros
======

lf-go-test
----------

Calls go-test.sh script against a Go project.
The script has the command 'go test ./...' which runs unit tests on current folder and all subfolders.

:Required Parameters:

    :go-root: Path to the Go project root directory.

lf-go-common
------------

Common Jenkins configuration for Go jobs.

Job Templates
=============

Go Verify
---------

Job which runs go test ./... to verify a Go project.

:Template Names:

    - {project-name}-go-verify-{stream}"
    - gerrit-go-verify
    - github-go-verify

:Comment Trigger: recheck|reverify

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally configured in defaults.yaml)

:Optional parameters:

    :branch: Git branch to fetch for the build. (default: master)
    :build-days-to-keep: Days to keep build logs in Jenkins. (default: 7)
    :build-timeout: Timeout in minutes before aborting build. (default: 60)
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
    :gerrit_trigger_file_paths: Override file paths to filter which file
        modifications will trigger a build.
