#!/usr/bin/env bats
# Integration tests - complete workflows

load helpers/test_helper

setup() {
    setup_mock_install_env
}

teardown() {
    teardown_test_env
}

@test "complete workflow: install → global → use" {
    # Install version
    mock_install_poetry 1.8.5

    # Set as global
    run poetryenv global 1.8.5
    [ "$status" -eq 0 ]

    # Use poetry
    run poetry --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.8.5" ]]

    # Check versions list
    run poetryenv versions
    [[ "$output" =~ "* 1.8.5" ]]
}

@test "complete workflow: install → global → local → use" {
    # Install two versions
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5

    # Set global
    run poetryenv global 1.8.5

    # Create project with local version
    project=$(create_test_project "myproject")
    cd "$project"

    run poetryenv local 1.7.1
    [ "$status" -eq 0 ]

    # Poetry should use local
    run poetry --version
    [[ "$output" =~ "1.7.1" ]]

    # versions should show local
    run poetryenv versions
    [[ "$output" =~ "* 1.7.1" ]]
    [[ "$output" =~ ".poetry-version" ]]

    # Go back to root, should use global
    cd "${TEST_DIR}"
    run poetry --version
    [[ "$output" =~ "1.8.5" ]]
}

@test "multi-project scenario" {
    # Install versions
    mock_install_poetry 1.6.1
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5

    # Set global
    run poetryenv global 1.8.5

    # Create three projects
    project_a=$(create_test_project "project-a")
    project_b=$(create_test_project "project-b")
    project_c=$(create_test_project "project-c")

    # Project A: Poetry 1.6.1
    cd "$project_a"
    run poetryenv local 1.6.1
    run poetry --version
    [[ "$output" =~ "1.6.1" ]]

    # Project B: Poetry 1.7.1
    cd "$project_b"
    run poetryenv local 1.7.1
    run poetry --version
    [[ "$output" =~ "1.7.1" ]]

    # Project C: No local, uses global
    cd "$project_c"
    run poetry --version
    [[ "$output" =~ "1.8.5" ]]

    # Verify each project still works
    cd "$project_a"
    run poetry --version
    [[ "$output" =~ "1.6.1" ]]

    cd "$project_b"
    run poetry --version
    [[ "$output" =~ "1.7.1" ]]
}

@test "upgrade workflow: install new → switch global → verify" {
    # Initial setup
    mock_install_poetry 1.7.1
    run poetryenv global 1.7.1

    run poetry --version
    [[ "$output" =~ "1.7.1" ]]

    # Install newer version
    mock_install_poetry 1.8.5

    # Switch global
    run poetryenv global 1.8.5
    [ "$status" -eq 0 ]

    # Verify switch
    run poetry --version
    [[ "$output" =~ "1.8.5" ]]

    # Old version still available in its directory
    [ -x "${POETRYENV_ROOT}/versions/1.7.1/bin/poetry" ]
}

@test "cleanup workflow: uninstall → verify removal" {
    # Install versions
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5

    # Uninstall old version
    run poetryenv uninstall -y 1.7.1
    [ "$status" -eq 0 ]

    # Verify it's gone
    run poetryenv versions
    ! [[ "$output" =~ "1.7.1" ]]
    [[ "$output" =~ "1.8.5" ]]

    # 1.7.1 directory should not exist
    [ ! -d "${POETRYENV_ROOT}/versions/1.7.1" ]

    # Current version still works
    run poetry --version
    [[ "$output" =~ "1.8.5" ]]
}

@test "error recovery: set non-existent local → fix" {
    # Install version
    mock_install_poetry 1.8.5
    run poetryenv global 1.8.5

    # Manually create bad .poetry-version
    echo "9.9.9" > .poetry-version

    # poetry should fail
    run poetry --version
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not installed" ]]

    # Fix by unsetting local
    run poetryenv local --unset
    [ "$status" -eq 0 ]

    # Should work now (uses global)
    run poetry --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.8.5" ]]
}

@test "version precedence verification" {
    mock_install_poetry 1.6.1
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5

    # Set global
    run poetryenv global 1.8.5

    # Test: no local → uses global
    run poetryenv version
    [[ "$output" =~ "1.8.5" ]]
    [[ "$output" =~ "global" ]]

    # Test: set local → uses local
    run poetryenv local 1.7.1
    run poetryenv version
    [[ "$output" =~ "1.7.1" ]]
    [[ "$output" =~ ".poetry-version" ]]

    # Test: remove local → back to global
    run poetryenv local --unset
    run poetryenv version
    [[ "$output" =~ "1.8.5" ]]
    [[ "$output" =~ "global" ]]
}

@test "versions list accuracy with mixed setup" {
    # Install multiple versions
    mock_install_poetry 1.6.1
    mock_install_poetry 1.7.1
    mock_install_poetry 1.8.5

    # Set global
    run poetryenv global 1.7.1

    # Set local in subdirectory
    subdir="${TEST_DIR}/subproject"
    mkdir -p "$subdir"
    cd "$subdir"
    run poetryenv local 1.8.5

    # Test versions output in subdir (should show local)
    run poetryenv versions
    [[ "$output" =~ "* 1.8.5" ]]
    [[ "$output" =~ ".poetry-version" ]]

    # Test versions output in root (should show global)
    cd "${TEST_DIR}"
    run poetryenv versions
    [[ "$output" =~ "* 1.7.1" ]]
    [[ "$output" =~ "global" ]]
}
