import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/components/toast.dart';
import 'package:humhub/pages/settings/provider.dart';

class DataSharingConsent extends ConsumerWidget {
  const DataSharingConsent({super.key});

  TextStyle get headerTextStyle => const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16.0,
        height: 24 / 16,
        letterSpacing: 0.0,
      );

  TextStyle get contentTextStyle => const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
        height: 22 / 14,
        letterSpacing: 0.25,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(dataSharingConsentProvider);
    final notifier = ref.read(dataSharingConsentProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Help us improve the HumHub App', style: headerTextStyle),
        const SizedBox(height: 12),
        Text(
          "To help us improve the app experience consider enabling the options below. "
          "This allows HumHub to receive anonymous error reports and basic device information, "
          "which helps us detect bugs faster, understand how the app performs in real conditions, "
          "and prioritize improvements.",
          style: contentTextStyle,
        ),
        const SizedBox(height: 20),
        ListTileTheme(
          data: const ListTileThemeData(
            titleAlignment: ListTileTitleAlignment.top,
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: 0,
            visualDensity: VisualDensity(horizontal: -4.0, vertical: 0),
          ),
          child: CheckboxListTile(
            value: consent.sendErrorReports,
            activeColor: Theme.of(context).primaryColor,
            checkColor: Theme.of(context).primaryColor,
            side: const BorderSide(
              color: Color(0xFFE5E5E5),
              width: 2,
            ),
            onChanged: (value) {
              notifier.setSendErrorReports(value ?? false);
              Toast.show(context, "Your choice has been saved.");
            },
            title: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Send anonymous error reports', style: headerTextStyle),
            ),
            subtitle: Text(
              'Includes crash logs and technical errors. No personal data is shared.',
              style: contentTextStyle,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        const SizedBox(height: 20),
        ListTileTheme(
          data: const ListTileThemeData(
            titleAlignment: ListTileTitleAlignment.top,
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: 0,
            visualDensity: VisualDensity(horizontal: -4.0, vertical: 0),
          ),
          child: CheckboxListTile(
            value: consent.sendDeviceIdentifiers,
            activeColor: Theme.of(context).primaryColor,
            checkColor: Theme.of(context).primaryColor,
            side: const BorderSide(
              color: Color(0xFFE5E5E5),
              width: 2,
            ),
            onChanged: (value) {
              notifier.setSendDeviceIdentifiers(value ?? false);
              Toast.show(context, "Your choice has been saved.");
            },
            title: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Send device and session identifiers', style: headerTextStyle),
            ),
            subtitle: Text(
              'Used to trace issues across devices and sessions. Helps reproduce bugs more accurately.',
              style: contentTextStyle,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ],
    );
  }
}
