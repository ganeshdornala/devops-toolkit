#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/http.sh"

TEST_PORT=18080
TEST_URL="http://localhost:$TEST_PORT"

echo "Running HTTP health check tests..."

cleanup() {
    if [[ -n "${SERVER_PID:-}" ]]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT

start_test_server() {
    (
        while true; do
            printf 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 15\r\n\r\nDevOps Toolkit\n' |
                nc -l "$TEST_PORT"
        done
    ) &

    SERVER_PID=$!

    sleep 1
}

start_test_server

if http_health_check "$TEST_URL" >/dev/null; then
    echo "PASS: healthy endpoint returns success"
else
    echo "FAIL: healthy endpoint returns success"
    exit 1
fi

if http_health_check "http://localhost:19999" >/dev/null 2>&1; then
    echo "FAIL: unavailable endpoint returns failure"
    exit 1
else
    echo "PASS: unavailable endpoint returns failure"
fi

echo "All HTTP health check tests passed."
