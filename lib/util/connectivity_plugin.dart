import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConnectivityPlugin {
  static Future<bool> get hasConnectivity async {
    List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}

class NoConnectionDialog extends StatelessWidget {
  const NoConnectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
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
  }

  static show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return NoConnectionDialog(
          key: context.widget.key,
        );
      },
    );
  }
}
