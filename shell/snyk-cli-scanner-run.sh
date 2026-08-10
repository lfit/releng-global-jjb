#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2023 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> snyk-cli-scanner-run.sh"
# shellcheck disable=SC1090
source ~/lf-env.sh

# Install Snyk CLI dependencies for Python
if [[ "$JOB_NAME" =~ "python" ]]; then
    # Install Snyk CLI dependencies for Python based projects
    lf-activate-venv flask flask-api flask-cors pg8000 pandas
else
    lf-activate-venv
fi
# Add mvn to PATH so that the Snyk CLI can use it
export PATH=$PATH:"$M2_HOME"/bin

# Fail the build on real errors (bad download, failed auth) from here on.
# Snyk *findings* stay advisory and are handled explicitly below.
set -eo pipefail
# Download and install a pinned Snyk scanner, verifying its checksum
SNYK_VERSION="${SNYK_VERSION:-v1.1306.3}"
echo "Installing Snyk ${SNYK_VERSION}..."
curl -fsSLO "https://static.snyk.io/cli/${SNYK_VERSION}/snyk-linux"
curl -fsSLO "https://static.snyk.io/cli/${SNYK_VERSION}/snyk-linux.sha256"
sha256sum -c snyk-linux.sha256
sudo install -m 0755 snyk-linux /usr/local/bin/snyk
echo "Verifying Snyk version..."
snyk --version
echo "Authenticate with SNYK_TOKEN..."
snyk auth "$SNYK_CLI"
# Snyk exit codes: 0 = clean, 1 = vulnerabilities found, >=2 = the scan failed.
# ponytail: findings are deliberately advisory, matching long-standing behaviour.
# To gate on findings instead, drop the "rc -ge 2" test and return rc directly.
run_snyk() {
    local rc=0
    "$@" || rc="$?"
    if [[ "$rc" -ge 2 ]]; then
        echo "ERROR: '$*' exited $rc (scan failure, not a vulnerability finding)"
        return "$rc"
    fi
    return 0
}

echo "Running Snyk CLI..."
if [[ "$JOB_NAME" =~ "docker" ]]; then
    run_snyk snyk container test "$SNYK_CLI_OPTIONS" \
        "$CONTAINER_PULL_REGISTRY/$DOCKER_NAME:$DOCKER_IMAGE_TAG" --org="$SNYK_ORG"
    run_snyk snyk container monitor "$SNYK_CLI_OPTIONS" \
        "$CONTAINER_PULL_REGISTRY/$DOCKER_NAME:$DOCKER_IMAGE_TAG" --org="$SNYK_ORG"
else
    run_snyk snyk test --json --severity-threshold=low "$SNYK_CLI_OPTIONS" --org="$SNYK_ORG"
    run_snyk snyk monitor --severity-threshold=low "$SNYK_CLI_OPTIONS" --org="$SNYK_ORG"
fi
