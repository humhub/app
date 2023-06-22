import 'dart:async';
import 'dart:developer';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/extensions.dart';

class MyInAppBrowser extends InAppBrowser {
  final Manifest manifest;
  late InAppBrowserClassOptions options;
  final Function concludeAuth;

  MyInAppBrowser({required this.manifest, required this.concludeAuth}) {
    options = InAppBrowserClassOptions(
      crossPlatform: InAppBrowserOptions(hideUrlBar: false, toolbarTopBackgroundColor: HexColor(manifest.themeColor)),
      inAppWebViewGroupOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(javaScriptEnabled: true, useShouldOverrideUrlLoading: true),
      ),
    );
  }

  @override
  Future<NavigationActionPolicy?>? shouldOverrideUrlLoading(NavigationAction navigationAction) async {
    log("Browser closed!");

    if (navigationAction.request.url!.origin.startsWith(manifest.baseUrl)) {
      concludeAuth(navigationAction.request);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  launchUrl(URLRequest urlRequest) {
    openUrlRequest(urlRequest: urlRequest, options: options);
  }
}
