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

# Script to install lftools via a version passed in via lf-infra-parameters
#
# Required parameters:
#
#     LFTOOLS_VERSION: Passed in via lf-infra-parameters configuration. Can be
#                      set to a strict version number like '1.2.3' or using
#                      PEP-440 definitions.
#
#                      Examples:
#                          <1.0.0
#                          >=1.0.0,<2.0.0
#
# By default a released version of lftools should always be used.
# The purpose of the 2 variables below is so that lftools devs can test
# unreleased versions of lftools. There are 2 methods to install a dev version
# of lftools:
#
#     1) gerrit patch: Used to test a patch that has not yet been merged.
#                      To do this set something like this:
#                          LFTOOLS_MODE=gerrit
#                          LFTOOLS_REFSPEC=refs/changes/96/5296/7
#
#     2) git branch: Used to install an lftools version from a specific branch.
#                    To use this set the variables as follows:
#                          LFTOOLS_MODE=git
#                          LFTOOLS_REFSPEC=master
#
#     3) release : The intended use case and default setting.
#                  Set LFTOOLS_MODE=release, in this case LFTOOLS_REFSPEC is unused.

LFTOOLS_MODE=release  # release | git | gerrit
LFTOOLS_REFSPEC=master

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

virtualenv --quiet "/tmp/v/lftools"
# shellcheck source=/tmp/v/lftools/bin/activate disable=SC1091
source "/tmp/v/lftools/bin/activate"
pip install --quiet --upgrade "pip==9.0.3" setuptools

case $LFTOOLS_MODE in
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
        if [[ $LFTOOLS_VERSION =~ ^[0-9] ]]; then
            LFTOOLS_VERSION="==$LFTOOLS_VERSION"
        fi

        pip install --quiet --upgrade "lftools${LFTOOLS_VERSION}"
        ;;
esac

lftools --version

# pipdeptree prints out a lot of information because lftools pulls in many
# dependencies. Let's only print it if we want to debug.
# echo "----> Pip Dependency Tree"
# pip install --quiet --upgrade pipdeptree
# pipdeptree
