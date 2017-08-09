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

# This script tests jjb templates by comparing the result with expected output.

test_dir=$(mktemp -d)
script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
expected_xml_dir="$script_dir/jjb-test/expected-xml"

echo "Script Directory: $script_dir"
echo "Test Directory: $test_dir"

jenkins-jobs test --recursive -o "$test_dir" "$script_dir"

fail=false
for xml in "$test_dir"/*; do
    job=$(basename "$xml")
    if ! cmp "$expected_xml_dir/$job" "$xml"; then
        echo "Differences detected in $job"
        diff "$expected_xml_dir/$job" "$xml"
        fail=true
    fi
done

# Cleanup
rm -rf "$test_dir"

if $fail; then
    echo "Differences detected. Check above for jobs that have been changed."
    exit 1
fi
