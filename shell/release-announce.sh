#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

PROJECT="${GERRIT_PROJECT#releng/}"  # For releng projects strip the prefix
TAG_NAME="${GERRIT_REFNAME#refs/tags/}"

set -eux -o pipefail

mail_opts=()
mail_opts+=("-r" "lf-releng@lists.linuxfoundation.org")
mail_opts+=("-s" "$PROJECT $TAG_NAME released")
mail_opts+=("lf-releng@lists.linuxfoundation.org")

mail_body="Hi Everyone,

$PROJECT $TAG_NAME is released. Thanks to everyone who contributed
to this release. Release notes are available online at:

https://docs.releng.linuxfoundation.org/projects/$PROJECT/en/latest/release-notes.html#${TAG_NAME}

Cheers,
LF Releng
"
eval echo \""$mail_body"\" | mail "${mail_opts[@]}"
