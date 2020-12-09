#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2020 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> pipeline-linter.sh"

set -eu -o pipefail

# shellcheck disable=SC2153
JENKINS_CRUMB=$(curl --silent "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
JENKINS_VAL="$JENKINS_URL/pipeline-model-converter/validate"
mapfile -t JENKINS_FILE_LIST < <(grep -lr "^pipeline\s*{" vars src Jenkinsfile*)
exit_code=0

for JENKINS_FILE in "${JENKINS_FILE_LIST[@]}"
do
    ret=$(curl --silent -X POST -H "$JENKINS_CRUMB" -F "jenkinsfile=<$JENKINS_FILE" "$JENKINS_VAL")
    if [[ $ret == *"Errors"* ]];then
        echo "ERROR: Linting error for $JENKINS_FILE"
        exit_code=1
    # Check for the line "agent any". This includes master as an agent.
    elif grep "^\s*agent any" "$JENKINS_FILE"; then
        echo "ERROR: $JENKINS_FILE is set to use any agent. Please specify a label instead."
        exit_code=1
    # If "any" is not used, check for master as a specified label or node.
    elif grep -Pz "agent\s*\{\s*(label|node)\s+['\"]*master" "$JENKINS_FILE"; then
        echo "ERROR: $JENKINS_FILE is set to use master as an agent. Please specify a different label."
        exit_code=1
    else
        echo "$JENKINS_FILE successfully validated"
    fi
done

# Set non-zero exit if linter reports any errors
exit "$exit_code"
