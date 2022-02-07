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
# do not print commands, credentials should not be logged
set +x

# Add mvn executable into PATH
export PATH=$PATH:${MVN::-4}
SBOM_LOCATION="/tmp/spdx-sbom-generator-${SBOM_GENERATOR_VERSION}-linux-amd64.tar.gz"
echo "INFO: downloading spdx-sbom-generator version ${SBOM_GENERATOR_VERSION}"
URL="https://github.com/spdx/spdx-sbom-generator/releases/download/${SBOM_GENERATOR_VERSION}/\
spdx-sbom-generator-${SBOM_GENERATOR_VERSION}-linux-amd64.tar.gz"
# Exit if wget fails
if ! wget -nv "${URL}" -O "${SBOM_LOCATION}"; then
    echo "wget ${SBOM_GENERATOR_VERSION} failed"
    exit 1;
fi
tar -xvf "${SBOM_LOCATION}"
echo "INFO: running spdx-sbom-generator"
./spdx-sbom-generator "${SBOM_FLAGS:-}" -o "${WORKSPACE}"/m2repo
mv spdx-sbom-generator /tmp/
rm /tmp/spdx*
echo "---> sbom-generator.sh ends"
