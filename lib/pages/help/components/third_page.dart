import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../util/const.dart';

class ThirdPage extends StatelessWidget {
  const ThirdPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                Locales.moreInfoTitle,
                style: getHeaderStyle(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(Locales.moreInfoFirstPar, style: paragraphStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(Locales.moreInfoSecPar, style: paragraphStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(Locales.moreInfoThirdPar, style: paragraphStyle),
          ),
          const SizedBox(
            height: 40,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width / 1.5,
                height: 50,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
                child: TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        return openerColor;
                      },
                    ),
                  ),
                  onPressed: () {
                    launchUrl(Uri.parse(Locales.moreInfoProEditionUrl), mode: LaunchMode.externalApplication);
                  },
                  child: Center(
                    child: Text(
                      Locales.moreInfoProEdition,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.normal),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
