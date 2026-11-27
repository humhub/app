# E2E smoke tests

Runs the `integration_test/` suite on an Android emulator and an iOS
Simulator against a disposable HumHub instance (official `humhub/humhub`
image + MariaDB).
CI: `.github/workflows/e2e-tests.yml`, only run by `version-release.yml` when
a version tag is pushed; if any job fails, nothing is built or released.

## Run locally

Requires Docker and a running Android emulator **without** Play Store
(`google_apis` image, so adb doesn't need on-screen authorization).

```bash
scripts/e2e/up.sh            # start, install and seed HumHub (re-runnable)
scripts/e2e/run_android.sh   # run the suite (DEVICE=emulator-5554 by default)
scripts/e2e/down.sh          # stop and delete all data
```

- Backend: http://localhost:8080, login `e2etester` / `E2e-Pass-1`.
- The device reaches it at `http://10.0.2.2:8080` (the emulator's alias for
  the host); that is also HumHub's configured base URL.
- Each test file is recorded to `logs/videos/<test>.mp4`, starting when the
  app launches. A failing test also leaves a screenshot of the moment it
  failed in `logs/screenshots/`, named after the test's description (via
  `integration_test/support/e2e_test.dart`). In CI both are in the
  `e2e-android-logs` / `e2e-ios-logs` artifacts, kept for 7 days.
- Pick a HumHub version with `HUMHUB_IMAGE_TAG=1.19 scripts/e2e/up.sh`
  (run `down.sh` first when switching).
- The image is amd64-only; on Apple Silicon it runs under emulation.

## Run locally on iOS

GitHub's Apple Silicon macOS runners can't run Docker, so for iOS HumHub runs
natively: PHP's built-in server and MariaDB on the Mac, with HumHub copied
out of the same `humhub/humhub` image (`native/start.sh`). The simulator
reaches it at `http://localhost:8080`.

Requires Xcode, PHP 8.2+ (exif, intl, zip, pdo_mysql, gd, mbstring, curl)
and `brew install mariadb crane wix/brew/applesimutils`.

```bash
E2E_BACKEND=native scripts/e2e/up.sh     # start, install and seed HumHub
scripts/e2e/run_ios.sh                   # run the suite (SIMULATOR=<udid> optional)
scripts/e2e/run_ios.sh integration_test/login_test.dart   # or single files
E2E_BACKEND=native scripts/e2e/down.sh   # stop and delete all data
```

`run_ios.sh` creates and reuses a simulator named `humhub-e2e`, and grants
the notification permission up front, as the test can't answer the alert.
By default it runs `integration_test/all_test.dart`, i.e. every test in one
app, since each `flutter test` file means another Xcode build of a few
minutes. Videos are then named after the test's description.

## Android version compatibility

The `android_compat` job in `.github/workflows/e2e-tests.yml` runs the app
launch test (`integration_test/app_launch_test.dart`) on one emulator per API
level, from the app's minSdk (24) up to its targetSdk (36), see
humhub/app#189. It runs alongside the other e2e jobs.
To check one level locally, start an emulator with that API level and run:

```bash
scripts/e2e/run_android.sh integration_test/app_launch_test.dart
```

## What's where

- `docker-compose.yml` – HumHub + MariaDB, plain HTTP on :8080.
- `seed_module/` – tiny HumHub module mounted into the container; its console
  commands create the fixture space/post (`e2e/seed`) and verify the uploaded
  file (`e2e/seed/assert-upload`).
- `lib.sh` – shared helpers; `E2E_BACKEND` selects `docker` (default) or
  `native`.
- `native/` – the native backend for iOS (`start.sh`, `stop.sh`, router for
  PHP's built-in server).
- `up.sh` – unattended install, test user, fixtures → `.e2e_fixtures.env`
  (`.e2e_fixtures.native.env` for the native backend).
- `run_android.sh [test_file...]` – runs each test file separately with a screen recording,
  passes the fixtures to the tests via `--dart-define`,
  grants runtime permissions in the background (`grant_permissions.sh`) so
  the app's startup permission request doesn't block, writes `logs/logcat.txt`,
  then checks the upload reached the backend.
- `run_ios.sh` – the same for the iOS Simulator, all tests in one run
  (`integration_test/all_test.dart`), recording each test on the markers
  `e2e_test.dart` prints.
- `integration_test/fixtures/google-services.json`, `GoogleService-Info.plist`
  – dummy Firebase configs so the app builds without secrets and never talks
  to the real project.
