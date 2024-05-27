import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/flavored/util/router.f.dart';
import 'package:humhub/flavored/web_view.f.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:loggy/loggy.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uni_links/uni_links.dart';

bool _initialUriIsHandled = false;

class IntentPluginF extends ConsumerStatefulWidget {
  final Widget child;

  const IntentPluginF({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  IntentPluginFState createState() => IntentPluginFState();
}

class IntentPluginFState extends ConsumerState<IntentPluginF> {
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
    intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
      setState(() {
        sharedFiles = value;
      });
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      setState(() {
        sharedFiles = value;
      });
    });
    _handleInitialUri();
    _handleIncomingLinks();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  /// Handle incoming links - the ones that the app will recieve from the OS
  /// while already started.
  Future<void> _handleIncomingLinks() async {
    if (!kIsWeb) {
      // It will handle app links while the app is already started - be it in
      // the foreground or in the background.
      _sub = uriLinkStream.listen((Uri? uri) async {
        if (!mounted) return;
        _latestUri = uri;
        String? redirectUrl = uri?.toString();
        if (redirectUrl != null && navigatorKeyF.currentState != null) {
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
        if (!mounted) {
          return;
        }
        _latestUri = uri;
        String? redirectUrl = uri.queryParameters['url'];
        if (redirectUrl != null && navigatorKeyF.currentState != null) {
          tryNavigateWithOpener(redirectUrl);
        } else {
          if (redirectUrl != null) {
            navigatorKeyF.currentState!.pushNamed(WebViewF.path, arguments: redirectUrl);
            return;
          }
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
    navigatorKeyF.currentState!.popUntil((route) {
      if (route.settings.name == WebViewF.path) {
        isNewRouteSameAsCurrent = true;
      }
      return true;
    });
    navigatorKeyF.currentState!.pushNamed(WebViewF.path, arguments: redirectUrl);
    return isNewRouteSameAsCurrent;
  }
}
