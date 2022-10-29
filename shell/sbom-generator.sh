#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2022 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> sbom-generator.sh"
# This script downloads the specified version of SBOM generator and triggers a run.

# stop on error or unbound variable
set -eu

# Add mvn executable into PATH
export PATH=${MVN::-4}:$PATH
SBOM_LOCATION="/tmp/spdx-sbom-generator-${SBOM_GENERATOR_VERSION}-linux-amd64.tar.gz"
echo "INFO: downloading spdx-sbom-generator version ${SBOM_GENERATOR_VERSION}"
URL="https://github.com/spdx/spdx-sbom-generator/releases/download/${SBOM_GENERATOR_VERSION}/\
spdx-sbom-generator-${SBOM_GENERATOR_VERSION}-linux-amd64.tar.gz"
# Exit if wget fails
if ! wget -nv "${URL}" -O "${SBOM_LOCATION}"; then
    echo "wget ${SBOM_GENERATOR_VERSION} failed"
    exit 1;
fi
# Extract SBOM bin in SBOM_PATH
# This is a workaround until the --path flag works
# https://github.com/opensbom-generator/spdx-sbom-generator/issues/227
tar -xzf "${SBOM_LOCATION}" -C ${SBOM_PATH}
echo "INFO: running spdx-sbom-generator"
cd ${SBOM_PATH}
./spdx-sbom-generator "${SBOM_FLAGS:-}" -g "$GLOBAL_SETTINGS_FILE" -o "${WORKSPACE}"/archives

# Maven artifacts
if [[ "$JOB_NAME" =~ "maven" ]]; then
    mvn_group_id=$("$MVN" help:evaluate -Dexpression=project.groupId -q -DforceStdout \
                    -s "$SETTINGS_FILE" -gs "$GLOBAL_SETTINGS_FILE")
    group_id_path="${mvn_group_id//.//}"
    release_version=$("$MVN" help:evaluate -Dexpression=project.version -q -DforceStdout \
                      -s "$SETTINGS_FILE" -gs "$GLOBAL_SETTINGS_FILE")

    mv "${WORKSPACE}/archives/bom-Java-Maven.spdx" \
        "${WORKSPACE}/archives/${PROJECT##*/}-sbom-${release_version}.spdx"
    cp "${WORKSPACE}/archives/${PROJECT##*/}-sbom-${release_version}.spdx" \
        "${WORKSPACE}/m2repo/${group_id_path}/${PROJECT##*/}-sbom-${release_version}.spdx"
fi

mv spdx-sbom-generator /tmp/
rm /tmp/spdx*
echo "---> sbom-generator.sh ends"
