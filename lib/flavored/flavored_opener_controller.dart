import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/api_provider.dart';
import 'package:humhub/util/connectivity_plugin.dart';
import 'package:http/http.dart' as http;

class FlavoredOpenerController {
  late AsyncValue<Manifest>? asyncData;
  bool doesViewExist = false;
  final String url;
  late HumHub humhub;

  FlavoredOpenerController({required this.url});

  Future<bool> findManifest(String url) async {
    List<String> possibleUrls = generatePossibleManifestsUrls(url);
    for (var url in possibleUrls) {
      asyncData = await APIProvider.requestBasic(Manifest.get(url));
      if (!asyncData!.hasError) break;
    }
    return asyncData!.hasError;
  }

  Future<HumHub?> initHumHub() async {
    var hasConnection = await ConnectivityPlugin.hasConnectivity;
    if (!hasConnection) {
      asyncData = null;
      return null;
    }
    await findManifest(url);
    if (asyncData!.hasValue) {
      await checkHumHubModuleView(asyncData!.value!.startUrl);
    }
    if (asyncData!.hasError || !doesViewExist) {
      asyncData = null;
      return null;
    } else {
      Manifest manifest = asyncData!.value!;
      String hash = HumHub.generateHash(32);
      HumHub instance = HumHub(manifest: manifest, randomHash: hash);
      humhub = instance;
      return instance;
    }
  }

  static Uri assumeUrl(String url) {
    if (url.startsWith("https://") || url.startsWith("http://")) return Uri.parse(url);
    return Uri.parse("https://$url");
  }

  checkHumHubModuleView(String url) async {
    Response? response;
    response = await http.Client().get(Uri.parse(url)).catchError((err) {
      return Response("Found manifest but not humhub.modules.ui.view tag", 404);
    });
    doesViewExist = response.statusCode == 200 && response.body.contains('humhub.modules.ui.view');
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
}
