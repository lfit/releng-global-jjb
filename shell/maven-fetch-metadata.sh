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

# Uses wget to fetch a project's maven-metadata.xml files from a Maven repository.

# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
# Ensure we fail the job if any steps fail.
set -e -o pipefail
set +u

project=$(xmlstarlet sel -N "x=http://maven.apache.org/POM/4.0.0" \
    -t -v "//x:project/x:groupId" pom.xml)
project_path="${project//.//}"

mkdir -p "$WORKSPACE/m2repo/$project_path"
pushd "$WORKSPACE/m2repo/$project_path"

wget -nv --recursive \
     --accept maven-metadata.xml \
     -R "index.html*" \
     --execute robots=off \
     --no-parent \
     --no-host-directories \
     --cut-dirs="$NEXUS_CUT_DIRS" \
     "$NEXUS_URL/content/repositories/$NEXUS_REPO/$project_path/"

popd
