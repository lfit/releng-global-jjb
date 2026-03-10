#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2026 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
# Sign a git tag using sigul inside a CentOS 7 Docker container.
# This script is the ENTRYPOINT for docker/Dockerfile.sigul-tag.
#
# Required environment variables:
#   SIGUL_CONFIG  - path to sigul client configuration
#   SIGUL_PASSWORD - path to file containing sigul password
#   SIGUL_KEY     - sigul signing key name
#   GIT_TAG       - git tag to sign

echo "---> sigul-sign-git-tag.sh (Docker)"
set -eu -o pipefail

if [[ -z "${GIT_TAG:-}" ]]; then
    echo "ERROR: GIT_TAG is not set"
    exit 1
fi

if [[ -z "${SIGUL_KEY:-}" ]]; then
    echo "ERROR: SIGUL_KEY is not set"
    exit 1
fi

if [[ -z "${SIGUL_CONFIG:-}" ]]; then
    echo "ERROR: SIGUL_CONFIG is not set"
    exit 1
fi

if [[ -z "${SIGUL_PASSWORD:-}" ]]; then
    echo "ERROR: SIGUL_PASSWORD is not set"
    exit 1
fi

SIGUL_MAX_RETRIES="${SIGUL_MAX_RETRIES:-5}"
SIGUL_RETRY_DELAY="${SIGUL_RETRY_DELAY:-15}"

echo "INFO: Signing git tag '$GIT_TAG' with key '$SIGUL_KEY'"
echo "INFO: Max retries: $SIGUL_MAX_RETRIES, delay: ${SIGUL_RETRY_DELAY}s"

for attempt in $(seq 1 "$SIGUL_MAX_RETRIES"); do
    if sigul --batch -c "$SIGUL_CONFIG" sign-git-tag \
            "$SIGUL_KEY" "$GIT_TAG" < "$SIGUL_PASSWORD"; then
        echo "INFO: Successfully signed git tag '$GIT_TAG' (attempt $attempt)"
        exit 0
    fi
    if [[ $attempt -lt $SIGUL_MAX_RETRIES ]]; then
        echo "WARN: sigul sign-git-tag failed (attempt $attempt/$SIGUL_MAX_RETRIES), retrying in ${SIGUL_RETRY_DELAY}s..."
        sleep "$SIGUL_RETRY_DELAY"
    fi
done

echo "ERROR: sigul sign-git-tag failed after $SIGUL_MAX_RETRIES attempts"
exit 1
