import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:humhub/models/manifest.dart';

class MyInAppBrowser extends InAppBrowser {
  final Manifest manifest;
  final InAppBrowserClassOptions options = InAppBrowserClassOptions(
    crossPlatform: InAppBrowserOptions(hideUrlBar: false, toolbarTopBackgroundColor: Colors.grey),
    inAppWebViewGroupOptions: InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(javaScriptEnabled: true, useShouldOverrideUrlLoading: true),
    ),
  );

  final Function concludeAuth;

  MyInAppBrowser({required this.manifest, required this.concludeAuth});

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
