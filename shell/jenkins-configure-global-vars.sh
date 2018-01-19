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

set -eu -o pipefail

export JENKINS_URL=$(crudini --get "$HOME"/.config/jenkins_jobs/jenkins_jobs.ini jenkins url)
export JENKINS_USER=$(crudini --get "$HOME"/.config/jenkins_jobs/jenkins_jobs.ini jenkins user)
export JENKINS_PASSWORD=$(crudini --get "$HOME"/.config/jenkins_jobs/jenkins_jobs.ini jenkins password)

global_vars="$WORKSPACE/jenkins-config/global-vars-$SILO.sh"

if [ ! -f "$global_vars" ]; then
    echo "ERROR: Configuration file $global_vars not found."
    exit 1
fi

mapfile -t vars < <(cat $global_vars)

rm -f insert.txt
for var in "${vars[@]}"; do
    key=$(echo $var | cut -d\= -f1)
    value=$(echo $var | cut -d\= -f2)
    echo "    '$key': '$value'," >> insert.txt
done

# Insert variables and remove first occurrence of JENKINS_URL variable
echo "-----> script.groovy"
sed "/'JENKINS_URL'/r insert.txt" "$GROOVY_SCRIPT_FILE" \
    | sed "0,/'JENKINS_URL'/{/'JENKINS_URL'/d}" \
    > script.groovy
cat script.groovy

lftools jenkins groovy script.groovy
