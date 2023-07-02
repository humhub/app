import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityPlugin extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivityPlugin({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConnectivityPluginState createState() => ConnectivityPluginState();

  static Future<bool> get hasConnectivity async {
    ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}

class ConnectivityPluginState extends ConsumerState<ConnectivityPlugin> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult?>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snap) {
        if (snap.hasData) {
          // Process the data from the stream
          ConnectivityResult result = snap.data!;
          if (result == ConnectivityResult.none) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Use a small delay to show the dialog after the build phase
              NoConnectionDialog.show(context);
            });
          }
        }
        return widget.child;
      },
    );
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
