import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/crypt.dart';
import '../api_provider.dart';
import '../connectivity_plugin.dart';

// TODO: Rewrite openers so that the opener_controller will expand universal_opener_controller
class UniversalOpenerController {
  late AsyncValue<Manifest>? asyncData;
  bool doesViewExist = false;
  final String url;
  late HumHub humhub;

  UniversalOpenerController({required this.url});

  Future<String?> findManifest(String url) async {
    List<String> possibleUrls = generatePossibleManifestsUrls(url);
    String? manifestUrl;
    for (var url in possibleUrls) {
      asyncData = await APIProvider.requestBasic(Manifest.get(url));
      manifestUrl = Manifest.getUriWithoutExtension(url);
      if (!asyncData!.hasError) break;
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

  checkHumHubModuleView(String url) async {
    Response? response;
    response = await Dio().get(Uri.parse(url).toString()).catchError((err) {
      return Response(data: "Found manifest but not humhub.modules.ui.view tag", statusCode: 404, requestOptions: RequestOptions());
    });

    doesViewExist = response.statusCode == 200 && response.data.contains('humhub.modules.ui.view');
  }

  Future<HumHub?> initHumHub() async {
    var hasConnection = await ConnectivityPlugin.hasConnectivity;
    if (!hasConnection) {
      asyncData = null;
      return null;
    }
    String? manifestUrl = await findManifest(url);
    if (asyncData!.hasValue && manifestUrl != null) {
      await checkHumHubModuleView(asyncData!.value!.startUrl);
    }
    if (asyncData!.hasError || !doesViewExist || manifestUrl == null) {
      asyncData = null;
      return null;
    } else {
      Manifest manifest = asyncData!.value!;
      String hash = Crypt.generateRandomString(32);
      HumHub? lastInstance = await getLastInstance();
      HumHub instance =
          HumHub(manifest: manifest, randomHash: hash, manifestUrl: manifestUrl, history: lastInstance?.history);
      humhub = instance;
      return instance;
    }
  }

  static Uri assumeUrl(String url) {
    if (url.startsWith("https://") || url.startsWith("http://")) return Uri.parse(url);
    return Uri.parse("https://$url");
  }

  Future<HumHub?> getLastInstance() async {
    var jsonStr = await InternalStorage.storage.read(key: InternalStorage.keyHumhubInstance);
    HumHub? humHub = jsonStr != null ? HumHub.fromJson(json.decode(jsonStr)) : null;
    return humHub;
  }
}
