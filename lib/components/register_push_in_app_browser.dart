import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class RegisterPushInAppBrowser extends InAppBrowser {
  final URLRequest request;
  late InAppBrowserClassOptions options;

  RegisterPushInAppBrowser({required this.request}) {
    options = InAppBrowserClassOptions(
      crossPlatform: InAppBrowserOptions(hidden: true),
      inAppWebViewGroupOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(javaScriptEnabled: true),
      ),
    );
  }

  Future<void> register() async {
    await openUrlRequest(urlRequest: request, options: options);
    close();
  }
}
