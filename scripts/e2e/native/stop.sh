#!/usr/bin/env bash
# Stops the native e2e backend and deletes its data (database and installed
# HumHub). The downloaded HumHub copy in .cache/ is kept; MariaDB keeps running.
set -euo pipefail

native_dir="$(cd "$(dirname "$0")" && pwd)"
server_pid_file="$native_dir/.server.pid"

if [ -f "$server_pid_file" ]; then
  kill "$(cat "$server_pid_file")" 2> /dev/null || true
  rm -f "$server_pid_file"
fi
if mariadb-admin ping > /dev/null 2>&1; then
  mariadb -e "DROP DATABASE IF EXISTS humhub"
fi
rm -rf "$native_dir/.humhub"
