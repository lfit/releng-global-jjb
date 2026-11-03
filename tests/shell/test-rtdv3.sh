#!/usr/bin/env bash
# SPDX-License-Identifier: EPL-1.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
#
# Tests for shell/rtdv3.sh against a fake lftools-uv, chiefly that a failed
# Read the Docs query stops the job instead of reading as "not found".

# shellcheck source=tests/shell/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

PROJECT_404="Error: Project 'onap-cps' not found"
HTTP_401="Error: Project 'onap-cps' failed with HTTP 401: Invalid token."

# Point ~/lf-env.sh at a fake lftools-uv, and set a merge job's environment
# for project onap-cps, a subproject of onap.
rtd_setup () {
    mkdir -p "$SCRATCH/rtd"
    cat > ~/lf-env.sh <<'SH'
lftools-uv () { "$SCRATCH/fake-lftools-uv" "$@"; }
SH
    cat > "$SCRATCH/fake-lftools-uv" <<'FAKE'
#!/usr/bin/env bash
# Answer 'rtd COMMAND' from rtd/COMMAND.N.*, for its Nth call, or else from
# rtd/COMMAND.*: the .out, .err and .rc files give stdout, stderr and status.
if [[ $1 == --version ]]; then
    exit 0
fi
echo "lftools-uv $*" >> "$SCRATCH/calls"
n="$(grep -c "^lftools-uv rtd $2 " "$SCRATCH/calls")"
base="$SCRATCH/rtd/$2"
if [[ -e $base.$n.rc ]]; then
    base="$base.$n"
fi
if [[ ! -e $base.rc ]]; then
    echo "fake lftools-uv: no answer for: $*" >&2
    exit 99
fi
if [[ -e $base.out ]]; then
    cat "$base.out"
fi
if [[ -e $base.err ]]; then
    cat "$base.err" >&2
fi
exit "$(cat "$base.rc")"
FAKE
    chmod +x "$SCRATCH/fake-lftools-uv"
    stub sleep <<< 'exit 0'
    export JOB_NAME=rtdv3-global-merge-master GERRIT_URL=https://gerrit.onap.org/r
    export PROJECT=cps SILO=production MASTER_RTD_PROJECT=doc
    export DEFAULT_VERSION=latest GERRIT_BRANCH=master
}

# answer COMMAND[.N] STATUS [STDOUT [STDERR]]
answer () {
    echo "$2" > "$SCRATCH/rtd/$1.rc"
    if [[ -n ${3:-} ]]; then
        echo "$3" > "$SCRATCH/rtd/$1.out"
    fi
    if [[ -n ${4:-} ]]; then
        echo "$4" > "$SCRATCH/rtd/$1.err"
    fi
}

# A merge on master of an existing project, whose build succeeds.
answer_happy_merge () {
    answer project-details 0 '{"slug": "onap-cps", "default_version": "latest"}'
    answer subproject-list 0 '{"project": "onap", "subprojects": ["onap-a", "onap-cps"]}'
    answer project-build-trigger 0 '{"build": {"id": 42}, "triggered": true}'
    answer project-build-details 0 '{"id": 42, "success": true}'
    answer project-create 0 '{}'
    answer subproject-create 0 '{}'
    answer project-update 0 '{}'
    answer project-version-update 0 '{}'
}

# Run rtdv3.sh, keeping its status in $rc and its output in ./out.
run_rtdv3 () {
    rc=0
    bash "$REPO_ROOT/shell/rtdv3.sh" > out 2>&1 || rc=$?
}

calls () {
    cat "$SCRATCH/calls" 2> /dev/null || true
}

test_verify_reports_missing_project () {
    rtd_setup
    export JOB_NAME=rtdv3-global-verify-master
    answer project-details 1 "" "$PROJECT_404"
    run_rtdv3
    assert_eq "$rc" 0 "status"
    assert_contains "$(cat out)" "Project not found, merge will create project"
}

test_verify_reports_missing_project_with_detail () {
    rtd_setup
    export JOB_NAME=rtdv3-global-verify-master
    answer project-details 1 "" "$PROJECT_404: Not found."
    run_rtdv3
    assert_eq "$rc" 0 "status"
    assert_contains "$(cat out)" "Project not found, merge will create project"
}

test_verify_fails_when_read_the_docs_rejects_the_token () {
    rtd_setup
    export JOB_NAME=rtdv3-global-verify-master
    answer project-details 1 "" "$HTTP_401"
    run_rtdv3
    assert_eq "$rc" 1 "status"
    assert_contains "$(cat out)" "$HTTP_401"
    assert_not_contains "$(cat out)" "Verify job completed"
}

test_verify_fails_on_another_resource_not_found () {
    rtd_setup
    export JOB_NAME=rtdv3-global-verify-master
    answer project-details 1 "" "Error: Version 'latest' of project 'onap-cps' not found: x"
    run_rtdv3
    assert_eq "$rc" 1 "status"
}

test_verify_fails_on_not_found_with_another_status () {
    rtd_setup
    export JOB_NAME=rtdv3-global-verify-master
    answer project-details 2 "" "$PROJECT_404"
    run_rtdv3
    assert_eq "$rc" 1 "status"
}

test_merge_on_master_builds_latest () {
    rtd_setup
    answer_happy_merge
    run_rtdv3
    assert_eq "$rc" 0 "status"
    assert_contains "$(calls)" "lftools-uv rtd project-build-trigger onap-cps latest --json"
    assert_not_contains "$(calls)" "create"
    assert_contains "$(cat out)" "read the docs build completed with status: true"
}

test_merge_creates_missing_project () {
    rtd_setup
    answer_happy_merge
    answer project-details.1 1 "" "$PROJECT_404"
    run_rtdv3
    assert_eq "$rc" 0 "status"
    assert_eq "$(grep -c 'rtd project-create onap-cps' calls)" 1 "project-create calls"
}

test_merge_does_not_create_project_on_outage () {
    rtd_setup
    answer_happy_merge
    answer project-details 1 "" "Error: Project 'onap-cps' failed with HTTP 503"
    run_rtdv3
    assert_eq "$rc" 1 "status"
    assert_not_contains "$(calls)" "project-create"
}

test_merge_fails_when_subproject_list_fails () {
    rtd_setup
    answer_happy_merge
    answer subproject-list 1 "" "Error: Subproject list for project 'onap' failed with HTTP 500"
    run_rtdv3
    assert_eq "$rc" 1 "status"
    assert_not_contains "$(calls)" "subproject-create"
}

test_merge_fails_on_malformed_subproject_list () {
    rtd_setup
    answer_happy_merge
    answer subproject-list 0 '{"detail": "unexpected"}'
    run_rtdv3
    assert_eq "$rc" 1 "status"
    assert_not_contains "$(calls)" "subproject-create"
}

test_merge_creates_missing_subproject () {
    rtd_setup
    answer_happy_merge
    answer subproject-list 0 '{"project": "onap", "subprojects": ["onap-a"]}'
    run_rtdv3
    assert_eq "$rc" 0 "status"
    assert_contains "$(calls)" "lftools-uv rtd subproject-create onap onap-cps"
}

test_merge_fails_when_build_fails () {
    rtd_setup
    answer_happy_merge
    answer project-build-details 0 '{"id": 42, "success": false}'
    run_rtdv3
    assert_eq "$rc" 1 "status"
    assert_contains "$(cat out)" "read the docs build 42 failed"
}

test_merge_waits_for_build () {
    rtd_setup
    answer_happy_merge
    answer project-build-details.1 0 '{"id": 42, "success": null}'
    run_rtdv3
    assert_eq "$rc" 0 "status"
    assert_eq "$(grep -c 'project-build-details' calls)" 2 "polls"
}

test_merge_stops_waiting_for_build () {
    rtd_setup
    answer_happy_merge
    answer project-build-details 0 '{"id": 42, "success": null}'
    run_rtdv3
    assert_eq "$rc" 1 "status"
    assert_eq "$(grep -c 'project-build-details' calls)" 360 "polls"
    assert_contains "$(cat out)" "did not finish within an hour"
}

test_merge_fails_without_build_id () {
    rtd_setup
    answer_happy_merge
    answer project-build-trigger 0 '{"triggered": false}'
    run_rtdv3
    assert_eq "$rc" 1 "status"
    assert_not_contains "$(calls)" "project-build-details"
}

test_merge_on_branch_discovers_and_activates_version () {
    rtd_setup
    answer_happy_merge
    export GERRIT_BRANCH=London
    answer project-version-details.1 1 "" "Error: Version 'london' of project 'onap-cps' not found"
    answer project-version-details.2 0 '{"slug": "london", "active": false}'
    run_rtdv3
    assert_eq "$rc" 0 "status"
    assert_contains "$(calls)" "rtd project-build-trigger onap-cps latest --json"
    assert_contains "$(calls)" "rtd project-build-trigger onap-cps london --json"
    assert_contains "$(calls)" "lftools-uv rtd project-version-update onap-cps london true"
}

test_merge_on_branch_fails_when_version_lookup_fails () {
    rtd_setup
    answer_happy_merge
    export GERRIT_BRANCH=london
    answer project-version-details 1 "" "Error: Version 'london' of project 'onap-cps' failed with HTTP 500"
    run_rtdv3
    assert_eq "$rc" 1 "status"
    assert_not_contains "$(calls)" "project-build-trigger"
}

run_all_tests
