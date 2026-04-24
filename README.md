# HumHub Mobile App

The official open source mobile app for HumHub.

This repository contains the Flutter app used to access HumHub networks on iPhone, iPad, and Android devices.

## What Is HumHub?

HumHub is open source software for social intranets, internal communities, and collaboration platforms. It is used to organize communication, content, spaces, and user interaction inside a private or branded network.

HumHub can be self-hosted or operated as a managed service.

## What This App Is For

The mobile app provides direct access to a HumHub network from a phone or tablet. It is intended to cover common mobile workflows such as:

- open your HumHub instance quickly
- follow activity streams and spaces
- receive push notifications
- open shared links directly in the app
- upload and share files, photos, and videos
- staying connected away from a desktop browser

## Download

<table>
  <tr>
    <td align="center" width="50%">
      <a href="https://apps.apple.com/us/app/humhub/id6446092274">
        <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" height="56">
      </a>
      <br><br>
      <a href="https://apps.apple.com/us/app/humhub/id6446092274">
        <img src="https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=https%3A%2F%2Fapps.apple.com%2Fus%2Fapp%2Fhumhub%2Fid6446092274" alt="QR code for the HumHub App Store listing" width="180" height="180">
      </a>
    </td>
    <td align="center" width="50%">
      <a href="https://play.google.com/store/apps/details?id=com.humhub.app">
        <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" height="84">
      </a>
      <br><br>
      <a href="https://play.google.com/store/apps/details?id=com.humhub.app">
        <img src="https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dcom.humhub.app" alt="QR code for the HumHub Google Play listing" width="180" height="180">
      </a>
    </td>
  </tr>
</table>

## Development

### Requirements

- Flutter `3.29.0`
- Xcode / CocoaPods for iOS development
- Android SDK for Android development

If you use FVM, the repo is already pinned to Flutter `3.29.0` in `.fvmrc`.

### Get Started

```bash
fvm flutter pub get
```

If you are not using FVM, run:

```bash
flutter pub get
```

### Run The App

Default development entrypoint:

```bash
fvm flutter run
```

The main entrypoint is `lib/main.dart`.

At startup, `HumHub.initApp()` selects one of two app shells:

- `com.humhub.app` starts the default `OpenerApp`
- any other package name starts `FlavoredApp`

### Flavored Builds

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

### Verification

Run the same core checks used in CI:

```bash
fvm flutter test
fvm flutter analyze --no-fatal-warnings --no-fatal-infos
```

Focused test suite:

```bash
fvm flutter test test/opener_test.dart
```

### iOS Notes

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

## Open Source

This project is part of the broader HumHub open source ecosystem.

To learn more about HumHub itself, visit:

- https://www.humhub.com/
- https://github.com/humhub
