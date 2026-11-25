# E2E smoke tests

Runs the `integration_test/` suite on an Android emulator against a
disposable HumHub instance (official `humhub/humhub` Docker image + MariaDB).
CI: `.github/workflows/e2e-tests.yml` (PRs, manual runs, and as a gate in
`version-release.yml`).

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
  `e2e-android-logs` artifact, kept for 7 days.
- Pick a HumHub version with `HUMHUB_IMAGE_TAG=1.19 scripts/e2e/up.sh`
  (run `down.sh` first when switching).
- The image is amd64-only; on Apple Silicon it runs under emulation.

## What's where

- `docker-compose.yml` – HumHub + MariaDB, plain HTTP on :8080.
- `seed_module/` – tiny HumHub module mounted into the container; its console
  commands create the fixture space/post (`e2e/seed`) and verify the uploaded
  file (`e2e/seed/assert-upload`).
- `up.sh` – unattended install, test user, fixtures → `.e2e_fixtures.env`.
- `run_android.sh` – runs each test file separately with a screen recording,
  passes the fixtures to the tests via `--dart-define`,
  grants runtime permissions in the background (`grant_permissions.sh`) so
  the app's startup permission request doesn't block, writes `logs/logcat.txt`,
  then checks the upload reached the backend.
- `integration_test/fixtures/google-services.json` – dummy Firebase config so
  the app builds without secrets and never talks to the real project.
