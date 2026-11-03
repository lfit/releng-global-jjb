# shellcheck shell=bash
# SPDX-License-Identifier: EPL-1.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
#
# Shared helpers for the shell tests. Each test function runs in a subshell
# of its own, under 'set -eu -o pipefail' as the job scripts are, with HOME
# and PATH in a scratch directory. PATH holds the stubs the test writes, then
# links to only the tools listed in TOOLS, so that nothing else installed on
# the machine running the tests, such as a real uvx, can be found.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT
TOOLS="awk bash basename cat chmod cp dirname env grep head jq ln mkdir mktemp rm sed sh tr"
tests_run=0
tests_failed=0

# Write the executable stub $1 onto PATH, with the body read from stdin.
stub () {
    { echo '#!/usr/bin/env bash'; cat; } > "$SCRATCH/stubs/$1"
    chmod +x "$SCRATCH/stubs/$1"
}

fail () {
    echo "FAIL: $*" >&2
    exit 1
}

assert_eq () {
    [[ $1 == "$2" ]] || fail "${3:-value}: expected [$2], got [$1]"
}

assert_contains () {
    [[ $1 == *"$2"* ]] || fail "${3:-output} lacks [$2]: [$1]"
}

assert_not_contains () {
    [[ $1 != *"$2"* ]] || fail "${3:-output} has [$2]: [$1]"
}

# Run the test function $1 in a fresh scratch directory and report it.
run_test () {
    local name=$1 tool path rc
    SCRATCH="$(mktemp -d)"
    export SCRATCH
    mkdir -p "$SCRATCH/stubs" "$SCRATCH/tools" "$SCRATCH/home"
    for tool in $TOOLS; do
        if path="$(command -v "$tool")"; then
            ln -s "$path" "$SCRATCH/tools/$tool"
        fi
    done
    tests_run=$((tests_run + 1))
    (
        set -eu -o pipefail
        unset GLOBAL_JJB_VERSION LEGACY_CLI LFTOOLS_UV_PYTHON LFTOOLS_UV_VERSION \
            PIP_INDEX_URL PYTHONHOME PYTHONPATH UV_VERSION _lf_uvx_index _lf_uvx_spec
        export HOME="$SCRATCH/home" PATH="$SCRATCH/stubs:$SCRATCH/tools"
        # Bash 5.3 can expand ~ from the HOME it last passed to a command,
        # until it runs another: run one, so that ~ is the scratch HOME.
        env > /dev/null
        cd "$SCRATCH"
        "$name"
    ) > "$SCRATCH/output" 2>&1
    rc=$?
    if (( rc == 0 )); then
        echo "ok - $name"
    else
        echo "not ok - $name"
        sed 's/^/    /' "$SCRATCH/output"
        tests_failed=$((tests_failed + 1))
    fi
    rm -rf "$SCRATCH"
}

# Run every test_* function defined, then report and set the exit status.
run_all_tests () {
    local name
    for name in $(declare -F | awk '$3 ~ /^test_/ {print $3}'); do
        run_test "$name"
    done
    echo "$tests_run tests, $tests_failed failed"
    (( tests_failed == 0 ))
}
