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
echo "---> check-info-votes.sh"
set -u unset

venv=/tmp/pypi
PATH=$venv/bin

ref=$(echo "$GERRIT_REFSPEC" | awk -F"/" '{ print $4 }')

echo "Checking votes:"
lftools infofile check-votes INFO.yaml "$GERRIT_URL" "$ref" > gerrit_comment.txt
exit_status="$?"

if [[ "$exit_status" -ne 0 ]]; then
    echo "Vote not yet complete"
    cat gerrit_comment.txt
    exit "$exit_status"
else
    echo "Vote completed submitting review"
    ssh -p "$GERRIT_PORT" "$USER"@"$GERRIT_HOST" gerrit review "$GERRIT_PATCHSET_REVISION" --verified 1
    sleep 5
    ssh -p "$GERRIT_PORT" "$USER"@"$GERRIT_HOST" gerrit review "$GERRIT_PATCHSET_REVISION" --submit
fi
