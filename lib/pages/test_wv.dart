import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewTestPrettyUrls extends StatefulWidget {
  static String path = "test_wv";
  const WebViewTestPrettyUrls({super.key});

  @override
  State<WebViewTestPrettyUrls> createState() => _WebViewTestPrettyUrlsState();
}

class _WebViewTestPrettyUrlsState extends State<WebViewTestPrettyUrls> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
              url: Uri.tryParse("https://labo-sphere.fr/index.php?r=user%2Fauth%2Flogin")), // Replace with your desired URL
        ),
      ),
    );
  }
}
