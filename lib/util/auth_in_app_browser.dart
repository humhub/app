import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:humhub/models/manifest.dart';
import 'package:loggy/loggy.dart';

import 'extensions.dart';

class AuthInAppBrowser extends InAppBrowser {
  final Manifest manifest;
  late InAppBrowserClassSettings settings;
  final Function concludeAuth;
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  AuthInAppBrowser({required this.manifest, required this.concludeAuth}) {
    settings = InAppBrowserClassSettings(
      browserSettings: InAppBrowserSettings(
        hideUrlBar: true,
        shouldCloseOnBackButtonPressed: true,
        toolbarTopBackgroundColor: Colors.white,
        toolbarTopTintColor: HexColor(manifest.themeColor),
        presentationStyle: ModalPresentationStyle.PAGE_SHEET,
      ),
      webViewSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        useShouldOverrideUrlLoading: true,
        userAgent: userAgent,
      ),
    );
  }

  @override
  Future<NavigationActionPolicy?>? shouldOverrideUrlLoading(NavigationAction navigationAction) async {
    logInfo("Browser closed!");

    if (navigationAction.request.url!.origin.startsWith(manifest.baseUrl)) {
      concludeAuth(navigationAction.request);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  launchUrl(URLRequest urlRequest) {
    openUrlRequest(urlRequest: urlRequest, settings: settings);
  }
}
