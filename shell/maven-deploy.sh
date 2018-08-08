#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
# Upload the snapshot files to a snapshot repo.
#
# Requires the existance of $WORKSPACE/m2repo and $WORKSPACE/m2repo-backup to
# compare if maven metadata files have changed. Unchanged files are then
# removed from $WORKSPACE/m2repo before uploading to the snapshot repo.
echo "---> maven-deploy.sh"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

m2repo_dir="$WORKSPACE/m2repo"
nexus_repo_url="$NEXUS_URL/content/repositories/$NEXUS_REPO"

lftools_activate

echo "-----> Remove metadata files that were not updated"
set +e  # Temporarily disable to run diff command.
mapfile -t metadata_files <<< "$(diff -s -r "$m2repo_dir" "$WORKSPACE/m2repo-backup" \
    | grep 'Files .* and .* are identical' \
    | awk '{print $2}')"
set -e  # Re-enable.

set +u  # $metadata_files could be unbound if project is new.
if [ -n "${metadata_files[*]}" ]; then
    for i in "${metadata_files[@]}"; do
        echo "Removing unmodified file $i"
        rm "$i"*
    done
fi
set -u  # Re-enable.

find "$m2repo_dir" -type d -empty -delete

echo "-----> Upload files to Nexus"
lftools deploy nexus -s "$nexus_repo_url" "$m2repo_dir"
