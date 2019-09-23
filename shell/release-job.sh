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

set +u
python3 -m venv /tmp/v/venv/
# shellcheck disable=SC1091
source /tmp/v/venv/bin/activate
set -u
python -m pip install lftools[nexus] jsonschema niet yq

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

    DISTRIBUTION_TYPE="${DISTRIBUTION_TYPE:-None}"
    if [[ $DISTRIBUTION_TYPE == "None" ]]; then
        DISTRIBUTION_TYPE="$(niet ".distribution_type" "$release_file")"
    fi

    PATCH_DIR="$(mktemp -d)"

    # Displaying Release Information (Common variables)
    printf "\t%-30s\n" RELEASE_ENVIRONMENT_INFO:
    printf "\t%-30s %s\n" RELEASE_FILE: $release_file
    printf "\t%-30s %s\n" LOGS_SERVER: $LOGS_SERVER
    printf "\t%-30s %s\n" NEXUS_PATH: $NEXUS_PATH
    printf "\t%-30s %s\n" JENKINS_HOSTNAME: $JENKINS_HOSTNAME
    printf "\t%-30s %s\n" SILO: $SILO
    printf "\t%-30s %s\n" PROJECT: $PROJECT
    printf "\t%-30s %s\n" PROJECT-DASHED: ${PROJECT//\//-}
    printf "\t%-30s %s\n" DISTRIBUTION_TYPE: $DISTRIBUTION_TYPE
}

set_variables_maven(){
    VERSION="${VERSION:-None}"
    if [[ $VERSION == "None" ]]; then
        VERSION="$(niet ".version" "$release_file")"
    fi
    LOG_DIR="${LOG_DIR:-None}"
    if [[ $LOG_DIR == "None" ]]; then
        LOG_DIR="$(niet ".log_dir" "$release_file")"
    fi
    LOGS_URL="${LOGS_SERVER}/${NEXUS_PATH}${LOG_DIR}"
    LOGS_URL=${LOGS_URL%/}  # strip any trailing '/'

    # Continuing displaying Release Information (Maven)
    printf "\t%-30s\n" RELEASE_MAVEN_INFO:
    printf "\t%-30s %s\n" VERSION: $VERSION
    printf "\t%-30s %s\n" LOG DIR: $LOG_DIR
    printf "\t%-30s %s\n" LOGS URL: $LOGS_URL
}

set_variables_container(){
    VERSION="${VERSION:-None}"
    if [[ $VERSION == "None" ]]; then
        VERSION="$(niet ".container_release_tag" "$release_file")"
    fi
    if grep -q "container_pull_registry" "$release_file" ; then
        CONTAINER_PULL_REGISTRY="$(niet ".container_pull_registry" "$release_file")"
    fi
    if grep -q "container_push_registry" "$release_file" ; then
        CONTAINER_PUSH_REGISTRY="$(niet ".container_push_registry" "$release_file")"
    fi
    # Make sure both pull and push registries are defined
    if [ -z ${CONTAINER_PULL_REGISTRY+x} ] || [ -z ${CONTAINER_PUSH_REGISTRY+x} ]; then
        echo "ERROR: CONTAINER_PULL_REGISTRY and CONTAINER_PUSH_REGISTRY need to be defined"
        exit 1
    fi
    ref="$(niet ".ref" "$release_file")"

    # Continuing displaying Release Information (Container)
    printf "\t%-30s\n" RELEASE_CONTAINER_INFO:
    printf "\t%-30s %s\n" CONTAINER_RELEASE_TAG: $VERSION
    printf "\t%-30s %s\n" CONTAINER_PULL_REGISTRY: $CONTAINER_PULL_REGISTRY
    printf "\t%-30s %s\n" CONTAINER_PUSH_REGISTRY: $CONTAINER_PUSH_REGISTRY
    printf "\t%-30s %s\n" GERRIT_REF_TO_TAG: $ref
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
        echo "OK: Repo already tagged $VERSION Continuting to release"
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

nexus_release(){
    for staging_url in $(zcat "$PATCH_DIR"/staging-repo.txt.gz | awk -e '{print $2}'); do
        # extract the domain name from URL
        NEXUS_URL=$(echo "$staging_url" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
        echo "INFO: NEXUS_URL: $NEXUS_URL"
        # extract the staging repo from URL
        STAGING_REPO=${staging_url#*repositories/}
        echo "INFO: Running Nexus Verify"
        lftools nexus release -v --server https://"$NEXUS_URL" "$STAGING_REPO"
        echo "INFO: Merge will run:"
        echo "lftools nexus release --server https://$NEXUS_URL $STAGING_REPO"
    done

    #Run the loop twice, to catch errors on either nexus repo
    if [[ "$JOB_NAME" =~ "merge" ]] && [[ "$DRY_RUN" = false ]]; then
        for staging_url in $(zcat "$PATCH_DIR"/staging-repo.txt.gz | awk -e '{print $2}'); do
          NEXUS_URL=$(echo "$staging_url" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
          STAGING_REPO=${staging_url#*repositories/}
          echo "INFO: Promoting $STAGING_REPO on $NEXUS_URL."
          lftools nexus release --server https://"$NEXUS_URL" "$STAGING_REPO"
        done
    fi
}

container_release_file(){
    echo "INFO: Processing container release"
    local lfn_umbrella
    lfn_umbrella="$(echo "$GERRIT_HOST" | awk -F"." '{print $2}')"

    for namequoted in $(cat $release_file | yq '.containers[].name'); do
        versionquoted=$(cat $release_file | yq ".containers[] |select(.name==$namequoted) |.version")

        #Remove extra yaml quotes
        name="${namequoted#\"}"
        name="${name%\"}"
        version="${versionquoted#\"}"
        version="${version%\"}"

        echo "$name"
        echo "$version"
        echo "INFO: Merge will release $name $version as $VERSION"
        # Attempt to pull from releases registry to see if the image has been released.
        if docker pull "$CONTAINER_PUSH_REGISTRY"/"$lfn_umbrella"/"$name":"$VERSION"; then
            echo "OK: $VERSION is already released for image $name, Continuing..."
        else
            echo "OK: $VERSION not found in releases, release will be prepared. Continuing..."
            docker pull "$CONTAINER_PULL_REGISTRY"/"$lfn_umbrella"/"$name":"$version"
            container_image_id="$(docker images | grep $name | grep $version | awk '{print $3}')"
            echo "INFO: Merge will run the following commands:"
            echo "docker tag $container_image_id $CONTAINER_PUSH_REGISTRY/$lfn_umbrella/$name:$VERSION"
            echo "docker push $CONTAINER_PUSH_REGISTRY/$lfn_umbrella/$name:$VERSION"
            if [[ "$JOB_NAME" =~ "merge" ]]; then
                docker tag "$container_image_id" "$CONTAINER_PUSH_REGISTRY"/"$lfn_umbrella"/"$name":"$VERSION"
                docker push "$CONTAINER_PUSH_REGISTRY"/"$lfn_umbrella"/"$name":"$VERSION"
            fi
            echo "#########################"
        fi
    done

    echo "INFO: Merge will tag ref: $ref"
    git checkout "$ref"
    tag
}

maven_release_file(){
    echo "INFO: wget -P $PATCH_DIR ${LOGS_URL}/staging-repo.txt.gz"
    wget -P "$PATCH_DIR" "${LOGS_URL}/"staging-repo.txt.gz
    pushd "$PATCH_DIR"
        echo "INFO: wget ${LOGS_URL}/patches/{${PROJECT//\//-}.bundle,taglist.log.gz}"
        wget "${LOGS_URL}"/patches/{"${PROJECT//\//-}".bundle,taglist.log.gz}
        gunzip taglist.log.gz
        cat "$PATCH_DIR"/taglist.log
    popd
    git checkout "$(awk '{print $NF}' "$PATCH_DIR/taglist.log")"
    git fetch "$PATCH_DIR/${PROJECT//\//-}.bundle"
    git merge --ff-only FETCH_HEAD
    nexus_release
    tag
}

echo "########### Start Script release-job.sh ###################################"

# Check if this is a container or maven release: release-container-schema.yaml vs release-schema.yaml
# Logic to determine what we are releasing.
##########################################

# Set common environment variables
set_variables_common

if [[ "$DISTRIBUTION_TYPE" == "maven" ]]; then
    wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/release-schema.yaml
    RELEASE_SCHEMA="release-schema.yaml"
    if $USE_RELEASE_FILE ; then
        verify_schema
    fi
    set_variables_maven
    verify_version
    maven_release_file
elif [[ "$DISTRIBUTION_TYPE" == "container" ]]; then
    wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/release-container-schema.yaml
    RELEASE_SCHEMA="release-container-schema.yaml"
    verify_schema
    set_variables_container
    verify_version
    container_release_file
else
    echo "ERROR: distribution_type: $DISTRIBUTION_TYPE not supported"
    echo "Must be maven or container"
    exit 1
fi
##########################################

echo "########### End Script release-job.sh ###################################"
