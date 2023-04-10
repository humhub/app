import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/api_provider.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/form_helper.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/providers.dart';
import 'package:loggy/loggy.dart';
import 'package:rive/rive.dart';
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
  late RiveAnimationController?  riveController;
  Artboard? _riveArtboard;

  void _togglePlay() {
    if (riveController == null) {
      return;
    }
    setState(() => riveController!.isActive = !riveController!.isActive);
  }

  @override
  void initState() {
    super.initState();
    rootBundle.load('assets/opener_animation.riv').then(
          (data) async {
        // Load the RiveFile from the binary data.
        final file = RiveFile.import(data);
        final artboard = file.mainArtboard;
        // ignore: cascade_invocations
        artboard.addController(riveController = SimpleAnimation('animation'));
        setState(() => _riveArtboard = artboard);

      },
    );
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration openerDecoration = InputDecoration(
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelText: 'URL',
        labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color),
        hintText: 'https://community.humhub.com');

    return SafeArea(
      child: Scaffold(
        body: Form(
          key: helper.key,
          child: Stack(
            children: [
              Rive(artboard: _riveArtboard!),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 120.0),
                    child: Center(
                      child: SizedBox(height: 100, width: 230, child: Image.asset('assets/images/logo.png')),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 35, right: 35, top: 80, bottom: 8),
                    child: FutureBuilder<String>(
                      future: ref.read(humHubProvider).getLastUrl(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          urlTextController.text = snapshot.data!;
                          return TextFormField(
                            controller: urlTextController,
                            cursorColor: Theme.of(context).textTheme.bodySmall?.color,
                            onSaved: helper.onSaved(formUrlKey),
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                            ),
                            decoration: openerDecoration,
                            validator: validateUrl,
                          );
                        }
                        return progress;
                      },
                    ),
                  ),
                  const Text(
                    'Enter your url and log in to your network.',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                  Container(
                    height: 50,
                    width: 250,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                    child: TextButton(
                      onPressed: onPressed,
                      child: Text(
                        'Connect',
                        style: TextStyle(color: openerColor, fontSize: 20),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _togglePlay();
                      /*Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Help()),
                      );*/
                    },
                    child: const Text("Need Help?"),
                  ),
                ],
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
