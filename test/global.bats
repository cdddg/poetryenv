#!/usr/bin/env bats
# Global version management tests

load helpers/test_helper

setup() {
    setup_mock_install_env
}

teardown() {
    teardown_test_env
}

# Basic global commands
@test "poetryenv global without version shows not set" {
    run poetryenv global
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No global version set" ]]
}

@test "poetryenv global <version> sets global version" {
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Global poetry version set to 1.8.5" ]]
}

@test "poetryenv global <version> creates global file" {
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5

    assert_file_exists "${POETRYENV_ROOT}/global"
    assert_file_contains "${POETRYENV_ROOT}/global" "1.8.5"
}

@test "poetryenv global shows current global version" {
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5

    run poetryenv global
    [ "$status" -eq 0 ]
    [[ "$output" == "1.8.5" ]]
}

@test "poetryenv global with uninstalled version shows error" {
    run poetryenv global 9.9.9
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not installed" ]]
}

@test "poetryenv global can switch versions" {
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5

    run poetryenv global 1.7.1
    [ "$status" -eq 0 ]

    run poetryenv global
    [[ "$output" == "1.7.1" ]]

    run poetryenv global 1.8.5
    [ "$status" -eq 0 ]

    run poetryenv global
    [[ "$output" == "1.8.5" ]]
}

# version command with global
@test "poetryenv version shows global when no local" {
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5

    run poetryenv version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.8.5" ]]
    [[ "$output" =~ "global" ]]
}

@test "poetryenv version shows error when nothing set" {
    run poetryenv version
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No poetry version configured" ]]
}

# versions command with global
@test "poetryenv versions marks global version" {
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5

    run poetryenv versions
    [ "$status" -eq 0 ]
    [[ "$output" =~ "* 1.8.5" ]]
    [[ "$output" =~ "$POETRYENV_ROOT/global" ]]
}

# which command with global
@test "poetryenv which shows correct path for global" {
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5

    run poetryenv which
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.8.5/bin/poetry" ]]
}

@test "poetryenv which shows error when nothing set" {
    run poetryenv which
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No poetry executable found" ]]
}
