import 'package:flutter/material.dart';
import 'package:humhub/components/rotating_globe.dart';
import 'package:humhub/util/const.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FirstPage extends StatelessWidget {
  final bool fadeIn;
  const FirstPage({
    super.key,
    required this.fadeIn,
  });

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
                AppLocalizations.of(context)!.help_title,
                style: HumhubTheme.getHeaderStyle(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              AppLocalizations.of(context)!.help_first_par,
              style: HumhubTheme.paragraphStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(AppLocalizations.of(context)!.help_second_par, style: HumhubTheme.paragraphStyle),
          ),
          Center(
            child: RotatingGlobe(
              rotationDirection: fadeIn ? Direction.left : Direction.right,
              imagePath: Assets.helpImg,
            ),
          ),
        ],
      ),
    );
  }
}
