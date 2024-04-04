#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2024 Cisco and/or its affiliates.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> resolve-jjb-version.sh"

RESOLVED_JJB_VERSION="${JJB_VERSION:-auto}"
if [[ "${RESOLVED_JJB_VERSION}" == "auto" ]]
then
    echo "Looking into requirements.txt for JJB version."
    version_line=$(grep '^jenkins-job-builder==' "${WORKSPACE}/requirements.txt")
    version_substring=$(echo "${version_line}" | cut -d '=' -f 3)
    # There could be a trailing comment.
    version_value=$(echo "${version_substring}" | cut -d ' ' -f 1 | cut -d '#' -f 1)
    if [[ "${version_value}" != "" ]]
    then
        echo "Found: ${version_value}"
        RESOLVED_JJB_VERSION="${version_value}"
    else
        echo "JJB version or requirements.txt not found."
    fi
else
    echo "Not asked to autodetect, using provided value: ${RESOLVED_JJB_VERSION}"
fi
if [[ "${RESOLVED_JJB_VERSION}" == "auto" ]]
then
    echo "Falling back to default JJB version."
    RESOLVED_JJB_VERSION="6.0.0"
fi

if echo "RESOLVED_JJB_VERSION=${RESOLVED_JJB_VERSION}" > "${WORKSPACE}/_resolved_jjb_version.txt"
then
    cat "${WORKSPACE}/_resolved_jjb_version.txt"
else
    echo "Failed to save JJB version!"
fi
