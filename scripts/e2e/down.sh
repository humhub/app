#!/usr/bin/env bash
# Stops the e2e HumHub backend and deletes its data.
#
# Env:
#   E2E_BACKEND  docker (default) or native, see lib.sh
set -euo pipefail

cd "$(dirname "$0")"
# shellcheck source=lib.sh
source lib.sh

if [ "$E2E_BACKEND" = native ]; then
  native/stop.sh
else
  docker compose down -v
fi
rm -f "$e2e_fixtures_file"
