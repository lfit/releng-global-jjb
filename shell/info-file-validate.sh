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
PROJECT="${PROJECT:-None}"

# shellcheck disable=SC1090
source ~/lf-env.sh
lf_activate_venv zipp==1.1.0 PyYAML jsonschema rfc3987 yamllint yq
pip freeze

# Download info-schema.yaml and yaml-verfy-schema.py
wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/info-schema.yaml \
https://raw.githubusercontent.com/lfit/releng-global-jjb/master/yaml-verify-schema.py

yamllint INFO.yaml

python yaml-verify-schema.py \
    -s info-schema.yaml \
    -y INFO.yaml


# Verfiy that there is only one repository and that it matches $PROJECT
REPO_LIST="$(yq -r '.repositories[]' INFO.yaml)"

while IFS= read -r project; do
    if [[ "$project" == "$PROJECT" ]]; then
        echo "$project is valid"
    else
        echo "ERROR: $project is invalid"
        echo "INFO.yaml file may only list one repository"
        echo "Repository must match $PROJECT"
        exit 1
    fi
done <<< "$REPO_LIST"
