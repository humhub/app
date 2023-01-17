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
  late final WebViewController controller;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late WebViewController controllerGlobal;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
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
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: _handleNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse(widget.manifest.startUrl));

    controllerGlobal = controller;
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    if (!request.url.startsWith(widget.manifest.baseUrl)) {
      launchUrl(Uri.parse(request.url), mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<bool> _exitApp(BuildContext context) async {
    bool canGoBack = await controllerGlobal.canGoBack();
    if (canGoBack) {
      controllerGlobal.goBack();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () => _exitApp(context),
        child: Scaffold(
          key: scaffoldKey,
          body: WebViewWidget(
            controller: controller,
          ),
        ),
      ),
    );
  }
}