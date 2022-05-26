#!/bin/bash

# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2022 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
# Script to run the sigul signing from within a CentOS7 docker container

echo "Sign files in: $SIGN_DIR"

set -e  # Fail immediately if any if signing fails
find "${SIGN_DIR}" -type f ! -name "*.asc" \
        ! -name "*.md5" \
        ! -name "*.sha1" \
        ! -name "_maven.repositories" \
        ! -name "_remote.repositories" \
        ! -name "*.lastUpdated" \
        ! -name "maven-metadata-local.xml" \
        ! -name "maven-metadata.xml" > ${WORKSPACE}/sign.lst

if [ -s ${WORKSPACE}/sign.lst ]; then
   echo "Sign list is not empty"
fi

files_to_sign=()
while IFS= read -rd $'\n' line; do
    files_to_sign+=("$line")
    sigul --batch -c "${SIGUL_CONFIG}" sign-data -a -o "${line}.asc" "${SIGUL_KEY}" "${line}" < "${SIGUL_PASSWORD}"
done < ${WORKSPACE}/sign.lst

if [ "${#files_to_sign[@]}" -eq 0 ]; then
     echo "ERROR: No files to sign. Quitting..."
     exit 1
fi
