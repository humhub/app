import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityPlugin {
  static Future<bool> get hasConnectivity async {
    ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}

class NoConnectionDialog extends StatelessWidget {
  const NoConnectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('No Connection'),
      content: const Text('Please check your internet connection and try again.'),
      actions: [
        TextButton(
          child: const Text('OK'),
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
        return const NoConnectionDialog();
      },
    );
  }
}
