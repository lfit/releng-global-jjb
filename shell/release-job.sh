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

logs_server="${logs_server:-None}"
maven_central_url="${maven_central_url:-None}"

if [ "${logs_server}" == 'None' ]; then
  echo "FAILED: log server not found"
  exit 1
fi

nexus_url="${ODLNEXUSPROXY:-$nexus_url}"

release_files=$(git diff HEAD^1 --name-only -- "releases/")
echo "---> RELEASE FILES ARE AS FOLLOWS: $release_files"

for release_file in $release_files; do
  echo "---> Verifying $release_file Schema."

  # OPTIONAL (TO PUSH TO MAVEN CENTRAL)
  if grep -q "\.maven_central_url" "$release_file"; then
    maven_central_url="$(niet ".maven_central_url" "$release_file")"
  fi

  echo "---> lftools command:"
  # Make sure the schema check catches a missing trailing / on log_dir
  # lftools schema is written, but not the schema file (yet)
  echo "lftools schema verify [OPTIONS] $release_file $SCHEMAFILE"

  version="$(niet ".version" "$release_file")"
  project="$(niet ".project" "$release_file")"
  log_dir="$(niet ".log_dir" "$release_file")"

  nexus_path="${SILO}/${JENKINS_HOSTNAME}/"
  logs_url="${logs_server}/${nexus_path}${log_dir}"
  patch_dir="$(mktemp -d)"

  pushd "$patch_dir"
    wget --quiet "${logs_url}"staging-repo.txt.gz
    staging_repo="$(zcat staging-repo.txt)"

    # RELEASE INFORMATION
    echo "---> RELEASE INFORMATION:"
    printf '%-18s: %s\n' "JENKINS_HOSTNAME" "$JENKINS_HOSTNAME"
    printf '%-18s: %s\n' "LOG_DIR" "$log_dir"
    printf '%-18s: %s\n' "LOGS_SERVER" "$logs_server"
    printf '%-18s: %s\n' "NEXUS_PATH" "$nexus_path"
    printf '%-18s: %s\n' "NEXUS_URL" "$nexus_url"
    printf '%-18s: %s\n' "ODLNEXUSPROXY" "$ODLNEXUSPROXY"
    printf '%-18s: %s\n' "PROJECT" "$project"
    printf '%-18s: %s\n' "RELEASE_FILE" "$release_file"
    printf '%-18s: %s\n' "SILO" "$SILO"
    printf '%-18s: %s\n' "STAGING_REPO" "$staging_repo"
    printf '%-18s: %s\n' "VERSION" "$version"

    wget --quiet  "${logs_url}"/patches/{"${project}".bundle,taglist.log.gz}
    gunzip taglist.log.gz
    cat "$patch_dir"/taglist.log
  popd

  git checkout "$(awk '{print $NF}' "$patch_dir/taglist.log")"
  git fetch "$patch_dir/$project.bundle"
  git merge --ff-only FETCH_HEAD
  git tag -am "$project $version" "v$version"
  sigul --batch -c "$SIGUL_CONFIG" sign-git-tag "$SIGUL_KEY" v"$version" < "$SIGUL_PASSWORD"
  echo "---> Showing latest signature for $project:"
  git log --show-signature -n1

  # MERGE PART (RELEASE ARTIFACTS BY MERGE JOB)
  if [[ "$JOB_NAME" =~ "merge" ]]; then
    echo "---> Running merge (Releasing the artifacts)..."
    git push origin "v$version"
    lftools nexus release --server "$nexus_url" "$staging_repo"
    if [ "${maven_central_url}" == 'None' ]; then
      echo "---> No Maven central url specified, not pushing to maven central"
    else
      lftools nexus release --server "$maven_central_url" "$staging_repo"
    fi
  fi
done
echo "---> end release-job.sh"
