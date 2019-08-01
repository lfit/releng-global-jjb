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
echo "---> check-info-votes.sh"
set -u unset

ref=$(echo "$GERRIT_REFSPEC" | awk -F"/" '{ print $4 }')
pip="pip3"

# For OPNFV
if [[ $NODE_NAME =~ "lf-build" ]]; then
    pip=pip
fi

if [ -d "/opt/pyenv" ]; then
    echo "---> Setting up pyenv"
    export PYENV_ROOT="/opt/pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    PYTHONPATH=$(pwd)
    export PYTHONPATH

    latest_version=$(pyenv versions \
      | sed s,*,,g \
      | awk '/[0-9]+/{ print $1 }' \
      | sort --version-sort \
      | awk '/./{line=$0} END{print line}')

    pyenv local "$latest_version"
    export PYENV_VERSION="3.6.4"
fi

sudo $pip install --upgrade pip
$pip install --user niet
$pip install --user lftools
$pip install --user jsonschema

echo "Checking votes:"
# Github
set +u unset
if ! [[ -z "$ghprbPullId" ]]; then
  echo "THIS IS A GITHUB PR"
  echo "$ghprbPullId"
  echo "$ghprbGhRepository"
  org=$(echo "$ghprbGhRepository" | awk -F"/" '{print $1}')
  repo=$(echo "$ghprbGhRepository" | awk -F"/" '{print $2}')
  lftools infofile check-votes INFO.yaml $org --github_repo $repo $ghprbPullId
  exit_status="$?"
  if [[ "$exit_status" -ne 0 ]]; then
    echo "Vote not yet complete"
  else
    echo "Vote completed submitting pr"
    lftools github submit-pr $org $repo $ghprbPullId
  fi

# Gerrit
else
  set -u unset
  echo "THIS IS A GERRIT PATCHSET"
  ref=$(echo "$GERRIT_REFSPEC" | awk -F"/" '{ print $4 }')
  change="$(echo "$GERRIT_CHANGE_URL" | awk -F"/" '{print $NF}')"
  echo "Checking votes:"
  lftools infofile check-votes INFO.yaml "$GERRIT_URL" "$ref" > gerrit_comment.txt
  exit_status="$?"
  #
  if [[ "$exit_status" -ne 0 ]]; then
    echo "Vote not yet complete"
    cat gerrit_comment.txt
    exit "$exit_status"
  else
    echo "Vote completed submitting review"
    ssh -p "$GERRIT_PORT" "$JENKINS_SSH_CREDENTIAL"@"$GERRIT_HOST" gerrit review "$change" --submit
  fi
fi

