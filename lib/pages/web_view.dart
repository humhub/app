import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/hex_color.dart';
import 'package:humhub/util/manifest.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewApp extends ConsumerStatefulWidget {
  final Manifest manifest;
  const WebViewApp({super.key, required this.manifest});

  @override
  WebViewAppState createState() => WebViewAppState();
}

class WebViewAppState extends ConsumerState<WebViewApp> {
  late final WebViewController webViewController;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final WebViewCookieManager cookieManager = WebViewCookieManager();


  @override
  void initState() {
    super.initState();
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(HexColor(widget.manifest.backgroundColor))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) async {
            /*final String cookies = await webViewController
                .runJavaScriptReturningResult('document.cookie') as String;*/
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (!request.url.startsWith(widget.manifest.baseUrl)) {
              launchUrl(Uri.parse(request.url),
                  mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.manifest.startUrl),);

    _setCookies(widget.manifest);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () => _exitApp(context),
        child: Scaffold(
          key: scaffoldKey,
          body: WebViewWidget(
            controller: webViewController,
          ),
        ),
      ),
    );
  }

  Future<bool> _exitApp(BuildContext context) async {
    bool canGoBack = await webViewController.canGoBack();
    if (canGoBack) {
      webViewController.goBack();
      return Future.value(false);
    } else {
      final exitConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to exit an App'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      return exitConfirmed ?? false;
    }
  }

  Future<void> _setCookies(Manifest manifest) async {
    await cookieManager.setCookie(
      WebViewCookie(
        name: 'is_mobile_app',
        value: 'true',
        domain: manifest.baseUrl,
      ),
    );
  }
}
