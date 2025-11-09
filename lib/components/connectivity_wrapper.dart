import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityWrapper extends ConsumerWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityStateProvider);

    return Stack(
      children: [
        child,
        if (connectivityState.shouldShowPopup)
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
            const Text(
              'No Internet Connection',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again',
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
    List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}

final connectivityStateProvider = Provider<ConnectivityState>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  final hasInternetAsync = ref.watch(hasInternetConnection);

  final isLoading = connectivityAsync.isLoading || hasInternetAsync.isLoading;

  final hasInternet = connectivityAsync.whenData((results) {
        final isConnected = !results.contains(ConnectivityResult.none);
        final hasInternetValue = hasInternetAsync.whenData((value) => value).value ?? true;
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
  return InternetConnectionCheckerPlus().onStatusChange.map((status) {
    return status == InternetConnectionStatus.connected;
  });
});
