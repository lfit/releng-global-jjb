#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2025 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> nexus-iq-go-api.sh"
# This script installs and runs cyclonedx-gomod to generate an SBOM xml
# for the Go project, then uses Nexus IQ REST API to analyze the Go project
# dependencies and publishes the result to Nexus IQ server.

# stop on error or unbound variable
set -eu
# do not print commands, credentials should not be logged
set +x

# shellcheck disable=SC1090
. ~/lf-env.sh

go version
go mod tidy

echo "INFO: running Nexus IQ scan (through REST API) on project $NEXUS_IQ_PROJECT_NAME and target: bom.xml"

go install github.com/CycloneDX/cyclonedx-gomod/cmd/cyclonedx-gomod@latest
PATH=$PATH:$(go env GOPATH)/bin
export PATH
cyclonedx-gomod mod -output bom.xml -output-version 1.5 # upgrade to latest SBOM schema version when Nexus IQ version >= 180

APP_ID=$(curl -u "${NEXUS_IQ_USER}:${NEXUS_IQ_PASSWORD}" \
    -X GET "https://nexus-iq.wl.linuxfoundation.org/api/v2/applications?publicId={$NEXUS_IQ_PROJECT_NAME}" \
    -s \
    | jq -r ".applications[].id")

curl -u "${NEXUS_IQ_USER}:${NEXUS_IQ_PASSWORD}" \
    -X POST -H "Content-Type: application/xml" --data "@bom.xml" \
    "https://nexus-iq.wl.linuxfoundation.org/api/v2/scan/applications/$APP_ID/sources/cyclonedx"

echo "---> nexus-iq-go-api.sh ends"
