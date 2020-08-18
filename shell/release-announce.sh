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
echo "---> release-announce.sh"

if [[ $PROJECT_SLUG != "" ]]; then
    PROJECT="$PROJECT_SLUG"
else
    PROJECT="${GERRIT_PROJECT#releng/}"  # For releng projects strip the prefix
fi

TAG_NAME="${GERRIT_REFNAME#refs/tags/}"

set -eux -o pipefail

mail_opts=()
mail_opts+=("-r" "LF Releng <lf-releng@lists.linuxfoundation.org>")
mail_opts+=("-s" "$PROJECT $TAG_NAME released")
mail_opts+=("lf-releng@lists.linuxfoundation.org")

mail "${mail_opts[@]}" << EOF
Hi Everyone,

$PROJECT $TAG_NAME is released. Thanks to everyone who contributed
to this release. Release notes are available online at:

https://docs.releng.linuxfoundation.org/projects/$PROJECT/en/latest/release-notes.html#${TAG_NAME}

Cheers,
LF Releng
EOF
