#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> sigul-sign-dir.sh"

# Ensure we fail the job if any steps fail.
set -e -o pipefail

# Download the Dockerfile and the enterpoint to build the docker image.
wget -O "${WORKSPACE}/Dockerfile" "https://gist.githubusercontent.com/askb/"\
"2feb911f9d18ba039344e697fba87b7b/raw/e95f6180f4bca303396bcef5e1109fc703574c40/Dockerfile"
wget -O "${WORKSPACE}/sigul-sign.sh" "https://gist.githubusercontent.com/askb/"\
"eab6b21b3127e9da2c780673da23ec81/raw/84b0a54fe67f365bb0ed7a5fb43e20e0721eae37/sigul-sign.sh"

OS=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')
OS_RELEASE=$(facter lsbdistrelease | tr '[:upper:]' '[:lower:]')
if [[ "$OS_RELEASE" == "8" && "$OS" == 'centos' ]]; then
    # Setup the docker environment for jenkins user
    docker build -f ${WORKSPACE}/Dockerfile \
          --build-arg SIGN_DIR=${SIGN_DIR} \
          -t sigul-sign .

    docker volume create --driver local \
      --opt type=none \
      --opt device=/w/workspace \
      --opt o=bind \
      wrkspc_vol

    docker volume inspect wrkspc_vol

    docker run -e SIGUL_KEY="${SIGUL_KEY}" -e SIGUL_PASSWORD="${SIGUL_PASSWORD}" \
              -e SIGUL_CONFIG=${SIGUL_CONFIG} \
              -e SIGN_DIR=${SIGN_DIR} \
              -e WORKSPACE=${WORKSPACE} \
              --name sigul-sign \
	            --security-opt label:disable \
              --mount type=bind,source="/w/workspace",target="/w/workspace" \
              --mount type=bind,source="/home/jenkins",target="/home/jenkins" \
              -u root:root -w $(pwd) sigul-sign
else
    lftools sign sigul -m "${SIGN_MODE}" "${SIGN_DIR}"
fi
