import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/pages/settings/components/language_switcher.dart';

import 'components/data_sharing_consent.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  static const String path = '/settings';

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends ConsumerState<SettingsPage> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.all(Color(0xFFF5F5F5)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          icon: Padding(padding: const EdgeInsets.all(3.0), child: Icon(Icons.arrow_back)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              LanguageSwitcher(),
              SizedBox(
                height: 35,
              ),
              DataSharingConsent(),
            ],
          ),
        ),
      ),
    );
  }
}
