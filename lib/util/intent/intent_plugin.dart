import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/intent/mail_link_provider.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:humhub/util/openers/universal_opener_controller.dart';
import 'package:loggy/loggy.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uni_links/uni_links.dart';

bool _initialUriIsHandled = false;

class IntentPlugin extends ConsumerStatefulWidget {
  final Widget child;

  const IntentPlugin({
    super.key,
    required this.child,
  });

  @override
  IntentPluginState createState() => IntentPluginState();
}

class IntentPluginState extends ConsumerState<IntentPlugin> {
  StreamSubscription? intentDataStreamSubscription;
  List<SharedMediaFile>? sharedFiles;
  Object? _err;
  Uri? _initialUri;
  Uri? _latestUri;
  StreamSubscription? _sub;

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
      _sub = uriLinkStream.listen((Uri? uri) async {
        if (!mounted && uri == null) return;
        _latestUri = await UrlProviderHandler.handleUniversalLink(uri!) ?? uri;
        String redirectUrl = _latestUri.toString();
        if (Keys.navigatorKey.currentState != null) {
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
        final uri = await getInitialUri();
        if (uri == null || !mounted) return;
        setState(() => _initialUri = uri);
        _latestUri = await UrlProviderHandler.handleUniversalLink(uri) ?? uri;
        String? redirectUrl = _latestUri.toString();
        if (Keys.navigatorKey.currentState != null) {
          tryNavigateWithOpener(redirectUrl);
        } else {
          UniversalOpenerController opener = UniversalOpenerController(url: redirectUrl);
          await opener.initHumHub();
          Keys.navigatorKey.currentState!.pushNamed(WebView.path, arguments: opener);
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
      if (route.settings.name == WebView.path) {
        isNewRouteSameAsCurrent = true;
      }
      return true;
    });
    UniversalOpenerController opener = UniversalOpenerController(url: redirectUrl);
    await opener.initHumHub();
    // Always pop the current instance and init the new one.
    LoadingProvider.of(ref).dismissAll();
    Keys.navigatorKey.currentState!.pushNamed(WebView.path, arguments: opener);
    return isNewRouteSameAsCurrent;
  }
}
