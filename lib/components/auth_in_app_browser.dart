import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/extensions.dart';

class AuthInAppBrowser extends InAppBrowser {
  final Manifest manifest;
  late InAppBrowserClassOptions options;
  final Function concludeAuth;
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  AuthInAppBrowser({required this.manifest, required this.concludeAuth}) {
    options = InAppBrowserClassOptions(
      crossPlatform: InAppBrowserOptions(
        hideUrlBar: false,
        toolbarTopBackgroundColor: HexColor(manifest.themeColor),
      ),
      inAppWebViewGroupOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            useShouldOverrideUrlLoading: true,
            userAgent: userAgent,
            applicationNameForUserAgent: 'HumHub-Mobile'),
      ),
    );
  }

  @override
  Future<NavigationActionPolicy?>? shouldOverrideUrlLoading(NavigationAction navigationAction) async {
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
