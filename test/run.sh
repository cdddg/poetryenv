#!/usr/bin/env bash
# Test runner for poetryenv

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat <<EOF
Usage: ./test.sh [options] [test-file]

Options:
    -h, --help          Show this help
    -v, --verbose       Verbose output (show all test output)
    -f, --failed        Only show failed tests details
    -t, --trace         Show detailed trace (like Python traceback)

Examples:
    ./test.sh                           # Run all tests
    ./test.sh test/basic.bats           # Run specific test file
    ./test.sh -v                        # Run all tests with verbose output
    ./test.sh -f test/global_local.bats # Run with failure details
    ./test.sh -t                        # Run with detailed trace

Test files:
    test/basic.bats              - Basic functionality tests
    test/version_management.bats - Install/uninstall tests
    test/global.bats             - Global version tests
    test/local.bats              - Local version tests
    test/shim.bats               - Poetry shim tests
    test/version_isolation.bats  - Version isolation tests
    test/integration.bats        - Integration workflow tests
EOF
}

# Parse arguments
VERBOSE=0
FAILED_ONLY=0
TRACE=0
TEST_PATH="test/"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -f|--failed)
            FAILED_ONLY=1
            shift
            ;;
        -t|--trace)
            TRACE=1
            shift
            ;;
        *)
            TEST_PATH="$1"
            shift
            ;;
    esac
done

# Build bats command
BATS_CMD="bats"

# Define the desired order of test execution
# If a specific test file is passed as an argument, only that file will be run.
if [[ "$TEST_PATH" != "test/" ]]; then
    TEST_TARGETS=("$TEST_PATH")
else
    TEST_TARGETS=(
        "test/basic.bats"
        "test/version_management.bats"
        "test/global.bats"
        "test/local.bats"
        "test/version_isolation.bats"
        "test/shim.bats"
        "test/integration.bats"
    )
fi

if [[ $TRACE -eq 1 ]]; then
    # Most detailed output - like Python traceback
    BATS_CMD="$BATS_CMD --print-output-on-failure --show-output-of-passing-tests --verbose-run --trace"
elif [[ $VERBOSE -eq 1 ]]; then
    # Verbose output - show ALL test outputs (passing and failing)
    BATS_CMD="$BATS_CMD --show-output-of-passing-tests --verbose-run"
elif [[ $FAILED_ONLY -eq 1 ]]; then
    # Only show failures - like Python traceback
    BATS_CMD="$BATS_CMD --print-output-on-failure"
fi

# Add formatter for better readability
BATS_CMD="$BATS_CMD --formatter pretty"

# Run tests
printf "${GREEN}→ Running tests...${NC}\n"
printf "${YELLOW}Command: ${BATS_CMD} ${TEST_TARGETS[*]}${NC}\n\n"

if $BATS_CMD "${TEST_TARGETS[@]}"; then
    printf "\n${GREEN}✓ All tests passed!${NC}\n"
    exit 0
else
    printf "\n${RED}✗ Some tests failed${NC}\n"
    exit 1
fi
