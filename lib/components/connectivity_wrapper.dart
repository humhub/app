import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:humhub/l10n/generated/app_localizations.dart';
import 'package:humhub/util/providers.dart';

class ConnectivityWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ConnectivityWrapper> createState() =>
      _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends ConsumerState<ConnectivityWrapper>
    with WidgetsBindingObserver {
  bool _appIsResumed = true;
  bool _awaitingResumeConnectivityConfirmation = false;
  bool _isConfirmingResumeConnectivity = false;
  bool _showOfflinePopup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        setState(() {
          _appIsResumed = true;
          _awaitingResumeConnectivityConfirmation = true;
          _isConfirmingResumeConnectivity = false;
          _showOfflinePopup = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleResumeConnectivityState(ref.read(connectivityStateProvider));
          }
        });
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        setState(() {
          _appIsResumed = false;
          _awaitingResumeConnectivityConfirmation = false;
          _isConfirmingResumeConnectivity = false;
          _showOfflinePopup = false;
        });
        if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) {
          // Release cached/decoded image bitmaps while backgrounded so they
          // don't count against the app's background memory footprint.
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
        }
        break;
    }
  }

  void _handleResumeConnectivityState(ConnectivityState connectivityState) {
    if (!_appIsResumed || !_awaitingResumeConnectivityConfirmation) {
      return;
    }

    if (connectivityState.isLoading) {
      return;
    }

    if (connectivityState.hasInternet) {
      setState(() {
        _awaitingResumeConnectivityConfirmation = false;
        _isConfirmingResumeConnectivity = false;
        _showOfflinePopup = false;
      });
      return;
    }

    if (!_isConfirmingResumeConnectivity) {
      _confirmConnectivityAfterResume();
    }
  }

  Future<void> _confirmConnectivityAfterResume() async {
    if (_isConfirmingResumeConnectivity) {
      return;
    }

    setState(() {
      _isConfirmingResumeConnectivity = true;
    });

    final hasConnection = await ConnectivityState.hasConnection;
    final hasInternet = await ConnectivityState.hasInternetAccess(
        _resolveProbeUrl(ref.read(humHubProvider)));
    final isOffline = !hasConnection || !hasInternet;

    if (!mounted || !_awaitingResumeConnectivityConfirmation) {
      return;
    }

    setState(() {
      _awaitingResumeConnectivityConfirmation = false;
      _isConfirmingResumeConnectivity = false;
      _showOfflinePopup = _appIsResumed && isOffline;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ConnectivityState>(connectivityStateProvider,
        (previous, current) {
      if (!_appIsResumed) {
        if (_showOfflinePopup) {
          setState(() {
            _showOfflinePopup = false;
          });
        }
        return;
      }

      if (current.isLoading) {
        return;
      }

      if (_awaitingResumeConnectivityConfirmation) {
        _handleResumeConnectivityState(current);
        return;
      }

      if (current.hasInternet) {
        if (_showOfflinePopup) {
          setState(() {
            _showOfflinePopup = false;
          });
        }
        return;
      }

      if (!_showOfflinePopup) {
        setState(() {
          _showOfflinePopup = true;
        });
      }
    });

    ref.watch(connectivityStateProvider);

    return Stack(
      children: [
        widget.child,
        if (_showOfflinePopup)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: NoInternetPopup(
                    onRefresh: () {
                      ref.invalidate(connectivityProvider);
                      ref.invalidate(hasInternetConnection);
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NoInternetPopup extends StatelessWidget {
  final VoidCallback onRefresh;

  const NoInternetPopup({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.connectivity_popup_title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.connectivity_popup_content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class ConnectivityState {
  final bool isLoading;
  final bool hasInternet;
  final bool shouldShowPopup;

  const ConnectivityState({
    required this.isLoading,
    required this.hasInternet,
    required this.shouldShowPopup,
  });

  static Future<bool> get hasConnection async {
    List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  /// Probes [targetUrl] with a lightweight HTTP request to confirm actual
  /// internet reachability, rather than relying on a fixed third-party
  /// DNS-over-HTTPS host. Any HTTP response (even an error status) counts as
  /// reachable; only connection-level failures (timeout, no route, DNS
  /// failure, ...) are treated as offline. If no URL is known yet (e.g. no
  /// instance configured), there is nothing meaningful to probe, so it
  /// assumes connectivity.
  static Future<bool> hasInternetAccess(String? targetUrl) async {
    if (targetUrl == null || targetUrl.isEmpty) {
      return true;
    }
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      validateStatus: (_) => true,
    ));
    try {
      await dio.head(targetUrl);
      return true;
    } catch (_) {
      return false;
    } finally {
      dio.close();
    }
  }
}

/// Resolves the URL to use as a reachability probe: the currently
/// configured/known HumHub instance, or the whitelabeled build's fixed
/// start URL as a fallback. Returns null if neither is available.
String? _resolveProbeUrl(HumHubNotifier humHub) {
  final url = humHub.currentInstanceUrl;
  if (url != null) {
    return url;
  }
  if (dotenv.isInitialized) {
    final envUrl = dotenv.env['START_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
  }
  return null;
}

final connectivityStateProvider = Provider<ConnectivityState>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  final hasInternetAsync = ref.watch(hasInternetConnection);

  final isLoading = connectivityAsync.isLoading || hasInternetAsync.isLoading;

  final hasInternet = connectivityAsync.whenData((results) {
        final isConnected = !results.contains(ConnectivityResult.none);
        final hasInternetValue =
            hasInternetAsync.whenData((value) => value).value ?? true;
        return isConnected && hasInternetValue;
      }).value ??
      true;

  final shouldShowPopup = !isLoading && !hasInternet;

  return ConnectivityState(
    isLoading: isLoading,
    hasInternet: hasInternet,
    shouldShowPopup: shouldShowPopup,
  );
});

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isConnectedToNetworkInterface = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return connectivityAsync.when(
    data: (results) => !results.contains(ConnectivityResult.none),
    loading: () => true,
    error: (_, __) => false,
  );
});

final hasInternetConnection = StreamProvider<bool>((ref) {
  Stream<bool> poll() async* {
    while (true) {
      yield await ConnectivityState.hasInternetAccess(
          _resolveProbeUrl(ref.read(humHubProvider)));
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  return poll();
});
