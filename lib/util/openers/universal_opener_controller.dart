import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/models/remote_config.dart';
import 'package:humhub/util/crypt.dart';
import 'package:loggy/loggy.dart';
import '../api_provider.dart';
import '../connectivity_plugin.dart';
import '../storage_service.dart';

class UniversalOpenerController {
  late AsyncValue<Manifest>? asyncData;
  // bool doesViewExist = false;
  final String url;
  late HumHub humhub;

  UniversalOpenerController({required this.url});

  Future<String?> findManifest(String url) async {
    logInfo('UniversalOpener: Searching manifest for $url');
    List<String> possibleUrls = generatePossibleManifestsUrls(url);
    logDebug('Generated ${possibleUrls.length} possible manifest URLs');
    String? manifestUrl;
    for (var url in possibleUrls) {
      logDebug('Checking manifest at: $url');
      asyncData = await APIProvider.requestBasic(Manifest.get(url));
      manifestUrl = Manifest.getUriWithoutExtension(url);
      if (!asyncData!.hasError) break;
    }
    if (manifestUrl == null) {
      logWarning('No valid manifest found in ${possibleUrls.length} attempts');
    }
    return manifestUrl;
  }

  static List<String> generatePossibleManifestsUrls(String url) {
    List<String> urls = [];
    Uri uri = assumeUrl(url);

    for (var i = uri.pathSegments.length; i >= 0; i--) {
      String urlIn = "${uri.origin}/${uri.pathSegments.getRange(0, i).join('/')}";
      urls.add(Manifest.defineUrl(i != 0 ? urlIn : uri.origin));
    }
    for (var i = uri.pathSegments.length; i >= 0; i--) {
      String urlIn = "${uri.origin}/${uri.pathSegments.getRange(0, i).join('/')}";
      urls.add(Manifest.defineUrl(i != 0 ? urlIn : uri.origin, isUriPretty: false));
    }
    return urls;
  }

  Future<HumHub?> initHumHub() async {
    var hasConnection = await ConnectivityPlugin.hasConnectivity;
    if (!hasConnection) {
      asyncData = null;
      return null;
    }
    String? manifestUrl = await findManifest(url);
    if (asyncData!.hasError || manifestUrl == null) {
      asyncData = null;
      return null;
    } else {
      Manifest manifest = asyncData!.value!;
      String hash = Crypt.generateRandomString(32);
      HumHub? lastInstance = await getLastInstance();
      humhub = HumHub(manifest: manifest, randomHash: hash, manifestUrl: manifestUrl, history: lastInstance?.history);
      RemoteConfig? remoteConfig = await RemoteConfig.get(manifest, humhub.customHeaders);
      humhub = humhub.copyWith(remoteConfig: remoteConfig);
      return humhub;
    }
  }

  static Uri assumeUrl(String url) {
    if (url.startsWith("https://") || url.startsWith("http://")) return Uri.parse(url);
    return Uri.parse("https://$url");
  }

  Future<HumHub?> getLastInstance() async {
    var jsonStr = await SecureStorageService.instance.read(key: SecureStorageService.keys.humhubInstance);
    HumHub? humHub = jsonStr != null ? HumHub.fromJson(json.decode(jsonStr)) : null;
    return humHub;
  }
}
