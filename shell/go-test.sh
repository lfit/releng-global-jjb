#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2021 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

set -eux

echo "--> go-test.sh"
go version

#cd test/usecases/oruclosedlooprecovery/goversion/
cd "$GO_ROOT"

go test ./...

echo "--> go-test.sh ends"
