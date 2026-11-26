#!/usr/bin/env bash
# Runs the integration_test suite on an Android emulator against the backend
# started by up.sh. Used both locally and in CI (.github/workflows/e2e-tests.yml).
#
# Env:
#   DEVICE   adb serial of the emulator (default: emulator-5554)
#   PACKAGE  application id of the app (default: com.humhub.app)
#
# Every test file gets its own screen recording in logs/videos/, and a failing
# test a screenshot in logs/screenshots/ (see integration_test/support/e2e_test.dart).
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
# shellcheck source=lib.sh
source "$script_dir/lib.sh"
fixtures_file="$e2e_fixtures_file"
export DEVICE="${DEVICE:-emulator-5554}"
export PACKAGE="${PACKAGE:-com.humhub.app}"
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
videos_dir="$logs_dir/videos"
screenshots_dir="$logs_dir/screenshots"
rm -rf "$videos_dir" "$screenshots_dir"
mkdir -p "$videos_dir" "$screenshots_dir"
adb -s "$DEVICE" logcat -c
adb -s "$DEVICE" logcat > "$logs_dir/logcat.txt" 2>&1 &

"$script_dir/grant_permissions.sh" &

# Takes a screenshot when a failing test asks for one. The test's own output is
# only printed once it has finished, so watch logcat instead.
adb -s "$DEVICE" logcat -T 1 -v raw -s flutter | while IFS= read -r line; do
  case "$line" in
    *E2E_SCREENSHOT:*)
      name="${line##*E2E_SCREENSHOT:}"
      name="${name//[^a-z0-9-]/}"
      adb -s "$DEVICE" exec-out screencap -p > "$screenshots_dir/$name.png" < /dev/null
      echo "Screenshot of failed test: $screenshots_dir/$name.png"
      ;;
  esac
done &

trap 'kill $(jobs -p) 2>/dev/null || true' EXIT

# Starts recording once the app is running, so the build is not recorded:
# screenrecord stops after 3 minutes and the first build alone takes longer.
start_recording() {
  (
    until adb -s "$DEVICE" shell pidof "$PACKAGE" > /dev/null 2>&1; do sleep 0.5; done
    adb -s "$DEVICE" shell screenrecord --bit-rate 4000000 "/sdcard/e2e_$1.mp4"
  ) &
  recorder_pid=$!
}

stop_recording() {
  local video="/sdcard/e2e_$1.mp4"
  adb -s "$DEVICE" shell pkill -INT screenrecord > /dev/null 2>&1 || true
  # Let screenrecord finish the file; the helper may also still be waiting for
  # an app that never started.
  for _ in $(seq 20); do
    kill -0 "$recorder_pid" 2> /dev/null || break
    sleep 0.25
  done
  pkill -P "$recorder_pid" 2> /dev/null || true
  kill "$recorder_pid" 2> /dev/null || true
  sleep 1
  if adb -s "$DEVICE" shell ls "$video" > /dev/null 2>&1; then
    adb -s "$DEVICE" pull "$video" "$videos_dir/$1.mp4" > /dev/null
    adb -s "$DEVICE" shell rm -f "$video"
  fi
}

status=0
for test_file in integration_test/*_test.dart; do
  name="$(basename "$test_file" .dart)"
  # A leftover app process would start the recording before the build.
  adb -s "$DEVICE" shell am force-stop "$PACKAGE" > /dev/null 2>&1 || true
  start_recording "$name"
  flutter test "$test_file" \
    -d "$DEVICE" \
    --dart-define=E2E_SERVER_URL="$E2E_SERVER_URL" \
    --dart-define=E2E_USERNAME="$E2E_USERNAME" \
    --dart-define=E2E_PASSWORD="$E2E_PASSWORD" \
    --dart-define=E2E_EXTERNAL_LINK_POST_URL="$E2E_EXTERNAL_LINK_POST_URL" \
    --dart-define=E2E_DEEP_LINK_TARGET_URL="$E2E_DEEP_LINK_TARGET_URL" \
    --dart-define=E2E_UPLOAD_FILE_NAME="$upload_file_name" || status=1
  stop_recording "$name"
done

e2e_assert_upload "$E2E_USERNAME" "$upload_file_name" || status=1

exit "$status"
