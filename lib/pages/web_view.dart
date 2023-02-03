import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/pages/opener.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/web_view_extension.dart';
import 'package:url_launcher/url_launcher.dart';
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
  late final InAppWebViewController inAppWebViewController;
  final WebViewCookieManager cookieManager = WebViewCookieManager();

  @override
  void initState() {
    super.initState();
    webViewController = webViewControllerConfig;
    cookieManager.setMyCookies(widget.manifest);
  }

  @override
  Widget build(BuildContext context) {
    /*return WillPopScope(
      onWillPop: () => webViewController.exitApp(context, ref),
      child: Scaffold(
          key: scaffoldKey,
          backgroundColor: HexColor(widget.manifest.themeColor),
          body: SafeArea(child: WebViewWidget(controller: webViewController))),
    );*/

    return WillPopScope(
      onWillPop: () => webViewController.exitApp(context, ref),
      child: Scaffold(
        backgroundColor: HexColor(widget.manifest.themeColor),
        body: SafeArea(
          child: InAppWebView(
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                useShouldOverrideUrlLoading: true,
                javaScriptEnabled: true,
              ),
            ),
            shouldOverrideUrlLoading: (controller, action) async {
              final url = action.request.url!.origin;
              if (!url.startsWith(widget.manifest.baseUrl)) {
                launchUrl(action.request.url!,
                    mode: LaunchMode.externalApplication);
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            initialUrlRequest:
                URLRequest(url: Uri.parse(widget.manifest.baseUrl)),
            onWebViewCreated: (controller) async {
              await controller.addWebMessageListener(WebMessageListener(
                jsObjectName: "flutterChannel",
                onPostMessage:
                    (message, sourceOrigin, isMainFrame, replyProxy) {
                  ref
                      .read(humHubProvider)
                      .setIsHideDialog(message == "humhub.mobile.hideOpener");
                  if (!ref.read(humHubProvider).isHideDialog) {
                    ref.read(humHubProvider).clearSafeStorage();
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const Opener()),
                        (Route<dynamic> route) => false);
                  }
                },
              ));
              inAppWebViewController = controller;
            },
          ),
        ),
      ),
    );
  }
}
