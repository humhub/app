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
      appBar: AppBar(automaticallyImplyLeading: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              LanguageSwitcher(),
              DataSharingConsent(),
            ],
          ),
        ),
      ),
    );
  }
}
