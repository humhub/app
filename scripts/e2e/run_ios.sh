#!/usr/bin/env bash
# Runs the integration_test suite on an iOS Simulator against the native
# backend started by `E2E_BACKEND=native up.sh`. Used both locally and in CI
# (.github/workflows/e2e-tests.yml).
#
# Env:
#   SIMULATOR  UDID of the simulator to use (default: a simulator named
#              "humhub-e2e", created with the newest iOS runtime if missing)
#   PACKAGE    bundle id of the app (default: com.humhub.app)
#
# Usage: run_ios.sh [test_file...]
#   By default runs integration_test/all_test.dart, i.e. every test in one app
#   build, as each `flutter test` file means another few-minute Xcode build.
#   Pass single files to run them separately (e.g. to rule out state leaking
#   from one test into the next).
#
# Every test gets its own screen recording in logs/videos/, and a failing test
# a screenshot in logs/screenshots/ (see integration_test/support/e2e_test.dart).
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
export E2E_BACKEND="${E2E_BACKEND:-native}"
# shellcheck source=lib.sh
source "$script_dir/lib.sh"
fixtures_file="$e2e_fixtures_file"
export PACKAGE="${PACKAGE:-com.humhub.app}"
upload_file_name="e2e_upload.txt"

if [ ! -f "$fixtures_file" ]; then
  echo "Missing $fixtures_file, run E2E_BACKEND=$E2E_BACKEND scripts/e2e/up.sh first." >&2
  exit 1
fi
set -a
# shellcheck source=/dev/null
source "$fixtures_file"
set +a

cd "$repo_root"

# Firebase needs a config file; use a dummy one so the tests never touch the
# production Firebase project.
if [ ! -f ios/GoogleService-Info.plist ]; then
  cp integration_test/fixtures/GoogleService-Info.plist ios/GoogleService-Info.plist
fi

if [ -z "${SIMULATOR:-}" ]; then
  SIMULATOR="$(xcrun simctl list devices -j | python3 -c '
import json, sys
for devices in json.load(sys.stdin)["devices"].values():
    for device in devices:
        if device["name"] == "humhub-e2e" and device["isAvailable"]:
            print(device["udid"])
            sys.exit()
')"
fi
if [ -z "$SIMULATOR" ]; then
  # The newest iOS runtime and its newest plain "iPhone <number>".
  read -r runtime device_type < <(xcrun simctl list runtimes -j | python3 -c '
import json, re, sys
runtime = [r for r in json.load(sys.stdin)["runtimes"] if r["platform"] == "iOS" and r["isAvailable"]][-1]
phones = [(int(m.group(1)), d["identifier"]) for d in runtime["supportedDeviceTypes"]
          if (m := re.fullmatch(r"iPhone (\d+)", d["name"]))]
print(runtime["identifier"], max(phones)[1])
')
  echo "Creating simulator humhub-e2e ($device_type, $runtime)..."
  SIMULATOR="$(xcrun simctl create humhub-e2e "$device_type" "$runtime")"
fi
export SIMULATOR
# Boots while the app builds.
(
  xcrun simctl boot "$SIMULATOR" 2> /dev/null || true
  xcrun simctl bootstatus "$SIMULATOR" -b > /dev/null
) &
boot_pid=$!

logs_dir="$script_dir/logs"
videos_dir="$logs_dir/videos"
screenshots_dir="$logs_dir/screenshots"
rm -rf "$videos_dir" "$screenshots_dir"
mkdir -p "$videos_dir" "$screenshots_dir"

if [ $# -eq 0 ]; then
  set -- integration_test/all_test.dart
fi
dart_defines=(
  --dart-define=E2E_SERVER_URL="$E2E_SERVER_URL"
  --dart-define=E2E_USERNAME="$E2E_USERNAME"
  --dart-define=E2E_PASSWORD="$E2E_PASSWORD"
  --dart-define=E2E_EXTERNAL_LINK_POST_URL="$E2E_EXTERNAL_LINK_POST_URL"
  --dart-define=E2E_DEEP_LINK_TARGET_URL="$E2E_DEEP_LINK_TARGET_URL"
  --dart-define=E2E_UPLOAD_FILE_NAME="$upload_file_name"
)

# HumHub.initApp() awaits the notification permission request, and the test
# can't answer the system alert. So the app is installed and the permission
# granted before `flutter test`, which installs over it (keeping the
# permission). Built with the same target and defines as the first test file,
# so the build in `flutter test` has little left to do.
echo "Building the app for the simulator..."
flutter build ios --simulator --debug --target "$1" "${dart_defines[@]}" 2>&1 | tee "$logs_dir/ios_build.txt"
wait "$boot_pid"

install_app() {
  xcrun simctl install "$SIMULATOR" build/ios/iphonesimulator/Runner.app
  applesimutils --byId "$SIMULATOR" --bundle "$PACKAGE" --setPermissions notifications=YES > /dev/null
}

xcrun simctl spawn "$SIMULATOR" log stream --level debug --style compact \
  --predicate 'process == "Runner"' > "$logs_dir/simulator.log" 2>&1 &

recorder_pid=

start_recording() {
  xcrun simctl io "$SIMULATOR" recordVideo --codec=h264 --force "$videos_dir/$1.mp4" > /dev/null 2>&1 < /dev/null &
  recorder_pid=$!
}

stop_recording() {
  [ -n "$recorder_pid" ] || return 0
  # SIGINT lets recordVideo finish the file.
  kill -INT "$recorder_pid" 2> /dev/null || true
  for _ in $(seq 40); do
    kill -0 "$recorder_pid" 2> /dev/null || break
    sleep 0.25
  done
  kill "$recorder_pid" 2> /dev/null || true
  recorder_pid=
}

# Records each test and takes a screenshot when a failing test asks for one,
# on the markers integration_test/support/e2e_test.dart prints. The test's own
# output is only printed once it has finished, so watch the device log instead.
xcrun simctl spawn "$SIMULATOR" log stream --style compact \
  --predicate 'eventMessage CONTAINS "E2E_"' 2> /dev/null | while IFS= read -r line; do
  marker="$(grep -oE 'E2E_[A-Z_]+:[a-z0-9-]+' <<< "$line" || true)"
  name="${marker#*:}"
  case "$marker" in
    E2E_TEST_START:*)
      stop_recording
      start_recording "$name"
      ;;
    E2E_TEST_END:*)
      stop_recording
      ;;
    E2E_SCREENSHOT:*)
      xcrun simctl io "$SIMULATOR" screenshot "$screenshots_dir/$name.png" > /dev/null 2>&1 < /dev/null
      echo "Screenshot of failed test: $screenshots_dir/$name.png"
      ;;
  esac
done &

trap 'kill $(jobs -p) 2>/dev/null || true' EXIT

status=0
install_app
# --no-uninstall keeps the app, and with it the permission, between files.
flutter test "$@" -d "$SIMULATOR" --no-uninstall "${dart_defines[@]}" || status=1

# A test that hit its own timeout prints no end marker; finish its video.
sleep 3
pkill -INT -f "recordVideo.*$videos_dir" 2> /dev/null && sleep 3

e2e_assert_upload "$E2E_USERNAME" "$upload_file_name" || status=1

exit "$status"
