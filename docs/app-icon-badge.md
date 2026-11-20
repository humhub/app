# App Icon Badge

The app icon shows the unread count of the HumHub networks the app is connected to: the number of unseen
notifications plus what other modules add, e.g. unread conversations of the mail module. With several networks,
the badge shows their sum, and the network picker shows the count of each network. A sum of `0` removes the badge.

Each network calculates its own count in the [`fcm-push`](https://github.com/humhub/fcm-push) module
(`MessagingService::getNotificationCount()`, extensible via `MessagingService::EVENT_NOTIFICATION_COUNT`).
The app keeps one count per network and shows the sum, see `lib/util/unread_counts.dart`.

## The count store

`UnreadCounts` stores one count per network, keyed by the `startUrl` of its manifest like the history, in
`shared_preferences`. It does not care where a count comes from, so other sources, e.g. a REST API, can feed it
later.

- **Known networks:** On app start and whenever the history changes, the store is aligned with the history
  (`UnreadCounts.sync()`). New networks start at `0`, the counts of removed networks are dropped. A flavored app
  knows exactly one network, the one from `assets/.env`.
- **App icon:** Every change of a count sets the badge to the sum. Aligning with the history only touches the
  badge if a removed network had unread items.
- **Background isolate:** On Android, push messages in the background are handled in a separate isolate. It
  reads and writes the same store. Every change reads the stored counts first, and the network picker reloads
  them when the app comes back to the foreground.

## How the counts reach the app

| Source | Attributed to | Applied by |
|---|---|---|
| `updateNotificationCount` channel message, sent by the web view on every page load and when the count changes on the page | the network open in the web view | `WebView` / `WebViewF` |
| `notification_count` of a push message in the foreground (iOS, Android) | the network of the message's `url` (`go.humhub.com` links unwrapped) | `PushPlugin`, `FirebaseMessaging.onMessage` |
| `notification_count` of a push message in the background (Android; iOS: silent messages only) | as above | `firebaseMessagingBackgroundHandler` |
| Opening a network in the app, and the `unregisterFcmDevice` channel message, sent on the first page after logout | the network open in the web view, set to `0` | `WebView` / `WebViewF` |

A count that cannot be attributed is only applied if the app knows exactly one network. This concerns silent
push messages, which carry no `url`, and messages of networks that are not in the history.

```json
{"type": "updateNotificationCount", "count": 3}
```

Opening a network in the app sets its count to `0`. A network sending `updateNotificationCount` replaces that
with what is really unread as soon as its page has loaded. For a network that does not send it yet, the count thus
means "new since last opened", like the badge did when the app still reset it on every start. The badge as a whole
is no longer reset on app start, so the counts of networks that were not opened stay.

## Server requirements

| What | Requires |
|---|---|
| Badge from visible push messages while the app is closed | Fcm driver: fcm-push 2.3.3 ([humhub/fcm-push#115](https://github.com/humhub/fcm-push/pull/115)). Proxy driver: set by push.humhub.com |
| Real unread count while the network is open in the app, instead of `0` | fcm-push sending `updateNotificationCount` ([humhub/fcm-push#116](https://github.com/humhub/fcm-push/pull/116)) |
| Counts corrected after reading in the browser | Silent push messages (Proxy driver only); with several networks only once they carry the network's URL |

## Platforms

- **iOS:** Numeric badge. Requires the notification permission, which the app requests on start. While the app
  is closed, iOS sets the badge from `aps.badge` of a push message itself, without running app code. That is the
  count of the sending network only, not the sum; the app sets the sum again with the next count change, at the
  latest when a network is opened in the app. After the
  user has swiped the app away, iOS does not run app code for push messages at all.
- **Android:** Depends on the launcher. Launchers supported by [`app_badge_plus`](https://pub.dev/packages/app_badge_plus)
  (e.g. Samsung, Huawei, Sony) show the count. Most others (e.g. Pixel) show a dot while the app has a notification
  in the notification shade. Notifications shown by the app itself do not carry the count as `number`: some
  launchers are said to add up `number` over all notifications of an app, which would overcount. This has not been
  verified.

## Testing

- **Without push:** As administrator, open *Administration → Settings → Advanced → Mobile App → Debug* in the
  app and use *Test Update Notification Count*. It sends a random count between 100 and 200. Leave the app: the
  icon shows it, and the network picker shows it at that network.
- **Several networks:** Repeat in a second network. The icon shows the sum, the network picker each count.
- **Push:** Let another user trigger a notification while the app is closed, then open the app and the
  notification dropdown. Leave the app: the count of that network must be gone.
- **Logout and removal:** Log out of a network, or remove it from the network picker: its count is gone from
  the sum.

## Limitations

- Silent push messages carry no network, so with several networks they are ignored until fcm-push and
  push.humhub.com add the network's URL to them.
- On iOS, the badge set by the OS while the app is closed shows the count of one network, see above. A Notification
  Service Extension could correct it, but is left out until the planned REST API integration.
- On Android, numeric badges depend on the launcher, see above.
