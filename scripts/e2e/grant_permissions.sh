#!/usr/bin/env bash
# Keeps granting the app's runtime permissions while the tests run.
#
# HumHub.initApp() awaits PermissionHandler.requestPermissions, so an
# unanswered system dialog would block app startup. `flutter test`
# reinstalls the app for every test file, so this loops until killed.
set -uo pipefail

PACKAGE="${PACKAGE:-com.humhub.app}"
DEVICE="${DEVICE:-emulator-5554}"
PERMISSIONS=(
  android.permission.POST_NOTIFICATIONS
  android.permission.CAMERA
  android.permission.RECORD_AUDIO
  android.permission.READ_MEDIA_IMAGES
  android.permission.READ_MEDIA_VIDEO
)

while true; do
  if adb -s "$DEVICE" shell pm path "$PACKAGE" >/dev/null 2>&1; then
    for permission in "${PERMISSIONS[@]}"; do
      adb -s "$DEVICE" shell pm grant "$PACKAGE" "$permission" >/dev/null 2>&1
    done
  fi
  sleep 0.5
done
