#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> license-check.sh"

# --- Inputs

# Space separated list of file patterns to scan for license headers.
file_patterns=("${FILE_PATTERNS:-*.go *.groovy *.java *.py *.sh}")
# Version of the License Header Checker to install
lhc_version="${LHC_VERSION:-0.2.0}"
# Comma-separated list of paths to exclude from license checking
license_exclude_paths="${LICENSE_EXCLUDE_PATHS:-}"
# Comma-separated list of allowed licenses
licenses_allowed="${LICENSES_ALLOWED:-Apache-2.0,EPL-1.0,MIT}"

if [[ "${SPDX_DISABLE}" == "true" ]]; then
    disable_spdx="--disable-spdx"
else
    disable_spdx=""
fi

# --- Script start

# DO NOT enable -u because LICENSE_EXCLUDE_PATHS is unbound.
# Ensure we fail the job if any steps fail.
set -eux -o pipefail

if hash lhc 2>/dev/null; then
    echo "License Header Checker is installed."
    lhc --version
else
    echo "License Header Checker is not installed. Installing..."
    mkdir "$WORKSPACE/bin"
    wget -nv -O "/tmp/lhc.tar.gz" "https://nexus.opendaylight.org/content/repositories/hosted_installers/org/linuxfoundation/lhc/${lhc_version}/lhc-${lhc_version}.tar.gz"
    tar -zxvf /tmp/lhc.tar.gz -C "$WORKSPACE/bin"
    chmod +x "$WORKSPACE/bin/lhc"
    export PATH="$WORKSPACE/bin:$PATH"
    lhc --version
fi


set -f  # Disable globbing for $file_patterns to pass '*'
# Purposely disable SC2068 for $file_patterns
# shellcheck disable=SC2068
lhc --license "$licenses_allowed" ${disable_spdx} \
    --exclude "$license_exclude_paths" \
    ${file_patterns[@]}
set +f
