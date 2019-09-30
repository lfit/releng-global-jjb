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

set -eu -o pipefail

echo "---> Fetching project"
if [[ $GERRIT_PROJECT != "$PROJECT" ]]; then
    # Only test projects that are a submodule of docs
    if ! git submodule | grep "$GERRIT_PROJECT"; then
        echo "WARN: Project is not a submodule of docs. This likely means " \
            "the project is not participating in the monolithic docs build " \
            "and should have their own verify job. Quitting job run..."
        exit 0
    fi
    cd "docs/submodules/$GERRIT_PROJECT"
fi

git fetch origin "$GERRIT_REFSPEC" && git checkout FETCH_HEAD
git submodule update

# I Don't understand need for this code. Both 'builder-rtd-verify-master' &
# 'lf-infra-lftools-rtd-verify-any' pass without lftools installed. Are we
# validating the ability to install lftools from the repo? We would NOT want
# to install lftools from a source repo into a shared venv. I no-one objects,
# I will remove this code.
#if [[ $JOB_NAME == "lf-infra-lftools-rtd-verify-any" ]]; then
#    # Install patchset lftools
#    python3 -m pip install --user -e .
#fi

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-venv-create tox tox-pyenv
lf-venv-activate

echo "---> Generating docs"
cd "$WORKSPACE"
tox -edocs

echo "---> Archiving generated docs"
mkdir -p "$WORKSPACE/archives"
mv "$DOC_DIR" archives/

