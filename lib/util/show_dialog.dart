import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ShowDialog {
  final BuildContext context;

  ShowDialog(this.context);

  static ShowDialog of(BuildContext context) {
    return ShowDialog(context);
  }

  noInternetPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.connectivity_popup_title),
          content: Text(AppLocalizations.of(context)!.connectivity_popup_content),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok.toUpperCase()),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}
