import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/api_provider.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/push/provider.dart';
import 'package:loggy/loggy.dart';

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
    return _RegisterToken(
      ready: initialized,
      child: child,
    );
  }
}

class _RegisterToken extends ConsumerStatefulWidget {
  final bool ready;
  final Widget child;

  const _RegisterToken({
    required this.ready,
    required this.child,
  });

  @override
  _RegisterTokenState createState() => _RegisterTokenState();
}

class _RegisterTokenState extends ConsumerState<_RegisterToken> {
  Future<void> _maybeRegisterToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      logInfo('Firebase reported null token.');
      return;
    }

    final cachedToken = ref.read(humHubProvider).pushToken;
    logInfo('Firebase token is $token name: PushPlugin');
    if (cachedToken == token) {
      logInfo('Firebase token already registered name: PushPlugin');
      return;
    }
    final result = await APIProvider.of(ref).request(
      _registerToken(token),
    );
    if (!result.isError) {
      logInfo('Registered Firebase token, caching it name: PushPlugin');
      ref.read(humHubProvider).setToken(token);
    }
  }

  Future<void> Function(Dio dio) _registerToken(String? token) => (dio) async {
        await dio.post(
          '/fcm-push/token/update',
          data: {
            'token': token,
          },
        );
      };

  @override
  void didUpdateWidget(oldWidget) {
    final isReady = !oldWidget.ready && widget.ready;
    if (isReady) {
      unawaited(_maybeRegisterToken());
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
