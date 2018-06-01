#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo '--> git-validate-info-yaml.sh'
# This script will make sure that the INFO.yaml file changes are kept
# isolated from other file changes.
# INFO.yaml file creation or moddifications should be kept in its own separate
# Gerrit.

# This script will fail if other file changes are also included in the same
# patch.

# Ensure we fail the job if any steps fail.
set -e -o pipefail
set +u

MODIFIED_FILES=$(git diff --name-only HEAD~1)

if [ "$MODIFIED_FILES" != "INFO.yaml" ]; then
    echo 'ERROR: Do not combine INFO.yaml file changes with other files. Please isolate INFO.yaml changes.'
    exit 1
fi
