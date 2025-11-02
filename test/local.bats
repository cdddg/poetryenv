#!/usr/bin/env bats
# Local (project-level) version management tests

load helpers/test_helper

setup() {
    setup_mock_install_env
}

teardown() {
    teardown_test_env
}

# Basic local commands
@test "poetryenv local without version shows not set" {
    run poetryenv local
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No .poetry-version file" ]]
}

@test "poetryenv local <version> sets local version" {
    mock_install_poetry 1.7.1
    run poetryenv local 1.7.1
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Set local poetry version to 1.7.1" ]]
}

@test "poetryenv local <version> creates .poetry-version file" {
    mock_install_poetry 1.7.1
    run poetryenv local 1.7.1

    assert_file_exists ".poetry-version"
    assert_file_contains ".poetry-version" "1.7.1"
}

@test "poetryenv local shows current local version" {
    mock_install_poetry 1.7.1
    run poetryenv local 1.7.1

    run poetryenv local
    [ "$status" -eq 0 ]
    [[ "$output" == "1.7.1" ]]
}

@test "poetryenv local with uninstalled version shows error" {
    run poetryenv local 9.9.9
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not installed" ]]
}

@test "poetryenv local --unset removes .poetry-version" {
    mock_install_poetry 1.7.1
    run poetryenv local 1.7.1

    [ -f ".poetry-version" ]

    run poetryenv local --unset
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Removed .poetry-version" ]]

    [ ! -f ".poetry-version" ]
}

@test "poetryenv local --unset without file shows warning" {
    run poetryenv local --unset
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No .poetry-version file" ]]
}

# Version precedence: local over global
@test "poetryenv version shows local over global" {
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5

    run poetryenv global 1.8.5
    run poetryenv local 1.7.1

    run poetryenv version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.7.1" ]]
    [[ "$output" =~ ".poetry-version" ]]
}

# versions command with local
@test "poetryenv versions marks local version" {
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5
    run poetryenv local 1.7.1

    run poetryenv versions
    [ "$status" -eq 0 ]
    [[ "$output" =~ "* 1.7.1" ]]
    [[ "$output" =~ ".poetry-version" ]]
}

@test "poetryenv versions local overrides global marker" {
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5
    run poetryenv local 1.7.1

    run poetryenv versions
    [ "$status" -eq 0 ]

    # Only 1.7.1 should be marked
    [[ "$output" =~ "* 1.7.1" ]]
    ! [[ "$output" =~ "* 1.8.5" ]]
}

# which command with local
@test "poetryenv which shows correct path for local" {
    mock_install_poetry 1.7.1
    run poetryenv local 1.7.1

    run poetryenv which
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.7.1/bin/poetry" ]]
}
