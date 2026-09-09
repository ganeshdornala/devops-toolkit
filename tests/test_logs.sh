#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/logs.sh"

echo "Running log collection tests..."

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

assert_file_exists() {
    local file="$1"
    local test_name="$2"

    if [[ -f "$file" ]]; then
        echo "PASS: $test_name"
    else
        echo "FAIL: $test_name"
        echo "  File not found: $file"
        exit 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local test_name="$2"

    if [[ ! -f "$file" ]]; then
        echo "PASS: $test_name"
    else
        echo "FAIL: $test_name"
        echo "  File should not exist: $file"
        exit 1
    fi
}

cleanup() {
    rm -f "$APP_LOG"
    rm -f "$LOG_ARCHIVE_DIR"/"${APP_NAME}"_test.tar.gz
}

trap cleanup EXIT

mkdir -p "$(dirname "$APP_LOG")"
mkdir -p "$LOG_ARCHIVE_DIR"

rm -f "$APP_LOG"

if logs_collect >/dev/null 2>&1; then
    echo "FAIL: collection should fail when log is missing"
    exit 1
else
    echo "PASS: collection fails when log is missing"
fi

assert_file_not_exists \
    "$APP_LOG" \
    "application log remains absent"

echo "Test log entry" > "$APP_LOG"

assert_file_exists \
    "$APP_LOG" \
    "application log exists"

before_count="$(find "$LOG_ARCHIVE_DIR" -maxdepth 1 -type f -name "${APP_NAME}_*.tar.gz" | wc -l)"

logs_collect >/dev/null

after_count="$(find "$LOG_ARCHIVE_DIR" -maxdepth 1 -type f -name "${APP_NAME}_*.tar.gz" | wc -l)"

if (( after_count > before_count )); then
    echo "PASS: log archive created"
else
    echo "FAIL: log archive created"
    echo "  Archives before: $before_count"
    echo "  Archives after:  $after_count"
    exit 1
fi

latest_archive="$(find "$LOG_ARCHIVE_DIR" -maxdepth 1 -type f -name "${APP_NAME}_*.tar.gz" -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d' ' -f2-)"

assert_file_exists \
    "$latest_archive" \
    "latest log archive exists"

if tar -tzf "$latest_archive" | grep -qx "$APP_NAME.log"; then
    echo "PASS: archive contains application log"
else
    echo "FAIL: archive contains application log"
    exit 1
fi

rm -f "$APP_LOG"

echo "All log collection tests passed."
