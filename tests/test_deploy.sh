#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/deploy.sh"

echo "Running deployment tests..."

SSH_CONFIG="$PROJECT_ROOT/apps/ssh-target/sshd_config.test"
SSH_HOST_KEY="$PROJECT_ROOT/apps/ssh-target/ssh_host_ed25519_key"
SSH_PID_FILE="$PROJECT_ROOT/apps/ssh-target/sshd.pid"
SSH_AUTHORIZED_KEYS="$PROJECT_ROOT/apps/ssh-target/.ssh/authorized_keys"

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

    if [[ -f "$SSH_PID_FILE" ]]; then
        sudo kill "$(sudo cat "$SSH_PID_FILE")" \
            >/dev/null 2>&1 || true
    fi

    rm -f "$SSH_CONFIG"
    rm -f "$SSH_PID_FILE"
}

trap cleanup EXIT

mkdir -p "$PROJECT_ROOT/apps/ssh-target/.ssh"

cat > "$SSH_CONFIG" <<EOF
Port $DEPLOY_PORT
ListenAddress $DEPLOY_HOST

HostKey $SSH_HOST_KEY
PidFile $SSH_PID_FILE
AuthorizedKeysFile $SSH_AUTHORIZED_KEYS

PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
StrictModes no

AllowUsers $DEPLOY_USER

Subsystem sftp internal-sftp
EOF

sudo mkdir -p /run/sshd

sudo /usr/sbin/sshd -t -f "$SSH_CONFIG"

sudo /usr/sbin/sshd -E "$PROJECT_ROOT/apps/ssh-target/sshd.log" -f "$SSH_CONFIG"

sleep 1

if ssh "${SSH_OPTIONS[@]}" \
    "$DEPLOY_USER@$DEPLOY_HOST" \
    "echo SSH_OK"; then
    echo "PASS: SSH connection"
else
    echo "FAIL: SSH connection"
    echo
    echo "SSH server log:"
    sudo cat "$PROJECT_ROOT/apps/ssh-target/sshd.log" 2>/dev/null || true
    echo
    echo "SSH process:"
    ps aux | grep '[s]shd' || true
    echo
    echo "Listening port:"
    sudo ss -ltnp | grep ":$DEPLOY_PORT" || true
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
