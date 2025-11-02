#!/usr/bin/env bash
# Test helper functions for poetryenv

# Setup isolated test environment
setup_test_env() {
    # Create unique test directory
    export TEST_DIR="${BATS_TEST_TMPDIR}/poetryenv-test-$$"
    export POETRYENV_ROOT="${TEST_DIR}/.poetryenv"
    export TEST_BIN_DIR="${TEST_DIR}/bin"
    export TEST_HOME="${TEST_DIR}/home"

    # Setup PATH to use test bin directory
    export PATH="${TEST_BIN_DIR}:${PATH}"

    # Disable colors in tests
    export NO_COLOR=1

    # Create directories
    mkdir -p "${POETRYENV_ROOT}"
    mkdir -p "${TEST_BIN_DIR}"
    mkdir -p "${TEST_HOME}"
    mkdir -p "${TEST_DIR}/libexec"

    # Copy poetryenv to test bin
    cp "${BATS_TEST_DIRNAME}/../bin/poetryenv" "${TEST_BIN_DIR}/poetryenv"
    chmod +x "${TEST_BIN_DIR}/poetryenv"

    # Copy libexec files
    cp -r "${BATS_TEST_DIRNAME}/../libexec"/* "${TEST_DIR}/libexec/"
    chmod +x "${TEST_DIR}/libexec"/*

    # Set POETRYENV_DIR so bin/poetryenv can find libexec
    export POETRYENV_DIR="${TEST_DIR}"

    # Copy poetry shim to test bin
    cp "${BATS_TEST_DIRNAME}/../bin/poetry-shim" "${TEST_BIN_DIR}/poetry"
    chmod +x "${TEST_BIN_DIR}/poetry"

    # Change to test directory
    cd "${TEST_DIR}"
}

# Setup for real installation tests (uses actual pip install)
# This is much slower than mocks, so use sparingly
setup_real_install_env() {
    setup_test_env

    # Ensure python3 is available
    if ! command -v python3 &> /dev/null; then
        skip "python3 not available for real installation tests"
    fi
}

# Fast mock setup for tests that don't need real Poetry installation
# Creates fake poetry executables without running pip install
setup_mock_install_env() {
    setup_test_env
    # No additional setup needed - tests will use mock_install_poetry
}

# Cleanup test environment
teardown_test_env() {
    # Remove test directory
    if [[ -n "${TEST_DIR}" ]] && [[ -d "${TEST_DIR}" ]]; then
        rm -rf "${TEST_DIR}"
    fi
}

# Create a mock Poetry installation (for fast tests that don't need real installation)
# This creates the directory structure that poetryenv expects
mock_install_poetry() {
    local version="$1"
    local install_dir="${POETRYENV_ROOT}/versions/${version}"

    # Create directory structure mimicking venv
    mkdir -p "${install_dir}/bin"
    mkdir -p "${install_dir}/lib/python3.11/site-packages"

    # Create fake poetry executable
    cat > "${install_dir}/bin/poetry" <<EOF
#!/usr/bin/env bash
# Mock Poetry ${version}
case "\$1" in
    --version)
        echo "Poetry (version ${version})"
        ;;
    config)
        # Mock config command
        case "\$2" in
            virtualenvs.in-project)
                echo "true"
                ;;
            virtualenvs.prefer-active-python)
                echo "true"
                ;;
            virtualenvs.use-poetry-python)
                echo "false"
                ;;
            *)
                # Setting config - just succeed
                exit 0
                ;;
        esac
        ;;
    *)
        echo "Poetry (version ${version})"
        ;;
esac
EOF
    chmod +x "${install_dir}/bin/poetry"

    # Create fake pyvenv.cfg to make it look like a real venv
    cat > "${install_dir}/pyvenv.cfg" <<EOF
home = /usr/bin
include-system-site-packages = false
version = 3.11.0
EOF
}

# Create a test project directory
create_test_project() {
    local project_name="$1"
    local project_dir="${TEST_DIR}/${project_name}"
    mkdir -p "${project_dir}"
    echo "${project_dir}"
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    [[ -f "${file}" ]] || {
        echo "Expected file ${file} to exist, but it doesn't"
        return 1
    }
}

# Assert file contains
assert_file_contains() {
    local file="$1"
    local expected="$2"
    grep -q "${expected}" "${file}" || {
        echo "Expected file ${file} to contain '${expected}'"
        echo "File contents:"
        cat "${file}"
        return 1
    }
}

# Assert command output contains
assert_output_contains() {
    local expected="$1"
    echo "${output}" | grep -q "${expected}" || {
        echo "Expected output to contain: ${expected}"
        echo "Actual output:"
        echo "${output}"
        return 1
    }
}

# Load bats-support and bats-assert if available
if [[ -f "/usr/local/lib/bats-support/load.bash" ]]; then
    load "/usr/local/lib/bats-support/load.bash"
fi

if [[ -f "/usr/local/lib/bats-assert/load.bash" ]]; then
    load "/usr/local/lib/bats-assert/load.bash"
fi
