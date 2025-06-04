import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

  BorderSide get borderSide => const BorderSide(
        color: Color(0xFFE5E5E5),
        width: 2,
      );

  ListTileThemeData get tileThemeData => ListTileThemeData(
        selectedColor: Color(0xFFF5F5F5),
        selectedTileColor: Color(0xFFF5F5F5),
        titleAlignment: ListTileTitleAlignment.top,
        contentPadding: const EdgeInsets.only(top: 10, bottom: 10, right: 5),
        minVerticalPadding: 0,
        visualDensity: const VisualDensity(horizontal: -4.0, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(dataSharingConsentProvider);
    final notifier = ref.read(dataSharingConsentProvider.notifier);
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.data_sharing_title, style: headerTextStyle),
        const SizedBox(height: 12),
        Text(
          loc.data_sharing_content,
          style: contentTextStyle,
        ),
        const SizedBox(height: 10),
        ListTileTheme(
          data: tileThemeData,
          child: CheckboxListTile(
            value: consent.sendErrorReports,
            activeColor: Theme.of(context).primaryColor,
            checkColor: Theme.of(context).primaryColor,
            side: borderSide,
            onChanged: (value) {
              notifier.setSendErrorReports(value ?? false);
              Toast.show(context, loc.data_sharing_saved);
            },
            title: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(loc.data_sharing_error_reports_title, style: headerTextStyle),
            ),
            subtitle: Text(
              loc.data_sharing_error_reports_subtitle,
              style: contentTextStyle,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        const SizedBox(height: 10),
        ListTileTheme(
          data: tileThemeData,
          child: CheckboxListTile(
            value: consent.sendDeviceIdentifiers,
            activeColor: Theme.of(context).primaryColor,
            checkColor: Theme.of(context).primaryColor,
            side: borderSide,
            onChanged: (value) {
              notifier.setSendDeviceIdentifiers(value ?? false);
              Toast.show(context, loc.data_sharing_saved);
            },
            title: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(loc.data_sharing_device_id_title, style: headerTextStyle),
            ),
            subtitle: Text(
              loc.data_sharing_device_id_subtitle,
              style: contentTextStyle,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ],
    );
  }
}
