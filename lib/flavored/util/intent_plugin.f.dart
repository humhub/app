import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/flavored/web_view.f.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/init_from_url.dart';
import 'package:humhub/util/intent/intent_state.dart';
import 'package:humhub/util/intent/mail_link_provider.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:loggy/loggy.dart';
import 'package:humhub/models/file_upload_settings.dart';
import 'package:humhub/util/providers.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

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

  /// Handle incoming links - the ones that the app will recieve from the OS
  /// while already started.
  /// TODO: This method is same as from intent_plugin.dart reuse it.
  Future<void> _subscribeToUriStream() async {
    if (!kIsWeb) {
      // It will handle app links while the app is already started - be it in
      // the foreground or in the background.
      _sub = appLinks.uriLinkStream.listen((Uri? uri) async {
        if (!mounted && uri == null) return;
        final latestUri = await UrlProviderHandler.handleUniversalLink(uri!) ?? uri;

        ref.read(intentProvider.notifier).setLatestUri(latestUri);

        logInfo('IntentPlugin._subscribeToUriStream', latestUri);

        String? redirectUrl = latestUri.toString();
        if (Keys.navigatorKey.currentState != null) {
          tryNavigateWithOpener(redirectUrl);
        }
        ref.read(intentProvider.notifier).setError(null);
      }, onError: (err) {
        if (kDebugMode) {
          ref.read(intentProvider.notifier).setError(err);
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
        final uri = await appLinks.getInitialLink();
        if (uri == null || !mounted) return;

        // Update the initial URI using the provider
        final latestUri = await UrlProviderHandler.handleUniversalLink(uri) ?? uri;

        // Update the latest URI using the provider
        ref.read(intentProvider.notifier).setLatestUri(latestUri);

        logInfo('IntentPlugin._handleInitialUri', latestUri);

        String redirectUrl = latestUri.toString();
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
        ref.read(intentProvider.notifier).setError(err);
        logError('Malformed initial uri');
      }
    }
  }

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

  @override
  void dispose() {
    intentDataStreamSubscription?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
