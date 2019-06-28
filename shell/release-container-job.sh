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

    container_name="$(niet ".container-name" "$release_file")"
    container_image_tag="$(niet ".container-image-tag" "$release_file")"
    project="$(niet ".project" "$release_file")"
    version="$(niet ".version" "$release_file")"
    container_pull_registry="$(niet ".container-pull-registry" "$release_file")"
    container_push_registry="$(niet ".container-push-registry" "$release_file")"
    log_dir="$(niet ".log_dir" "$release_file")"

    nexus3_path="${SILO}/${JENKINS_HOSTNAME}/"
    logs_url="${logs_server}/${NEXUS_PATH}${log_dir}"
    patch_dir="$(mktemp -d)"

    pushd "$patch_dir"

        #INFO
        echo "INFO:"
        printf '%-18s: %s\n' "RELEASE_FILE" "$release_file"
        printf '%-18s: %s\n' "JENKINS_HOSTNAME" "$JENKINS_HOSTNAME"
        printf '%-18s: %s\n' "log_dir" "$log_dir"
        printf '%-18s: %s\n' "LOGS_SERVER" "$logs_server"
        printf '%-18s: %s\n' "nexus3_path" "$nexus3_path"
        printf '%-18s: %s\n' "NEXUS3_URL" "$nexus3_url"
        printf '%-18s: %s\n' "NEXUS3PROXY" "$NEXUS3PROXY"
        printf '%-18s: %s\n' "project" "$project"
        printf '%-18s: %s\n' "SILO" "$SILO"
        printf '%-18s: %s\n' "version" "$version"
        printf '%-18s: %s\n' "container_image_tag" "$container_image_tag"
        printf '%-18s: %s\n' "container_name" "$container_name"
        printf '%-18s: %s\n' "container_pull_registry" "$container_pull_registry"
        printf '%-18s: %s\n' "container_push_registry" "$container_push_registry"

        wget --quiet  "${logs_url}"/patches/{"${project}".bundle,taglist.log.gz}
        gunzip taglist.log.gz
        cat "$patch_dir"/taglist.log
    popd

    git checkout "$(awk '{print $NF}' "$patch_dir/taglist.log")"
    git fetch "$patch_dir/$project.bundle"
    git merge --ff-only FETCH_HEAD
    git tag -am "$project $container_image_tag" "$container_image_tag"
    sigul --batch -c "$SIGUL_CONFIG" sign-git-tag "$SIGUL_KEY" v"$container_image_tag" < "$SIGUL_PASSWORD"
    echo "Showing latest signature for $project:"
    git log --show-signature -n1

    # Attempting to pull the image
    docker pull $container_pull_registry/$container_name:$container_image_tag

    ########## Merge Part ##############
    if [[ "$JOB_NAME" =~ "merge" ]]; then
        echo "Running merge"
        git push origin "$container_image_tag"
        container_image_id=$(docker images | grep $container_name | awk '{print $3}')
        docker tag $container_image_id $container_push_registry/$container_name:$container_image_tag
        docker push $container_push_registry/$container_name:$container_image_tag
        lftools nexus release --server "$NEXUS_URL" "$STAGING_REPO"
        if [ "${registry_url}" == 'None' ]; then
            echo "No registry url specified, not pushing to any registry"
        else
            docker tag $container_image_id $registry_url/$container_name:$container_image_tag
            docker push $registry_url/$container_name:$container_image_tag
        fi
    fi
done
echo "########### End Script release-container-job.sh ###################################"
