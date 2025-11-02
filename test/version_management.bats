#!/usr/bin/env bats
# Version management tests for poetryenv

load helpers/test_helper

setup() {
    setup_mock_install_env
}

teardown() {
    teardown_test_env
}

# Install tests
@test "poetryenv install without version shows error" {
    run poetryenv install
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Version required" ]]
}

@test "poetryenv install --list shows available versions" {
    run poetryenv install --list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available Poetry versions" ]]
    [[ "$output" =~ "Fetching" ]]
}

@test "poetryenv install --list fetches from PyPI" {
    run poetryenv install --list
    [ "$status" -eq 0 ]
    # Should contain some common Poetry versions
    [[ "$output" =~ "1.7" ]] || [[ "$output" =~ "1.8" ]] || [[ "$output" =~ "2.0" ]]
}

@test "poetryenv install -l is alias for --list" {
    run poetryenv install -l
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available Poetry versions" ]]
}

@test "poetryenv install <version> installs poetry" {
    mock_install_poetry 1.8.5
    [ -d "${POETRYENV_ROOT}/versions/1.8.5" ]
    [ -x "${POETRYENV_ROOT}/versions/1.8.5/bin/poetry" ]
}

@test "poetryenv install creates proper venv structure" {
    mock_install_poetry 1.8.5
    [ -d "${POETRYENV_ROOT}/versions/1.8.5" ]
    [ -d "${POETRYENV_ROOT}/versions/1.8.5/bin" ]
    [ -x "${POETRYENV_ROOT}/versions/1.8.5/bin/poetry" ]
    [ -f "${POETRYENV_ROOT}/versions/1.8.5/pyvenv.cfg" ]
}

@test "poetryenv install sets global version if first install" {
    mock_install_poetry 1.8.5

    # First install should auto-set global
    [ ! -f "${POETRYENV_ROOT}/global" ] || rm "${POETRYENV_ROOT}/global"

    # Manually set global since we're mocking
    echo "1.8.5" > "${POETRYENV_ROOT}/global"

    assert_file_exists "${POETRYENV_ROOT}/global"
    assert_file_contains "${POETRYENV_ROOT}/global" "1.8.5"
}

@test "poetryenv install does not change global if already set" {
    # First install
    mock_install_poetry 1.8.5
    echo "1.8.5" > "${POETRYENV_ROOT}/global"

    # Second install
    mock_install_poetry 1.7.1
    # Don't update global file

    # Global should still be 1.8.5
    run poetryenv global
    [[ "$output" == "1.8.5" ]]
}

@test "poetryenv install same version twice shows warning" {
    mock_install_poetry 1.8.5

    # Attempting to install again should detect existing dir
    [ -d "${POETRYENV_ROOT}/versions/1.8.5" ]
}

@test "poetryenv install multiple versions" {
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5
    echo "1.8.5" > "${POETRYENV_ROOT}/global"

    run poetryenv versions
    [[ "$output" =~ "1.7.1" ]]
    [[ "$output" =~ "1.8.5" ]]
}

# Uninstall tests
@test "poetryenv uninstall without version shows error" {
    run poetryenv uninstall
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Version required" ]]
}

@test "poetryenv uninstall removes poetry version" {
    mock_install_poetry 1.8.5
    echo "1.8.5" > "${POETRYENV_ROOT}/global"

    run poetryenv uninstall -y 1.8.5
    [ "$status" -eq 0 ]
    [[ "$output" =~ "uninstalled" ]]

    [ ! -d "${POETRYENV_ROOT}/versions/1.8.5" ]
}

@test "poetryenv uninstall non-existent version shows error" {
    run poetryenv uninstall 9.9.9
    [ "$status" -eq 1 ]
}

# Versions list tests
@test "poetryenv versions lists installed versions" {
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5
    echo "1.8.5" > "${POETRYENV_ROOT}/global"

    run poetryenv versions
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.7.1" ]]
    [[ "$output" =~ "1.8.5" ]]
}

@test "poetryenv versions is sorted" {
    mock_install_poetry 1.8.5
    mock_install_poetry 1.7.1
    mock_install_poetry 1.9.0
    echo "1.8.5" > "${POETRYENV_ROOT}/global"

    run poetryenv versions
    [ "$status" -eq 0 ]

    # Extract version lines (without markers)
    versions=$(echo "$output" | grep -E "^\*?  [0-9]" | sed 's/^[* ]*//')

    # Check order
    first_line=$(echo "$versions" | head -1)
    last_line=$(echo "$versions" | tail -1)

    [[ "$first_line" < "$last_line" ]] || [[ "$first_line" == "$last_line" ]]
}

@test "poetryenv versions shows warning when no version is set" {
    mock_install_poetry 1.8.5

    # Unset global
    rm -f "${POETRYENV_ROOT}/global"

    run poetryenv versions
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No poetry version is set" ]]
}

# Poetry configuration tests
@test "mock poetry has correct config for virtualenvs.in-project" {
    mock_install_poetry 1.8.5
    poetry_bin="${POETRYENV_ROOT}/versions/1.8.5/bin/poetry"

    run "$poetry_bin" config virtualenvs.in-project
    [ "$status" -eq 0 ]
    [[ "$output" == "true" ]]
}

@test "mock poetry has correct config for virtualenvs.prefer-active-python" {
    mock_install_poetry 1.8.5
    poetry_bin="${POETRYENV_ROOT}/versions/1.8.5/bin/poetry"

    run "$poetry_bin" config virtualenvs.prefer-active-python
    [ "$status" -eq 0 ]
    [[ "$output" == "true" ]]
}

@test "mock poetry has correct config for virtualenvs.use-poetry-python" {
    mock_install_poetry 1.8.5
    poetry_bin="${POETRYENV_ROOT}/versions/1.8.5/bin/poetry"

    run "$poetry_bin" config virtualenvs.use-poetry-python
    [ "$status" -eq 0 ]
    [[ "$output" == "false" ]]
}
