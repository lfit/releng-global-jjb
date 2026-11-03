#!/usr/bin/env bash
# SPDX-License-Identifier: EPL-1.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
#
# Run every tests/shell/test-*.sh, and fail when any of them fails.

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
rc=0
for test_file in ./test-*.sh; do
    echo "# ${test_file#./}"
    bash "$test_file" || rc=1
done
exit "$rc"
