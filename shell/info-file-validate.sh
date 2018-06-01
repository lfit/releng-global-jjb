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
set -eu -o pipefail
set -x  # Enable trace

# Activate virtualenv, supressing shellcheck warning
# shellcheck source=/dev/null
. $WORKSPACE/venv/bin/activate
source "/tmp/v/info/bin/activate"
cat <<'EOF' > shell/info-yaml-requirements.txt
PyYAML
jsonschema
rfc3987
EOF
pip install -r shell/info-file-requirements.txt

MODIFIED_FILES=$(git diff HEAD^1 --name-only -- "**.y*ml")

for yaml_file in $MODIFIED_FILES; do
    python shell/yaml-verify-schema.py \
    -s shell/info-file-schema.yaml \
    -y $yaml_file
done
