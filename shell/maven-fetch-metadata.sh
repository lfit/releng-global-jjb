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

# Uses wget to fetch a project's maven-metadata.xml files from a Maven repository.

# Ensure we fail the job if any steps fail.
set -xeu -o pipefail

project=$(xmlstarlet sel \
    -N "x=http://maven.apache.org/POM/4.0.0" -t \
    --if "/x:project/x:groupId" \
      -v "/x:project/x:groupId" \
    --elif "/x:project/x:parent/x:groupId" \
      -v "/x:project/x:parent/x:groupId" \
    --else -o "" pom.xml)
project_path="${project//.//}"

mkdir -p "$WORKSPACE/m2repo/$project_path"
pushd "$WORKSPACE/m2repo/$project_path"
    # Temporarily disable failing for wget
    # If 404 happens we don't care because it might be a new project.
    set +e
    wget -nv --recursive \
         --accept maven-metadata.xml \
         -R "index.html*" \
         --execute robots=off \
         --no-parent \
         --no-host-directories \
         --cut-dirs="$NEXUS_CUT_DIRS" \
         "$NEXUS_URL/content/repositories/$NEXUS_REPO/$project_path/"
    set -e  # Re-enable.
popd

# Backup metadata - Used later to find metadata files that have not been modified
mkdir -p "$WORKSPACE/m2repo-backup"
cp -a "$WORKSPACE/m2repo/"* "$WORKSPACE/m2repo-backup"
