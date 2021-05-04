#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2016 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> gpg-verify-git-signature.sh"

if git log --show-signature -1 | grep -E -q 'gpg: Signature made.*key ID'; then
     echo "Git commit is GPG signed."
else
     echo "WARNING: GPG signature missing for the commit."
fi

# Do NOT fail the job for unsigned commits
exit 0
