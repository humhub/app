import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/file_upload_settings.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/intent/mail_link_provider.dart';
import 'package:humhub/util/openers/universal_opener_controller.dart';
import 'package:humhub/util/providers.dart';
import 'package:loggy/loggy.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'intent_state.dart';

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
  StreamSubscription? _sub;
  final appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialUri();
      _subscribeToUriStream();
      _handleFileSharing();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  /// Handle incoming links - the ones that the app will receive from the OS
  /// while already started.
  Future<void> _subscribeToUriStream() async {
    if (!kIsWeb) {
      _sub = appLinks.uriLinkStream.listen((Uri? uri) async {
        if (!mounted || uri == null) return;

        final latestUri = await UrlProviderHandler.handleUniversalLink(uri) ?? uri;

        // Update the latest URI using the provider
        ref.read(intentProvider.notifier).setLatestUri(latestUri);

        logInfo('IntentPlugin._subscribeToUriStream', latestUri);

        String redirectUrl = latestUri.toString();
        if (Keys.navigatorKey.currentState != null) {
          tryNavigateWithOpener(redirectUrl);
        }

        // Clear error state
        ref.read(intentProvider.notifier).setError(null);
      }, onError: (err) {
        if (kDebugMode) {
          print(err);
        }
        // Update error state using the provider
        ref.read(intentProvider.notifier).setError(err);
      });
    }
  }

  /// Handle the initial Uri - the one the app was started with
  Future<void> _handleInitialUri() async {
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      try {
        final uri = await appLinks.getInitialLink();
        if (uri == null || !mounted) return;

        // Update the initial URI using the provider
        ref.read(intentProvider.notifier).setInitialUri(uri);

        final latestUri = await UrlProviderHandler.handleUniversalLink(uri) ?? uri;

        // Update the latest URI using the provider
        ref.read(intentProvider.notifier).setLatestUri(latestUri);

        logInfo('IntentPlugin._handleInitialUri', latestUri);

        String redirectUrl = latestUri.toString();
        if (Keys.navigatorKey.currentState != null) {
          tryNavigateWithOpener(redirectUrl);
        } else {
          UniversalOpenerController opener = UniversalOpenerController(url: redirectUrl);
          await opener.initHumHub();
          Keys.navigatorKey.currentState!.pushNamed(WebView.path, arguments: opener);
        }
      } on PlatformException {
        logError('Failed to get initial uri');
      } on FormatException catch (err) {
        if (!mounted) return;
        ref.read(intentProvider.notifier).setError(err);
        logError('Malformed initial uri');
      }
    }
  }

  /// Handle file sharing using `receive_sharing_intent`
  void _handleFileSharing() {
    intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        // Update shared files using the provider
        ref.read(intentProvider.notifier).setSharedFiles(value);

        logInfo('Received shared files: $value');
      },
      onError: (err) {
        // Update error using the provider
        ref.read(intentProvider.notifier).setError(err);

        logError('Error receiving shared files: $err');
      },
    );

    ReceiveSharingIntent.instance.getInitialMedia().then((mediaList) {
      if (mediaList.isEmpty) return;
      FileUploadSettings? settings = ref.read(humHubProvider).fileUploadSettings;
      if (settings == null) return;
      ref.read(intentProvider.notifier).setSharedFiles(mediaList);
      logInfo('Initial shared files: $mediaList');
    });
  }

  Future<bool> tryNavigateWithOpener(String redirectUrl) async {
    final latestUri = ref.read(intentProvider).latestUri;
    logInfo('IntentPlugin.tryNavigateWithOpener', latestUri);

    bool isNewRouteSameAsCurrent = false;
    Keys.navigatorKey.currentState!.popUntil((route) {
      if (route.settings.name == WebView.path) {
        isNewRouteSameAsCurrent = true;
      }
      return true;
    });

    UniversalOpenerController opener = UniversalOpenerController(url: redirectUrl);
    await opener.initHumHub();

    Keys.navigatorKey.currentState!.pushNamed(WebView.path, arguments: opener);

    return isNewRouteSameAsCurrent;
  }

  @override
  void dispose() {
    intentDataStreamSubscription?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
