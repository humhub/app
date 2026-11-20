#!/usr/bin/env bash
# Runs the integration_test suite on an Android emulator against the backend
# started by up.sh. Used both locally and in CI (.github/workflows/e2e-tests.yml).
#
# Env:
#   DEVICE  adb serial of the emulator (default: emulator-5554)
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
fixtures_file="$script_dir/.e2e_fixtures.env"
export DEVICE="${DEVICE:-emulator-5554}"
upload_file_name="e2e_upload.txt"

if [ ! -f "$fixtures_file" ]; then
  echo "Missing $fixtures_file, run scripts/e2e/up.sh first." >&2
  exit 1
fi
set -a
# shellcheck source=/dev/null
source "$fixtures_file"
set +a

cd "$repo_root"

# The Gradle google-services plugin needs a config file; use a dummy one so
# the tests never touch the production Firebase project.
if [ ! -f android/app/google-services.json ]; then
  cp integration_test/fixtures/google-services.json android/app/google-services.json
fi

logs_dir="$script_dir/logs"
mkdir -p "$logs_dir"
adb -s "$DEVICE" logcat -c
adb -s "$DEVICE" logcat > "$logs_dir/logcat.txt" 2>&1 &
logcat_pid=$!

"$script_dir/grant_permissions.sh" &
grant_pid=$!
trap 'kill "$grant_pid" "$logcat_pid" 2>/dev/null || true' EXIT

flutter test integration_test \
  -d "$DEVICE" \
  --dart-define=E2E_SERVER_URL="$E2E_SERVER_URL" \
  --dart-define=E2E_USERNAME="$E2E_USERNAME" \
  --dart-define=E2E_PASSWORD="$E2E_PASSWORD" \
  --dart-define=E2E_EXTERNAL_LINK_POST_URL="$E2E_EXTERNAL_LINK_POST_URL" \
  --dart-define=E2E_DEEP_LINK_TARGET_URL="$E2E_DEEP_LINK_TARGET_URL" \
  --dart-define=E2E_UPLOAD_FILE_NAME="$upload_file_name"

echo "Checking the shared file reached the backend..."
(cd "$script_dir" && docker compose exec -T humhub /app/yii e2e/seed/assert-upload "$E2E_USERNAME" "$upload_file_name")
