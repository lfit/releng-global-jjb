#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# Deploy maven artifacts to Nexus using cURL

# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
# Ensure we fail the job if any steps fail.
set -e -o pipefail
set +u

m2repo_dir="$WORKSPACE/m2repo"

# Remove metadata files that were not updated.
metadata_files=($(diff -s -r "$m2repo_dir" "$WORKSPACE/m2repo-backup" \
    | grep 'Files .* and .* are identical' | awk '{print $2}'))

for i in "${metadata_files[@]}"; do
    rm "$i"*
done

find "$m2repo_dir" -type d -empty -delete
