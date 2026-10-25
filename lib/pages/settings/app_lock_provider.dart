import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/app_lock_service.dart';
import 'package:humhub/util/storage_service.dart';

class AppLockState {
  final bool enabled;
  final bool isSupported;

  const AppLockState({
    required this.enabled,
    required this.isSupported,
  });

  AppLockState copyWith({
    bool? enabled,
    bool? isSupported,
  }) {
    return AppLockState(
      enabled: enabled ?? this.enabled,
      isSupported: isSupported ?? this.isSupported,
    );
  }
}

class AppLockNotifier extends AutoDisposeNotifier<AppLockState> {
  static Future<bool> get isEnabled async =>
      await SecureStorageService.instance.read(key: SecureStorageService.keys.keyAppLockEnabled) == 'true';

  @override
  AppLockState build() {
    _load();
    return const AppLockState(enabled: false, isSupported: true);
  }

  Future<void> _load() async {
    final enabled = await isEnabled;
    final isSupported = await AppLockService.isDeviceSupported;
    state = state.copyWith(enabled: enabled, isSupported: isSupported);
  }

  /// Persists the app lock setting. Callers are responsible for running a
  /// successful [AppLockService.authenticate] check before enabling it, so
  /// nobody can lock themselves out by turning this on without first
  /// proving their device unlock works.
  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await SecureStorageService.write(key: SecureStorageService.keys.keyAppLockEnabled, value: value.toString());
  }
}

final appLockProvider = AutoDisposeNotifierProvider<AppLockNotifier, AppLockState>(
  AppLockNotifier.new,
);
