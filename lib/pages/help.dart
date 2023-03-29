import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:humhub/util/const.dart';
import 'package:url_launcher/url_launcher.dart';

class Help extends StatefulWidget {
  const Help({Key? key}) : super(key: key);

  @override
  HelpState createState() => HelpState();
}

class HelpState extends State<Help> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HumHub App'),
        backgroundColor: const Color(0xff21A1B3),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 60),
                child: Image.asset('assets/images/logo.png'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                Locales.helpFirstPar,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                Locales.helpSecPar,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(Locales.helpThirdPar),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    TextSpan(style: Theme.of(context).textTheme.bodyMedium, text: Locales.helpForthPar),
                    TextSpan(
                      text: ' https://www.humhub.com',
                      style: const TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(Uri.parse('https://www.humhub.com'), mode: LaunchMode.externalApplication);
                        },
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text('We wish you a lot of fun and every success with the HumHub app.'),
            ),
          ],
        ),
      ),
    );
  }
}
