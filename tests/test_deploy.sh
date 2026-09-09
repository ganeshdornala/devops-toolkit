#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/deploy.sh"

echo "Running deployment tests..."

SSH_OPTIONS=(
    -i "$DEPLOY_KEY"
    -p "$DEPLOY_PORT"
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
)

cleanup() {
    ssh "${SSH_OPTIONS[@]}" \
        "$DEPLOY_USER@$DEPLOY_HOST" \
        "rm -f '$DEPLOY_TARGET/test-app.sh'" \
        >/dev/null 2>&1 || true

    if [[ -f "$PROJECT_ROOT/apps/ssh-target/sshd.pid" ]]; then
        sudo kill "$(sudo cat "$PROJECT_ROOT/apps/ssh-target/sshd.pid")" \
            >/dev/null 2>&1 || true
    fi
}

trap cleanup EXIT

sudo /usr/sbin/sshd -f "$PROJECT_ROOT/apps/ssh-target/sshd_config"

sleep 1

if ssh "${SSH_OPTIONS[@]}" \
    "$DEPLOY_USER@$DEPLOY_HOST" \
    "echo SSH_OK" >/dev/null 2>&1; then
    echo "PASS: SSH connection"
else
    echo "FAIL: SSH connection"
    exit 1
fi

deploy >/dev/null

if ssh "${SSH_OPTIONS[@]}" \
    "$DEPLOY_USER@$DEPLOY_HOST" \
    "test -f '$DEPLOY_TARGET/test-app.sh'"; then
    echo "PASS: application deployed"
else
    echo "FAIL: application deployed"
    exit 1
fi

if ssh "${SSH_OPTIONS[@]}" \
    "$DEPLOY_USER@$DEPLOY_HOST" \
    "test -x '$DEPLOY_TARGET/test-app.sh'"; then
    echo "PASS: deployed application is executable"
else
    echo "FAIL: deployed application is executable"
    exit 1
fi

rollback >/dev/null

if ssh "${SSH_OPTIONS[@]}" \
    "$DEPLOY_USER@$DEPLOY_HOST" \
    "test ! -f '$DEPLOY_TARGET/test-app.sh'"; then
    echo "PASS: rollback removes application"
else
    echo "FAIL: rollback removes application"
    exit 1
fi

echo "All deployment tests passed."
