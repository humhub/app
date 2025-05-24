import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/storage_service.dart';

class DataSharingConsentState {
  final bool sendErrorReports;
  final bool sendDeviceIdentifiers;

  const DataSharingConsentState({
    required this.sendErrorReports,
    required this.sendDeviceIdentifiers,
  });

  DataSharingConsentState copyWith({
    bool? sendErrorReports,
    bool? sendDeviceIdentifiers,
  }) {
    return DataSharingConsentState(
      sendErrorReports: sendErrorReports ?? this.sendErrorReports,
      sendDeviceIdentifiers: sendDeviceIdentifiers ?? this.sendDeviceIdentifiers,
    );
  }
}

class DataSharingConsentNotifier extends AutoDisposeNotifier<DataSharingConsentState> {
  @override
  DataSharingConsentState build() {
    _loadFromStorage();
    return const DataSharingConsentState(
      sendErrorReports: false,
      sendDeviceIdentifiers: false,
    );
  }

  Future<void> _loadFromStorage() async {
    final errorReports = await SecureStorageService.instance.read(key: SecureStorageService.keys.keyErrorReports);
    final deviceIdentifiers = await SecureStorageService.instance.read(key: SecureStorageService.keys.keyDeviceIdentifiers);
    state = DataSharingConsentState(
      sendErrorReports: errorReports == 'true',
      sendDeviceIdentifiers: deviceIdentifiers == 'true',
    );
  }

  Future<void> setSendErrorReports(bool value) async {
    state = state.copyWith(sendErrorReports: value);
    await SecureStorageService.instance.write(key: SecureStorageService.keys.keyErrorReports, value: value.toString());
  }

  Future<void> setSendDeviceIdentifiers(bool value) async {
    state = state.copyWith(sendDeviceIdentifiers: value);
    await SecureStorageService.instance.write(key: SecureStorageService.keys.keyDeviceIdentifiers, value: value.toString());
  }
}

final dataSharingConsentProvider = AutoDisposeNotifierProvider<DataSharingConsentNotifier, DataSharingConsentState>(
  DataSharingConsentNotifier.new,
);
