import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';
import 'package:http/http.dart' as http;
import '../api_provider.dart';
import '../connectivity_plugin.dart';

class UniversalOpenerController {
  late AsyncValue<Manifest>? asyncData;
  bool doesViewExist = false;
  final String url;
  late HumHub humhub;

  UniversalOpenerController({required this.url});

  findManifest(String url) async {
    Uri uri = assumeUrl(url);
    for (var i = uri.pathSegments.length - 1; i >= 0; i--) {
      String urlIn = "${uri.origin}/${uri.pathSegments.getRange(0, i).join('/')}";
      asyncData = await APIProvider.requestBasic(Manifest.get(i != 0 ? urlIn : uri.origin));
      if (!asyncData!.hasError) break;
    }
    if (uri.pathSegments.isEmpty) {
      asyncData = await APIProvider.requestBasic(Manifest.get(uri.origin));
    }
    await checkHumHubModuleView(uri);
  }

  checkHumHubModuleView(Uri uri) async {
    Response? response;
    response = await http.Client().get(Uri.parse(uri.origin)).catchError((err) {
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
    await findManifest(url);
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

  bool get allOk => !(asyncData == null || asyncData!.hasError || !doesViewExist);

  Uri assumeUrl(String url) {
    if (url.startsWith("https://") || url.startsWith("http://")) return Uri.parse(url);
    return Uri.parse("https://$url");
  }

  String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Specify you HumHub location';
    }
    return null;
  }
}
