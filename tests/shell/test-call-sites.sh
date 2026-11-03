#!/usr/bin/env bash
# SPDX-License-Identifier: EPL-1.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
#
# Tests for the scripts that run lftools-uv: each must cope with an agent
# whose ~/lf-env.sh predates the lftools-uv function, and none may still
# call legacy lftools.

# shellcheck source=tests/shell/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

GUARD_START="# An agent's ~/lf-env.sh is copied when it boots, so may predate lftools-uv."

# Print the guard block of script $1: from its first line to the first 'fi'
# at the start of a line.
guard_of () {
    awk -v start="$GUARD_START" '$0 == start {on = 1} on {print} on && /^fi$/ {exit}' "$1"
}

# Print the scripts that run lftools-uv, outside comments. python-tools-install.sh
# only mentions it.
callers () {
    grep -l -E '^[^#]*lftools-uv ' "$REPO_ROOT"/shell/*.sh | grep -v '/python-tools-install\.sh$'
}

# Print an lftools-uv function that logs its calls to $SCRATCH/calls.
logging_lftools_uv () {
    cat <<'SH'
lftools-uv () { echo "lftools-uv $*" >> "$SCRATCH/calls"; }
SH
}

# A ~/lf-env.sh from before lftools-uv, and a wget that logs its arguments and
# serves $SCRATCH/served as the lf-env.sh it fetches.
stale_agent () {
    cat > ~/lf-env.sh <<'SH'
lf-echo-stderr () { echo "$@" >&2; }
SH
    stub wget <<'STUB'
echo "wget $*" >> "$SCRATCH/wget.log"
while (( $# )); do
    if [[ $1 == -O ]]; then
        out=$2
    fi
    shift
done
[[ -f $SCRATCH/served ]] || exit 8
cp "$SCRATCH/served" "$out"
STUB
    logging_lftools_uv > "$SCRATCH/served"
    export OS_CLOUD=vex OS_STACK_NAME=stack-1
}

test_every_caller_carries_the_same_guard () {
    local reference script count=0
    reference="$(guard_of "$REPO_ROOT/shell/rtdv3.sh")"
    [[ -n $reference ]] || fail "no guard in rtdv3.sh"
    for script in $(callers); do
        count=$((count + 1))
        assert_eq "$(guard_of "$script")" "$reference" "guard in ${script#"$REPO_ROOT"/}"
        grep -A1 -E '^(source|\.) ~/lf-env\.sh$' "$script" | grep -q -F -x "$GUARD_START" \
            || fail "${script#"$REPO_ROOT"/}: guard does not follow sourcing ~/lf-env.sh"
    done
    (( count >= 19 )) || fail "found only $count callers"
}

test_no_script_calls_legacy_lftools () {
    local found
    found="$(grep -n -E '(^|[[:space:];|&(])lftools[[:space:]]' "$REPO_ROOT"/shell/*.sh \
        | grep -v -E '^[^:]*:[0-9]+:[[:space:]]*#' \
        | grep -v '/python-tools-install\.sh:' || true)"
    assert_eq "$found" "" "legacy lftools calls"
}

test_no_script_needs_the_legacy_front_end () {
    local found
    found="$(grep -n 'LEGACY_CLI' "$REPO_ROOT"/shell/*.sh "$REPO_ROOT/tox.ini" || true)"
    assert_eq "$found" "" "LEGACY_CLI uses"
}

test_tox_pins_the_version_lf_env_runs () {
    local pinned deps
    pinned="$(sed -n 's/.*LFTOOLS_UV_VERSION:-\([^}]*\)}.*/\1/p' \
        "$REPO_ROOT/jenkins-init-scripts/lf-env.sh")"
    [[ -n $pinned ]] || fail "no default version in lf-env.sh"
    deps="$(grep -E '^deps = lftools-uv' "$REPO_ROOT/tox.ini")"
    assert_eq "$deps" "deps = lftools-uv{env:LFTOOLS_UV_VERSION_OP:==}{env:LFTOOLS_UV_VERSION:$pinned}
deps = lftools-uv{env:LFTOOLS_UV_VERSION_OP:==}{env:LFTOOLS_UV_VERSION:$pinned}" "tox.ini lftools-uv deps"
}

test_stale_lf_env_fetches_lf_env_of_global_jjb_version () {
    stale_agent
    export GLOBAL_JJB_VERSION=v0.99.0
    rc=0
    bash "$REPO_ROOT/shell/openstack-stack-delete.sh" > out 2>&1 || rc=$?
    assert_eq "$rc" 0 "status"
    assert_contains "$(cat wget.log)" \
        "https://raw.githubusercontent.com/lfit/releng-global-jjb/v0.99.0/jenkins-init-scripts/lf-env.sh"
    assert_eq "$(cat calls)" "lftools-uv openstack --os-cloud vex stack delete stack-1" "lftools-uv calls"
}

test_stale_lf_env_fetches_master_by_default () {
    stale_agent
    bash "$REPO_ROOT/shell/openstack-stack-delete.sh" > out 2>&1
    assert_contains "$(cat wget.log)" "/releng-global-jjb/master/jenkins-init-scripts/lf-env.sh"
}

test_stale_lf_env_fails_when_fetch_fails () {
    stale_agent
    rm "$SCRATCH/served"
    rc=0
    bash "$REPO_ROOT/shell/openstack-stack-delete.sh" > out 2>&1 || rc=$?
    assert_eq "$rc" 1 "status"
    assert_contains "$(cat out)" "ERROR: lf-env.sh has no lftools-uv function"
    [[ ! -e calls ]] || fail "ran lftools-uv anyway"
}

test_stale_lf_env_fails_when_fetched_lf_env_lacks_lftools_uv () {
    stale_agent
    echo '# an older lf-env.sh' > "$SCRATCH/served"
    rc=0
    bash "$REPO_ROOT/shell/check-info-votes.sh" > out 2>&1 || rc=$?
    assert_eq "$rc" 1 "status"
    assert_contains "$(cat out)" "ERROR: lf-env.sh has no lftools-uv function"
}

test_current_lf_env_is_used_as_is () {
    stale_agent
    cat "$SCRATCH/served" >> ~/lf-env.sh
    bash "$REPO_ROOT/shell/openstack-stack-delete.sh" > out 2>&1
    [[ ! -e wget.log ]] || fail "fetched lf-env.sh although ~/lf-env.sh has lftools-uv"
    assert_eq "$(cat calls)" "lftools-uv openstack --os-cloud vex stack delete stack-1" "lftools-uv calls"
}

test_maven_deploy_allows_an_empty_snapshot_deploy () {
    logging_lftools_uv > ~/lf-env.sh
    export WORKSPACE="$SCRATCH/ws" NEXUS_URL=https://nexus.example NEXUS_REPO=snapshots
    mkdir -p "$WORKSPACE/m2repo/org/example" "$WORKSPACE/m2repo-backup"
    touch "$WORKSPACE/m2repo/org/example/_remote.repositories"
    bash "$REPO_ROOT/shell/maven-deploy.sh" > out 2>&1
    local url=https://nexus.example/content/repositories/snapshots
    assert_eq "$(cat calls)" "lftools-uv deploy nexus -s --allow-empty $url $WORKSPACE/m2repo" \
        "lftools-uv calls"
}

run_all_tests
