#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/app.sh"

echo "Running application tests..."

cleanup() {
    if [[ -f "$PID_FILE" ]]; then
        app_stop >/dev/null 2>&1 || true
    fi

    rm -f "$PID_FILE"
    rm -f "$LOG_FILE"
}

trap cleanup EXIT

rm -f "$PID_FILE"

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

assert_equals \
    "STOPPED" \
    "$(app_status)" \
    "application initially stopped"

app_start

assert_equals \
    "RUNNING" \
    "$(app_status)" \
    "application running after start"

assert_file_exists \
    "$PID_FILE" \
    "PID file created after start"

assert_file_exists \
    "$LOG_FILE" \
    "log file created after start"

app_stop

assert_equals \
    "STOPPED" \
    "$(app_status)" \
    "application stopped after stop"

assert_file_not_exists \
    "$PID_FILE" \
    "PID file removed after stop"

app_start

old_pid="$(cat "$PID_FILE")"

app_restart

new_pid="$(cat "$PID_FILE")"

assert_equals \
    "RUNNING" \
    "$(app_status)" \
    "application running after restart"

if [[ "$old_pid" != "$new_pid" ]]; then
    echo "PASS: restart created a new process"
else
    echo "FAIL: restart created a new process"
    echo "  PID did not change: $old_pid"
    exit 1
fi

app_stop

echo "All application tests passed."
