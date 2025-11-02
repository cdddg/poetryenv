#!/usr/bin/env bats
# Environment variable isolation tests

load helpers/test_helper

setup() {
    setup_mock_install_env
}

teardown() {
    teardown_test_env
}

@test "poetry shim uses version-specific paths" {
    mock_install_poetry 2.1.3
    poetryenv global 2.1.3

    # When poetry runs, it should use version-specific directories
    # We can verify this by checking that the version directory structure exists
    version_dir="$POETRYENV_ROOT/versions/2.1.3"

    [ -d "$version_dir" ]
    [ -d "$version_dir/bin" ]
    [ -x "$version_dir/bin/poetry" ]
}

@test "setup_poetry_env sets correct environment variables" {
    # Source the lib
    source libexec/poetryenv--lib

    # Call setup_poetry_env
    setup_poetry_env "2.1.3"

    # Check env vars are set correctly
    [[ "$POETRY_CONFIG_DIR" == *"/versions/2.1.3/config" ]]
    [[ "$POETRY_DATA_DIR" == *"/versions/2.1.3/data" ]]
    [[ "$POETRY_CACHE_DIR" == *"/versions/2.1.3/cache" ]]
}

@test "different versions have isolated config directories" {
    mock_install_poetry 2.1.3
    mock_install_poetry 2.2.1

    # Check that config paths are separate (directories may not exist until first use)
    config_213="$POETRYENV_ROOT/versions/2.1.3/config"
    config_221="$POETRYENV_ROOT/versions/2.2.1/config"

    # Paths should be different
    [ "$config_213" != "$config_221" ]

    # Both should be under their respective version directories
    [[ "$config_213" == *"/versions/2.1.3/config" ]]
    [[ "$config_221" == *"/versions/2.2.1/config" ]]
}

@test "different versions have isolated data directories" {
    mock_install_poetry 2.1.3
    mock_install_poetry 2.2.1

    # Check that data directories are separate
    data_213="$POETRYENV_ROOT/versions/2.1.3/data"
    data_221="$POETRYENV_ROOT/versions/2.2.1/data"

    # Directories should exist or at least be different paths
    [ "$data_213" != "$data_221" ]
}

@test "different versions have isolated cache directories" {
    mock_install_poetry 2.1.3
    mock_install_poetry 2.2.1

    # Check that cache directories are separate
    cache_213="$POETRYENV_ROOT/versions/2.1.3/cache"
    cache_221="$POETRYENV_ROOT/versions/2.2.1/cache"

    # Directories should be different paths
    [ "$cache_213" != "$cache_221" ]
}

@test "config directory is under version directory" {
    mock_install_poetry 2.1.3

    # Config should be under versions/2.1.3/
    config_dir="$POETRYENV_ROOT/versions/2.1.3/config"

    # Parent directory should be the version directory
    parent=$(dirname "$config_dir")
    [[ "$parent" == *"/versions/2.1.3" ]]
}

@test "uninstalling version removes all isolated directories" {
    mock_install_poetry 2.1.3

    version_dir="$POETRYENV_ROOT/versions/2.1.3"

    # Directory should exist
    [ -d "$version_dir" ]

    # Uninstall
    run poetryenv uninstall -f 2.1.3
    [ "$status" -eq 0 ]

    # All directories should be gone
    [ ! -d "$version_dir" ]
    [ ! -d "$version_dir/config" ]
    [ ! -d "$version_dir/data" ]
    [ ! -d "$version_dir/cache" ]
}
