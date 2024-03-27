import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:app_settings/app_settings.dart';

class ShowDialog {
  final BuildContext context;

  ShowDialog(this.context);

  static ShowDialog of(BuildContext context) {
    return ShowDialog(context);
  }

  void notificationPermission() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.notification_permission_popup_title),
        content: Text(AppLocalizations.of(context)!.notification_permission_popup_content),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.enable),
            onPressed: () {
              AppSettings.openAppSettings();
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.skip),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  noInternetPopup(){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text(AppLocalizations.of(context)!.connectivity_popup_title),
          content:  Text(AppLocalizations.of(context)!.connectivity_popup_content),
          actions: [
            TextButton(
              child:  Text(AppLocalizations.of(context)!.ok.toUpperCase()),
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
