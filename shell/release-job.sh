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
echo "---> release-job.sh"

set -eu -o pipefail

if [ -d "/opt/pyenv" ]; then
    echo "---> Setting up pyenv"
    export PYENV_ROOT="/opt/pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
fi
PYTHONPATH=$(pwd)
export PYTHONPATH
pyenv local 3.6.4
export PYENV_VERSION="3.6.4"

pip install --user lftools[nexus] jsonschema niet

echo "########### Start Script release-job.sh ###################################"

LOGS_SERVER="${LOGS_SERVER:-None}"
MAVEN_CENTRAL_URL="${MAVEN_CENTRAL_URL:-None}"

if [ "${LOGS_SERVER}" == 'None' ]; then
    echo "FAILED: log server not found"
    exit 1
fi

NEXUS_URL="${NEXUSPROXY:-$NEXUS_URL}"

# Fetch the release-schema.yaml
wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/release-schema.yaml

release_files=$(git diff HEAD^1 --name-only -- "releases/")
echo "RELEASE FILES ARE AS FOLLOWS: $release_files"

for release_file in $release_files; do
    echo "--> Verifying $release_file schema."
    lftools schema verify $release_file release-schema.yaml

    #OPTIONAL
    if grep -q "\.maven_central_url" "$release_file"; then
        MAVEN_CENTRAL_URL="$(niet ".maven_central_url" "$release_file")"
    fi

    VERSION="$(niet ".version" "$release_file")"
    PROJECT="$(niet ".project" "$release_file")"
    LOG_DIR="$(niet ".log_dir" "$release_file")"

    NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/"
    LOGS_URL="${LOGS_SERVER}/${NEXUS_PATH}${LOG_DIR}"
    PATCH_DIR="$(mktemp -d)"

    pushd "$PATCH_DIR"
        wget --quiet "${LOGS_URL}"staging-repo.txt.gz
        STAGING_REPO="$(zcat staging-repo.txt)"

        #INFO
        echo "INFO:"
        echo "RELEASE_FILE: $release_file"
        echo "LOGS_SERVER: $LOGS_SERVER"
        echo "NEXUS_URL: $NEXUS_URL"
        echo "NEXUS_PATH: $NEXUS_PATH"
        echo "NEXUSPROXY: $NEXUSPROXY"
        echo "JENKINS_HOSTNAME: $JENKINS_HOSTNAME"
        echo "SILO: $SILO"
        echo "PROJECT: $PROJECT"
        echo "STAGING_REPO: $STAGING_REPO"
        echo "VERSION: $VERSION"
        echo "PROJECT: $PROJECT"
        echo "LOG DIR: $LOG_DIR"

        wget --quiet  "${LOGS_URL}"/patches/{"${PROJECT}".bundle,taglist.log.gz}
        gunzip taglist.log.gz
        cat "$PATCH_DIR"/taglist.log
    popd

    # Verify allowed versions
    # Allowed versions are "v#.#.#" or "#.#.#" aka SemVer
    allowed_version_regex="^((v?)([0-9]+)\.([0-9]+)\.([0-9]+))$"
    if [[ ! $VERSION =~ $allowed_version_regex ]]; then
        echo "The version $VERSION is not a semantic valid version"
        echo "Allowed versions are "v#.#.#" or "#.#.#" aka SemVer"
        echo "See https://semver.org/ for more details on SemVer"
        exit 1
    fi

    git checkout "$(awk '{print $NF}' "$PATCH_DIR/taglist.log")"
    git fetch "$PATCH_DIR/$PROJECT.bundle"
    git merge --ff-only FETCH_HEAD
    git tag -am "$PROJECT $VERSION" "$VERSION"
    sigul --batch -c "$SIGUL_CONFIG" sign-git-tag "$SIGUL_KEY" "$VERSION" < "$SIGUL_PASSWORD"
    echo "Showing latest signature for $PROJECT:"
    git log --show-signature -n1


    ########## Merge Part ##############
    if [[ "$JOB_NAME" =~ "merge" ]]; then
        echo "Running merge"
        gerrit_ssh=$(echo "$GERRIT_URL" | awk -F"/" '{print $3}')
        git remote set-url origin ssh://"$RELEASE_USERNAME"@"$gerrit_ssh":29418/$PROJECT
        git config user.name "$RELEASE_USERNAME"
        git config user.email "$RELEASE_EMAIL"
        git push origin "$VERSION"
        lftools nexus release --server "$NEXUS_URL" "$STAGING_REPO"
        if [ "${MAVEN_CENTRAL_URL}" == 'None' ]; then
            echo "No Maven central url specified, not pushing to maven central"
        else
            lftools nexus release --server "$MAVEN_CENTRAL_URL" "$STAGING_REPO"
        fi
    fi

done
echo "########### End Script release-job.sh ###################################"
