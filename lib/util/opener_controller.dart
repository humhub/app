import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/providers.dart';
import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';
import 'api_provider.dart';
import 'connectivity_plugin.dart';
import 'form_helper.dart';

class OpenerController {
  late AsyncValue<Manifest>? asyncData;
  bool doesViewExist = false;
  final FormHelper helper;
  TextEditingController urlTextController = TextEditingController();
  late String? postcodeErrorMessage;
  final String formUrlKey = "redirect_url";
  final String error404 = "404";
  final String noConnection = "no_connection";
  final WidgetRef ref;

  OpenerController({required this.ref, required this.helper});

  /// Finds the `manifest.json` file associated with the given URL. If the URL does not
  /// directly point to the `manifest.json` file, it traverses up the directory structure
  /// to locate it. If not found, it assumes a default path format. This method makes
  /// asynchronous requests to fetch the manifest data.
  ///
  /// @param url The URL from which to start searching for the `manifest.json` file.
  /// @return A Future that completes with no result once the `manifest.json` file is found
  /// or the default path is assumed, or if an error occurs during the search process.
  /// Additionally, it may trigger a check for the HumHub module view based on the start URL
  /// obtained from the manifest data.
  ///
  /// @throws Exception if an error occurs during the search process.
  Future<bool> findManifest(String url) async {
    List<String> possibleUrls = generatePossibleManifestsUrls(url);
    for (var url in possibleUrls) {
      asyncData = await APIProvider.of(ref).request(Manifest.get(url));
      if (!asyncData!.hasError) break;
    }
    return asyncData!.hasError;
  }

  checkHumHubModuleView(String url) async {
    Response? response;
    response = await http.Client().get(Uri.parse(url)).catchError((err) {
      return Response("Found manifest but not humhub.modules.ui.view tag", 404);
    });

    doesViewExist = response.statusCode == 200 && response.body.contains('humhub.modules.ui.view');
  }

  initHumHub() async {
    // Validate the URL format and if !value.isEmpty
    if (!helper.validate()) return;
    helper.save();

    var hasConnection = await ConnectivityPlugin.hasConnectivity;
    if (!hasConnection) {
      String value = urlTextController.text;
      urlTextController.text = noConnection;
      helper.validate();
      urlTextController.text = value;
      asyncData = null;
      return;
    }
    // Get the manifest.json for given url.
    await findManifest(helper.model[formUrlKey]!);
    if (asyncData!.hasValue) {
      await checkHumHubModuleView(asyncData!.value!.startUrl);
    }
    // If manifest.json does not exist the url is incorrect.
    // This is a temp. fix the validator expect sync function this is established workaround.
    // In the future we could define our own TextFormField that would also validate the API responses.
    // But it this is not acceptable I can suggest simple popup or tempPopup.
    if (asyncData!.hasError || !doesViewExist) {
      logError("Open URL error: $asyncData");
      String value = urlTextController.text;
      urlTextController.text = error404;
      helper.validate();
      urlTextController.text = value;
    } else {
      Manifest manifest = asyncData!.value!;
      // Set the manifestStateProvider with the manifest value so that it's globally accessible
      // Generate hash and save it to store
      String lastUrl = "";
      lastUrl = await ref.read(humHubProvider).getLastUrl();
      String currentUrl = urlTextController.text;
      String hash = HumHub.generateHash(32);
      if (lastUrl == currentUrl) hash = ref.read(humHubProvider).randomHash ?? hash;
      await ref.read(humHubProvider).setInstance(HumHub(manifest: manifest, randomHash: hash));
    }
  }

  bool get allOk => !(asyncData == null || asyncData!.hasError || !doesViewExist);

  String? validateUrl(String? value) {
    if (value == error404) return 'Your HumHub installation does not exist';
    if (value == noConnection) return 'Please check your internet connection.';
    if (value == null || value.isEmpty) {
      return 'Specify you HumHub location';
    }
    return null;
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

  static Uri assumeUrl(String url) {
    if (url.startsWith("https://") || url.startsWith("http://")) return Uri.parse(url);
    return Uri.parse("https://$url");
  }
}
