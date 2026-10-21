import 'package:flutter_test/flutter_test.dart';
import 'package:humhub/models/file_upload_settings.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/remote_config.dart';
import 'package:humhub/util/intent/intent_state.dart';
import 'package:humhub/util/providers.dart';
import 'package:listen_sharing_intent/listen_sharing_intent.dart';

SharedMediaFile _file(String path) =>
    SharedMediaFile(path: path, type: SharedMediaType.image);

FileUploadSettings _settings(String fileUploadUrl) => FileUploadSettings(
      fileUploadUrl: fileUploadUrl,
      shareIntendTargetUrl: '$fileUploadUrl/create',
      maxFileSize: 1024,
      imageMaxProcessingMP: 1,
      denyDoubleFileExtensions: false,
    );

RemoteConfig _remoteConfig(FileUploadSettings settings) => RemoteConfig(
      appName: 'app',
      appVersion: '1.0.0',
      fileUploadSettings: settings,
      whiteListedDomains: null,
      whiteListedUrls: null,
      authClientUrls: null,
    );

void main() {
  group('HumHubNotifier.fileUploadSettings', () {
    test('falls back to remote config when the webview has not delivered settings',
        () {
      final FileUploadSettings remoteSettings = _settings('https://remote/upload');
      final HumHubNotifier notifier = HumHubNotifier(HumHub(
        remoteConfig: _remoteConfig(remoteSettings),
      ));

      expect(notifier.fileUploadSettings, same(remoteSettings));
    });

    test('prefers settings delivered by the webview', () {
      final FileUploadSettings webViewSettings = _settings('https://webview/upload');
      final FileUploadSettings remoteSettings = _settings('https://remote/upload');
      final HumHubNotifier notifier = HumHubNotifier(HumHub(
        fileUploadSettings: webViewSettings,
        remoteConfig: _remoteConfig(remoteSettings),
      ));

      expect(notifier.fileUploadSettings, same(webViewSettings));
    });

    test('returns null when neither source is available', () {
      final HumHubNotifier notifier = HumHubNotifier(HumHub());

      expect(notifier.fileUploadSettings, isNull);
    });
  });

  group('IntentNotifier pending files', () {
    test('keeps shared files until an upload clears them', () {
      final IntentNotifier notifier = IntentNotifier();
      final List<SharedMediaFile> files = [_file('/tmp/a.jpg')];

      notifier.setSharedFiles(files);

      expect(notifier.pendingSharedFiles, same(files));
      expect(notifier.currentState.isSharedFilesNullOrEmpty, isFalse);
    });

    test('does not clear files that arrived while an upload was in flight', () {
      final IntentNotifier notifier = IntentNotifier();
      final List<SharedMediaFile> inFlight = [_file('/tmp/a.jpg')];
      final List<SharedMediaFile> newer = [_file('/tmp/b.jpg')];

      notifier.setSharedFiles(inFlight);
      notifier.setSharedFiles(newer);

      notifier.clearSharedFiles(inFlight);
      expect(notifier.pendingSharedFiles, same(newer));

      notifier.clearSharedFiles(newer);
      expect(notifier.currentState.isSharedFilesNullOrEmpty, isTrue);
    });
  });
}
