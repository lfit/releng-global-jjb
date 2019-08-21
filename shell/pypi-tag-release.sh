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
echo "---> pypi-tag-release.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

# Functions.

set_variables(){
    echo "INFO: Setting variables"
    # Verify if using release file or parameters
    if $USE_RELEASE_FILE ; then
        release_files=$(git diff-tree --no-commit-id -r "$GIT_COMMIT" --name-only -- "releases/" ".releases/")
        if (( $(echo "$release_files" | wc -w) != 1 )); then
          echo "ERROR: RELEASE FILES: $release_files"
          echo "ERROR: Committing multiple release files in the same commit OR rename/amend of existing files is not supported."
          exit 1
        else
          release_file="$release_files"
          echo "INFO: RELEASE FILE: $release_file"
        fi
    else
        echo "INFO: This job is built with parameters, no release file needed. Continuing..."
        release_file="None"
    fi

    if [[ -z ${DISTRIBUTION_TYPE:-} ]]; then
        echo "INFO: reading DISTRIBUTION_TYPE from file $release_file"
        DISTRIBUTION_TYPE="$(niet ".distribution_type" "$release_file")"
    fi
    if [[ -z ${VERSION:-} ]]; then
        echo "INFO: reading VERSION from file $release_file"
        VERSION="$(niet ".version" "$release_file")"
    fi

    # Display Release Information
    printf "\t%-30s\n" RELEASE_ENVIRONMENT_INFO:
    printf "\t%-30s %s\n" RELEASE_FILE: $release_file
    printf "\t%-30s %s\n" JENKINS_HOSTNAME: $JENKINS_HOSTNAME
    printf "\t%-30s %s\n" SILO: $SILO
    printf "\t%-30s %s\n" PROJECT: $PROJECT
    printf "\t%-30s %s\n" PROJECT-DASHED: ${PROJECT//\//-}
    printf "\t%-30s %s\n" DISTRIBUTION_TYPE: $DISTRIBUTION_TYPE
    printf "\t%-30s %s\n" VERSION: $VERSION
}

# needs to run in the repository root
verify_schema(){
    echo "INFO: Fetching schema"
    pypi_schema="release-pypi-schema.yaml"
    wget https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/${pypi_schema}
    echo "INFO: Verifying $release_file against schema $pypi_schema"
    lftools schema verify "$release_file" "$pypi_schema"
}

verify_version(){
    # Verify allowed patterns "v#.#.#" or "#.#.#" aka SemVer
    echo "INFO: Verifying version string $VERSION"
    allowed_version_regex="^((v?)([0-9]+)\.([0-9]+)\.([0-9]+))$"
    if [[ ! $VERSION =~ $allowed_version_regex ]]; then
        echo "ERROR: The version $VERSION is not a semantic valid version"
        echo "ERROR: Allowed versions are \"v#.#.#\" or \"#.#.#\" aka SemVer"
        echo "ERROR: See https://semver.org/ for more details on SemVer"
        exit 1
    fi
}

verify_dist(){
    # Verify all file names in dist folder have the expected version string
    dir="$WORKSPACE/$TOX_DIR/dist"
    echo "INFO: Verifying files in $dir"
    file_count=$(ls $dir | wc -l)
    vers_count=$(ls $dir | grep "$VERSION" | wc -l)
    if [[ $file_count != $vers_count ]]; then
        echo "ERROR: found file names without expected string ${VERSION}"
        echo "ERROR: dist file total count ${file_count}"
        echo "ERROR: dist file version count ${vers_count}"
        exit 1
    fi
}

# TODO: how to tag Github?
tag_gerrit(){
    echo "INFO: Verifying tag $VERSION in repo"
    # Import public signing key
    gpg --import "$SIGNING_PUBKEY"
    # Fail if tag exists
    if git tag -v "$VERSION"; then
        echo "INFO: Repo already tagged with $VERSION"
        exit 1
    fi
    echo "INFO: Repo has not yet been tagged $VERSION"
    git tag -am "${PROJECT//\//-} $VERSION" "$VERSION"
    sigul --batch -c "$SIGUL_CONFIG" sign-git-tag "$SIGUL_KEY" "$VERSION" < "$SIGUL_PASSWORD"
    echo "INFO: Showing latest signature for $PROJECT:"
    echo "INFO: git tag -v $VERSION"
    git tag -v "$VERSION"
    if [[ $JOB_NAME =~ "merge" ]] ; then
        # The verify job also calls this script
        echo "INFO: preparing to push tag"
        gerrit_ssh=$(echo "$GERRIT_URL" | awk -F"/" '{print $3}')
        git remote set-url origin "ssh://$RELEASE_USERNAME@$gerrit_ssh:29418/$PROJECT"
        git config user.name "$RELEASE_USERNAME"
        git config user.email "$RELEASE_EMAIL"
        echo -e "Host $gerrit_ssh\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
        chmod 600 ~/.ssh/config
        if $DRY_RUN ; then
            echo "INFO: dry run, tag not pushed!"
        else
            echo "INFO: pushing tag"
            git push origin "$VERSION"
        fi
    fi
}

# Main
virtualenv "/tmp/pypi"
# shellcheck source=/tmp/pypi/bin/activate disable=SC1091
source "/tmp/pypi/bin/activate"
pip install lftools jsonschema niet
set_variables
if [[ $DISTRIBUTION_TYPE != "pypi" ]]; then
    echo "ERROR: unexpected distribution type $DISTRIBUTION_TYPE"
    exit 1
fi
if $USE_RELEASE_FILE ; then
    verify_schema
fi
verify_version
verify_dist
tag_gerrit
