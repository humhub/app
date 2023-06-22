import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/channel_message.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/pages/opener.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/notifications/plugin.dart';
import 'package:humhub/util/push/push_plugin.dart';
import 'package:humhub/util/providers.dart';
import 'package:loggy/loggy.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:humhub/util/router.dart' as m;

import '../components/in_app_browser.dart';
import '../models/hum_hub.dart';

class WebViewApp extends ConsumerStatefulWidget {
  const WebViewApp({super.key});
  static const String path = '/web_view';

  @override
  WebViewAppState createState() => WebViewAppState();
}

class WebViewAppState extends ConsumerState<WebViewApp> {
  late InAppWebViewController webViewController;
  late MyInAppBrowser authBrowser;
  late Manifest manifest;
  late URLRequest _initialRequest;
  final _options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      useShouldInterceptAjaxRequest: true,
      useShouldInterceptFetchRequest: true,
      javaScriptEnabled: true,
    ),
  );

  PullToRefreshController? _pullToRefreshController;
  late PullToRefreshOptions _pullToRefreshOptions;

  @override
  void initState() {
    super.initState();
  }

  Future<NavigationActionPolicy> shouldOverride(NavigationAction navigationAction) async {
    return NavigationActionPolicy.ALLOW;
  }

  @override
  Widget build(BuildContext context) {
    _initialRequest = _initRequest;
    _pullToRefreshController = initPullToRefreshController;
    authBrowser = MyInAppBrowser(
      manifest: manifest,
      concludeAuth: (URLRequest request) {
        _concludeAuth(request);
      },
    );
    return WillPopScope(
      onWillPop: () => webViewController.exitApp(context, ref),
      child: Scaffold(
        backgroundColor: HexColor(manifest.themeColor),
        body: NotificationPlugin(
          child: PushPlugin(
            child: SafeArea(
              bottom: false,
              child: InAppWebView(
                initialUrlRequest: _initialRequest,
                initialOptions: _options,
                pullToRefreshController: _pullToRefreshController,
                shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
                onWebViewCreated: _onWebViewCreated,
                shouldInterceptAjaxRequest: _shouldInterceptAjaxRequest,
                shouldInterceptFetchRequest: _shouldInterceptFetchRequest,
                onLoadStop: _onLoadStop,
                onProgressChanged: _onProgressChanged,
                onConsoleMessage: (controller, msg) {
                  // Handle the web resource error here
                  log('Console Message: $msg');
                },
                onLoadHttpError: (InAppWebViewController controller, Uri? url, int statusCode, String description) {
                  // Handle the web resource error here
                  log('Http Error: $description');
                },
                onLoadError: (InAppWebViewController controller, Uri? url, int code, String message) {
                  log('Load Error: $message');
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<NavigationActionPolicy?> _shouldOverrideUrlLoading(
      InAppWebViewController controller, NavigationAction action) async {
    // 1st check if url is not def. app url and open it in a browser or inApp.
    final url = action.request.url!.origin;
    if (!url.startsWith(manifest.baseUrl)) {
      authBrowser.launchUrl(action.request);
      /*launchUrl(action.request.url!, mode: LaunchMode.inAppWebView);*/
      return NavigationActionPolicy.CANCEL;
    }
    // 2nd Append customHeader if url is in app redirect and CANCEL the requests without custom headers
    if (Platform.isAndroid || action.iosWKNavigationType == IOSWKNavigationType.LINK_ACTIVATED) {
      action.request.headers?.addAll(_initialRequest.headers!);
      controller.loadUrl(urlRequest: action.request);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  _concludeAuth(URLRequest request) {
    authBrowser.close();
    webViewController.loadUrl(urlRequest: request);
  }

  _onWebViewCreated(InAppWebViewController controller) async {
    await controller.addWebMessageListener(
      WebMessageListener(
        jsObjectName: "flutterChannel",
        onPostMessage: (inMessage, sourceOrigin, isMainFrame, replyProxy) async {
          logInfo(inMessage);
          ChannelMessage message = ChannelMessage.fromJson(inMessage!);
          switch (message.action) {
            case ChannelAction.showOpener:
              ref.read(humHubProvider).setIsHideOpener(false);
              ref.read(humHubProvider).clearSafeStorage();
              Navigator.of(context).pushNamedAndRemoveUntil(Opener.path, (Route<dynamic> route) => false);
              break;
            case ChannelAction.hideOpener:
              ref.read(humHubProvider).setIsHideOpener(true);
              ref.read(humHubProvider).setHash(HumHub.generateHash(32));
              break;
            case ChannelAction.registerFcmDevice:
              String? token = ref.read(pushTokenProvider).value;
              if (token != null) {
                var postData = Uint8List.fromList(utf8.encode("token=$token"));
                controller.postUrl(url: Uri.parse(message.url!), postData: postData);
              }
              var status = await Permission.notification.status;
              // status.isDenied: The user has previously denied the notification permission
              // !status.isGranted: The user has never been asked for the notification permission
              if (status.isDenied || !status.isGranted) askForNotificationPermissions();
              break;
            case ChannelAction.updateNotificationCount:
              if (message.count != null) FlutterAppBadger.updateBadgeCount(message.count!);
              break;
            case ChannelAction.none:
              break;
          }
        },
      ),
    );
    webViewController = controller;
  }

  Future<AjaxRequest?> _shouldInterceptAjaxRequest(InAppWebViewController controller, AjaxRequest request) async {
    _initialRequest.headers!.forEach((key, value) {
      request.headers!.setRequestHeader(key, value);
    });
    return request;
  }

  Future<FetchRequest?> _shouldInterceptFetchRequest(InAppWebViewController controller, FetchRequest request) async {
    request.headers!.addAll(_initialRequest.headers!);
    return request;
  }

  URLRequest get _initRequest {
    //Append random hash to customHeaders in this state the header should always exist.
    bool isHideDialog = ref.read(humHubProvider).isHideDialog;
    Map<String, String> customHeaders = {};
    customHeaders.addAll({
      'x-humhub-app-token': ref.read(humHubProvider).randomHash!,
      'x-humhub-app': ref.read(humHubProvider).appVersion!,
      'x-humhub-app-ostate': isHideDialog ? '1' : '0'
    });
    final args = ModalRoute.of(context)!.settings.arguments;
    String? url;
    if (args is Manifest) {
      manifest = args;
    }
    if (args is String) {
      manifest = m.MyRouter.initParams;
      url = args;
    }
    if (args == null) {
      manifest = m.MyRouter.initParams;
    }
    return URLRequest(url: Uri.parse(url ?? manifest.baseUrl), headers: customHeaders);
  }

  _onLoadStop(InAppWebViewController controller, Uri? url) {
    // Disable remember me checkbox on login and set def. value to true: check if the page is actually login page, if it is inject JS that hides element
    if (url!.path.contains('/user/auth/login')) {
      webViewController.evaluateJavascript(source: "document.querySelector('#login-rememberme').checked=true");
      webViewController.evaluateJavascript(
          source:
              "document.querySelector('#account-login-form > div.form-group.field-login-rememberme').style.display='none';");
    }
    _pullToRefreshController?.endRefreshing();
  }

  _onProgressChanged(InAppWebViewController controller, int progress) {
    if (progress == 100) {
      _pullToRefreshController?.endRefreshing();
    }
  }

  PullToRefreshController? get initPullToRefreshController {
    _pullToRefreshOptions = PullToRefreshOptions(
      color: HexColor(manifest.themeColor),
    );
    return kIsWeb
        ? null
        : PullToRefreshController(
            options: _pullToRefreshOptions,
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController.loadUrl(urlRequest: URLRequest(url: await webViewController.getUrl()));
              }
            },
          );
  }

  askForNotificationPermissions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notification Permission"),
        content: const Text("Please enable notifications for HumHub in the device settings"),
        actions: <Widget>[
          TextButton(
            child: const Text("Enable"),
            onPressed: () {
              AppSettings.openAppSettings();
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text("Skip"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
