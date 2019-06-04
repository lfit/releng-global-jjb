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
echo '--> info-file-validate.sh'
set -e -o pipefail
set -x  # Enable trace

virtualenv --quiet "/tmp/v/info"
# shellcheck source=/tmp/v/info/bin/activate disable=SC1091
source "/tmp/v/info/bin/activate"
pip install PyYAML jsonschema rfc3987 yamllint

# Cloning global-jjb to get access to needed scripts
git clone https://github.com/lfit/releng-global-jjb.git

yamllint INFO.yaml

python releng-global-jjb/yaml-verify-schema.py \
    -s releng-global-jjb/info-schema \
    -y INFO.yaml

rm -rf releng-global-jjb
