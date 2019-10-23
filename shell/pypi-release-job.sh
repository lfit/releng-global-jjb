#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> pypi-release-job.sh"
set -eu -o pipefail

echo "INFO: creating virtual environment"
virtualenv -p python3 /tmp/pypi
PATH=/tmp/pypi/bin:$PATH
pipup="python -m pip install -q --upgrade pip lftools jsonschema niet twine"
echo "INFO: $pipup"
$pipup

#Functions.

set_variables_common(){
    echo "INFO: Setting all common variables"
    LOGS_SERVER="${LOGS_SERVER:-None}"
    if [ "${LOGS_SERVER}" == 'None' ]; then
        echo "ERROR: log server not found"
        exit 1
    fi
    NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/"
    # Verify if using release file or parameters
    if $USE_RELEASE_FILE ; then
        # release-job.sh uses $GERRIT_PATCHSET_REVISION which is not available in sandbox
        release_files=$(git diff-tree --no-commit-id -r "$GIT_COMMIT" --name-only -- "releases/" ".releases/")
        if (( $(grep -c . <<<"$release_files") > 1 )); then
          echo "INFO: RELEASE FILES ARE AS FOLLOWS: $release_files"
          echo "ERROR: Committing multiple release files in the same commit OR rename/amend of existing files is not supported."
          exit 1
        else
          release_file="$release_files"
          echo "INFO: RELEASE FILE: $release_files"
        fi
    else
        echo "INFO: This job is built with parameters, no release file needed. Continuing..."
        release_file="None"
    fi

    DISTRIBUTION_TYPE="${DISTRIBUTION_TYPE:-None}"
    if [[ $DISTRIBUTION_TYPE == "None" ]]; then
        DISTRIBUTION_TYPE="$(niet ".distribution_type" "$release_file")"
    fi

    # PATCH_DIR="$(mktemp -d)"

    # Displaying Release Information (Common variables)
    printf "\t%-30s\n" RELEASE_ENVIRONMENT_INFO:
    printf "\t%-30s %s\n" RELEASE_FILE: "$release_file"
    printf "\t%-30s %s\n" LOGS_SERVER: "$LOGS_SERVER"
    printf "\t%-30s %s\n" NEXUS_PATH: "$NEXUS_PATH"
    printf "\t%-30s %s\n" JENKINS_HOSTNAME: "$JENKINS_HOSTNAME"
    printf "\t%-30s %s\n" SILO: "$SILO"
    printf "\t%-30s %s\n" PROJECT: "$PROJECT"
    printf "\t%-30s %s\n" PROJECT-DASHED: ${PROJECT//\//-}
    printf "\t%-30s %s\n" DISTRIBUTION_TYPE: "$DISTRIBUTION_TYPE"
}

set_variables_pypi(){
    echo "INFO: Setting pypi variables"

    # Jenkins parameters may supply values; if not, read from file
    LOG_DIR="${LOG_DIR:-None}"
    if [[ $LOG_DIR == "None" ]]; then
        LOG_DIR="$(niet ".log_dir" "$release_file")"
    fi
    LOGS_URL="${LOGS_SERVER}/${NEXUS_PATH}${LOG_DIR}"
    LOGS_URL=${LOGS_URL%/}  # strip any trailing '/'
    if [[ -z ${PYPI_PROJECT:-} ]]; then
        echo "INFO: reading pypi_project from file $release_file"
        PYPI_PROJECT="$(niet ".pypi_project" "$release_file")"
    fi
    if [[ -z ${PYTHON_VERSION:-} ]]; then
        echo "INFO: reading python_version from file $release_file"
        # workaround strange niet behavior on valid decimal numbers
        PYTHON_VERSION="$(niet -f newline ".python_version" "$release_file")"
    fi
    if [[ -z ${VERSION:-} ]]; then
        echo "INFO: reading version from file $release_file"
        VERSION="$(niet ".version" "$release_file")"
    fi
    # Make sure required values are defined
    if [ -z ${PYPI_PROJECT+x} ] || [ -z ${PYTHON_VERSION+x} ] || [ -z ${VERSION+x} ]; then
        echo "ERROR: PYPI_PROJECT, PYTHON_VERSION and VERSION must be defined"
        exit 1
    fi

    # Display Release Information
    printf "\t%-30s\n" RELEASE_PYPI_INFO:
    printf "\t%-30s %s\n" LOG DIR: "$LOG_DIR"
    printf "\t%-30s %s\n" LOGS URL: "$LOGS_URL"
    printf "\t%-30s %s\n" PYPI_INDEX: "$PYPI_INDEX"
    printf "\t%-30s %s\n" PYPI_PROJECT: "$PYPI_PROJECT"
    printf "\t%-30s %s\n" PYTHON_VERSION: "$PYTHON_VERSION"
    printf "\t%-30s %s\n" VERSION: "$VERSION"
}

# needs to run in the repository root
verify_schema(){
    echo "INFO: Verifying $release_file schema."
    lftools schema verify "$release_file" "$RELEASE_SCHEMA"
}

verify_version(){
    # Verify allowed patterns "v#.#.#" or "#.#.#" aka SemVer
    echo "INFO: Verifying version string $VERSION"
    allowed_version_regex="^((v?)([0-9]+)\.([0-9]+)\.([0-9]+))$"
    if [[ $VERSION =~ $allowed_version_regex ]]; then
        echo "INFO: The version $VERSION is a valid semantic version"
    else
        echo "ERROR: The version $VERSION is not a valid semantic version"
        echo "ERROR: Allowed versions are \"v#.#.#\" or \"#.#.#\" aka SemVer"
        echo "ERROR: See https://semver.org/ for more details on SemVer"
        exit 1
    fi
}

# check prerequisites to detect mistakes in the release YAML file
verify_pypi_match_release(){
    wget -q -P /tmp "${LOGS_URL}/"console.log.gz
    echo "INFO: Searching for strings >$PYPI_PROJECT< and >$VERSION< in job log"
    # pypi-upload.sh generates success message with file list
    if zgrep -i "uploaded" /tmp/console.log.gz | grep "$PYPI_PROJECT" | grep "$VERSION" ; then
        echo "INFO: expected strings found in job log"
    else
        echo "ERROR: expected strings not found in job log"
        exit 1
    fi
}

# calls pip to download binary and source distributions from the specified index,
# which requires a recent-in-2019 version.  Uploads the files it received.
pypi_release_file(){
    tgtdir=dist
    mkdir $tgtdir
    pip_pfx="pip download -d $tgtdir --no-deps --python-version $PYTHON_VERSION -i $PYPI_INDEX"
    module="$PYPI_PROJECT==$VERSION"
    pip_bin="$pip_pfx $module"
    echo "INFO: downloading binary: $pip_bin"
    if ! $pip_bin ; then
        echo "WARN: failed to download binary distribution"
    fi
    pip_src="$pip_pfx --no-binary=:all: $module"
    echo "INFO: downloading source: $pip_src"
    if ! $pip_src ; then
        echo "WARN: failed to download source distribution"
    fi
    echo "INFO: Checking files in $tgtdir"
    filecount=$(ls $tgtdir | wc -l)
    if [[ $filecount = 0 ]] ; then
        echo "ERROR: no files downloaded"
        exit 1
    else
        echo "INFO: downloaded $filecount distributions:"
        ls $tgtdir
    fi

    if [[ ! "$JOB_NAME" =~ "merge" ]] ; then
        echo "INFO: not a merge job, not uploading files"
        return
    fi

    cmd="twine upload -r $REPOSITORY $tgtdir/*"
    if $DRY_RUN; then
        echo "INFO: dry-run is set, echoing command only"
        echo "$cmd"
    else
        echo "INFO: uploading $filecount distributions to repo $REPOSITORY"
        $cmd
    fi
    tag
}

# sigul is only available on Centos
# TODO: write tag_github function
tag(){
    echo "INFO: Verifying tag $VERSION in repo"
    # Import public signing key
    gpg --import "$SIGNING_PUBKEY"
    if git tag -v "$VERSION"; then
        echo "INFO: Repo already tagged"
        return 0
    fi
    echo "INFO: Tagging repo"
    git tag -am "${PROJECT//\//-} $VERSION" "$VERSION"
    echo "INFO: Signing tag"
    sigul --batch -c "$SIGUL_CONFIG" sign-git-tag "$SIGUL_KEY" "$VERSION" < "$SIGUL_PASSWORD"
    echo "INFO: Verifying tag"
    # may fail due to missing public key
    if ! git tag -v "$VERSION"; then
        echo "WARN: failed to verify tag, continuing anyhow"
    fi
    # The verify job also calls this script
    if [[ ! $JOB_NAME =~ "merge" ]] ; then
        echo "INFO: job is not a merge, skipping push"
    else
        echo "INFO: configuring Gerrit remote"
        gerrit_ssh=$(echo "$GERRIT_URL" | awk -F"/" '{print $3}')
        git remote set-url origin "ssh://$RELEASE_USERNAME@$gerrit_ssh:29418/$PROJECT"
        git config user.name "$RELEASE_USERNAME"
        git config user.email "$RELEASE_EMAIL"
        echo -e "Host $gerrit_ssh\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
        chmod 600 ~/.ssh/config
        if $DRY_RUN; then
            echo "INFO: dry run, skipping push"
        else
            echo "INFO: pushing tag"
            git push origin "$VERSION"
        fi
    fi
}

# Set common environment variables
set_variables_common

if [[ "$DISTRIBUTION_TYPE" == "pypi" ]]; then
    if $USE_RELEASE_FILE ; then
        echo "INFO: Fetching schema"
        RELEASE_SCHEMA="release-pypi-schema.yaml"
        wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/${RELEASE_SCHEMA}
        verify_schema
    fi
    set_variables_pypi
    verify_version
    verify_pypi_match_release
    pypi_release_file
else
    echo "ERROR: unexpected distribution type $DISTRIBUTION_TYPE"
    exit 1
fi

echo "---> pypi-release-job.sh ends"
