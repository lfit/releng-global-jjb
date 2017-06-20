#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> jjb-verify-job.sh"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

# If project is global-jjb then prepare custom tests
if [ "$PROJECT" == "global-jjb" ]; then
    cp test.template jjb/test.yaml
fi

jenkins-jobs -l DEBUG test --recursive -o archives/job-configs jjb/

# Cleanup custom global-jjb test yaml
if [ "$PROJECT" == "global-jjb" ]; then
    rm jjb/test.yaml
fi

# Sort job output into sub-directories. On large Jenkins systems that have
# many jobs archiving so many files into the same directory makes NGINX return
# the directory list slow.
pushd archives/job-configs
for letter in {a..z}
do
    if [[ $(ls "$letter"* > /dev/null 2>&1) -eq 0 ]]
    then
        mkdir "$letter"
        find . -maxdepth 1 -type f -name "$letter*" -exec mv {} "$letter" \;
    fi
done
popd
