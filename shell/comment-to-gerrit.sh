#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> comment-to-gerrit.sh"
set -xe -o pipefail

if [[ -e gerrit_comment.txt ]] ; then
    echo
    echo "posting review comment to gerrit..."
    echo
    cat gerrit_comment.txt
    echo
    ssh -p 29418 "$GERRIT_HOST" \
        "gerrit review -p $GERRIT_PROJECT \
        -m '$(cat gerrit_comment.txt)' \
        $GERRIT_PATCHSET_REVISION \
        --notify NONE"
fi
