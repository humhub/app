# App Icon Badge

The app icon shows the unread count of the HumHub network, like a mail app: the number of unseen
notifications plus what other modules add, e.g. unread conversations of the mail module. A count of `0`
removes the badge.

The count is calculated by the [`fcm-push`](https://github.com/humhub/fcm-push) module of the network
(`MessagingService::getNotificationCount()`, extensible via `MessagingService::EVENT_NOTIFICATION_COUNT`).
The app only displays it, see `lib/util/app_badge.dart`.

## How the count reaches the app

| Source | When | Applied by |
|---|---|---|
| `aps.badge` of a push message | App in background or terminated (iOS) | iOS itself |
| `notification_count` of a push message (data) | App in foreground (iOS, Android) | `PushPlugin`, `FirebaseMessaging.onMessage` |
| | App in background or terminated (Android) | `firebaseMessagingBackgroundHandler` |
| `updateNotificationCount` channel message | Every page load in the web view, and when the count changes on the page (e.g. notifications marked as seen by opening the dropdown) | `WebView` / `WebViewF` |
| `unregisterFcmDevice` channel message | First page after logout | `WebView` / `WebViewF`, removes the badge |

Push messages carry the count in two flavors:

- **Visible messages**, sent for every new notification.
- **Silent (data-only) messages**, sent when the count changes, e.g. after notifications or conversations were read.
  The server waits 10 minutes before sending one, to collapse several changes. Only the Proxy driver (HumHub
  community app) sends them.

The channel message is what corrects the badge right away while the network is open in the app, so it is
already correct when the user leaves the app.

```json
{"type": "updateNotificationCount", "count": 3}
```

The badge is deliberately **not** reset when the app starts. iOS also starts the app in the background to
deliver silent push messages, so a reset in `main()` would remove the badge the message just set.

## Server requirements

| What | Requires |
|---|---|
| Badge from visible push messages while the app is closed | Fcm driver: fcm-push 2.3.3 ([humhub/fcm-push#115](https://github.com/humhub/fcm-push/pull/115)). Proxy driver: set by push.humhub.com |
| Badge corrected while the network is open in the app | fcm-push sending `updateNotificationCount` ([humhub/fcm-push#116](https://github.com/humhub/fcm-push/pull/116)) |
| Badge corrected after reading in the browser | Silent push messages (Proxy driver only) |

With an older fcm-push, the app shows the count of the latest push message until the next one arrives.

## Platforms

- **iOS:** Numeric badge. Requires the notification permission, which the app requests on start.
- **Android:** Depends on the launcher. Launchers supported by [`app_badge_plus`](https://pub.dev/packages/app_badge_plus)
  (e.g. Samsung, Huawei, Sony) show the count. Most others (e.g. Pixel) show a dot while the app has a notification in
  the notification shade, and some count the notifications instead (Launcher3 adds up their `number`).
  Notifications shown by the app itself therefore do not carry the unread count as `number`.

## Testing

- **Without push:** As administrator, open *Administration → Settings → Advanced → Mobile App → Debug* in the
  app and use *Test Update Notification Count*. It sends a random count between 100 and 200.
- **Push:** Let another user trigger a notification while the app is closed, then open the app and the
  notification dropdown. Leave the app: the badge must be gone (or show the conversation count).
- **Logout:** Log out in the app: the badge must be gone.

## Limitations

- The badge belongs to the app, not to a network. If the device is registered for push messages of several
  networks, the badge shows the count of the network that sent the latest message.
- On Android, numeric badges depend on the launcher, see above.
