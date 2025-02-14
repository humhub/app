import 'package:flutter/material.dart';
import 'package:humhub/components/ease_out_container.dart';
import 'package:humhub/util/const.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SecondPage extends StatelessWidget {
  final bool fadeIn;
  const SecondPage({super.key, required this.fadeIn});

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
                AppLocalizations.of(context)!.how_to_connect_title,
                style: HumhubTheme.getHeaderStyle(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(AppLocalizations.of(context)!.how_to_connect_first_par, style: HumhubTheme.paragraphStyle),
          ),
          EaseOutContainer(
            fadeIn: fadeIn,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20, left: 4),
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.grey[200],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 4,
                    ),
                    Icon(
                      Icons.public,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'https://',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            TextSpan(
                              text: AppLocalizations.of(context)!.how_to_connect_url_example,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(AppLocalizations.of(context)!.how_to_connect_sec_par, style: HumhubTheme.paragraphStyle),
          ),
          EaseOutContainer(
            fadeIn: fadeIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width / 2,
                  height: 50,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          return HumhubTheme.primaryColor;
                        },
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.connect,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(AppLocalizations.of(context)!.how_to_connect_third_par, style: HumhubTheme.paragraphStyle),
          )
        ],
      ),
    );
  }
}
