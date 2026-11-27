#!/usr/bin/env bash
# Starts the disposable HumHub backend for the e2e smoke tests, installs it
# unattended and seeds fixtures. Writes the fixture URLs to .e2e_fixtures.env
# (sourced by run_android.sh / run_ios.sh). Safe to re-run: install/seed only
# happen once.
#
# Env:
#   E2E_BACKEND       docker (default, for Android) or native (for iOS), see lib.sh
#   HUMHUB_IMAGE_TAG  humhub/humhub image tag (default: see docker-compose.yml)
#   E2E_BASE_URL      URL the device uses to reach the backend (default:
#                     http://10.0.2.2:8080, the Android emulator's alias for
#                     the host; http://localhost:8080 for the native backend,
#                     as the iOS Simulator shares the host's network)
set -euo pipefail

cd "$(dirname "$0")"
# shellcheck source=lib.sh
source lib.sh

if [ "$E2E_BACKEND" = native ]; then
  E2E_BASE_URL="${E2E_BASE_URL:-http://localhost:8080}"
else
  E2E_BASE_URL="${E2E_BASE_URL:-http://10.0.2.2:8080}"
fi
E2E_USERNAME="${E2E_USERNAME:-e2etester}"
E2E_PASSWORD="${E2E_PASSWORD:-E2e-Pass-1}"
FIXTURES_FILE="$e2e_fixtures_file"

yii() { e2e_yii "$@"; }

if [ "$E2E_BACKEND" = native ]; then
  native/start.sh
else
  echo "Starting HumHub containers..."
  docker compose up -d --wait
fi

if yii settings/list-module admin 2>/dev/null | grep -q installationId; then
  echo "HumHub already installed, skipping install and seed."
else
  echo "Installing HumHub..."
  yii installer/install-db
  yii installer/write-site-config "HumHub E2E" "e2e@example.com"
  yii installer/set-base-url "$E2E_BASE_URL"
  yii installer/create-admin-account admin admin@example.com "$E2E_PASSWORD"

  echo "Creating test user '$E2E_USERNAME'..."
  yii user/create "$E2E_USERNAME" e2etester@example.com E2E Tester
  yii user/set-password "$E2E_USERNAME" "$E2E_PASSWORD"
  yii user/make-admin "$E2E_USERNAME"

  echo "Seeding fixtures..."
  yii module/enable e2e
  # Written to a temp file first, so a failed seed leaves no fixtures file
  # that looks complete.
  {
    echo "E2E_SERVER_URL=$E2E_BASE_URL"
    echo "E2E_USERNAME=$E2E_USERNAME"
    echo "E2E_PASSWORD=$E2E_PASSWORD"
    yii e2e/seed "$E2E_USERNAME"
  } > "$FIXTURES_FILE.tmp"
  mv "$FIXTURES_FILE.tmp" "$FIXTURES_FILE"
fi

if [ ! -f "$FIXTURES_FILE" ]; then
  echo "HumHub is installed but $FIXTURES_FILE is missing; run down.sh and up.sh again." >&2
  exit 1
fi

echo "HumHub is up on http://localhost:${E2E_PORT:-8080} (device URL: $E2E_BASE_URL)"
cat "$FIXTURES_FILE"
