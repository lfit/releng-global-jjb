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

# This script publishes packages (rpms/debs) or any file to Nexus hosted
# maven2 repository.
#
# $NEXUS_URL          :  Jenkins global variable should be defined.
# $REPO_ID            :  Provided by a job parameter.
# $UPLOAD_FILES_PATH  :  Provided by a job parameter.

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

TMP_FILE="$(mktemp)"

UPLOAD_FILES_PATH=${UPLOAD_FILES_PATH:-"$WORKSPACE/archives/upload_files"}
mkdir -p "$UPLOAD_FILES_PATH"

while IFS="" read -r file_name
do
    lftools deploy maven-file "$NEXUS_URL" "$REPO_ID" "$file_name" | tee "$TMP_FILE"
done < <(find "$UPLOAD_FILES_PATH" -type d -name "*")

# Store repo info to a file in archives
mkdir -p "$WORKSPACE/archives"
cp "$TMP_FILE" "$WORKSPACE/archives/deploy-maven-file.log"

# Cleanup
rm "$TMP_FILE"
