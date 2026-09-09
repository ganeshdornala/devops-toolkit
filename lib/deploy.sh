#!/usr/bin/env bash

CONFIG_FILE="$PROJECT_ROOT/config/devops-toolkit.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

DEPLOY_SOURCE="$PROJECT_ROOT/apps/test-app.sh"

deploy() {
    require_command ssh
    require_command scp

    if [[ ! -f "$DEPLOY_SOURCE" ]]; then
        log_error "Deployment source not found: $DEPLOY_SOURCE"
        return 1
    fi

    if [[ ! -f "$DEPLOY_KEY" ]]; then
        log_error "Deployment SSH key not found: $DEPLOY_KEY"
        return 1
    fi

    log_info "Checking SSH connection to $DEPLOY_HOST:$DEPLOY_PORT"

    ssh -i "$DEPLOY_KEY" \
        -p "$DEPLOY_PORT" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "$DEPLOY_USER@$DEPLOY_HOST" \
        "mkdir -p '$DEPLOY_TARGET'"

    log_info "Copying application to deployment target"

    scp -i "$DEPLOY_KEY" \
        -P "$DEPLOY_PORT" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "$DEPLOY_SOURCE" \
        "$DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_TARGET/"

    ssh -i "$DEPLOY_KEY" \
        -p "$DEPLOY_PORT" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "$DEPLOY_USER@$DEPLOY_HOST" \
        "chmod +x '$DEPLOY_TARGET/test-app.sh'"

    log_info "Deployment completed successfully"
}

rollback() {
    require_command ssh

    if [[ ! -f "$DEPLOY_KEY" ]]; then
        log_error "Deployment SSH key not found: $DEPLOY_KEY"
        return 1
    fi

    log_info "Rolling back deployment"

    ssh -i "$DEPLOY_KEY" \
        -p "$DEPLOY_PORT" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "$DEPLOY_USER@$DEPLOY_HOST" \
        "rm -f '$DEPLOY_TARGET/test-app.sh'"

    log_info "Rollback completed successfully"
}

deploy_command() {
    deploy
}

rollback_command() {
    rollback
}
