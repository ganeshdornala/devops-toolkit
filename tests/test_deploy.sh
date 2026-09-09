#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/deploy.sh"

CI_DEPLOY_USER="devops-ci"
CI_DEPLOY_HOME="/home/$CI_DEPLOY_USER"
CI_DEPLOY_TARGET="$CI_DEPLOY_HOME/deployments/devops-toolkit"

DEPLOY_USER="$CI_DEPLOY_USER"
DEPLOY_TARGET="$CI_DEPLOY_TARGET"

echo "Running deployment tests..."

SSH_CONFIG="$PROJECT_ROOT/apps/ssh-target/sshd_config.test"
SSH_HOST_KEY="$PROJECT_ROOT/apps/ssh-target/ssh_host_ed25519_key"
SSH_PID_FILE="$PROJECT_ROOT/apps/ssh-target/sshd.pid"
SSH_LOG_FILE="$PROJECT_ROOT/apps/ssh-target/sshd.log"

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

    sudo userdel -r "$CI_DEPLOY_USER" \
        >/dev/null 2>&1 || true

    rm -f "$SSH_CONFIG"
    rm -f "$SSH_PID_FILE"
    rm -f "$SSH_LOG_FILE"
}

trap cleanup EXIT

sudo useradd \
    --create-home \
    --shell /bin/bash \
    "$CI_DEPLOY_USER"

echo "$CI_DEPLOY_USER:ci-test-password" | sudo chpasswd

mkdir -p "$PROJECT_ROOT/apps/ssh-target/.ssh"

cat > "$SSH_CONFIG" <<EOF
Port $DEPLOY_PORT
ListenAddress $DEPLOY_HOST

HostKey $SSH_HOST_KEY
PidFile $SSH_PID_FILE
AuthorizedKeysFile $CI_DEPLOY_HOME/.ssh/authorized_keys

PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
StrictModes no

AllowUsers $DEPLOY_USER

Subsystem sftp internal-sftp
EOF

sudo mkdir -p "$CI_DEPLOY_HOME/.ssh"

sudo cp "$DEPLOY_KEY.pub" \
    "$CI_DEPLOY_HOME/.ssh/authorized_keys"

sudo chown -R "$CI_DEPLOY_USER:$CI_DEPLOY_USER" \
    "$CI_DEPLOY_HOME/.ssh"

sudo chmod 700 "$CI_DEPLOY_HOME/.ssh"
sudo chmod 600 "$CI_DEPLOY_HOME/.ssh/authorized_keys"

sudo mkdir -p /run/sshd

sudo /usr/sbin/sshd -t -f "$SSH_CONFIG"

sudo /usr/sbin/sshd -E "$SSH_LOG_FILE" -f "$SSH_CONFIG"

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
