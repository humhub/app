import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/push/provider.dart';
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
  final startUrl = humHub.manifest?.startUrl;
  if (startUrl == null || WebViewGlobalController.value == null) {
    logInfo('No active instance session, skipping token registration name: PushPlugin');
    return;
  }

  logInfo('Registering Firebase token $token name: PushPlugin');
  WebViewGlobalController.ajaxPost(
    url: '$startUrl/fcm-push/token/update-mobile-app',
    data: '{ token: \'$token\' }',
    headers: humHub.customHeaders,
  );
  ref.read(humHubProvider).setToken(token);
}

class RegisterToken extends ConsumerWidget {
  final Widget child;

  const RegisterToken({
    super.key,
    required this.child,
  });

  @override
  Widget build(context, ref) {
    final firebaseInitializedL = ref.watch(firebaseInitialized);
    final initialized = firebaseInitializedL.isLoaded;
    final loggedIn = ref.watch(humHubProvider.select((n) => n.openerState == OpenerState.hidden));
    return _RegisterToken(
      ready: initialized,
      loggedIn: loggedIn,
      child: child,
    );
  }
}

class _RegisterToken extends ConsumerStatefulWidget {
  final bool ready;
  final bool loggedIn;
  final Widget child;

  const _RegisterToken({
    required this.ready,
    required this.loggedIn,
    required this.child,
  });

  @override
  _RegisterTokenState createState() => _RegisterTokenState();
}

class _RegisterTokenState extends ConsumerState<_RegisterToken> {
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
  void didUpdateWidget(oldWidget) {
    final isReady = !oldWidget.ready && widget.ready;
    final justLoggedIn = !oldWidget.loggedIn && widget.loggedIn && widget.ready;
    if (isReady || justLoggedIn) {
      unawaited(registerPushToken(ref));
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
