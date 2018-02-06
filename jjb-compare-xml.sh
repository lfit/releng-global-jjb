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

# This script tests jjb templates by comparing the result with expected output
# from global-jjb's origin/master branch.

test_dir=$(mktemp -d)
script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
expected_xml_dir="$(mktemp -d -t gjjb-XXXXXXXX)"

echo "Script Directory: $script_dir"
echo "Test Directory: $test_dir"
echo "Expected XML Directory: $expected_xml_dir"

git fetch origin
gittmp="$(mktemp -d)"
git worktree add --detach "$gittmp" origin/master
pushd "$gittmp" || exit
echo "Generating expected XML."
jenkins-jobs test --recursive -o "$expected_xml_dir" "$gittmp":.jjb-test > /dev/null 2>&1
popd || exit
rm -r "$gittmp"

echo "Generating test XML."
jenkins-jobs test --recursive -o "$test_dir" "$script_dir":.jjb-test

fail=false
for xml in "$test_dir"/*; do
    job=$(basename "$xml")
    if ! cmp "$expected_xml_dir/$job" "$xml"; then
        echo "Differences detected in $job"
        diff "$expected_xml_dir/$job" "$xml"
        fail=true
    fi
done

echo "Checking for double curly braces..."
mapfile -t xml_files < <(find "$test_dir" -type f)
for xml in "${xml_files[@]}"; do
    if grep '{{' "$xml"; then
        echo "ERROR: Double curly braces discovered in output XML."
        exit 1
    fi
done
echo "No double curly braces found."

# Cleanup
rm -rf "$test_dir" "$expected_xml_dir"

if $fail; then
    echo "WARN: Differences detected. Check above for jobs that have been changed."
    exit 0
fi
