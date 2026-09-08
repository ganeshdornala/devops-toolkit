#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/health.sh"

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo "PASS: $test_name"
    else
        echo "FAIL: $test_name"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        exit 1
    fi
}

echo "Running health tests..."

assert_equals "HEALTHY" "$(get_status 50 70 90)" "value below warning threshold"
assert_equals "WARNING" "$(get_status 70 70 90)" "value at warning threshold"
assert_equals "WARNING" "$(get_status 89 70 90)" "value below critical threshold"
assert_equals "CRITICAL" "$(get_status 90 70 90)" "value at critical threshold"
assert_equals "CRITICAL" "$(get_status 100 70 90)" "value above critical threshold"

assert_equals "HEALTHY" \
    "$(get_overall_status HEALTHY HEALTHY HEALTHY)" \
    "all metrics healthy"

assert_equals "WARNING" \
    "$(get_overall_status HEALTHY WARNING HEALTHY)" \
    "one metric warning"

assert_equals "CRITICAL" \
    "$(get_overall_status HEALTHY WARNING CRITICAL)" \
    "one metric critical"

echo "All health tests passed."
