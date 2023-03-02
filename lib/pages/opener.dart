import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/api_provider.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/form_helper.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/providers.dart';
import 'package:loggy/loggy.dart';
import 'help.dart';

class Opener extends ConsumerStatefulWidget {
  const Opener({Key? key}) : super(key: key);
  static const String path = '/opener';

  @override
  OpenerState createState() => OpenerState();
}

class OpenerState extends ConsumerState<Opener> {
  final helper = FormHelper();
  final String formUrlKey = "redirect_url";
  final String error404 = "404";
  late String? postcodeErrorMessage;
  TextEditingController urlTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: helper.key,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 60.0),
                child: Center(
                  child: Container(margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 20), child: Image.asset('assets/images/logo.png')),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 50),
                child: FutureBuilder<String>(
                  future: ref.read(humHubProvider).getLastUrl(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      urlTextController.text = snapshot.data!;
                      return TextFormField(
                        controller: urlTextController,
                        onSaved: helper.onSaved(formUrlKey),
                        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'URL', hintText: 'https://community.humhub.com'),
                        validator: validateUrl,
                      );
                    }
                    return progress;
                  },
                ),
              ),
              Container(
                height: 50,
                width: 250,
                decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                child: TextButton(
                  onPressed: onPressed,
                  child: const Text(
                    'Connect',
                    style: TextStyle(color: Colors.white, fontSize: 25),
                  ),
                ),
              ),
              const SizedBox(
                height: 130,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Help()),
                  );
                },
                child: const Text("Need Help?"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  onPressed() async {
    // Validate the URL format and if !value.isEmpty
    if (!helper.validate()) return;
    helper.save();
    // Get the manifest.json for given url.
    Uri url = assumeUrl(helper.model[formUrlKey]!);
    logInfo("Host: ${url.host}");
    AsyncValue<Manifest>? asyncData;
    for (var i = url.pathSegments.length - 1; i >= 0; i--) {
      String urlIn = "${url.origin}/${url.pathSegments.getRange(0, i).join('/')}";
      asyncData = await APIProvider.of(ref).request(Manifest.get(i != 0 ? urlIn : url.origin));
      if (!asyncData.hasError) break;
    }
    if (url.pathSegments.isEmpty) {
      asyncData = await APIProvider.of(ref).request(Manifest.get(url.origin));
    }
    // If manifest.json does not exist the url is incorrect.
    // This is a temp. fix the validator expect sync. function this is some established workaround.
    // In the future we could define our own TextFormField that would also validate the API responses.
    // But it this is not acceptable I can suggest simple popup or tempPopup.
    if (asyncData!.hasError) {
      log("Open URL error: $asyncData");
      String value = urlTextController.text;
      urlTextController.text = error404;
      helper.validate();
      urlTextController.text = value;
    } else {
      Manifest manifest = asyncData.value!;
      // Set the manifestStateProvider with the manifest value so that it's globally accessible
      // Generate hash and save it to store
      String lastUrl = await ref.read(humHubProvider).getLastUrl();
      String currentUrl = urlTextController.text;
      String hash = HumHub.generateHash(32);
      if (lastUrl == currentUrl) hash = ref.read(humHubProvider).randomHash ?? hash;
      ref.read(humHubProvider).setInstance(HumHub(manifest: manifest, randomHash: hash));
      redirect(manifest);
    }
  }

  redirect(Manifest manifest) {
    Navigator.pushNamed(context, WebViewApp.path, arguments: manifest);
  }

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
