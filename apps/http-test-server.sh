#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

while true; do
    printf 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 15\r\n\r\nDevOps Toolkit\n' |
        nc -l 8080
done
