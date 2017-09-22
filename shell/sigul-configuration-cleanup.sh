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
echo "---> sigul-configuration-cleanup.sh"

# Do NOT cause build failure if any of the rm calls fail
set +e

rm "${SIGUL_CONFIG}" "${SIGUL_PASSWORD}" "${SIGUL_PKI}"
# Sigul pki configuration is designed to live in ${HOME}/sigul
rm -rf "${HOME}/sigul*"

# DO NOT fail build if any of the above lines fail.
exit 0
