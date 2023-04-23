import 'package:flutter/material.dart';
import 'package:humhub/components/hatch_image.dart';

import '../../../util/const.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({Key? key}) : super(key: key);

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
                Locales.helpTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              Locales.helpFirstPar,
              style: const TextStyle(letterSpacing: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              Locales.helpSecPar,
              style: const TextStyle(letterSpacing: 0.5),
            ),
          ),
          const HatchImage(imageUrl: 'assets/images/help.png',)
        ],
      ),
    );
  }
}
