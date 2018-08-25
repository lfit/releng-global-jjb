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

# Checks for JJB documentation interest points and ensures they are documented.

mapfile -t jjb_files < <(find jjb -name "*.yaml")

undocumented_count=0
for file in "${jjb_files[@]}"; do
    mapfile -t docs_interests < <(grep -e '\- builder:' \
         -e '\- job-template:' \
         -e '\- parameter:' \
         -e '\- property:' \
         -e '\- publisher:' \
         -e '\- scm:' \
         -e '\- trigger:' \
         -e '\- wrapper:' \
         -A1 "$file" \
         | grep 'name: ' | awk -F': ' '{print $2}' | sort | uniq \
         | tr -d "'")

    for item in "${docs_interests[@]}"; do
        if ! grep -q "$item" "docs/${file//.yaml/.rst}"; then
            echo "$file:$item"
            let "undocumented_count++"
        fi
    done
done

if [ $undocumented_count -gt 0 ]; then
    echo "Number of undocumented items: $undocumented_count"
    exit 1
fi
