#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> lftools-sysstat.sh"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

OS=$(facter operatingsystem)
case "$OS" in
    Ubuntu)
        SYSSTAT_PATH="/var/log/sysstat"
    ;;
    CentOS|RedHat)
        SYSSTAT_PATH="/var/log/sa"
    ;;
    *)
        # nothing to do
    ;;
esac

mkdir -p archives/sar-reports
cp "$SYSSTAT_PATH/*" $_
# convert sar data to ascii format
while IFS="" read -r s
do
    [ -f "$s" ] && LC_TIME=POSIX sar -A -f "$s" > archives/sar-reports/sar${s//[!0-9]/}
done < <(find "$SYSSTAT_PATH" -name "sa[0-9]*" || true)

# DO NOT fail the build if script fails
exit 0
