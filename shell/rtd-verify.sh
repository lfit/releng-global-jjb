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
echo "---> rtd-verify.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

echo "---> Fetching project"
if [ "$GERRIT_PROJECT" != "$PROJECT" ]; then
    cd "docs/submodules/$GERRIT_PROJECT"
fi

git fetch origin "$GERRIT_REFSPEC" && git checkout FETCH_HEAD

echo "---> Generating docs"
tox -edocs

echo "---> Archiving generated docs"
mkdir -p "$WORKSPACE/archives"
mv "$DOC_DIR" archives/
