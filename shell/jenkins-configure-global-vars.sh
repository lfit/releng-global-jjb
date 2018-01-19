#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> jenkins-configure-global-vars.sh"

GROOVY_SCRIPT_FILE="jjb/global-jjb/jenkins-admin/set_global_properties.groovy"

virtualenv --quiet "/tmp/v/lftools"
# shellcheck source=/tmp/v/lftools/bin/activate disable=SC1091
source "/tmp/v/lftools/bin/activate"

export JENKINS_URL=$(crudini --get "$HOME"/.config/jenkins_jobs/jenkins_jobs.ini jenkins url)
export JENKINS_USER=$(crudini --get "$HOME"/.config/jenkins_jobs/jenkins_jobs.ini jenkins user)
export JENKINS_PASSWORD=$(crudini --get "$HOME"/.config/jenkins_jobs/jenkins_jobs.ini jenkins password)

mapfile -t vars <<< $(cat $WORKSPACE/jenkins-config/jenkins-global-vars)

rm insert.txt || true  # Ensure insert.txt does not already exist
for var in "${vars[@]}"; do
    key=$(echo $var | cut -d\= -f1)
    value=$(echo $var | cut -d\= -f2)
    echo "    '$key': '$value'," >> insert.txt
done

sed "/'JENKINS_URL'/r insert.txt" "$GROOVY_SCRIPT_FILE" \
    | sed "0,/'JENKINS_URL'/{/'JENKINS_URL'/d}" \  # Remove first occurrance of JENKINS_URL variable
    > script.groovy

lftools jenkins groovy script.groovy
