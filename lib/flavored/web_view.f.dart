import 'dart:async';
import 'dart:io';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/app_flavored.dart';
import 'package:humhub/flavored/models/humhub.f.dart';
import 'package:humhub/util/auth_in_app_browser.dart';
import 'package:humhub/models/channel_message.dart';
import 'package:humhub/util/black_list_rules.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/init_from_url.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:humhub/util/push/provider.dart';
import 'package:humhub/util/show_dialog.dart';
import 'package:humhub/util/web_view_global_controller.dart';
import 'package:loggy/loggy.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:humhub/util/file_download_manager.dart';
import 'package:open_file_plus/open_file_plus.dart';

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late PullToRefreshController pullToRefreshController;
  late double downloadProgress = 0;

  @override
  void initState() {
    instance = ref.read(humHubFProvider);
    _authBrowser = AuthInAppBrowser(
      manifest: ref.read(humHubFProvider).manifest,
      concludeAuth: (URLRequest request) {
        _concludeAuth(request);
      },
    );
    super.initState();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: HexColor(instance.manifest.themeColor),
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          WebViewGlobalController.value?.reload();
        } else if (Platform.isIOS) {
          WebViewGlobalController.value?.loadUrl(urlRequest: URLRequest(url: await WebViewGlobalController.value?.getUrl(), headers: instance.customHeaders));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () => exitApp(context, ref),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: HexColor(instance.manifest.themeColor),
        body: SafeArea(
          bottom: false,
          child: InAppWebView(
            initialUrlRequest: _initialRequest,
            initialSettings: WebViewGlobalController.settings(),
            pullToRefreshController: pullToRefreshController,
            shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
            shouldInterceptFetchRequest: _shouldInterceptFetchRequest,
            onWebViewCreated: _onWebViewCreated,
            onCreateWindow: _onCreateWindow,
            onLoadStop: _onLoadStop,
            onLoadStart: _onLoadStart,
            onReceivedError: _onLoadError,
            onProgressChanged: _onProgressChanged,
            onDownloadStartRequest: _onDownloadStartRequest,
            onLongPressHitTestResult: WebViewGlobalController.onLongPressHitTestResult,
          ),
        ),
      ),
    );
  }

  URLRequest get _initialRequest {
    var payload = ModalRoute.of(context)!.settings.arguments;
    String? url = instance.manifest.startUrl;
    String? payloadForInitFromPush = InitFromUrl.usePayload();
    String? payloadFromPush;
    if (payload is String) payloadFromPush = payload;
    if (payloadForInitFromPush != null) url = payloadForInitFromPush;
    if (payloadFromPush != null) url = payloadFromPush;
    return URLRequest(url: WebUri(url), headers: instance.customHeaders);
  }

  Future<NavigationActionPolicy?> _shouldOverrideUrlLoading(InAppWebViewController controller, NavigationAction action) async {
    // 1st check if url is not def. app url and open it in a browser or inApp.
    WebViewGlobalController.ajaxSetHeaders(headers: instance.customHeaders);
    WebViewGlobalController.listenToImageOpen();
    WebViewGlobalController.appendViewportFitCover();
    final url = action.request.url!.rawValue;

    /// First BLOCK everything that rules out as blocked.
    if (BlackListRules.check(url)) {
      return NavigationActionPolicy.CANCEL;
    }
    // For SSO
    if (!url.startsWith(instance.manifest.baseUrl) && action.isForMainFrame) {
      _authBrowser.launchUrl(action.request);
      return NavigationActionPolicy.CANCEL;
    }
    // For all other external links
    if (!url.startsWith(instance.manifest.baseUrl) && !action.isForMainFrame) {
      await launchUrl(action.request.url!.uriValue, mode: LaunchMode.externalApplication);
      return NavigationActionPolicy.CANCEL;
    }
    // 2nd Append customHeader if url is in app redirect and CANCEL the requests without custom headers
    if (Platform.isAndroid || action.navigationType == NavigationType.LINK_ACTIVATED || action.navigationType == NavigationType.FORM_SUBMITTED) {
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
          ChannelMessage message = ChannelMessage.fromJson(inMessage!.data);
          await _handleJSMessage(message, headlessWebView!);
        },
      ),
    );
    WebViewGlobalController.setValue(controller);
  }

  Future<FetchRequest?> _shouldInterceptFetchRequest(InAppWebViewController controller, FetchRequest request) async {
    request.headers?.addAll(instance.customHeaders);
    return request;
  }

  Future<bool> _onCreateWindow(InAppWebViewController controller, CreateWindowAction createWindowAction) async {
    final urlToOpen = createWindowAction.request.url;
    if (urlToOpen == null) return Future.value(false);
    if (WebViewGlobalController.openCreateWindowInWebView(url: urlToOpen.rawValue, manifest: instance.manifest)) {
      controller.loadUrl(urlRequest: createWindowAction.request);
      return Future.value(false);
    }
    if (await canLaunchUrl(urlToOpen)) {
      await launchUrl(urlToOpen, mode: LaunchMode.externalApplication);
    } else {
      logError('Could not launch $urlToOpen');
    }
    return Future.value(true); // Allow creating a new window.
  }

  Future<void> _onLoadStop(InAppWebViewController controller, Uri? url) async {
    // Disable remember me checkbox on login and set def. value to true: check if the page is actually login page, if it is inject JS that hides element
    if (url!.path.contains('/user/auth/login')) {
      WebViewGlobalController.value!.evaluateJavascript(source: "document.querySelector('#login-rememberme').checked=true");
      WebViewGlobalController.value!
          .evaluateJavascript(source: "document.querySelector('#account-login-form > div.form-group.field-login-rememberme').style.display='none';");
    }
    WebViewGlobalController.ajaxSetHeaders(headers: instance.customHeaders);
    WebViewGlobalController.listenToImageOpen();
    WebViewGlobalController.appendViewportFitCover();
    LoadingProvider.of(ref).dismissAll();
  }

  void _onLoadStart(InAppWebViewController controller, Uri? url) async {
    WebViewGlobalController.ajaxSetHeaders(headers: instance.customHeaders);
    WebViewGlobalController.listenToImageOpen();
    WebViewGlobalController.appendViewportFitCover();
  }

  void _onLoadError(InAppWebViewController controller, WebResourceRequest request, WebResourceError error) async {
    logError(error);
    if (error.description == 'net::ERR_INTERNET_DISCONNECTED') ShowDialog.of(context).noInternetPopup();
    pullToRefreshController.endRefreshing();
  }

  void _onProgressChanged(controller, progress) async {
    if (progress == 100) {
      pullToRefreshController.endRefreshing();
    }
  }

  void _concludeAuth(URLRequest request) {
    _authBrowser.close();
    WebViewGlobalController.value!.loadUrl(urlRequest: request);
  }

  Future<void> _handleJSMessage(ChannelMessage message, HeadlessInAppWebView headlessWebView) async {
    switch (message.action) {
      case ChannelAction.registerFcmDevice:
        String? token = ref.read(pushTokenProvider).value ?? await FirebaseMessaging.instance.getToken();
        if (token != null) {
          WebViewGlobalController.ajaxPost(
            url: message.url!,
            data: '{ token: \'$token\' }',
            headers: instance.customHeaders,
          );
        }
        break;
      case ChannelAction.updateNotificationCount:
        UpdateNotificationCountChannelData data = message.data as UpdateNotificationCountChannelData;
        AppBadgePlus.updateBadge(data.count);
        break;
      case ChannelAction.unregisterFcmDevice:
        String? token = ref.read(pushTokenProvider).value;
        if (token != null) {
          WebViewGlobalController.ajaxPost(
            url: message.url!,
            data: '{ token: \'$token\' }',
            headers: instance.customHeaders,
          );
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

  void _onDownloadStartRequest(InAppWebViewController controller, DownloadStartRequest downloadStartRequest) async {
    PersistentBottomSheetController? persistentController;
    //bool isBottomSheetVisible = false;

    // Initialize the download progress
    downloadProgress = 0;

    // Timer to control when to show the bottom sheet
    Timer? downloadTimer;
    bool isDone = false;

    FileDownloadManager(
      downloadStartRequest: downloadStartRequest,
      controller: controller,
      onSuccess: (File file, String filename) async {
        // Hide the bottom sheet if it is visible
        Navigator.popUntil(context, ModalRoute.withName(WebViewF.path));
        isDone = true;
        Keys.scaffoldMessengerStateKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.file_download}: $filename'),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.open,
              onPressed: () {
                OpenFile.open(file.path);
              },
            ),
          ),
        );
      },
      onStart: () async {
        downloadProgress = 0;
        // Start the timer for 1 second
        downloadTimer = Timer(const Duration(seconds: 1), () {
          // Show the persistent bottom sheet if not already shown
          if (!isDone) {
            persistentController = _scaffoldKey.currentState!.showBottomSheet((context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                height: 100,
                color: const Color(0xff313033),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${AppLocalizations.of(context)!.downloading}...",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: downloadProgress / 100,
                            backgroundColor: Colors.grey,
                            color: Colors.green,
                          ),
                          downloadProgress.toStringAsFixed(0) == "100"
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 25,
                                )
                              : Text(
                                  downloadProgress.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            });
          }
        });
      },
      onProgress: (progress) async {
        downloadProgress = progress;
        if (persistentController != null) {
          persistentController!.setState!(() {});
        }
      },
      onError: (er) {
        downloadTimer?.cancel();
        if (persistentController != null) {
          Navigator.popUntil(context, ModalRoute.withName(WebViewF.path));
        }
        Keys.scaffoldMessengerStateKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.generic_error),
          ),
        );
      },
    ).download();

    // Ensure to cancel the timer if download finishes before 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (downloadProgress >= 100) {
        downloadTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (headlessWebView != null) {
      headlessWebView!.dispose();
    }
  }
}
