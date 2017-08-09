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
echo "---> lftools-install.sh"

# By default we always want to use a released version of lftools.
# The purpose of the 2 variables below is so that lftools devs can test
# unreleased versions of lftools. There are 2 methods to install a dev version
# of lftools:
#
#     1) gerrit patch: Used to test a patch that has not yet been merged.
#                      To do this set something like this:
#                          LFTOOLS_VERSION=gerrit
#                          LFTOOLS_REFSPEC=refs/changes/96/5296/7
#
#     2) git branch: Used to install an lftools version from a specific branch.
#                    To use this set the variables as follows:
#                          LFTOOLS_VERSION=git
#                          LFTOOLS_REFSPEC=master
LFTOOLS_VERSION=release  # release | git | gerrit
LFTOOLS_REFSPEC=master

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

virtualenv --quiet "/tmp/v/lftools"
# shellcheck source=/tmp/v/lftools/bin/activate disable=SC1091
source "/tmp/v/lftools/bin/activate"
pip install --quiet --upgrade pip

case $LFTOOLS_VERSION in
    gerrit)
        git clone https://gerrit.linuxfoundation.org/infra/releng/lftools.git /tmp/lftools
        pushd /tmp/lftools
        git fetch origin "$LFTOOLS_REFSPEC"
        git checkout FETCH_HEAD
        pip install --quiet --upgrade -r requirements.txt
        pip install --quiet --upgrade -e .
        popd
        ;;

    git)
        pip install --quiet --upgrade git+https://gerrit.linuxfoundation.org/infra/releng/lftools.git@"$BRANCH"
        ;;

    release)
        pip install --quiet --upgrade "lftools<1.0.0"
        ;;
esac

# pipdeptree prints out a lot of information because lftools pulls in many
# dependencies. Let's only print it if we want to debug.
# echo "----> Pip Dependency Tree"
# pip install --quiet --upgrade pipdeptree
# pipdeptree
