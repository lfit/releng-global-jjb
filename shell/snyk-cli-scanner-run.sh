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

# Add mvn to PATH so that the Snyk CLI can use it
export PATH=$PATH:"$M2_HOME"/bin
# Download and install the latest Snyk scanner
echo "Installing Snyk (latest)..."
curl https://static.snyk.io/cli/latest/snyk-linux -o snyk
sudo chmod +x ./snyk
sudo mv ./snyk /usr/local/bin/
echo "Verifying Snyk version..."
snyk --version
echo "Authenticate with SNYK_TOKEN..."
snyk auth "$SNYK_CLI"
echo "Running Snyk CLI..."
snyk test --json --severity-threshold=low --org="$SNYK_ORG"
snyk monitor --severity-threshold=low --org="$SNYK_ORG"
