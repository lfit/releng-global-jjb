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

jenkins-jobs -l DEBUG test --recursive -o archives/job_output jjb/

# Sort job output into sub-directories. On large Jenkins systems that have
# many jobs archiving so many files into the same directory makes NGINX return
# the directory list slow.
alphabet="a b c d e f g h i j k l m n o p q r s t u v w x y z"
for letter in $alphabet
do
    if [[ $(ls "$letter"*) -ne 0 ]]
    then
        mkdir "$letter"
        mv "$letter"* "$letter"
    fi
done
