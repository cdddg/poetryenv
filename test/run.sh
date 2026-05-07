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
Usage: ./test.sh [mode] [verbosity] [test-file]

Modes (mutually exclusive — last one wins):
    --unit              Run unit tests (default)
    --integration       Run integration tests
    --all               Run both

Verbosity:
    -v, --verbose       Show all test output
    -f, --failed        Print output only when a test fails
    -t, --trace         Detailed trace

Other:
    -h, --help          Show this help

Examples:
    ./test.sh                           # Unit (default)
    ./test.sh --integration             # Integration only
    ./test.sh --all                     # Both
    ./test.sh test/basic.bats           # A specific file
    ./test.sh -v                        # Unit, verbose
EOF
}

UNIT_TESTS=(
    "test/basic.bats"
    "test/version_management.bats"
    "test/global.bats"
    "test/local.bats"
    "test/mock_isolation.bats"
    "test/shim.bats"
    "test/workflow.bats"
)

INTEGRATION_TESTS=(
    "test/real_isolation.bats"
)

VERBOSE=0
FAILED_ONLY=0
TRACE=0
MODE="unit"
EXPLICIT_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)        show_help; exit 0 ;;
        --unit)           MODE="unit"; shift ;;
        --integration)    MODE="integration"; shift ;;
        --all)            MODE="all"; shift ;;
        -v|--verbose)     VERBOSE=1; shift ;;
        -f|--failed)      FAILED_ONLY=1; shift ;;
        -t|--trace)       TRACE=1; shift ;;
        *)                EXPLICIT_FILE="$1"; shift ;;
    esac
done

if [[ -n "$EXPLICIT_FILE" ]]; then
    TEST_TARGETS=("$EXPLICIT_FILE")
else
    case "$MODE" in
        unit)        TEST_TARGETS=("${UNIT_TESTS[@]}") ;;
        integration) TEST_TARGETS=("${INTEGRATION_TESTS[@]}") ;;
        all)         TEST_TARGETS=("${UNIT_TESTS[@]}" "${INTEGRATION_TESTS[@]}") ;;
    esac
fi

BATS_CMD="bats"
if [[ $TRACE -eq 1 ]]; then
    BATS_CMD="$BATS_CMD --print-output-on-failure --show-output-of-passing-tests --verbose-run --trace"
elif [[ $VERBOSE -eq 1 ]]; then
    BATS_CMD="$BATS_CMD --show-output-of-passing-tests --verbose-run"
elif [[ $FAILED_ONLY -eq 1 ]]; then
    BATS_CMD="$BATS_CMD --print-output-on-failure"
fi

# `pretty` calls tput and breaks on non-TTY stdout (CI runners have no $TERM).
# Fall back to the default TAP formatter when not attached to a terminal.
if [[ -t 1 ]]; then
    BATS_CMD="$BATS_CMD --formatter pretty"
fi

printf "${GREEN}→ Running tests (${MODE})...${NC}\n"
printf "${YELLOW}Command: ${BATS_CMD} ${TEST_TARGETS[*]}${NC}\n\n"

if $BATS_CMD "${TEST_TARGETS[@]}"; then
    printf "\n${GREEN}✓ All tests passed!${NC}\n"
    exit 0
else
    printf "\n${RED}✗ Some tests failed${NC}\n"
    exit 1
fi
