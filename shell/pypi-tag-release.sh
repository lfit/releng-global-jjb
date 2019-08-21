#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> release-tag-pypi.sh"
set -eu -o pipefail

#Python bits. Remove when centos 7.7 builder is avaliable.
if [ -d "/opt/pyenv" ]; then
    echo "INFO: Setting up pyenv"
    export PYENV_ROOT="/opt/pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
fi
PYTHONPATH=$(pwd)
export PYTHONPATH
pyenv local 3.6.4
export PYENV_VERSION="3.6.4"
pip install --user jsonschema niet

#Functions.

set_variables_common(){
    echo "INFO: Setting all common variables"
    # Verify if using release file or parameters
    if $USE_RELEASE_FILE ; then
        release_files=$(git diff-tree --no-commit-id -r "$GERRIT_PATCHSET_REVISION" --name-only -- "releases/" ".releases/")
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

    DISTRIBUTION_TYPE="pypi"
    PATCH_DIR="$(mktemp -d)"

    # Displaying Release Information (Common variables)
    printf "\t%-30s\n" RELEASE_ENVIRONMENT_INFO:
    printf "\t%-30s %s\n" RELEASE_FILE: $release_file
    printf "\t%-30s %s\n" JENKINS_HOSTNAME: $JENKINS_HOSTNAME
    printf "\t%-30s %s\n" SILO: $SILO
    printf "\t%-30s %s\n" PROJECT: $PROJECT
    printf "\t%-30s %s\n" PROJECT-DASHED: ${PROJECT//\//-}
    printf "\t%-30s %s\n" DISTRIBUTION_TYPE: $DISTRIBUTION_TYPE
}

set_variables_pypi(){
    VERSION="${VERSION:-None}"
    if [[ $VERSION == "None" ]]; then
        VERSION="$(niet ".version" "$release_file")"
    fi

    # Continuing displaying Release Information
    printf "\t%-30s\n" RELEASE_PYPI_INFO:
    printf "\t%-30s %s\n" VERSION: $VERSION
}

verify_schema(){
    echo "INFO: Verifying $release_file schema."
    lftools schema verify "$release_file" "$RELEASE_SCHEMA"
}

verify_version(){
    # Verify allowed versions
    # Allowed versions are "v#.#.#" or "#.#.#" aka SemVer
    allowed_version_regex="^((v?)([0-9]+)\.([0-9]+)\.([0-9]+))$"
    if [[ ! $VERSION =~ $allowed_version_regex ]]; then
        echo "INFO: The version $VERSION is not a semantic valid version"
        echo "INFO: Allowed versions are \"v#.#.#\" or \"#.#.#\" aka SemVer"
        echo "INFO: See https://semver.org/ for more details on SemVer"
        exit 1
    fi
}

tag(){
    # Import public signing key
    gpg --import "$SIGNING_PUBKEY"
    if git tag -v "$VERSION"; then
        echo "OK: Repo already tagged $VERSION Continuing to release"
    else
        echo "INFO: Repo has not yet been tagged $VERSION"
        git tag -am "${PROJECT//\//-} $VERSION" "$VERSION"
        sigul --batch -c "$SIGUL_CONFIG" sign-git-tag "$SIGUL_KEY" "$VERSION" < "$SIGUL_PASSWORD"
        echo "INFO: Showing latest signature for $PROJECT:"
        echo "INFO: git tag -v $VERSION"
        git tag -v "$VERSION"

        ########## Merge Part ##############
        if [[ "$JOB_NAME" =~ "merge" ]] && [[ "$DRY_RUN" = false ]]; then
            echo "INFO: Running merge, pushing tag"
            gerrit_ssh=$(echo "$GERRIT_URL" | awk -F"/" '{print $3}')
            git remote set-url origin ssh://"$RELEASE_USERNAME"@"$gerrit_ssh":29418/"$PROJECT"
            git config user.name "$RELEASE_USERNAME"
            git config user.email "$RELEASE_EMAIL"
            echo -e "Host $gerrit_ssh\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
            chmod 600 ~/.ssh/config
            git push origin "$VERSION"
        fi
    fi
}

# Set common environment variables
set_variables_common

RELEASE_SCHEMA="release-pypi-schema.yaml"
wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/${RELEASE_SCHEMA}
if $USE_RELEASE_FILE ; then
    verify_schema
fi
set_variables_pypi
verify_version
tag
