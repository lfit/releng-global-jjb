#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2020 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> nexus-iq-python-cli.sh"
# This script downloads the specified version of the nexus-iq-cli jar, uses it
# to analyze the Python project dependencies from the specified requirements file,
# then publishes the result to an LF server using the specified credentials.

# stop on error or unbound variable
set -eu
# do not print commands, credentials should not be logged
set +x

# Use pyenv to select the latest python version
if [[ -d "/opt/pyenv" ]]; then
    echo "Setup pyenv:"
    export PYENV_ROOT="/opt/pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    pyenv versions
    if command -v pyenv 1>/dev/null 2>&1; then
        eval "$(pyenv init - --no-rehash)"
        # Choose the latest numeric Python version from installed list
        version=$(pyenv versions --bare | sed '/^[^0-9]/d' | sort -V | tail -n 1)
        pyenv local "${version}"
    fi
fi

CLI_LOCATION="/tmp/nexus-iq-cli-${NEXUS_IQ_CLI_VERSION}.jar"
echo "INFO: downloading nexus-iq-cli version $NEXUS_IQ_CLI_VERSION"
wget -nv "https://download.sonatype.com/clm/scanner/nexus-iq-cli-${NEXUS_IQ_CLI_VERSION}.jar" -O "${CLI_LOCATION}"
echo "-a" > cli-auth.txt
echo "${NEXUS_IQ_USER}:${NEXUS_IQ_PASSWORD}" >> cli-auth.txt
if [ -z "${NEXUS_TARGET_BUILD}" ]; then
    echo "WARN: NEXUS_TARGET_BUILD has not been set"
fi
echo "INFO: running nexus-iq-cli on project $NEXUS_IQ_PROJECT_NAME and target: ${NEXUS_TARGET_BUILD}"
echo "Downloading Python dependencies into target directory"
python3 -m pip download -r requirements.txt -d "${NEXUS_TARGET_BUILD}"
# result.json is a mystery
# Do NOT double-quote ${NEXUS_TARGET_BUILD} below; causes breakage
# shellcheck disable=SC2086
java -jar "${CLI_LOCATION}" @cli-auth.txt \
    -s https://nexus-iq.wl.linuxfoundation.org -i "${NEXUS_IQ_PROJECT_NAME}" \
    -t build -r result.json ${NEXUS_TARGET_BUILD}
rm cli-auth.txt
rm "${CLI_LOCATION}"

echo "---> nexus-iq-python-cli.sh ends"
