# Contributing

Thanks for contributing to the HumHub mobile app.

## How To Contribute

1. [Create an issue](https://github.com/humhub/app/issues) to describe your idea. 
2. Fork the repository and create a branch for your change.
3. Keep changes focused and avoid mixing unrelated fixes in one pull request.
4. Run the relevant verification steps before opening a pull request.
5. Open a pull request with a clear description of the problem, the change, and any testing you ran.

For larger changes, bug fixes with behavior impact, or platform-specific work, include enough context in the pull request so reviewers can reproduce and validate the change.

## Requirements

- Flutter `3.29.0`
- Xcode / CocoaPods for iOS development
- Android SDK for Android development

If you use FVM, the repo is already pinned to Flutter `3.29.0` in `.fvmrc`.

## Get Started

```bash
fvm flutter pub get
```

If you are not using FVM, run:

```bash
flutter pub get
```

## Run The App

Default development entrypoint:

```bash
fvm flutter run
```

The main entrypoint is `lib/main.dart`.

At startup, `HumHub.initApp()` selects one of two app shells:

- `com.humhub.app` starts the default `OpenerApp`
- any other package name starts `FlavoredApp`

## Flavored Builds

Flavored mode requires `assets/.env`.

The env-backed values currently used by the app are:

- `MANIFEST_URL`
- `DISPLAY`
- `START_URL`
- `SHORT_NAME`
- `NAME`
- `BACKGROUND_COLOR`
- `THEME_COLOR`

If `assets/.env` is missing, flavored mode should not be expected to run correctly.

## Verification

Run the same core checks used in CI:

```bash
fvm flutter test
fvm flutter analyze --no-fatal-warnings --no-fatal-infos
```

Focused test suite:

```bash
fvm flutter test test/opener_test.dart
```

## iOS Notes

`flutter pub get` must be run before manual `pod install` because `ios/Podfile` depends on Flutter-generated files.

If CocoaPods gets out of sync, use this order:

```bash
flutter clean
flutter pub get
rm -rf ios/Pods ios/Podfile.lock
cd ios
pod deintegrate
pod repo update
pod install --repo-update
```
