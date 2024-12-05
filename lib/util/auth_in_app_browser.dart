import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:humhub/models/global_package_info.dart';
import 'package:humhub/models/global_user_agent.dart';
import 'package:humhub/models/manifest.dart';
import 'package:loggy/loggy.dart';
import 'extensions.dart';

class AuthInAppBrowser extends InAppBrowser {
  final Manifest manifest;
  late InAppBrowserClassSettings settings;
  final Function concludeAuth;
  AuthInAppBrowser({required this.manifest, required this.concludeAuth}) {
    settings = InAppBrowserClassSettings(
      browserSettings: InAppBrowserSettings(
        hideUrlBar: true,
        hideTitleBar: true,
        closeOnCannotGoBack: true,
        shouldCloseOnBackButtonPressed: true,
        toolbarTopBackgroundColor: Colors.white,
        toolbarTopTintColor: HexColor(manifest.themeColor),
        presentationStyle: ModalPresentationStyle.PAGE_SHEET,
      ),
      webViewSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          useShouldOverrideUrlLoading: true,
          userAgent: GlobalUserAgent.value,
          applicationNameForUserAgent: GlobalPackageInfo.info.appName),
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
