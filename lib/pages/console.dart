import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ConsolePage extends StatelessWidget {
  static const String routeName = '/console';
  static Talker talker = TalkerFlutter.init();

  const ConsolePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: TalkerView(
        talker: talker,
        theme: TalkerScreenTheme(
          cardColor: Colors.grey[700]!,
          backgroundColor: Colors.grey[800]!,
          textColor: Colors.white,
          logColors: {
            TalkerLogType.error.key: Colors.red,
            TalkerLogType.info.key: Colors.green,
            TalkerLogType.warning.key: Colors.orange,
          },
        ),
      ),
    );
  }
}