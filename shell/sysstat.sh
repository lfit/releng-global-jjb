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
echo "---> sysstat.sh"
set +e  # DON'T fail build if script fails.

OS_FAMILY=$(ANSIBLE_STDOUT_CALLBACK=json ANSIBLE_LOAD_CALLBACK_PLUGINS=1 ansible
    \ all -i "localhost," --connection=local -m setup | jq -r \
    '.. | .ansible_os_family? | select(type != "null")' \
    | tr '[:upper:]' '[:lower:]')

case "${OS_FAMILY}" in
    debian)
        SYSSTAT_PATH="/var/log/sysstat"

        # Dont run the script when systat is not enabled by default
        if ! grep --quiet 'ENABLED="true"' "/etc/default/sysstat"; then
            exit 0
        fi
    ;;
    redhat)
        SYSSTAT_PATH="/var/log/sa"
    ;;
    *)
        # nothing to do
        exit 0
    ;;
esac

SAR_DIR="$WORKSPACE/archives/sar-reports"
mkdir -p "$SAR_DIR"
cp "$SYSSTAT_PATH/"* "$_"
# convert sar data to ascii format
while IFS="" read -r sarfilenum
do
    [ -f "$sarfilenum" ] && LC_TIME=POSIX sar -A -f "$sarfilenum" > "$SAR_DIR/sar${sarfilenum//[!0-9]/}"
done < <(find "$SYSSTAT_PATH" -name "sa[0-9]*" || true)

# DON'T fail build if script fails.
exit 0
