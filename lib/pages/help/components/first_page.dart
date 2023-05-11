import 'package:flutter/material.dart';
import 'package:humhub/components/hatch_image.dart';
import 'package:humhub/components/rotating_globe.dart';

import '../../../util/const.dart';

class FirstPage extends StatelessWidget {
  final bool fadeIn;
  const FirstPage({Key? key, required this.fadeIn}) : super(key: key);

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
                style: getHeaderStyle(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              Locales.helpFirstPar,
              style: getParagraphStyle(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              Locales.helpSecPar,
              style: getParagraphStyle(context),
            ),
          ),
          SizedBox(
            height: 320,
            child: Center(
              child: RotatingGlobe(
                rotationDirection: fadeIn ? Direction.left : Direction.right,
                imagePath: 'assets/images/help.png',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
