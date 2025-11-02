#!/usr/bin/env bats
# Poetry shim tests

load helpers/test_helper

setup() {
    setup_mock_install_env
}

teardown() {
    teardown_test_env
}

@test "poetry shim exists" {
    [ -f "${TEST_BIN_DIR}/poetry" ]
    [ -x "${TEST_BIN_DIR}/poetry" ]
}

@test "poetry shim uses global version" {
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5

    run poetry --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.8.5" ]]
}

@test "poetry shim uses local version" {
    mock_install_poetry 1.7.1
    run poetryenv local 1.7.1

    run poetry --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.7.1" ]]
}

@test "poetry shim prefers local over global" {
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5
    run poetryenv local 1.7.1

    run poetry --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.7.1" ]]
}

@test "poetry shim switches when changing directory" {
    # Setup two projects
    project1=$(create_test_project "project1")
    project2=$(create_test_project "project2")

    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5

    # Set different versions for each project
    cd "$project1"
    run poetryenv local 1.7.1

    cd "$project2"
    run poetryenv local 1.8.5

    # Test project 1
    cd "$project1"
    run poetry --version
    [[ "$output" =~ "1.7.1" ]]

    # Test project 2
    cd "$project2"
    run poetry --version
    [[ "$output" =~ "1.8.5" ]]
}

@test "poetry shim shows error when version not installed" {
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5

    # Set local to a non-existent version
    echo "9.9.9" >.poetry-version

    run poetry --version
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Poetry version 9.9.9 not installed" ]]
}

@test "poetry shim shows error when no version configured" {
    run poetry --version
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No poetry version configured" ]]
    [[ "$output" =~ "poetryenv install" ]]
}

@test "poetry shim passes arguments correctly" {
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5

    # The mock poetry just echoes version, but we test that shim executes it
    run poetry --version
    [ "$status" -eq 0 ]
}
