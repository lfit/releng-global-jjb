#!/usr/bin/env bash
# SPDX-License-Identifier: EPL-1.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
#
# Tests for the lftools-uv function in lf-env.sh, against a fake uvx.

# shellcheck source=tests/shell/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# shellcheck source=jenkins-init-scripts/lf-env.sh
source "$REPO_ROOT/jenkins-init-scripts/lf-env.sh"

PIN="--quiet --python 3.12 --from lftools-uv[openstack]==0.7.10"
PYPI="https://pypi.org/simple"
MIRROR="https://mirror.example/simple"

# Write a fake uvx to $1. It logs each call to uvx.log and fails a fetch from
# FAKE_UVX_BAD_INDEX; an offline run prints "lftools-uv ran" and exits
# FAKE_UVX_STATUS, and 'uvx --version' exits FAKE_UVX_VERSION_STATUS.
fake_uvx () {
    cat > "$1" <<'FAKE'
#!/usr/bin/env bash
index="" offline="" prev=""
for arg in "$@"; do
    if [[ $prev == --default-index ]]; then
        index=$arg
    fi
    if [[ $arg == --offline ]]; then
        offline=1
    fi
    prev=$arg
done
{
    echo "uvx $*"
    echo "  PYTHONPATH=${PYTHONPATH-unset} PYTHONHOME=${PYTHONHOME-unset}"
    echo "  LEGACY_CLI=${LEGACY_CLI-unset} NEXUS_PASSWORD=${NEXUS_PASSWORD-unset}"
} >> "$SCRATCH/uvx.log"
if [[ $* == --version ]]; then
    exit "${FAKE_UVX_VERSION_STATUS:-0}"
fi
if [[ -n $index && $index == "${FAKE_UVX_BAD_INDEX:-}" ]]; then
    echo "error: Failed to fetch lftools-uv" >&2
    exit 2
fi
if [[ -n $offline ]]; then
    echo "lftools-uv ran"
    exit "${FAKE_UVX_STATUS:-0}"
fi
FAKE
    chmod +x "$1"
}

uvx_calls () {
    grep '^uvx' "$SCRATCH/uvx.log" || true
}

# A wget that serves $SCRATCH/installer as the uv installer, and an installer
# that leaves a fake uvx in ~/.local/bin, then exits INSTALLER_STATUS.
stub_uv_installer () {
    stub wget <<'STUB'
echo "wget $*" >> "$SCRATCH/wget.log"
while (( $# )); do
    if [[ $1 == -O ]]; then
        out=$2
    fi
    shift
done
[[ -f $SCRATCH/installer ]] || exit 8
cp "$SCRATCH/installer" "$out"
STUB
    fake_uvx "$SCRATCH/fake-uvx"
    cat > "$SCRATCH/installer" <<'SH'
mkdir -p "$HOME/.local/bin"
cp "$SCRATCH/fake-uvx" "$HOME/.local/bin/uvx"
exit "${INSTALLER_STATUS:-0}"
SH
}

test_runs_pinned_version_offline_once () {
    fake_uvx "$SCRATCH/stubs/uvx"
    out="$(lftools-uv deploy nexus -s https://nexus.example/repo m2repo)"
    assert_eq "$out" "lftools-uv ran" "stdout"
    assert_eq "$(uvx_calls)" "uvx $PIN --default-index $PYPI lftools-uv --version
uvx $PIN --offline --default-index $PYPI lftools-uv deploy nexus -s https://nexus.example/repo m2repo" "uvx calls"
}

test_fetches_once_per_shell () {
    fake_uvx "$SCRATCH/stubs/uvx"
    lftools-uv one > /dev/null
    lftools-uv two > /dev/null
    assert_eq "$(grep -c "^uvx" uvx.log)" 3 "uvx calls"
}

test_honours_version_and_python_overrides () {
    fake_uvx "$SCRATCH/stubs/uvx"
    LFTOOLS_UV_VERSION=0.8.0 LFTOOLS_UV_PYTHON=3.13 lftools-uv x > /dev/null
    assert_contains "$(uvx_calls)" "--python 3.13 --from lftools-uv[openstack]==0.8.0 --offline"
}

test_reads_index_from_pip_conf () {
    fake_uvx "$SCRATCH/stubs/uvx"
    mkdir -p ~/.config/pip
    printf '[global]\nindex-url = %s  \ntimeout = 60\n' "$MIRROR" > ~/.config/pip/pip.conf
    lftools-uv x > /dev/null
    assert_eq "$(uvx_calls | grep -c -- "--default-index $MIRROR lftools-uv")" 2 "mirror calls"
}

test_pip_index_url_overrides_pip_conf () {
    fake_uvx "$SCRATCH/stubs/uvx"
    mkdir -p ~/.config/pip
    printf '[global]\nindex-url = https://other.example/simple\n' > ~/.config/pip/pip.conf
    PIP_INDEX_URL="$MIRROR" lftools-uv x > /dev/null
    assert_eq "$(uvx_calls | grep -c -- "--default-index $MIRROR lftools-uv")" 2 "mirror calls"
}

test_falls_back_to_pypi_when_mirror_fails () {
    fake_uvx "$SCRATCH/stubs/uvx"
    export PIP_INDEX_URL="$MIRROR" FAKE_UVX_BAD_INDEX="$MIRROR"
    out="$(lftools-uv x 2> err)"
    assert_eq "$out" "lftools-uv ran" "stdout"
    assert_contains "$(cat err)" "WARNING: could not fetch lftools-uv[openstack]==0.7.10 from $MIRROR"
    assert_eq "$(uvx_calls)" "uvx $PIN --default-index $MIRROR lftools-uv --version
uvx $PIN --default-index $PYPI lftools-uv --version
uvx $PIN --offline --default-index $PYPI lftools-uv x" "uvx calls"
}

test_fails_without_running_when_unfetchable () {
    fake_uvx "$SCRATCH/stubs/uvx"
    export FAKE_UVX_BAD_INDEX="$PYPI"
    rc=0
    lftools-uv x 2> err || rc=$?
    assert_eq "$rc" 1 "status"
    assert_contains "$(cat err)" "ERROR: could not fetch"
    assert_not_contains "$(uvx_calls)" "--offline" "uvx calls"
}

test_clears_python_path_but_keeps_other_variables () {
    fake_uvx "$SCRATCH/stubs/uvx"
    export PYTHONPATH="$SCRATCH/job" PYTHONHOME=/job/python NEXUS_PASSWORD=pw
    lftools-uv x > /dev/null
    assert_eq "$(grep -c 'PYTHONPATH=unset PYTHONHOME=unset' uvx.log)" 2 "cleared"
    assert_eq "$(grep -c 'NEXUS_PASSWORD=pw' uvx.log)" 2 "passed through"
    assert_eq "$PYTHONPATH" "$SCRATCH/job" "caller's PYTHONPATH"
}

test_passes_legacy_cli_through () {
    fake_uvx "$SCRATCH/stubs/uvx"
    LEGACY_CLI=1 lftools-uv nexus release > /dev/null
    assert_contains "$(grep -A2 -- '--offline' uvx.log)" "LEGACY_CLI=1"
}

test_hides_index_credentials () {
    fake_uvx "$SCRATCH/stubs/uvx"
    export PIP_INDEX_URL="https://jenkins:s3cret@mirror.example/simple"
    export FAKE_UVX_BAD_INDEX="$PIP_INDEX_URL"
    {
        set -x
        lftools-uv x > /dev/null
        flags=$-
        set +x
    } 2> err
    assert_contains "$(cat err)" "+ lftools-uv x" "trace"
    assert_contains "$(cat err)" "from https://***@mirror.example/simple" "warning"
    assert_not_contains "$(cat err)" "s3cret" "stderr"
    assert_contains "$flags" x "caller's xtrace"
}

test_leaves_xtrace_off () {
    fake_uvx "$SCRATCH/stubs/uvx"
    lftools-uv x > /dev/null
    assert_not_contains "$-" x "shell flags"
}

test_returns_command_status () {
    fake_uvx "$SCRATCH/stubs/uvx"
    export FAKE_UVX_STATUS=3
    rc=0
    lftools-uv x > /dev/null || rc=$?
    assert_eq "$rc" 3 "status"
    set +e
    (
        set -e
        lftools-uv x > /dev/null
        echo "still running"
    ) > out
    rc=$?
    set -e
    assert_eq "$rc" 3 "errexit status"
    assert_eq "$(cat out)" "" "output after the failure"
}

test_uses_uvx_from_local_bin () {
    stub wget <<< 'exit 1'
    mkdir -p ~/.local/bin
    fake_uvx ~/.local/bin/uvx
    assert_eq "$(lftools-uv x)" "lftools-uv ran" "stdout"
}

test_installs_uv_when_missing () {
    stub_uv_installer
    out="$(UV_VERSION=0.9.0 lftools-uv x 2> err)"
    assert_eq "$out" "lftools-uv ran" "stdout"
    assert_contains "$(cat wget.log)" "https://astral.sh/uv/0.9.0/install.sh"
}

test_rejects_failed_installer () {
    stub_uv_installer
    export INSTALLER_STATUS=42
    rc=0
    lftools-uv x > out 2> err || rc=$?
    assert_eq "$rc" 1 "status"
    assert_contains "$(cat err)" "ERROR: the uv installer failed"
    assert_eq "$(cat out)" "" "stdout"
}

test_rejects_failed_installer_download () {
    stub_uv_installer
    rm "$SCRATCH/installer"
    rc=0
    lftools-uv x > out 2> err || rc=$?
    assert_eq "$rc" 1 "status"
    assert_contains "$(cat err)" "ERROR: cannot download the uv installer"
}

test_rejects_installed_uvx_that_does_not_run () {
    stub_uv_installer
    export FAKE_UVX_VERSION_STATUS=1
    rc=0
    lftools-uv x > out 2> err || rc=$?
    assert_eq "$rc" 1 "status"
    assert_contains "$(cat err)" "ERROR: uvx does not run after installing uv"
}

test_rejects_failed_mktemp () {
    stub_uv_installer
    stub mktemp <<< 'exit 1'
    rc=0
    lftools-uv x > out 2> err || rc=$?
    assert_eq "$rc" 1 "status"
    assert_contains "$(cat err)" "ERROR: cannot create a file for the uv installer"
    [[ ! -e wget.log ]] || fail "downloaded the installer anyway"
}

run_all_tests
