#!/usr/bin/env bats
# Basic functionality tests for poetryenv

load helpers/test_helper

setup() {
    setup_mock_install_env
}

teardown() {
    teardown_test_env
}

@test "poetryenv command exists" {
    run command -v poetryenv
    [ "$status" -eq 0 ]
}

@test "poetryenv --help shows usage" {
    run poetryenv --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage: poetryenv" ]]
}

@test "poetryenv help shows usage" {
    run poetryenv help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage: poetryenv" ]]
}

@test "poetryenv without arguments shows help" {
    run poetryenv
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage: poetryenv" ]]
}

@test "poetryenv with invalid command shows error" {
    run poetryenv invalid-command
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown command" ]]
}

@test "POETRYENV_ROOT is set correctly" {
    [[ -d "${POETRYENV_ROOT}" ]]
}

@test "poetryenv versions shows empty list initially" {
    run poetryenv versions
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No poetry versions installed" ]]
}
