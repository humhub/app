import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/web_view_extension.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewApp extends ConsumerStatefulWidget {
  final Manifest manifest;
  const WebViewApp({super.key, required this.manifest});

  @override
  WebViewAppState createState() => WebViewAppState();
}

class WebViewAppState extends ConsumerState<WebViewApp> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late final WebViewController webViewController;
  final WebViewCookieManager cookieManager = WebViewCookieManager();

  @override
  void initState() {
    super.initState();
    webViewController = webViewControllerConfig;
    cookieManager.setMyCookies(widget.manifest);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => webViewController.exitApp(context, ref),
      child: Scaffold(
          key: scaffoldKey,
          backgroundColor: HexColor(widget.manifest.themeColor),
          body: SafeArea(child: WebViewWidget(controller: webViewController))),
    );
  }
}
