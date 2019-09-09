#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
#WIP STUFF, this will be covered by python-tools-install.sh tox-install.sh tox-run.sh
python3 -m venv ~/.venv
source ~/.venv/bin/activate
pip install --upgrade pip
pip install yq

git clone "https://gerrit.linuxfoundation.org/infra/releng/lftools"
pushd lftools
pip install -e .
popd

lftools --help
#END WIP STUFF

echo "---> rtd-verify.sh"
set -xe -o pipefail

echo "$PROJECT"
project_dashed="${PROJECT////-}"
umbrella="$(echo "$GERRIT_URL" | awk -F"." '{print $2}')"

if [[ "$JOB_NAME" =~ "verify" ]]; then

  if [[ "$(lftools rtd project-details "$umbrella"-"$project_dashed"-test | yq -r '.detail')" == "Not found." ]]; then
    echo "Project not found, creating project"
    lftools rtd project-create "$umbrella"-"$project_dashed-test" "$GERRIT_URL/$PROJECT" git "https://$umbrella-$project_dashed-test.readthedocs.io" py en

  fi

fi

echo "Merge will run"
echo "lftools rtd project-build-trigger $umbrella-$project_dashed-test $STREAM"

if [[ "$JOB_NAME" =~ "merge" ]]; then
    lftools rtd project-build-trigger "$umbrella"-"$project_dashed-test" "$STREAM"
fi
