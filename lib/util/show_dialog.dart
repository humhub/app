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
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  intentErrors(List<String> errors) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ErrorListPopup(title: AppLocalizations.of(context)!.file_sharing_error, errors: errors);
        });
  }
}

class ErrorListPopup extends StatelessWidget {
  final String title;
  final List<String> errors;

  const ErrorListPopup({super.key, required this.errors, required this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var error in errors)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("• ", style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 30,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.transparent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context)!.close,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
