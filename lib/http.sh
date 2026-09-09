#!/usr/bin/env bash

HTTP_DEFAULT_URL="http://localhost:8080"

http_health_check() {
    local url="${1:-$HTTP_DEFAULT_URL}"
    local http_code

    if ! http_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$url")"; then
        log_error "HTTP health check failed: $url"
        return 1
    fi

    if [[ "$http_code" == "200" ]]; then
        echo "HEALTHY"
        return 0
    fi

    echo "UNHEALTHY"
    log_error "HTTP health check returned status $http_code: $url"
    return 1
}

http_command() {
    local subcommand="${1:-}"

    case "$subcommand" in
        health-check)
            http_health_check "${2:-$HTTP_DEFAULT_URL}"
            ;;

        *)
            log_error "Unknown http command: ${subcommand:-none}"
            echo "Usage: devops-toolkit http health-check [url]"
            return 1
            ;;
    esac
}
