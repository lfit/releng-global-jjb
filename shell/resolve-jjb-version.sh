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
    tmp_version=$(fgrep 'jenkins-job-builder==' "${WORKSPACE}/jjb_version.txt" | cut -d '=' -f 3)
    if [[ "${tmp_version}" != "" ]]
    then
        RESOLVED_JJB_VERSION="${tmp_version}"
    fi
fi
if [[ "${RESOLVED_JJB_VERSION}" == "auto" ]]
then
    RESOLVED_JJB_VERSION="6.0.0"
fi

if echo "RESOLVED_JJB_VERSION=${RESOLVED_JJB_VERSION}" > "${WORKSPACE}/_resolved_jjb_version.txt"
then
    cat "${WORKSPACE}/_resolved_jjb_version.txt"
else
    echo "Failed to resolve JJB version!"
fi
