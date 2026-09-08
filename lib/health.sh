#!/usr/bin/env bash

CONFIG_FILE="$PROJECT_ROOT/config/devops-toolkit.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

get_hostname() {
    hostname
}

get_uptime() {
    uptime -p
}

get_load_average() {
    awk '{print $1, $2, $3}' /proc/loadavg
}

get_cpu_usage() {
    local cpu1
    local cpu2
    local idle1
    local idle2
    local total1
    local total2
    local idle_delta
    local total_delta
    local usage

    cpu1="$(awk '/^cpu / {print $2, $3, $4, $5, $6, $7, $8, $9}' /proc/stat)"

    sleep 1

    cpu2="$(awk '/^cpu / {print $2, $3, $4, $5, $6, $7, $8, $9}' /proc/stat)"

    read -r user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 <<< "$cpu1"
    read -r user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 <<< "$cpu2"

    total1=$((user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1 + steal1))
    total2=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2))

    idle_delta=$((idle2 - idle1))
    total_delta=$((total2 - total1))

    if (( total_delta == 0 )); then
        echo "0"
        return
    fi

    usage=$((100 * (total_delta - idle_delta) / total_delta))

    echo "$usage"
}

get_memory_usage() {
    local total
    local available
    local usage

    total="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
    available="$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)"

    if (( total == 0 )); then
        echo "0"
        return
    fi

    usage=$((100 * (total - available) / total))

    echo "$usage"
}

get_disk_usage() {
    local usage

    usage="$(df -P "$PROJECT_ROOT" | awk 'NR==2 {gsub("%", "", $5); print $5}')"

    echo "$usage"
}

get_status() {
    local value="$1"
    local warning="$2"
    local critical="$3"

    if (( value >= critical )); then
        echo "CRITICAL"
    elif (( value >= warning )); then
        echo "WARNING"
    else
        echo "HEALTHY"
    fi
}

get_overall_status() {
    local cpu_status="$1"
    local memory_status="$2"
    local disk_status="$3"

    if [[ "$cpu_status" == "CRITICAL" ||
          "$memory_status" == "CRITICAL" ||
          "$disk_status" == "CRITICAL" ]]; then
        echo "CRITICAL"
    elif [[ "$cpu_status" == "WARNING" ||
            "$memory_status" == "WARNING" ||
            "$disk_status" == "WARNING" ]]; then
        echo "WARNING"
    else
        echo "HEALTHY"
    fi
}

get_exit_code() {
    local overall_status="$1"

    case "$overall_status" in
        HEALTHY)
            return 0
            ;;

        WARNING)
            return 1
            ;;

        CRITICAL)
            return 2
            ;;

        *)
            return 2
            ;;
    esac
}

health_check() {
    local hostname
    local uptime
    local load_average
    local cpu_usage
    local memory_usage
    local disk_usage
    local cpu_status
    local memory_status
    local disk_status
    local overall_status

    hostname="$(get_hostname)"
    uptime="$(get_uptime)"
    load_average="$(get_load_average)"
    cpu_usage="$(get_cpu_usage)"
    memory_usage="$(get_memory_usage)"
    disk_usage="$(get_disk_usage)"

    cpu_status="$(get_status "$cpu_usage" "$CPU_WARNING" "$CPU_CRITICAL")"
    memory_status="$(get_status "$memory_usage" "$MEMORY_WARNING" "$MEMORY_CRITICAL")"
    disk_status="$(get_status "$disk_usage" "$DISK_WARNING" "$DISK_CRITICAL")"

    overall_status="$(get_overall_status \
        "$cpu_status" \
        "$memory_status" \
        "$disk_status")"

    echo "========================================"
    echo "       DEVOPS TOOLKIT - HEALTH"
    echo "========================================"
    echo
    echo "Hostname       : $hostname"
    echo "Uptime         : $uptime"
    echo "CPU Usage      : ${cpu_usage}%"
    echo "Memory Usage   : ${memory_usage}%"
    echo "Disk Usage     : ${disk_usage}%"
    echo "Load Average   : $load_average"
    echo
    echo "CPU Status     : $cpu_status"
    echo "Memory Status  : $memory_status"
    echo "Disk Status    : $disk_status"
    echo
    echo "Overall Status : $overall_status"
    echo
    echo "========================================"

    get_exit_code "$overall_status"
}
