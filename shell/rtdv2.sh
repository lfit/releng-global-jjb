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
#sudo yum install python34 python34-devel python34-pip python34-setuptools python34-virtualenv


#WIP FIX ENV STUFF
#sudo yum -y install python36 python36-devel python36-pip python36-setuptools python36-virtualenv
#sudo alternatives --list | grep -i python
#sudo alternatives --install /usr/bin/python python /usr/bin/python3.6 70
#sudo alternatives --install /usr/bin/python python /usr/bin/python2.7 60

#pip3.6 --version
#python --version

python3 -m venv ~/.venv
source ~/.venv/bin/activate

pip install --upgrade pip
pip install yq

git clone "https://gerrit.linuxfoundation.org/infra/releng/lftools"
pushd lftools
git fetch "https://gerrit.linuxfoundation.org/infra/releng/lftools" refs/changes/23/61523/11 && git checkout FETCH_HEAD
pip install -e .
popd

lftools --help
#END WIP STUFF

echo "---> rtd-verify.sh"
set -xe -o pipefail

echo "---> Generating docs"
pip install tox

echo "$PROJECT"
project_dashed="${PROJECT////-}"
umbrella="$(echo "$GERRIT_URL" | awk -F"." '{print $2}')"


#we can generate staging docs on a verify job.
if [[ "$JOB_NAME" =~ "verify" ]]; then
  #create and trigger build on a staging job.
  if [[ "$(lftools rtd project-details "$umbrella"-"$project_dashed"-test-stage | yq -r '.detail')" == "Not found." ]]; then
    lftools rtd project-create "$umbrella"-"$project_dashed-test-stage" "$GERRIT_URL/$PROJECT" git "https://$umbrella-$project_dashed-test-stage.readthedocs.io" py en
    tox -e docs
    if [[ "$(lftools rtd project-details "$umbrella"-"$project_dashed"-test-stage | yq -r '.detail')" == "Not found." ]]; then
      sleep 30
    else
      lftools rtd project-build-trigger "$umbrella"-"$project_dashed-test-stage" master
      echo "Docs will be avaliable at https://$umbrella-$project_dashed-test-stage.readthedocs.io"
    fi

  fi

  if [[ "$(lftools rtd project-details "$umbrella"-"$project_dashed"-test | yq -r '.detail')" == "Not found." ]]; then
    echo "Project not found, creating project"
    lftools rtd project-create "$umbrella"-"$project_dashed-test" "$GERRIT_URL/$PROJECT" git "https://$umbrella-$project_dashed-test.readthedocs.io" py en

  fi

fi

echo "Merge will run"
echo "lftools rtd project-build-trigger $umbrella-$project_dashed-test master"

if [[ "$JOB_NAME" =~ "merge" ]]; then
    lftools rtd project-build-trigger "$umbrella"-"$project_dashed-test" master
fi
