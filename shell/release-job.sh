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

# shellcheck disable=SC1090
source ~/lf-env.sh

# Version controlled by JJB_VERSION
lf-activate-venv lftools pip idna==2.8 lftools jsonschema twine yq readline

# show installed versions
python -m pip --version
python -m pip freeze

#Functions.

set_variables_common(){
    echo "INFO: Setting common variables"
    if [[ -z ${LOGS_SERVER:-} ]]; then
        echo "ERROR: LOGS_SERVER not defined"
        exit 1
    fi
    NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/"
    # Verify if using release file or parameters
    if $USE_RELEASE_FILE ; then
        release_files=$(git diff-tree -m --no-commit-id -r "$GIT_COMMIT" "$GIT_COMMIT^1" \
            --name-only -- "releases/" ".releases/")
        if (( $(grep -c . <<<"$release_files") > 1 )); then
          echo "INFO: RELEASE FILES ARE AS FOLLOWS: $release_files"
          echo "ERROR: Adding multiple release files in the same commit"
          echo "ERROR: OR rename/amend/delete of existing files is not supported."
          exit 1
        else
          release_file="$release_files"
          echo "INFO: RELEASE FILE: $release_files"
        fi
    else
        echo "INFO: This job is built with parameters, no release file needed."
        release_file="None"
    fi

    # Jenkins parameter drop-down defaults DISTRIBUTION_TYPE to None
    # in the contain/maven release job; get value from release yaml.
    # Packagecloud and PyPI jobs set the appropriate value.
    DISTRIBUTION_TYPE="${DISTRIBUTION_TYPE:-None}"
    if [[ $DISTRIBUTION_TYPE == "None" ]]; then
        if ! DISTRIBUTION_TYPE=$(yq -r ".distribution_type" "$release_file"); then
            echo "ERROR: Failed to get distribution_type from $release_file"
            exit 1
        fi
    fi

    PATCH_DIR=$(mktemp -d)

    TAG_RELEASE="${TAG_RELEASE:-None}"
    if [[ $TAG_RELEASE == "None" ]]; then
        if grep -q "tag_release" $release_file ; then
            TAG_RELEASE=$(yq -r .tag_release "$release_file")
        else
            TAG_RELEASE=true
        fi
    fi

    # Displaying Release Information (Common variables)
    printf "\t%-30s\n" RELEASE_ENVIRONMENT_INFO:
    printf "\t%-30s %s\n" RELEASE_FILE: "$release_file"
    printf "\t%-30s %s\n" LOGS_SERVER: "$LOGS_SERVER"
    printf "\t%-30s %s\n" NEXUS_PATH: "$NEXUS_PATH"
    printf "\t%-30s %s\n" JENKINS_HOSTNAME: "$JENKINS_HOSTNAME"
    printf "\t%-30s %s\n" SILO: "$SILO"
    printf "\t%-30s %s\n" PROJECT: "$PROJECT"
    printf "\t%-30s %s\n" PROJECT-DASHED: "${PROJECT//\//-}"
    printf "\t%-30s %s\n" TAG_RELEASE: "$TAG_RELEASE"
    printf "\t%-30s %s\n" DISTRIBUTION_TYPE: "$DISTRIBUTION_TYPE"
}

set_variables_maven(){
    echo "INFO: Setting maven variables"
    if [[ -z ${VERSION:-} ]]; then
        VERSION=$(yq -r ".version" "$release_file")
    fi
    if [[ -z ${GIT_TAG:-} ]]; then
        if grep -q "git_tag" "$release_file" ; then
            GIT_TAG=$(yq -r ".git_tag" "$release_file")
        else
            GIT_TAG="$VERSION"
        fi
    fi
    if [[ -z ${LOG_DIR:-} ]]; then
        LOG_DIR=$(yq -r ".log_dir" "$release_file")
    fi
    LOGS_URL="${LOGS_SERVER}/${NEXUS_PATH}${LOG_DIR}"
    LOGS_URL=${LOGS_URL%/}  # strip any trailing '/'

    # Continuing displaying Release Information (Maven)
    printf "\t%-30s\n" RELEASE_MAVEN_INFO:
    printf "\t%-30s %s\n" VERSION: "$VERSION"
    printf "\t%-30s %s\n" GIT_TAG: "$GIT_TAG"
    printf "\t%-30s %s\n" LOG_DIR: "$LOG_DIR"
    printf "\t%-30s %s\n" LOGS_URL: "$LOGS_URL"
}

set_variables_container(){
    echo "INFO: Setting container variables"
    if [[ -z ${VERSION:-} ]]; then
        VERSION=$(yq -r ".container_release_tag" "$release_file")
    fi
    if [[ -z ${GIT_TAG:-} ]]; then
        if grep -q "git_tag" "$release_file" ; then
            GIT_TAG=$(yq -r ".git_tag" "$release_file")
        else
            GIT_TAG="$VERSION"
        fi
   fi
    if grep -q "container_pull_registry" "$release_file" ; then
        CONTAINER_PULL_REGISTRY=$(yq -r ".container_pull_registry" "$release_file")
    fi
    if grep -q "container_push_registry" "$release_file" ; then
        CONTAINER_PUSH_REGISTRY=$(yq -r ".container_push_registry" "$release_file")
    fi
    # Make sure both pull and push registries are defined
    if [ -z ${CONTAINER_PULL_REGISTRY+x} ] || [ -z ${CONTAINER_PUSH_REGISTRY+x} ]; then
        echo "ERROR: CONTAINER_PULL_REGISTRY and CONTAINER_PUSH_REGISTRY need to be defined"
        exit 1
    fi
    ref=$(yq -r ".ref" "$release_file")

    # Continuing displaying Release Information (Container)
    printf "\t%-30s\n" RELEASE_CONTAINER_INFO:
    printf "\t%-30s %s\n" CONTAINER_RELEASE_TAG: "$VERSION"
    printf "\t%-30s %s\n" CONTAINER_PULL_REGISTRY: "$CONTAINER_PULL_REGISTRY"
    printf "\t%-30s %s\n" CONTAINER_PUSH_REGISTRY: "$CONTAINER_PUSH_REGISTRY"
    printf "\t%-30s %s\n" GERRIT_REF_TO_TAG: "$ref"
    printf "\t%-30s %s\n" GIT_TAG: "$GIT_TAG"
}

set_variables_pypi(){
    echo "INFO: Setting pypi variables"
    if [[ -z ${LOG_DIR:-} ]]; then
        LOG_DIR=$(yq -r ".log_dir" "$release_file")
    fi
    LOGS_URL="${LOGS_SERVER}/${NEXUS_PATH}${LOG_DIR}"
    LOGS_URL=${LOGS_URL%/}  # strip any trailing '/'
    if [[ -z ${PYPI_PROJECT:-} ]]; then
        PYPI_PROJECT=$(yq -r ".pypi_project" "$release_file")
    fi
    if [[ -z ${PYTHON_VERSION:-} ]]; then
        PYTHON_VERSION=$(yq -r ".python_version" "$release_file")
    fi
    if [[ -z ${VERSION:-} ]]; then
        VERSION=$(yq -r ".version" "$release_file")
    fi
    if [[ -z ${GIT_TAG:-} ]]; then
        if grep -q "git_tag" "$release_file" ; then
            GIT_TAG=$(yq -r ".git_tag" "$release_file")
        else
            GIT_TAG="$VERSION"
        fi
   fi

    # Continuing displaying Release Information (pypi)
    printf "\t%-30s\n" RELEASE_PYPI_INFO:
    printf "\t%-30s %s\n" LOG_DIR: "$LOG_DIR"
    printf "\t%-30s %s\n" LOGS_URL: "$LOGS_URL"
    printf "\t%-30s %s\n" PYPI_INDEX: "$PYPI_INDEX" # from job configuration
    printf "\t%-30s %s\n" PYPI_PROJECT: "$PYPI_PROJECT"
    printf "\t%-30s %s\n" PYTHON_VERSION: "$PYTHON_VERSION"
    printf "\t%-30s %s\n" VERSION: "$VERSION"
    printf "\t%-30s %s\n" GIT_TAG: "$GIT_TAG"
}

set_variables_packagecloud(){
     echo "INFO: Setting packagecloud variables"
     if [[ -z ${VERSION:-} ]]; then
         VERSION=$(yq -r ".version" "$release_file")
     fi
     if [[ -z ${GIT_TAG:-} ]]; then
         if grep -q "git_tag" $release_file ; then
             GIT_TAG=$(yq -r ".git_tag" "$release_file")
         else
             GIT_TAG="$VERSION"
         fi
     fi
     if [[ -z ${LOG_DIR:-} ]]; then
         LOG_DIR=$(yq -r ".log_dir" "$release_file")
     fi
     if [[ -z ${REF:-} ]]; then
         REF=$(yq -r ".ref" "$release_file")
     fi
     if [[ -z ${PACKAGE_NAME:-} ]]; then
         PACKAGE_NAME=$(yq -r ".package_name" "$release_file")
     fi
     logs_url="${LOGS_SERVER}/${NEXUS_PATH}${LOG_DIR}"
     logs_url=${logs_url%/}  # strip any trailing '/'

     printf "\t%-30s %s\n" PACKAGE_NAME: "$PACKAGE_NAME"
     printf "\t%-30s %s\n" LOG_DIR: "$LOG_DIR"
     printf "\t%-30s %s\n" LOGS_URL: "$logs_url"
     printf "\t%-30s %s\n" GERRIT_REF_TO_TAG: "$REF"
     printf "\t%-30s %s\n" VERSION: "$VERSION"
     printf "\t%-30s %s\n" GIT_TAG: "$GIT_TAG"
}

verify_schema(){
    echo "INFO: Verifying $release_file against schema $release_schema"
    lftools schema verify "$release_file" "$release_schema"
}

verify_version(){
    # Verify allowed patterns "#.#.#" (SemVer) or "v#.#.#"
    echo "INFO: Verifying version $VERSION"
    allowed_version_regex="^[vV]?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)([\-|\.](0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*))*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?"
    if [[ $VERSION =~ $allowed_version_regex ]]; then
        echo "INFO: The version $VERSION is valid"
    else
        echo "ERROR: The version $VERSION is not valid"
        echo "ERROR: Valid versions are \"#.#.#\" (SemVer) or \"v#.#.#\""
        echo "ERROR: See https://semver.org/ for more details on SemVer"
        exit 1
    fi
}

verify_version_match_release(){
    echo "INFO: Fetching console log from $LOGS_URL"
    wget -P /tmp "${LOGS_URL}/"console.log.gz
    echo "INFO: Searching for uploaded step and version $VERSION in job log"
    if zgrep "Successfully uploaded" /tmp/console.log.gz | grep "$VERSION"; then
        echo "INFO: found expected strings in job log"
    else
        echo "ERROR: Defined version in release file does not match staging repo artifacts version to be released"
        echo "ERROR: Please make sure maven stage job log dir and release version are both correct"
        exit 1
    fi
}

# check prerequisites to detect mistakes in the release YAML file
verify_pypi_match_release(){
    echo "INFO: Fetching console log from $LOGS_URL"
    wget -q -P /tmp "${LOGS_URL}/"console.log.gz
    echo "INFO: Searching for uploaded step, project $PYPI_PROJECT and version $VERSION in job log"
    # pypi-upload.sh generates success message with file list
    if zgrep -i "uploaded" /tmp/console.log.gz | grep "$PYPI_PROJECT" | grep "$VERSION" ; then
        echo "INFO: found expected strings in job log"
    else
        echo "ERROR: failed to find expected strings in job log"
        exit 1
    fi
}

verify_packagecloud_match_release(){
    echo "INFO: Fetching console log from $logs_url"
    wget -q -P /tmp "${logs_url}/"console.log.gz
    echo "INFO: Searching for uploaded step, package name $PACKAGE_NAME and version $VERSION in job log"
    if  zgrep -E "Pushing.*$PACKAGE_NAME.*$VERSION.*success\!" /tmp/console.log.gz; then
        echo "INFO: found expected strings in job log"
    else
        echo "ERROR: failed to find expected strings in job log"
        exit 1
    fi
}

# sigul is only available on Centos
# TODO: write tag-github-repo function
tag-gerrit-repo(){
    if [[ $TAG_RELEASE == false ]]; then
       echo "INFO: Skipping gerrit repo tag"
       return
    fi

    echo "INFO: tag gerrit with $GIT_TAG"
    # Import public signing key
    gpg --import "$SIGNING_PUBKEY"
    if type=$(git cat-file -t "$GIT_TAG"); then
        if [[ $type == "tag" ]]; then
            echo "INFO: Repo already has signed tag $GIT_TAG, nothing to do"
        else
            echo "ERROR: Repo has lightweight tag $GIT_TAG, blocks push of signed tag"
            exit 1
        fi
    else
        echo "INFO: Repo has not yet been tagged $GIT_TAG"
        git tag -am "${PROJECT//\//-} $GIT_TAG" "$GIT_TAG"
        sigul --batch -c "$SIGUL_CONFIG" sign-git-tag "$SIGUL_KEY" "$GIT_TAG" < "$SIGUL_PASSWORD"
        echo "INFO: Showing latest signature for $PROJECT:"
        echo "INFO: git tag -v $GIT_TAG"
        git tag -v "$GIT_TAG"

        ########## Merge Part ##############
        if [[ "$JOB_NAME" =~ "merge" ]] && [[ "$DRY_RUN" = false ]]; then
            echo "INFO: Running merge, pushing tag"
            gerrit_ssh=$(echo "$GERRIT_URL" | awk -F"/" '{print $3}')
            git remote set-url origin ssh://"$RELEASE_USERNAME"@"$gerrit_ssh":29418/"$PROJECT"
            git config user.name "$RELEASE_USERNAME"
            git config user.email "$RELEASE_EMAIL"
            echo -e "Host $gerrit_ssh\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
            chmod 600 ~/.ssh/config
            git push origin "$GIT_TAG"
        fi
    fi
}

nexus_release(){
    echo "INFO: Processing nexus release"
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
    docker --version
    local lfn_umbrella
    lfn_umbrella="$(echo "$GERRIT_URL" | awk -F"." '{print $2}')"

    for namequoted in $(yq '.containers[].name' $release_file); do
        versionquoted=$(yq ".containers[] |select(.name==$namequoted) |.version" $release_file)

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
            echo "INFO: $VERSION is already released for image $name, Continuing..."
        else
            echo "INFO: $VERSION not found in releases, release will be prepared. Continuing..."
            docker pull "$CONTAINER_PULL_REGISTRY"/"$lfn_umbrella"/"$name":"$version"
            container_image_id=$(docker images | grep "$name" | grep "$version" | awk '{print $3}')
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
    tag-gerrit-repo
}

maven_release_file(){
    echo "INFO: Processing maven release"
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
    tag-gerrit-repo
}

# calls pip to download binary and source distributions from the specified index,
# which requires a recent-in-2019 version.  Uploads the files it received.
pypi_release_file(){
    echo "INFO: Processing pypi release"
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
    # shellcheck disable=SC2012
    filecount=$(ls $tgtdir | wc -l)
    if [[ $filecount = 0 ]] ; then
        echo "ERROR: no files downloaded"
        exit 1
    else
        # shellcheck disable=SC2046
        echo "INFO: downloaded $filecount distributions: " $(ls $tgtdir)
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
    tag-gerrit-repo
}

packagecloud_verify(){
    echo "INFO: Verifying $1 exists in staging..."
    if [[ $1 == $(curl --netrc-file ~/packagecloud_api --silent \
        https://packagecloud.io/api/v1/repos/"$2"/staging/search?q="$1" \
        | yq -r .[].filename) ]]; then
        echo "INFO: $1 exists in staging!"
        echo "INFO: Existing package location: https://packagecloud.io$(curl \
            --netrc-file ~/packagecloud_api --silent \
            https://packagecloud.io/api/v1/repos/"$2"/staging/search?q="$1" \
            | yq -r .[].package_html_url)"
    else
        echo "ERROR: $1 does not exist in staging"
        exit 1
    fi
}

packagecloud_promote(){
    echo "INFO: Preparing to promote $1..."
    promote_url="https://packagecloud.io$(curl --netrc-file ~/packagecloud_api \
        --silent https://packagecloud.io/api/v1/repos/"$2"/staging/search?q="$1" \
        | yq -r .[].promote_url)"
    echo "INFO: Promoting $1 from staging to release"
    curl --netrc-file ~/packagecloud_api -X POST -F \
        destination="$2/release" "$promote_url" \
        | echo "INFO: Promoted package location: \
        https://packagecloud.io$(yq -r .package_html_url)"
    git checkout "$REF"
    tag-gerrit-repo
}

##############################  End Function Declarations  ################################

# Set common environment variables
set_variables_common

# Determine the type of release:
#   - container, release-container-schema.yaml
#   - maven, release-schema.yaml
#   - pypi,  release-pypi-schema.yaml

case $DISTRIBUTION_TYPE in

    maven)
        if $USE_RELEASE_FILE ; then
            release_schema="release-schema.yaml"
            echo "INFO: Fetching schema $release_schema"
            wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/$release_schema
            verify_schema
        fi
        set_variables_maven
        verify_version
        verify_version_match_release
        maven_release_file
        ;;

    container)
        if $USE_RELEASE_FILE ; then
            release_schema="release-container-schema.yaml"
            echo "INFO: Fetching schema $release_schema"
            wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/${release_schema}
            verify_schema
        fi
        set_variables_container
        verify_version
        container_release_file
        ;;

    pypi)
        if $USE_RELEASE_FILE ; then
            release_schema="release-pypi-schema.yaml"
            echo "INFO: Fetching schema $release_schema"
            wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/${release_schema}
            verify_schema
        fi
        set_variables_pypi
        verify_version
        verify_pypi_match_release
        pypi_release_file
        ;;

    packagecloud)
        if $USE_RELEASE_FILE ; then
            release_schema="release-packagecloud-schema.yaml"
            packagecloud_account=$(cat "$ACCOUNT_NAME_FILE")
            echo "INFO: Fetching schema $release_schema"
            wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/${release_schema}
            verify_schema
        fi
        set_variables_packagecloud
        verify_packagecloud_match_release
        for name in $(yq -r '.packages[].name' $release_file); do
            package=$name
            packagecloud_verify "$package" "$packagecloud_account"
            if [[ "$JOB_NAME" =~ "merge" ]] && ! $DRY_RUN; then
                packagecloud_promote "$package" "$packagecloud_account"
            fi
        done
        ;;

    *)
        echo "ERROR: distribution_type: $DISTRIBUTION_TYPE not supported"
        exit 1
        ;;
esac

echo "---> release-job.sh ends"
