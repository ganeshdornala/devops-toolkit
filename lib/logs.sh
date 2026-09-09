#!/usr/bin/env bash

APP_NAME="test-app"
APP_LOG="$PROJECT_ROOT/apps/logs/$APP_NAME.log"
LOG_ARCHIVE_DIR="$PROJECT_ROOT/logs"

logs_collect() {
    if [[ ! -f "$APP_LOG" ]]; then
        log_error "Application log not found: $APP_LOG"
        return 1
    fi

    mkdir -p "$LOG_ARCHIVE_DIR"

    local timestamp
    local archive_file

    timestamp="$(date '+%Y%m%d_%H%M%S')"
    archive_file="$LOG_ARCHIVE_DIR/${APP_NAME}_${timestamp}.tar.gz"

    tar -czf "$archive_file" -C "$(dirname "$APP_LOG")" "$(basename "$APP_LOG")"

    log_info "Log archive created: $archive_file"
}

logs_command() {
    local subcommand="${1:-}"

    case "$subcommand" in
        collect)
            logs_collect
            ;;

        *)
            log_error "Unknown logs command: ${subcommand:-none}"
            echo "Usage: devops-toolkit logs collect"
            return 1
            ;;
    esac
}
