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

jenkins-jobs -l DEBUG test --recursive -o archives/job-configs jjb/

# Sort job output into sub-directories. On large Jenkins systems that have
# many jobs archiving so many files into the same directory makes NGINX return
# the directory list slow.
pushd archives/job-configs
for letter in {a..z}
do
    ls "$letter"* > /dev/null 2>&1
    if [[ "$?" -eq 0 ]]
    then
        mkdir "$letter"
        find . -type f -maxdepth 1 -name "$letter*" -exec mv {} "$letter" \;
    fi
done
popd
