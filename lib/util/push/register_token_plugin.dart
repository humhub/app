import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/web_view_global_controller.dart';
import 'package:loggy/loggy.dart';

/// Fetches a fresh FCM token (never trusts a previously cached one, since the
/// backend may have discarded a registration without the app knowing) and
/// registers it against the currently active, authenticated instance webview.
Future<void> registerPushToken(WidgetRef ref) async {
  final token = await FirebaseMessaging.instance.getTokenSafe();
  if (token == null) {
    logInfo('Firebase reported null token.');
    return;
  }

  final humHub = ref.read(humHubProvider);
  if (humHub.openerState != OpenerState.hidden) {
    logInfo('Opener is not hidden, skipping token registration name: PushPlugin');
    return;
  }

  final startUrl = humHub.manifest?.startUrl;
  if (startUrl == null || WebViewGlobalController.value == null) {
    logInfo('No active instance session, skipping token registration name: PushPlugin');
    return;
  }

  logInfo('Registering Firebase token $token name: PushPlugin');
  final res = await WebViewGlobalController.ajaxPost(
    url: '$startUrl/fcm-push/token/update-mobile-app',
    data: '{ token: \'$token\' }',
    headers: humHub.customHeaders,
  );
  logInfo(res);
  final success = res is Map && res['status'] == 200;
  if (!success) {
    logError('Failed to register push token name: PushPlugin, response: ${jsonEncode(res)}');
  }

  ref.read(humHubProvider).setToken(token);
}

/// Re-registers the FCM token whenever Firebase rotates it. Post-login
/// registration is handled by the webview itself once it settles (see
/// `WebViewAppState._scheduleTokenRegistrationCheck` in `lib/pages/web_view.dart`),
/// since only it knows when the page has actually finished loading.
class RegisterToken extends ConsumerStatefulWidget {
  final Widget child;

  const RegisterToken({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<RegisterToken> createState() => _RegisterTokenState();
}

class _RegisterTokenState extends ConsumerState<RegisterToken> {
  StreamSubscription<String>? _tokenRefreshSubscription;

  @override
  void initState() {
    super.initState();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      unawaited(registerPushToken(ref));
    });
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
