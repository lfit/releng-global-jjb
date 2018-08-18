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
echo "---> sigul-configuration.sh"

# Ensure we fail the job if any steps fail.
set -e -o pipefail

# Sigul pki configuration is designed to live in ${HOME}/sigul
cd "${HOME}"

# decrypt the sigul-pki tarball and extract it
gpg --batch --passphrase-file "${SIGUL_PASSWORD}" -o sigul.tar.xz \
    -d "${SIGUL_PKI}"
tar Jxf sigul.tar.xz

# Any future use of $SIGUL_PASSWORD needs to have it null terminated
sed -i 's/$/\x0/' "${SIGUL_PASSWORD}"
