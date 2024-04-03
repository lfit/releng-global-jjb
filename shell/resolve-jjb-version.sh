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

if [[ "${JJB_VERSION:-auto}" == "auto" ]]
then
    { tmp_version=$(< ${WORKSPACE}/jjb_version.txt); } 2> /dev/null
    if [[ "${tmp_version}" != "" ]]
    then
        JJB_VERSION="${tmp_version}"
    fi
fi
if [[ "${JJB_VERSION:-auto}" == "auto" ]]
then
    JJB_VERSION="6.0.0"
fi

if echo "JJB_VERSION=${JJB_VERSION}" > "${WORKSPACE}/__jjb_version.txt"
then
    cat "${WORKSPACE}/__jjb_version.txt"
else
    echo "Failed to resolve JJB_VERSION!"
fi
