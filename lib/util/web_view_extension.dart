import 'package:flutter/material.dart';
import 'package:humhub/pages/opener.dart';
import 'package:humhub/util/extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../pages/web_view.dart';
import 'providers.dart';

extension WebViewExtension on WebViewAppState {
  WebViewController get webViewControllerConfig => WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(HexColor(widget.manifest.backgroundColor))
    ..addJavaScriptChannel('flutterChannel',
        onMessageReceived: onMessageReceived)
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          debugPrint('WebView is loading (progress : $progress%)');
        },
        onPageStarted: (String url) {
          debugPrint('Page started loading: $url');
        },
        onPageFinished: (String url) async {
          debugPrint('Page finished loading: $url');
        },
        onWebResourceError: (WebResourceError error) {},
       /* onNavigationRequest: (NavigationRequest request) {
          if (!request.url.startsWith(widget.manifest.baseUrl)) {
            launchUrl(Uri.parse(request.url),
                mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },*/
      ),
    )
    ..loadRequest(
      Uri.parse(widget.manifest.startUrl),
    );

  onMessageReceived(JavaScriptMessage message) {
    ref
        .read(humHubProvider)
        .setIsHideDialog(message.message == "humhub.mobile.hideOpener");
    if (!ref.read(humHubProvider).isHideDialog) {
      ref.read(humHubProvider).clearSafeStorage();
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Opener()),
          (Route<dynamic> route) => false);
    }
  }
}
