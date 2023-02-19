import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/push/register_token_plugin.dart';
import 'package:loggy/loggy.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uni_links/uni_links.dart';

bool _initialUriIsHandled = false;

class IntentPlugin extends ConsumerStatefulWidget {
  final Widget child;

  const IntentPlugin({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  IntentPluginState createState() => IntentPluginState();
}

class IntentPluginState extends ConsumerState<IntentPlugin> {
  StreamSubscription? intentDataStreamSubscription;
  List<SharedMediaFile>? sharedFiles;
  final _scaffoldKey = GlobalKey();
  Object? _err;
  Uri? _initialUri;
  Uri? _latestUri;
  StreamSubscription? _sub;

  @override
  void initState() {
    logDebug([_err, _initialUri, _latestUri, _sub]);
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
    return RegisterToken(
      child: widget.child,
    );
  }

  /// Handle incoming links - the ones that the app will recieve from the OS
  /// while already started.
  void _handleIncomingLinks() {
    if (!kIsWeb) {
      // It will handle app links while the app is already started - be it in
      // the foreground or in the background.
      _sub = uriLinkStream.listen((Uri? uri) {
        if (!mounted) return;
        setState(() {
          _latestUri = uri;
          _err = null;
        });
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
    // was a weidget that will be disposed of (ex. a navigation route change).
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      _showSnackBar('_handleInitialUri called');
      try {
        final uri = await getInitialUri();
        if (uri == null) {
          logWarning('no initial uri');
        } else {
          logInfo('got initial uri: $uri');
        }
        if (!mounted) return;
        setState(() => _initialUri = uri);
      } on PlatformException {
        // Platform messages may fail but we ignore the exception
        logError('falied to get initial uri');
      } on FormatException catch (err) {
        if (!mounted) return;
        logError('malformed initial uri');
        setState(() => _err = err);
      }
    }
  }

  void _showSnackBar(String msg) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _scaffoldKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
        ));
      }
    });
  }
}
