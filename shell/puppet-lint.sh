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
echo "---> puppet-lint.sh"

# Performs linting for Puppet code.
set -e -o pipefail

BINDIR=$(ruby -r rubygems -e 'puts Gem.bindir')
ARCHIVE_PUPPETLINT_DIR="$WORKSPACE/archives/puppet-lint"
mkdir -p "$ARCHIVE_PUPPETLINT_DIR"
cd "$WORKSPACE/$PUPPET_DIR"

gem install puppet-lint -v $PUPPET_LINT_VERSION
echo "---> Running puppet-lint"
"$BINDIR/puppet-lint" . | tee -a "$ARCHIVE_PUPPETLINT_DIR/puppet-lint.log"
