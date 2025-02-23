import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/flavored/web_view.f.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/init_from_url.dart';
import 'package:humhub/util/intent/mail_link_provider.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:loggy/loggy.dart';

bool _initialUriIsHandled = false;

class IntentPluginF extends ConsumerStatefulWidget {
  final Widget child;

  const IntentPluginF({
    super.key,
    required this.child,
  });

  @override
  IntentPluginFState createState() => IntentPluginFState();
}

class IntentPluginFState extends ConsumerState<IntentPluginF> {
  StreamSubscription? intentDataStreamSubscription;
  Object? _err;
  Uri? _initialUri;
  Uri? _latestUri;
  StreamSubscription? _sub;
  final appLinks = AppLinks();

  @override
  void initState() {
    logInfo([_err, _initialUri, _latestUri, _sub]);
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialUri();
      _subscribeToUriStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  /// Handle incoming links - the ones that the app will recieve from the OS
  /// while already started.
  Future<void> _subscribeToUriStream() async {
    if (!kIsWeb) {
      // It will handle app links while the app is already started - be it in
      // the foreground or in the background.
      _sub = appLinks.uriLinkStream.listen((Uri? uri) async {
        if (!mounted && uri == null) return;
        _latestUri = await UrlProviderHandler.handleUniversalLink(uri!) ?? uri;
        String? redirectUrl = _latestUri?.toString();
        if (redirectUrl != null && Keys.navigatorKey.currentState != null) {
          tryNavigateWithOpener(redirectUrl);
        }
        _err = null;
      }, onError: (err) {
        if (kDebugMode) {
          print(err);
        }
      });
    }
  }

  /// Handle the initial Uri - the one the app was started with
  ///
  /// **ATTENTION**: `getInitialLink`/`getInitialUri` should be handled
  /// ONLY ONCE in your app's lifetime, since it is not meant to change
  /// throughout your app's life.
  ///
  /// We handle all exceptions, since it is called from initState.
  Future<void> _handleInitialUri() async {
    // In this example app this is an almost useless guard, but it is here to
    // show we are not going to call getInitialUri multiple times, even if this
    // was a widget that will be disposed of (ex. a navigation route change).
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      try {
        Uri? uri = await appLinks.getInitialLink();
        if (uri == null) return;
        setState(() => _initialUri = uri);
        _latestUri = await UrlProviderHandler.handleUniversalLink(uri) ?? uri;
        String? redirectUrl = _latestUri.toString();
        if (Keys.navigatorKey.currentState != null) {
          tryNavigateWithOpener(redirectUrl);
        } else {
          InitFromUrl.setPayload(redirectUrl);
        }
      } on PlatformException {
        // Platform messages may fail but we ignore the exception
        logError('Failed to get initial uri');
      } on FormatException catch (err) {
        if (!mounted) return;
        logError('Malformed initial uri');
        setState(() => _err = err);
      }
    }
  }

  Future<bool> tryNavigateWithOpener(String redirectUrl) async {
    LoadingProvider.of(ref).showLoading();
    bool isNewRouteSameAsCurrent = false;
    Keys.navigatorKey.currentState!.popUntil((route) {
      if (route.settings.name == WebViewF.path) {
        isNewRouteSameAsCurrent = true;
      }
      return true;
    });
    Keys.navigatorKey.currentState!.pushNamed(WebViewF.path, arguments: redirectUrl);
    return isNewRouteSameAsCurrent;
  }
}
