import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/models/register_fcm.dart';
import 'package:humhub/pages/opener.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/notifications/plugin.dart';
import 'package:humhub/util/push/push_plugin.dart';
import 'package:humhub/util/providers.dart';
import 'package:loggy/loggy.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:humhub/util/router.dart' as m;

import '../models/hum_hub.dart';

class WebViewApp extends ConsumerStatefulWidget {
  const WebViewApp({super.key});
  static const String path = '/web_view';

  @override
  WebViewAppState createState() => WebViewAppState();
}

class WebViewAppState extends ConsumerState<WebViewApp> {
  late InAppWebViewController inAppWebViewController;
  final WebViewCookieManager cookieManager = WebViewCookieManager();
  final options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      useShouldInterceptAjaxRequest: true,
      useShouldInterceptFetchRequest: true,
      javaScriptEnabled: true,
    ),
  );
  late Manifest manifest;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //Append random hash to customHeaders in this state the header should always exist.
    customHeaders.addAll({'x-humhub-app-token': ref.read(humHubProvider).randomHash!, 'x-humhub-app': ref.read(humHubProvider).appVersion!});

    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null) {
      manifest = args as Manifest;
    } else {
      manifest = m.Router.initParams;
    }

    final initialRequest = URLRequest(url: Uri.parse(manifest.baseUrl), headers: customHeaders);
    return WillPopScope(
      onWillPop: () => inAppWebViewController.exitApp(context, ref),
      child: Scaffold(
        backgroundColor: HexColor(manifest.themeColor),
        body: NotificationPlugin(
          child: PushPlugin(
            child: SafeArea(
              child: InAppWebView(
                  initialUrlRequest: initialRequest,
                  initialOptions: options,
                  shouldOverrideUrlLoading: shouldOverrideUrlLoading,
                  onWebViewCreated: onWebViewCreated,
                  shouldInterceptAjaxRequest: shouldInterceptAjaxRequest,
                  shouldInterceptFetchRequest: shouldInterceptFetchRequest),
            ),
          ),
        ),
      ),
    );
  }

  Future<NavigationActionPolicy?> shouldOverrideUrlLoading(InAppWebViewController controller, NavigationAction action) async {
    // 1st check if url is not def. app url and open it in a browser or inApp.
    final url = action.request.url!.origin;
    if (!url.startsWith(manifest.baseUrl)) {
      launchUrl(action.request.url!, mode: LaunchMode.externalApplication);
      return NavigationActionPolicy.CANCEL;
    }
    // 2nd Append customHeader if url is in app redirect and CANCEL the requests without custom headers
    if (Platform.isAndroid || action.iosWKNavigationType == IOSWKNavigationType.LINK_ACTIVATED) {
      controller.loadUrl(urlRequest: URLRequest(url: action.request.url, headers: customHeaders));
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  onWebViewCreated(InAppWebViewController controller) async {
    await controller.addWebMessageListener(
      WebMessageListener(
        jsObjectName: "flutterChannel",
        onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) async {
          logInfo(message);
          bool isJson = false;
          try {
            var decodedJSON = jsonDecode(message!) as Map<String, dynamic>;
            RegisterFcm request = RegisterFcm.fromJson(decodedJSON);
            String? token = ref.read(pushTokenProvider).value;
            if (token != null) {
              var postData = Uint8List.fromList(utf8.encode("token=$token"));
              controller.postUrl(url: Uri.parse(request.url), postData: postData);
            }
            isJson = true;
          } on FormatException catch (e) {
            logInfo('The provided string is not valid JSON', e);
          }
          if (!isJson) {
            ref.read(humHubProvider).setIsHideDialog(message == "humhub.mobile.hideOpener");
            if (!ref.read(humHubProvider).isHideDialog) {
              ref.read(humHubProvider).clearSafeStorage();
              Navigator.of(context).pushNamedAndRemoveUntil(Opener.path, (Route<dynamic> route) => false);
            } else {
              ref.read(humHubProvider).setHash(HumHub.generateHash(32));
            }
          }
        },
      ),
    );
    inAppWebViewController = controller;
  }

  Future<AjaxRequest?> shouldInterceptAjaxRequest(InAppWebViewController controller, AjaxRequest ajaxReq) async {
    // Append headers on every AJAX request
    ajaxReq.headers = AjaxRequestHeaders(customHeaders);
    return ajaxReq;
  }

  Future<FetchRequest?> shouldInterceptFetchRequest(InAppWebViewController controller, FetchRequest fetchReq) async {
    fetchReq.headers?.addAll(customHeaders);
    return fetchReq;
  }
}
