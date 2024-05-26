import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/app_flavored.dart';
import 'package:humhub/flavored/models/humhub.f.dart';
import 'package:humhub/util/auth_in_app_browser.dart';
import 'package:humhub/models/channel_message.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:humhub/util/notifications/init_from_push.dart';
import 'package:humhub/util/notifications/plugin.dart';
import 'package:humhub/util/push/provider.dart';
import 'package:humhub/util/show_dialog.dart';
import 'package:humhub/util/web_view_global_controller.dart';
import 'package:loggy/loggy.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WebViewF extends ConsumerStatefulWidget {
  static const String path = '/web_view_f';
  const WebViewF({super.key});

  @override
  FlavoredWebViewState createState() => FlavoredWebViewState();
}

class FlavoredWebViewState extends ConsumerState<WebViewF> {
  late AuthInAppBrowser _authBrowser;
  HeadlessInAppWebView? headlessWebView;
  late HumHubF instance;

  @override
  void initState() {
    instance = ref.read(humHubFProvider).value!;
    _authBrowser = AuthInAppBrowser(
      manifest: ref.read(humHubFProvider).value!.manifest,
      concludeAuth: (URLRequest request) {
        _concludeAuth(request);
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () => exitApp(context, ref),
      child: Scaffold(
        backgroundColor: HexColor(instance.manifest.themeColor),
        body: SafeArea(
          bottom: false,
          child: InAppWebView(
            initialUrlRequest: _initialRequest,
            initialOptions: _options,
            pullToRefreshController: _pullToRefreshController,
            shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
            shouldInterceptFetchRequest: _shouldInterceptFetchRequest,
            onWebViewCreated: _onWebViewCreated,
            onCreateWindow: _onCreateWindow,
            onLoadStop: _onLoadStop,
            onLoadStart: _onLoadStart,
            onLoadError: _onLoadError,
            onProgressChanged: _onProgressChanged,
          ),
        ),
      ),
    );
  }

  URLRequest get _initialRequest {
    String? url = instance.manifest.startUrl;
    String? payloadFromPush = InitFromPush.usePayload();
    if (payloadFromPush != null) url = payloadFromPush;
    return URLRequest(url: Uri.parse(url), headers: instance.customHeaders);
  }

  InAppWebViewGroupOptions get _options => InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          useShouldInterceptFetchRequest: true,
          javaScriptEnabled: true,
          supportZoom: false,
          javaScriptCanOpenWindowsAutomatically: true,
        ),
        android: AndroidInAppWebViewOptions(
          supportMultipleWindows: true,
        ),
      );

  PullToRefreshController get _pullToRefreshController => PullToRefreshController(
        options: PullToRefreshOptions(
          color: HexColor(instance.manifest.themeColor),
        ),
        onRefresh: () async {
          Uri? url = await WebViewGlobalController.value!.getUrl();
          if (url != null) {
            WebViewGlobalController.value!.loadUrl(
              urlRequest:
                  URLRequest(url: await WebViewGlobalController.value!.getUrl(), headers: instance.customHeaders),
            );
          } else {
            WebViewGlobalController.value!.reload();
          }
        },
      );

  Future<NavigationActionPolicy?> _shouldOverrideUrlLoading(
      InAppWebViewController controller, NavigationAction action) async {
    // 1st check if url is not def. app url and open it in a browser or inApp.
    _setAjaxHeadersJQuery(controller);
    final url = action.request.url!.origin;
    if (!url.startsWith(instance.manifest.baseUrl) && action.isForMainFrame) {
      _authBrowser.launchUrl(action.request);
      return NavigationActionPolicy.CANCEL;
    }
    // 2nd Append customHeader if url is in app redirect and CANCEL the requests without custom headers
    if (Platform.isAndroid ||
        action.iosWKNavigationType == IOSWKNavigationType.LINK_ACTIVATED ||
        action.iosWKNavigationType == IOSWKNavigationType.FORM_SUBMITTED) {
      Map<String, String> mergedMap = {...instance.customHeaders, ...?action.request.headers};
      URLRequest newRequest = action.request.copyWith(headers: mergedMap);
      controller.loadUrl(urlRequest: newRequest);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  Future<void> _onWebViewCreated(InAppWebViewController controller) async {
    LoadingProvider.of(ref).showLoading();
    headlessWebView = HeadlessInAppWebView();
    headlessWebView!.run();
    await controller.addWebMessageListener(
      WebMessageListener(
        jsObjectName: "flutterChannel",
        onPostMessage: (inMessage, sourceOrigin, isMainFrame, replyProxy) async {
          ChannelMessage message = ChannelMessage.fromJson(inMessage!);
          await _handleJSMessage(message, headlessWebView!);
        },
      ),
    );
    WebViewGlobalController.setValue(controller);
  }

  Future<FetchRequest?> _shouldInterceptFetchRequest(InAppWebViewController controller, FetchRequest request) async {
    request.headers!.addAll(_initialRequest.headers!);
    return request;
  }

  Future<bool> _onCreateWindow(inAppWebViewController, createWindowAction) async {
    logDebug("onCreateWindow");
    final urlToOpen = createWindowAction.request.url;
    if (urlToOpen == null) return Future.value(false);
    if (await canLaunchUrl(urlToOpen)) {
      await launchUrl(urlToOpen, mode: LaunchMode.externalApplication);
    } else {
      logError('Could not launch $urlToOpen');
    }
    LoadingProvider.of(ref).dismissAll();
    return Future.value(true); // Allow creating a new window.
  }

  Future<void> _onLoadStop(InAppWebViewController controller, Uri? url) async {
    // Disable remember me checkbox on login and set def. value to true: check if the page is actually login page, if it is inject JS that hides element
    if (url!.path.contains('/user/auth/login')) {
      WebViewGlobalController.value!
          .evaluateJavascript(source: "document.querySelector('#login-rememberme').checked=true");
      WebViewGlobalController.value!.evaluateJavascript(
          source:
              "document.querySelector('#account-login-form > div.form-group.field-login-rememberme').style.display='none';");
    }
    _setAjaxHeadersJQuery(controller);
    await _pullToRefreshController.endRefreshing();
    LoadingProvider.of(ref).dismissAll();
  }

  void _onLoadStart(InAppWebViewController controller, Uri? url) async {
    _setAjaxHeadersJQuery(controller);
    LoadingProvider.of(ref).dismissAll();
  }

  void _onLoadError(InAppWebViewController controller, Uri? url, int code, String message) async {
    if (code == -1009) ShowDialog.of(context).noInternetPopup();
    await _pullToRefreshController.endRefreshing();
  }

  void _onProgressChanged(controller, progress) async {
    if (progress == 100) {
      await _pullToRefreshController.endRefreshing();
    }
  }

  void _concludeAuth(URLRequest request) {
    _authBrowser.close();
    WebViewGlobalController.value!.loadUrl(urlRequest: request);
  }

  Future<void> _setAjaxHeadersJQuery(InAppWebViewController controller) async {
    String jsCode = "\$.ajaxSetup({headers: ${jsonEncode(instance.customHeaders).toString()}});";
    dynamic jsResponse = await controller.evaluateJavascript(source: jsCode);
    logInfo(jsResponse != null ? jsResponse.toString() : "Script returned null value");
  }

  Future<void> _handleJSMessage(ChannelMessage message, HeadlessInAppWebView headlessWebView) async {
    switch (message.action) {
      case ChannelAction.registerFcmDevice:
        String? token = ref.read(pushTokenProvider).value;
        if (token != null) {
          var postData = Uint8List.fromList(utf8.encode("token=$token"));
          await headlessWebView.webViewController.postUrl(url: Uri.parse(message.url!), postData: postData);
        }
        var status = await Permission.notification.status;
        // status.isDenied: The user has previously denied the notification permission
        // !status.isGranted: The user has never been asked for the notification permission
        bool wasAskedBefore = await NotificationPlugin.hasAskedPermissionBefore();
        // ignore: use_build_context_synchronously
        if (status != PermissionStatus.granted && !wasAskedBefore) ShowDialog.of(context).notificationPermission();
        break;
      case ChannelAction.updateNotificationCount:
        if (message.count != null) FlutterAppBadger.updateBadgeCount(message.count!);
        break;
      case ChannelAction.unregisterFcmDevice:
        String? token = ref.read(pushTokenProvider).value;
        if (token != null) {
          var postData = Uint8List.fromList(utf8.encode("token=$token"));
          URLRequest request = URLRequest(url: Uri.parse(message.url!), method: "POST", body: postData);
          // Works but for admin to see the changes it need to reload a page because a request is called on separate instance.
          await headlessWebView.webViewController.loadUrl(urlRequest: request);
        }
        break;
      default:
        break;
    }
  }

  Future<bool> exitApp(context, ref) async {
    bool canGoBack = await WebViewGlobalController.value!.canGoBack();
    if (canGoBack) {
      WebViewGlobalController.value!.goBack();
      return Future.value(false);
    } else {
      final exitConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: Text(AppLocalizations.of(context)!.web_view_exit_popup_title),
          content: Text(AppLocalizations.of(context)!.web_view_exit_popup_content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
        ),
      );
      return exitConfirmed ?? false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (headlessWebView != null) {
      headlessWebView!.dispose();
    }
  }
}
