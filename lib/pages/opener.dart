import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/api_provider.dart';
import 'package:humhub/util/form_helper.dart';
import 'package:humhub/util/manifest.dart';
import 'help.dart';
import 'web_view.dart';

class Opener extends ConsumerStatefulWidget {
  const Opener({Key? key}) : super(key: key);

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
  void initState() {
    super.initState();
    /*checkAndRequestPermissions();*/
  }

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
                  child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 20),
                      child: Image.asset('assets/images/logo.png')),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 50),
                child: TextFormField(
                  controller: urlTextController,
                  onSaved: helper.onSaved(formUrlKey),
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'URL',
                      hintText: 'https://community.humhub.com'),
                  validator: validateUrl,
                ),
              ),
              Container(
                height: 50,
                width: 250,
                decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20)),
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
    AsyncValue<Manifest> asyncData = await APIProvider.of(ref).request(
      Manifest.get(helper.model[formUrlKey]!),
    );
    // If manifest.json does not exist the url is incorrect.
    // This is a temp. fix the validator expect sync. function this is some established workaround.
    // In the future we could define our own TextFormField that would also validate the API responses.
    // But it this is not acceptable I can suggest simple popup or tempPopup.
    if (asyncData.hasError) {
      log("Open URL error: $asyncData");
      String value = urlTextController.text;
      urlTextController.text = error404;
      helper.validate();
      urlTextController.text = value;
    } else {
      Manifest manifest = asyncData.value!;
      // Set the manifestStateProvider with the manifest value so that it's globally accessible
      ref.read(manifestStateProvider.notifier).state = manifest;
      redirect();
    }
  }

  redirect() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => WebViewApp(
                manifest: ref.read(manifestStateProvider),
              )),
    );
  }

  String? validateUrl(String? value) {
    if (value == error404) return 'Your HumHub installation does not exist';

    if (value == null || value.isEmpty) {
      return 'Specify you HumHub location';
    }
    if (!value.startsWith("https://") || !value.endsWith(".humhub.com")) {
      return 'Your HumHub URL is not in the right format';
    }
    return null;
  }
}
