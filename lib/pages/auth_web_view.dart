import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:humhub/l10n/generated/app_localizations.dart';
import 'package:humhub/models/auth_web_view_args.dart';
import 'package:humhub/util/web_view_global_controller.dart';
import 'package:share_plus/share_plus.dart';

class AuthWebView extends StatefulWidget {
  static const String path = '/auth_web_view';

  const AuthWebView({super.key});

  @override
  State<AuthWebView> createState() => _AuthWebViewState();
}

class _AuthWebViewState extends State<AuthWebView> {
  AuthWebViewArgs? _args;
  InAppWebViewController? _controller;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) return;
    _args = ModalRoute.of(context)!.settings.arguments as AuthWebViewArgs;
    _isInit = true;
  }

  Future<void> _handleBack() async {
    final navigator = Navigator.of(context);
    final controller = _controller;
    if (controller == null) {
      navigator.pop();
      return;
    }

    if (await controller.canGoBack()) {
      controller.goBack();
      return;
    }

    navigator.pop();
  }

  Future<void> _handleForward() async {
    final controller = _controller;
    if (controller == null) return;
    if (await controller.canGoForward()) {
      controller.goForward();
    }
  }

  Future<void> _handleReload() async {
    await _controller?.reload();
  }

  Future<void> _handleShare() async {
    final args = _args!;
    final url = await _controller?.getUrl() ?? args.request.url;
    if (url == null) return;
    await Share.share(url.rawValue);
  }

  Future<void> _handleClose() async {
    Navigator.of(context).pop();
  }

  Future<void> _handleAuthSuccess(URLRequest request) async {
    Navigator.of(context).pop(request);
  }

  Future<NavigationActionPolicy?> _shouldOverrideUrlLoading(InAppWebViewController controller, NavigationAction action) async {
    final args = _args!;
    if (action.request.url != null && action.request.url!.rawValue.startsWith(args.manifest.startUrl)) {
      await _handleAuthSuccess(action.request);
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }

  Future<void> _onWebViewCreated(InAppWebViewController controller) async {
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    final args = _args!;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          surfaceTintColor: Colors.white,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          leading: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.auth_web_view_back,
          ),
          actions: [
            PopupMenuButton<_AuthMenuAction>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                switch (action) {
                  case _AuthMenuAction.goBack:
                    unawaited(_handleBack());
                    break;
                  case _AuthMenuAction.goForward:
                    unawaited(_handleForward());
                    break;
                  case _AuthMenuAction.share:
                    unawaited(_handleShare());
                    break;
                  case _AuthMenuAction.reload:
                    unawaited(_handleReload());
                    break;
                  case _AuthMenuAction.close:
                    unawaited(_handleClose());
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _AuthMenuAction.goBack,
                  child: Text(l10n.auth_web_view_go_back),
                ),
                PopupMenuItem(
                  value: _AuthMenuAction.goForward,
                  child: Text(l10n.auth_web_view_go_forward),
                ),
                PopupMenuItem(
                  value: _AuthMenuAction.share,
                  child: Text(l10n.auth_web_view_share),
                ),
                PopupMenuItem(
                  value: _AuthMenuAction.reload,
                  child: Text(l10n.auth_web_view_reload),
                ),
                PopupMenuItem(
                  value: _AuthMenuAction.close,
                  child: Text(l10n.auth_web_view_close),
                ),
              ],
            ),
          ],
        ),
        body: InAppWebView(
          initialUrlRequest: args.request,
          initialSettings: WebViewGlobalController.settings(),
          onWebViewCreated: _onWebViewCreated,
          shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
          onWebContentProcessDidTerminate: (controller) async {
            await controller.reload();
          },
          onReceivedHttpError: (controller, request, errorResponse) {},
          onLoadStart: (controller, url) {},
          onLoadStop: (controller, url) {},
          onProgressChanged: (controller, progress) {},
        ),
      ),
    );
  }
}

enum _AuthMenuAction { goBack, goForward, share, reload, close }
