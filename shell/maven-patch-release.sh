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

# This script removes the -SNAPSHOT from a project to prepare it for release.

PATCH_DIR="$WORKSPACE/archives/patches"
mkdir -p "$PATCH_DIR"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

echo "$PROJECT" "$(git rev-parse --verify HEAD)" | tee -a "$PATCH_DIR/taglist.log"

# Strip -SNAPSHOT from version to prepare release.
find . -name "*.xml" -print0 | xargs -0 sed -i 's/-SNAPSHOT//g'

git commit -am "Release $PROJECT"
git format-patch --stdout "origin/$GERRIT_BRANCH" > "$PATCH_DIR/${PROJECT//\//-}.patch"
git bundle create "$PATCH_DIR/${PROJECT//\//-}.bundle" "origin/${GERRIT_BRANCH}..HEAD"
