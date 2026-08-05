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

# Git ref of lfit/releng-global-jjb used for helper files fetched at
# runtime. Defaults to master to preserve existing behaviour; set this to
# the tag the submodule is pinned to so a job cannot pick up a helper
# newer than the global-jjb it was generated from.
GLOBAL_JJB_VERSION="${GLOBAL_JJB_VERSION:-master}"
GLOBAL_JJB_URL="https://raw.githubusercontent.com/lfit/releng-global-jjb/${GLOBAL_JJB_VERSION}"
PROJECT="${PROJECT:-None}"

# shellcheck disable=SC1090
source ~/lf-env.sh
lf-activate-venv zipp==1.1.0 PyYAML jsonschema rfc3987 yamllint yq
pip freeze

# Download info-schema.yaml and yaml-verfy-schema.py
wget -q "${GLOBAL_JJB_URL}/schema/info-schema.yaml" \
"${GLOBAL_JJB_URL}/yaml-verify-schema.py"

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
