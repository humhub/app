#!/usr/bin/env bash
# Stops the e2e HumHub backend and deletes its data.
set -euo pipefail

cd "$(dirname "$0")"

docker compose down -v
rm -f .e2e_fixtures.env
