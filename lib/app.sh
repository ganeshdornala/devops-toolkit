#!/usr/bin/env bash

APP_NAME="test-app"
APP_SCRIPT="$PROJECT_ROOT/apps/test-app.sh"
PID_FILE="$PROJECT_ROOT/apps/pids/$APP_NAME.pid"
LOG_FILE="$PROJECT_ROOT/apps/logs/$APP_NAME.log"

app_status() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo "STOPPED"
        return 0
    fi

    local pid
    pid="$(cat "$PID_FILE")"

    if kill -0 "$pid" 2>/dev/null; then
        echo "RUNNING"
    else
        echo "STOPPED"
        rm -f "$PID_FILE"
    fi
}

app_start() {
    if [[ ! -f "$APP_SCRIPT" ]]; then
        log_error "Application script not found: $APP_SCRIPT"
        return 1
    fi

    if [[ -f "$PID_FILE" ]]; then
        local existing_pid
        existing_pid="$(cat "$PID_FILE")"

        if kill -0 "$existing_pid" 2>/dev/null; then
            log_warn "$APP_NAME is already running with PID $existing_pid"
            return 0
        fi

        rm -f "$PID_FILE"
    fi

    nohup "$APP_SCRIPT" >> "$LOG_FILE" 2>&1 &
    local pid=$!

    echo "$pid" > "$PID_FILE"

    log_info "$APP_NAME started with PID $pid"
}

app_stop() {
    if [[ ! -f "$PID_FILE" ]]; then
        log_warn "$APP_NAME is not running"
        return 0
    fi

    local pid
    pid="$(cat "$PID_FILE")"

    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid"

        for _ in {1..10}; do
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi

            sleep 1
        done

        if kill -0 "$pid" 2>/dev/null; then
            log_error "Failed to stop $APP_NAME with PID $pid"
            return 1
        fi

        log_info "$APP_NAME stopped"
    else
        log_warn "$APP_NAME process is no longer running"
    fi

    rm -f "$PID_FILE"
}

app_restart() {
    app_stop
    app_start
}

app_command() {
    local subcommand="${1:-}"

    case "$subcommand" in
        start)
            app_start
            ;;

        stop)
            app_stop
            ;;

        restart)
            app_restart
            ;;

        status)
            app_status
            ;;

        *)
            log_error "Unknown app command: ${subcommand:-none}"
            echo "Usage: devops-toolkit app {start|stop|restart|status}"
            return 1
            ;;
    esac
}
