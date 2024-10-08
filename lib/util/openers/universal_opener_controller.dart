import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';
import 'package:http/http.dart' as http;
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
    response = await http.Client().get(Uri.parse(url)).catchError((err) {
      return Response("Found manifest but not humhub.modules.ui.view tag", 404);
    });

    doesViewExist = response.statusCode == 200 && response.body.contains('humhub.modules.ui.view');
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
      String hash = HumHub.generateHash(32);
      HumHub instance = HumHub(manifest: manifest, randomHash: hash, manifestUrl: manifestUrl);
      humhub = instance;
      return instance;
    }
  }

  static Uri assumeUrl(String url) {
    if (url.startsWith("https://") || url.startsWith("http://")) return Uri.parse(url);
    return Uri.parse("https://$url");
  }
}
