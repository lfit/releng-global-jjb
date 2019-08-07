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

NEXUSPROXY="${NEXUSPROXY:-None}"
NEXUS_URL="${NEXUSPROXY:-$NEXUS_URL}"

release_files=$(git diff-tree --no-commit-id -r "$GERRIT_PATCHSET_REVISION" --name-only -- "releases/")
echo "RELEASE FILES ARE AS FOLLOWS: $release_files"

if (( $(grep -c . <<<"$release_files") > 1 )); then
  echo "multiple release files in the same commit do not make sense"
  echo "Additionally, do not rename or ammend an already merged release file"
  exit 1
else
  release_file="$release_files"
  echo "RELEASE FILE IS AS FOLLOWS: $release_file"
fi

NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/"
VERSION="$(niet ".version" "$release_file")"
LOG_DIR="$(niet ".log_dir" "$release_file")"
LOGS_URL="${LOGS_SERVER}/${NEXUS_PATH}${LOG_DIR}"
PATCH_DIR="$(mktemp -d)"
LOGS_URL=${LOGS_URL%/}  # strip any trailing '/'

#Check if this is a container of maven release: release-container-schema.yaml vs release-schema.yaml
echo "--> Verifying $release_file schema."
DISTRIBUTION_TYPE="$(niet ".distribution_type:" "$release_file")"

#INFO
echo "INFO:"
echo "RELEASE_FILE: $release_file"
echo "LOGS_SERVER: $LOGS_SERVER"
echo "NEXUS_PATH: $NEXUS_PATH"
echo "NEXUSPROXY: $NEXUSPROXY"
echo "JENKINS_HOSTNAME: $JENKINS_HOSTNAME"
echo "SILO: $SILO"
echo "PROJECT: $PROJECT"
echo "PROJECT-DASHED: ${PROJECT//\//-}"
echo "VERSION: $VERSION"
echo "LOG DIR: $LOG_DIR"

verify_schema(){
  lftools schema verify "$release_file" "$RELEASE_SCHEMA"
  # Verify allowed versions
  # Allowed versions are "v#.#.#" or "#.#.#" aka SemVer
  allowed_version_regex="^((v?)([0-9]+)\.([0-9]+)\.([0-9]+))$"
  if [[ ! $VERSION =~ $allowed_version_regex ]]; then
    echo "The version $VERSION is not a semantic valid version"
    echo "Allowed versions are \"v#.#.#\" or \"#.#.#\" aka SemVer"
    echo "See https://semver.org/ for more details on SemVer"
    exit 1
  fi

}

tag(){
  if git tag -v "$VERSION"; then
    echo "Repo already tagged $VERSION"
    echo "This job has already run exit 0"
    exit 0
  fi
  git tag -am "${PROJECT//\//-} $VERSION" "$VERSION"
  sigul --batch -c "$SIGUL_CONFIG" sign-git-tag "$SIGUL_KEY" "$VERSION" < "$SIGUL_PASSWORD"
  echo "Showing latest signature for $PROJECT:"
  gpg --import "$SIGNING_PUBKEY"
  echo "git tag -v $VERSION"
  git tag -v "$VERSION"
  ########## Merge Part ##############
  if [[ "$JOB_NAME" =~ "merge" ]]; then
    echo "Running merge"
    gerrit_ssh=$(echo "$GERRIT_URL" | awk -F"/" '{print $3}')
    git remote set-url origin ssh://"$RELEASE_USERNAME"@"$gerrit_ssh":29418/"$PROJECT"
    git config user.name "$RELEASE_USERNAME"
    git config user.email "$RELEASE_EMAIL"
    echo -e "Host $gerrit_ssh\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
    chmod 600 ~/.ssh/config
    git push origin "$VERSION"
  fi
}

nexus_release(){
  for staging_url in $(zcat "$PATCH_DIR"/staging-repo.txt.gz | awk -e '{print $2}'); do
    # extract the domain name from URL
    NEXUS_URL=$(echo "$staging_url" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    echo "NEXUS_URL: $NEXUS_URL"
    # extract the staging repo from URL
    STAGING_REPO=${staging_url#*repositories/}

    echo "Running Nexus Verify"
    lftools nexus release -v --server https://"$NEXUS_URL" "$STAGING_REPO"
    echo "Merge will run"
    echo "lftools nexus release --server https://$NEXUS_URL $STAGING_REPO"
    if [[ "$JOB_NAME" =~ "merge" ]]; then
      echo "Promoting $STAGING_REPO on $NEXUS_URL."
      lftools nexus release --server https://"$NEXUS_URL" "$STAGING_REPO"
    fi
  done
 }


container_release_file(){
  lfn_umbrella="$(echo "$GERRIT_HOST" | awk -F"." '{print $2}')"

  wget -P "$PATCH_DIR" "${LOGS_URL}/"console.log.gz
  ref=$(zcat console.log.gz | grep "git\ checkout\ \-f" | awk '{print $5}')
  #TAG PART
  echo "must tag ref $ref"
  git checkout "$ref"
  #Call tag function
  tag

  while read -d $'\n' name version; do
    name="$name"
    version=$(echo "$version" | awk '{print $4}' | cut -d "," -f1 )

    echo "Releasing $name $version as $VERSION"
    docker pull "$DOCKER_REGISTRY":10003/"$lfn_umbrella"/"$name":"$version"

    #TODO Determine if there is an edge case here
    container_image_id="$(docker images | grep "$name" | awk '{print $3}')"

    echo "Merge will run"
    echo "docker tag $container_image_id $DOCKER_REGISTRY:10002/$lfn_umbrella/$name:$VERSION"
    echo "docker push $DOCKER_REGISTRY:10002/$lfn_umbrella/$name:$VERSION"

    if [[ "$JOB_NAME" =~ "merge" ]]; then
    #TODO need to check if tag was allredy applied
    docker tag "$container_image_id" "$DOCKER_REGISTRY":10002/"$lfn_umbrella"/"$name":"$VERSION"
    docker push "$DOCKER_REGISTRY":10002/"$lfn_umbrella"/"$name":"$VERSION"
    fi
    echo "#########################"
  done < <(zcat "$PATCH_DIR"/console.log.gz | grep "DOCKER>" | grep "Tag\ with" | awk -F'"' '{print $2, $3}')

}

maven_release_file(){



  echo "wget -P $PATCH_DIR ${LOGS_URL}/staging-repo.txt.gz"
  wget -P "$PATCH_DIR" "${LOGS_URL}/"staging-repo.txt.gz


  pushd "$PATCH_DIR"
    echo "wget ${LOGS_URL}/patches/{${PROJECT//\//-}.bundle,taglist.log.gz}"
    wget "${LOGS_URL}"/patches/{"${PROJECT//\//-}".bundle,taglist.log.gz}
    gunzip taglist.log.gz
    cat "$PATCH_DIR"/taglist.log
  popd

  git checkout "$(awk '{print $NF}' "$PATCH_DIR/taglist.log")"
  git fetch "$PATCH_DIR/${PROJECT//\//-}.bundle"
  git merge --ff-only FETCH_HEAD

  #Call tag function
  tag

  # This function: if merge push to nexus. If verify output the proposed push command.
  nexus_release
  #
}

#Logic to determine what we are releasing.
##########################################
if [[ "$DISTRIBUTION_TYPE" == "maven" ]]; then
  wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/release-schema.yaml
  RELEASE_SCHEMA="release-schema.yaml"
  verify_schema
  maven_release_file
elif [[ "$DISTRIBUTION_TYPE" == "container" ]]; then
  wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/release-container-schema.yaml
  RELEASE_SCHEMA="release-container-schema.yaml"
  verify_schema
  container_release_file
else
  echo "distribution_type: $DISTRIBUTION_TYPE not supported"
  echo "Must be maven or container"
  exit 1
fi
##########################################

echo "########### End Script release-job.sh ###################################"
