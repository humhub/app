import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/app_flavored.dart';
import 'package:humhub/models/auth_web_view_args.dart';
import 'package:humhub/pages/auth_web_view.dart';
import 'package:humhub/flavored/models/humhub.f.dart';
import 'package:humhub/models/feature_flag.dart';
import 'package:humhub/models/channel_message.dart';
import 'package:humhub/util/black_list_rules.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/file_upload_manager.dart';
import 'package:humhub/util/init_from_url.dart';
import 'package:humhub/util/intent/intent_state.dart';
import 'package:humhub/util/loading_provider.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/push/provider.dart';
import 'package:humhub/util/show_dialog.dart';
import 'package:humhub/util/web_view_global_controller.dart';
import 'package:loggy/loggy.dart';
import 'package:humhub/components/file_actions_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:humhub/l10n/generated/app_localizations.dart';
import 'package:humhub/util/file_download_manager.dart';

class WebViewF extends ConsumerStatefulWidget {
  static const String path = '/web_view_f';
  const WebViewF({super.key});

  @override
  FlavoredWebViewState createState() => FlavoredWebViewState();
}

class FlavoredWebViewState extends ConsumerState<WebViewF> with RouteAware {
  HeadlessInAppWebView? headlessWebView;
  late HumHubF instance;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late PullToRefreshController pullToRefreshController;
  late double downloadProgress = 0;
  bool _isRouteObserverSubscribed = false;

  @override
  void initState() {
    instance = ref.read(humHubFProvider);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isRouteObserverSubscribed) {
      routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
      _isRouteObserverSubscribed = true;
    }
  }

  /// Called when a route pushed on top of WebViewF (e.g. AuthWebView) is popped.
  /// That screen locks orientation to portrait, and since popping back doesn't
  /// re-run WebViewF's own route builder, the lock would otherwise persist.
  @override
  void didPopNext() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(humHubFRemoteConfigProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => exitApp(context, ref),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: HexColor(instance.manifest.themeColor),
        body: SafeArea(
          bottom: false,
          child: FileUploadManagerWidget(
            child: InAppWebView(
              preventGestureDelay: true,
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
    // Route external main-frame URLs based on whiteListedUrls presence
    final remoteConfig = ref.read(humHubFRemoteConfigProvider).asData?.value;
    if (!url.startsWith(instance.manifest.startUrl) && action.isForMainFrame) {
      if (remoteConfig?.whiteListedUrls == null && remoteConfig?.authClientUrls == null) {
        logInfo('Legacy SSO detected, launching AuthWebView for $url');
        unawaited(_launchAuthWebView(action.request));
        return NavigationActionPolicy.CANCEL;
      }
      if (remoteConfig!.isTrustedUrl(action.request.url!.uriValue)) {
        logInfo('Whitelisted URL, launching AuthWebView for $url');
        unawaited(_launchAuthWebView(action.request));
        return NavigationActionPolicy.CANCEL;
      }
      await launchUrl(action.request.url!.uriValue, mode: LaunchMode.externalApplication);
      return NavigationActionPolicy.CANCEL;
    }
    // For non-main-frame external links
    if (!url.startsWith(instance.manifest.startUrl)) {
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
    final remoteConfig = ref.read(humHubFRemoteConfigProvider).asData?.value;
    if ((remoteConfig?.whiteListedUrls == null && remoteConfig?.authClientUrls == null) ||
        remoteConfig!.isTrustedUrl(urlToOpen.uriValue)) {
      unawaited(_launchAuthWebView(createWindowAction.request));
      return Future.value(true);
    }
    if (await canLaunchUrl(urlToOpen)) {
      await launchUrl(urlToOpen, mode: LaunchMode.externalApplication);
    } else {
      logError('Could not launch $urlToOpen');
    }
    return Future.value(true);
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
    if (error.description == 'net::ERR_INTERNET_DISCONNECTED') {
      ShowDialog.of(context).noInternetPopup();
    }
    pullToRefreshController.endRefreshing();
  }

  void _onProgressChanged(controller, progress) async {
    if (progress == 100) {
      pullToRefreshController.endRefreshing();
    }
  }

  void _concludeAuth(URLRequest request) {
    WebViewGlobalController.value!.loadUrl(urlRequest: request);
  }

  Future<void> _launchAuthWebView(URLRequest request) async {
    final result = await Navigator.of(context).pushNamed(
      AuthWebView.path,
      arguments: AuthWebViewArgs(
        manifest: instance.manifest,
        request: request,
      ),
    );

    if (!mounted || result is! URLRequest) return;
    _concludeAuth(result);
  }

  Future<void> _handleJSMessage(ChannelMessage message, HeadlessInAppWebView headlessWebView) async {
    switch (message.action) {
      case ChannelAction.authClientRedirect:

        final data = message.data as AuthClientRedirectChannelData;
        data.handle(
          isSupported: FeatureFlag.supportsAuthClientRedirect,
          onIgnored: logInfo,
          onLaunchable: (request, url) async {
            if (_supportsAuthClientRedirect) {
              logInfo('Launching flavored AuthWebView from authClientRedirect for $url');
              unawaited(_launchAuthWebView(request));
              return;
            }

            logInfo('Launching flavored browser from authClientRedirect for $url');
            await launchUrl(request.url!.uriValue, mode: LaunchMode.externalApplication);
          },
        );
        break;
      case ChannelAction.registerFcmDevice:
        String? token = ref.read(pushTokenProvider).value ?? await FirebaseMessaging.instance.getTokenSafe();
        if (token != null) {
          WebViewGlobalController.ajaxPost(
            url: message.url!,
            data: '{ token: \'$token\' }',
            headers: instance.customHeaders,
          );
        }
        break;
      case ChannelAction.updateNotificationCount:
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
      case ChannelAction.fileUploadSettings:
        logInfo('Action: fileUploadSettings');
        FileUploadSettingsChannelData data = message.data as FileUploadSettingsChannelData;
        ref.read(humHubProvider.notifier).setFileUploadSettings(data.settings);
        FileUploadManager(
                webViewController: WebViewGlobalController.value!,
                intentNotifier: ref.read(intentProvider.notifier),
                fileUploadSettings: data.settings,
                context: context)
            .upload();
      default:
        break;
    }
  }

  bool get _supportsAuthClientRedirect {
    final remoteConfig = ref.read(humHubFRemoteConfigProvider).asData?.value;
    final supportsAuthClientRedirect = instance.forceV2AuthClient || remoteConfig?.supportsAuthClientRedirect == true;
    logDebug(
        'Flavored authClientRedirect supported: $supportsAuthClientRedirect (FORCE_V2_AUTH_CLIENT=${instance.forceV2AuthClient}, backend=${remoteConfig?.appVersion ?? 'unknown'})');
    return supportsAuthClientRedirect;
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
        FileActionsBottomSheet.show(context, file, filename);
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
    routeObserver.unsubscribe(this);
    super.dispose();
    if (headlessWebView != null) {
      headlessWebView!.dispose();
    }
  }
}
