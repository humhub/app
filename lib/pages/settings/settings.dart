import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/components/accept_all.dart';
import 'package:humhub/components/toast.dart';
import 'package:humhub/pages/settings/components/language_switcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:humhub/pages/settings/provider.dart';
import 'package:humhub/util/storage_service.dart';

import 'components/data_sharing_consent.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  static const String path = '/settings';

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends ConsumerState<SettingsPage> with SingleTickerProviderStateMixin {
  bool showButton = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SecureStorageService.setVisitedSettings();
      if (!context.mounted) return;
      final showBut = ModalRoute.of(context)?.settings.arguments as bool? ?? false;
      setState(() {
        showButton = showBut;
      });
    });
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
              Visibility(
                visible: showButton,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                  child: AcceptAllButton(onPressed: () {
                    ref.read(dataSharingConsentProvider.notifier).setSendDeviceIdentifiers(true);
                    ref.read(dataSharingConsentProvider.notifier).setSendErrorReports(true);
                    setState(() {
                      showButton = false;
                    });
                    Toast.show(context, AppLocalizations.of(context)!.data_sharing_saved);
                    Future.delayed(Duration(seconds: 4), () {
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    });
                  }),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
