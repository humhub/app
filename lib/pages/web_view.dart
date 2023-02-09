import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/pages/opener.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/providers.dart';
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
  late InAppWebViewController inAppWebViewController;
  final WebViewCookieManager cookieManager = WebViewCookieManager();
  var customHeader = {'my-header-value-01': '111111', 'my-header-value-02': '222222'};

  @override
  void initState() {
    super.initState();
    cookieManager.setMyCookies(widget.manifest);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => inAppWebViewController.exitApp(context, ref),
      child: Scaffold(
        backgroundColor: HexColor(widget.manifest.themeColor),
        body: SafeArea(
          child: InAppWebView(
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                useShouldOverrideUrlLoading: true,
                useShouldInterceptAjaxRequest: true,
                useShouldInterceptFetchRequest: true,
                javaScriptEnabled: true,
              ),
            ),
            shouldOverrideUrlLoading: (controller, action) async {
              // 1st check if url is not def. app url and open it in a browser or inApp.
              final url = action.request.url!.origin;
              if (!url.startsWith(widget.manifest.baseUrl)) {
                launchUrl(action.request.url!,
                    mode: LaunchMode.externalApplication);
                return NavigationActionPolicy.CANCEL;
              }
              // 2nd Append customHeader if url is in app redirect and CANCEL the requests without custom headers
              if (Platform.isAndroid ||
                  action.iosWKNavigationType ==
                      IOSWKNavigationType.LINK_ACTIVATED) {
                controller.loadUrl(
                    urlRequest: URLRequest(
                        url: action.request.url, headers: customHeader));
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            shouldInterceptAjaxRequest: (controller, ajaxReq) async {
              // Append headers on every AJAX request
              ajaxReq.headers = AjaxRequestHeaders(customHeader);
              return ajaxReq;
            },
            shouldInterceptFetchRequest: (controller, fetchReq) async {
              fetchReq.headers?.addAll(customHeader);
              return fetchReq;
            },
            initialUrlRequest: URLRequest(
                url: Uri.parse(widget.manifest.baseUrl), headers: customHeader),
            onWebViewCreated: (controller) async {
              await controller.addWebMessageListener(
                WebMessageListener(
                  jsObjectName: "flutterChannel",
                  onPostMessage:
                      (message, sourceOrigin, isMainFrame, replyProxy) {
                    ref
                        .read(humHubProvider)
                        .setIsHideDialog(message == "humhub.mobile.hideOpener");
                    if (!ref.read(humHubProvider).isHideDialog) {
                      ref.read(humHubProvider).clearSafeStorage();
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const Opener()),
                          (Route<dynamic> route) => false);
                    }
                  },
                ),
              );
              inAppWebViewController = controller;
            },
          ),
        ),
      ),
    );
  }
}
