import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class RegisterPushInAppBrowser extends InAppBrowser {
  final URLRequest request;
  late InAppBrowserClassSettings settings;

  RegisterPushInAppBrowser({required this.request}) {
    settings = InAppBrowserClassSettings(
      browserSettings: InAppBrowserSettings(hidden: true),
      webViewSettings: InAppWebViewSettings(javaScriptEnabled: true),
    );
  }

  Future<void> register() async {
    await openUrlRequest(urlRequest: request, settings: settings);
    close();
  }
}
