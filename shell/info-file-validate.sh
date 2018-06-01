#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
set -xe

# Activate virtualenv, supressing shellcheck warning
# shellcheck source=/dev/null
. $WORKSPACE/venv/bin/activate
pip install -r shell/info-file-requirements.txt

MODIFIED_FILES=$(git diff HEAD^1 --name-only -- "**.y*ml")

for yaml_file in $MODIFIED_FILES; do
    python shell/yaml-verify-schema.py \
    -s shell/info-file-schema.yaml \
    -y $yaml_file
done
