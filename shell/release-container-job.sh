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
set -eu -o pipefail
echo "---> release-container-job.sh"

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

nexus3_url="${NEXUS3PROXY:-$nexus3_url}"

# Fetch the release-container-schema.yaml
wget -q https://github.com/lfit/releng-global-jjb/blob/master/schema/release-container-schema.yaml

release_files=$(git diff HEAD^1 --name-only -- "releases-container/")
echo "RELEASE FILES ARE AS FOLLOWS: $release_files"

for release_file in $release_files; do
    echo "--> Verifying $release_file schema."
    lftools schema verify $release_file release-container-schema.yaml

    CONTAINER_NAME="$(niet ".container-name" "$release_file")"
    CONTAINER_IMAGE_TAG="$(niet ".container-image-tag" "$release_file")"
    PROJECT="$(niet ".project" "$release_file")"
    VERSION="$(niet ".version" "$release_file")"
    CONTAINER_PULL_REGISTRY="$(niet ".container-pull-registry" "$release_file")"
    CONTAINER_PUSH_REGISTRY="$(niet ".container-push-registry" "$release_file")"
    LOG_DIR="$(niet ".log_dir" "$release_file")"

    NEXUS3_PATH="${SILO}/${JENKINS_HOSTNAME}/"
    LOGS_URL="${logs_server}/${NEXUS_PATH}${LOG_DIR}"
    PATCH_DIR="$(mktemp -d)"

    pushd "$PATCH_DIR"

        #INFO
        echo "INFO:"
        printf '%-18s: %s\n' "RELEASE_FILE" "$release_file"
        printf '%-18s: %s\n' "JENKINS_HOSTNAME" "$JENKINS_HOSTNAME"
        printf '%-18s: %s\n' "LOG_DIR" "$LOG_DIR"
        printf '%-18s: %s\n' "LOGS_SERVER" "$logs_server"
        printf '%-18s: %s\n' "NEXUS3_PATH" "$NEXUS3_PATH"
        printf '%-18s: %s\n' "NEXUS3_URL" "$nexus3_url"
        printf '%-18s: %s\n' "NEXUS3PROXY" "$NEXUS3PROXY"
        printf '%-18s: %s\n' "PROJECT" "$PROJECT"
        printf '%-18s: %s\n' "SILO" "$SILO"
        printf '%-18s: %s\n' "VERSION" "$VERSION"
        printf '%-18s: %s\n' "CONTAINER_IMAGE_TAG" "$CONTAINER_IMAGE_TAG"
        printf '%-18s: %s\n' "CONTAINER_NAME" "$CONTAINER_NAME"
        printf '%-18s: %s\n' "CONTAINER_PULL_REGISTRY" "$CONTAINER_PULL_REGISTRY"
        printf '%-18s: %s\n' "CONTAINER_PUSH_REGISTRY" "$CONTAINER_PUSH_REGISTRY"

        wget --quiet  "${LOGS_URL}"/patches/{"${PROJECT}".bundle,taglist.log.gz}
        gunzip taglist.log.gz
        cat "$PATCH_DIR"/taglist.log
    popd

    git checkout "$(awk '{print $NF}' "$PATCH_DIR/taglist.log")"
    git fetch "$PATCH_DIR/$PROJECT.bundle"
    git merge --ff-only FETCH_HEAD
    git tag -am "$PROJECT $CONTAINER_IMAGE_TAG" "$CONTAINER_IMAGE_TAG"
    sigul --batch -c "$SIGUL_CONFIG" sign-git-tag "$SIGUL_KEY" v"$CONTAINER_IMAGE_TAG" < "$SIGUL_PASSWORD"
    echo "Showing latest signature for $PROJECT:"
    git log --show-signature -n1

    # Attempting to pull the image
    docker pull $CONTAINER_PULL_REGISTRY/$CONTAINER_NAME:$CONTAINER_IMAGE_TAG

    ########## Merge Part ##############
    if [[ "$JOB_NAME" =~ "merge" ]]; then
        echo "Running merge"
        git push origin "$CONTAINER_IMAGE_TAG"
        container_image_id=$(docker images | grep $CONTAINER_NAME | awk '{print $3}')
        docker tag $container_image_id $CONTAINER_PUSH_REGISTRY/$CONTAINER_NAME:$CONTAINER_IMAGE_TAG
        docker push $CONTAINER_PUSH_REGISTRY/$CONTAINER_NAME:$CONTAINER_IMAGE_TAG
        lftools nexus release --server "$NEXUS_URL" "$STAGING_REPO"
        if [ "${registry_url}" == 'None' ]; then
            echo "No registry url specified, not pushing to any registry"
        else
            docker tag $container_image_id $registry_url/$CONTAINER_NAME:$CONTAINER_IMAGE_TAG
            docker push $registry_url/$CONTAINER_NAME:$CONTAINER_IMAGE_TAG
        fi
    fi
done
echo "########### End Script release-container-job.sh ###################################"
