import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/providers.dart';
import 'package:http/http.dart' as http;
import 'api_provider.dart';
import 'form_helper.dart';
import 'dart:developer';

class OpenerController {
  late AsyncValue<Manifest>? asyncData;
  bool doesViewExist = false;
  final helper = FormHelper();
  TextEditingController urlTextController = TextEditingController();
  late String? postcodeErrorMessage;
  final String formUrlKey = "redirect_url";
  final String error404 = "404";
  final WidgetRef ref;

  OpenerController({required this.ref});

  findManifest(String url) async {
    Uri uri = assumeUrl(url);
    for (var i = uri.pathSegments.length - 1; i >= 0; i--) {
      String urlIn = "${uri.origin}/${uri.pathSegments.getRange(0, i).join('/')}";
      asyncData = await APIProvider.of(ref).request(Manifest.get(i != 0 ? urlIn : uri.origin));
      if (!asyncData!.hasError) break;
    }
    if (uri.pathSegments.isEmpty) {
      asyncData = await APIProvider.of(ref).request(Manifest.get(uri.origin));
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

  initHumHub() async {
    // Validate the URL format and if !value.isEmpty
    if (!helper.validate()) return;
    helper.save();
    // Get the manifest.json for given url.
    await findManifest(helper.model[formUrlKey]!);
    // If manifest.json does not exist the url is incorrect.
    // This is a temp. fix the validator expect sync. function this is some established workaround.
    // In the future we could define our own TextFormField that would also validate the API responses.
    // But it this is not acceptable I can suggest simple popup or tempPopup.
    if (asyncData!.hasError || !doesViewExist) {
      log("Open URL error: $asyncData");
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

  bool get allOk => !(asyncData!.hasError || !doesViewExist);

  Uri assumeUrl(String url) {
    if (url.startsWith("https://") || url.startsWith("http://")) return Uri.parse(url);
    return Uri.parse("https://$url");
  }

  String? validateUrl(String? value) {
    if (value == error404) return 'Your HumHub installation does not exist';

    if (value == null || value.isEmpty) {
      return 'Specify you HumHub location';
    }
    return null;
  }
}
