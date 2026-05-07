#!/usr/bin/env bats
# Real-install isolation tests.
#
# For every Poetry version already installed under POETRYENV_ROOT, verify that
# the Poetry binary actually honors POETRY_CONFIG_DIR / POETRY_DATA_DIR /
# POETRY_CACHE_DIR — i.e. that per-version isolation works for real, not just
# in theory. POETRYENV_ROOT defaults to ~/.poetryenv (same as poetryenv itself).
#
# This file does NOT install Poetry, and does NOT write to the user's real
# config. Each version is probed via a private temp config dir that bats
# cleans up automatically.

setup_file() {
    # Mirror the fallback used by libexec/poetryenv--lib.
    : "${POETRYENV_ROOT:=$HOME/.poetryenv}"
    export POETRYENV_ROOT

    if [[ ! -d "$POETRYENV_ROOT/versions" ]]; then
        export REAL_ISOLATION_SKIP="$POETRYENV_ROOT/versions does not exist — run 'poetryenv install <version>' first"
        export INSTALLED_VERSIONS_LIST=""
        return 0
    fi

    local list=()
    local d
    for d in "$POETRYENV_ROOT/versions"/*; do
        [[ -d "$d" && -x "$d/bin/poetry" ]] && list+=("$(basename "$d")")
    done

    if (( ${#list[@]} == 0 )); then
        export REAL_ISOLATION_SKIP="no installed versions under $POETRYENV_ROOT/versions"
        export INSTALLED_VERSIONS_LIST=""
        return 0
    fi

    # Bash arrays can't be exported, so stash the joined string instead.
    export INSTALLED_VERSIONS_LIST="${list[*]}"
    export PROBE_DIR="${BATS_FILE_TMPDIR}/probe"
    mkdir -p "$PROBE_DIR"
}

# Probe one installed Poetry version using a private throw-away config tree
# under $PROBE_DIR. Verifies:
#   1. POETRY_CONFIG_DIR is honored — poetry reads from the dir we point at
#      (we pre-seed a marker value and read it back)
#   2. POETRY_CACHE_DIR is honored — surfaces in `poetry config --list`
# The user's real ~/.poetryenv/versions/<v>/config is never touched.
assert_version_isolated() {
    local version="$1"
    local poetry_bin="$POETRYENV_ROOT/versions/$version/bin/poetry"

    [[ -x "$poetry_bin" ]] || {
        echo "[$version] poetry binary missing at $poetry_bin"
        return 1
    }

    local probe_root="$PROBE_DIR/$version"
    local probe_config="$probe_root/config"
    local probe_data="$probe_root/data"
    local probe_cache="$probe_root/cache"
    local marker="$probe_root/marker-virtualenvs"
    mkdir -p "$probe_config" "$probe_data" "$probe_cache"

    cat >"$probe_config/config.toml" <<EOF
[virtualenvs]
path = "$marker"
EOF

    # 1. POETRY_CONFIG_DIR honored: poetry should read back our marker.
    local actual
    actual=$(POETRY_CONFIG_DIR="$probe_config" \
        POETRY_DATA_DIR="$probe_data" \
        POETRY_CACHE_DIR="$probe_cache" \
        "$poetry_bin" config virtualenvs.path 2>&1) || true

    if [[ "$actual" != "$marker" ]]; then
        echo "[$version] POETRY_CONFIG_DIR ignored: expected $marker, got: $actual"
        return 1
    fi

    # 2. POETRY_CACHE_DIR honored: surfaces in `poetry config --list`.
    local listing
    listing=$(POETRY_CONFIG_DIR="$probe_config" \
        POETRY_DATA_DIR="$probe_data" \
        POETRY_CACHE_DIR="$probe_cache" \
        "$poetry_bin" config --list 2>&1) || true

    if ! grep -q "$probe_cache" <<<"$listing"; then
        echo "[$version] POETRY_CACHE_DIR not in 'poetry config --list':"
        echo "$listing" | sed 's/^/    /'
        return 1
    fi

    return 0
}

@test "POETRYENV_ROOT contains at least one installed version" {
    [[ -z "${REAL_ISOLATION_SKIP:-}" ]] || skip "$REAL_ISOLATION_SKIP"
    [[ -n "$INSTALLED_VERSIONS_LIST" ]] || {
        echo "no installed versions under $POETRYENV_ROOT/versions"
        false
    }
    # FD 3 is bats' "always show" channel; visible on PASS too.
    echo "# POETRYENV_ROOT=$POETRYENV_ROOT" >&3
    echo "# versions under test: $INSTALLED_VERSIONS_LIST" >&3
}

@test "every installed version honours POETRY_CONFIG_DIR / POETRY_CACHE_DIR" {
    [[ -z "${REAL_ISOLATION_SKIP:-}" ]] || skip "$REAL_ISOLATION_SKIP"

    local fails=()
    local v
    for v in $INSTALLED_VERSIONS_LIST; do
        if assert_version_isolated "$v"; then
            echo "#   PASS $v" >&3
        else
            echo "#   FAIL $v" >&3
            fails+=("$v")
        fi
    done

    if (( ${#fails[@]} > 0 )); then
        echo "isolation failed for: ${fails[*]}"
        false
    fi
}

@test "two probe configs for the same version stay independent" {
    # Sanity check: writing distinct marker values via two different
    # POETRY_CONFIG_DIRs must not bleed into each other. This catches the
    # failure mode where POETRY_CONFIG_DIR is silently ignored (the second
    # write would clobber the first, or both reads return the same value).
    [[ -z "${REAL_ISOLATION_SKIP:-}" ]] || skip "$REAL_ISOLATION_SKIP"

    local versions=($INSTALLED_VERSIONS_LIST)
    local v="${versions[0]}"
    local poetry_bin="$POETRYENV_ROOT/versions/$v/bin/poetry"

    local pa="$PROBE_DIR/_pair/a" pb="$PROBE_DIR/_pair/b"
    mkdir -p "$pa" "$pb"
    printf '[virtualenvs]\npath = "%s"\n' "$pa/marker-A" >"$pa/config.toml"
    printf '[virtualenvs]\npath = "%s"\n' "$pb/marker-B" >"$pb/config.toml"

    local got_a got_b
    got_a=$(POETRY_CONFIG_DIR="$pa" "$poetry_bin" config virtualenvs.path 2>&1)
    got_b=$(POETRY_CONFIG_DIR="$pb" "$poetry_bin" config virtualenvs.path 2>&1)

    [[ "$got_a" == "$pa/marker-A" ]] || {
        echo "config A read back wrong: $got_a"; false
    }
    [[ "$got_b" == "$pb/marker-B" ]] || {
        echo "config B read back wrong: $got_b"; false
    }
}
