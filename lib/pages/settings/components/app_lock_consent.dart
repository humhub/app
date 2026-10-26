import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/l10n/generated/app_localizations.dart';
import 'package:humhub/components/toast.dart';
import 'package:humhub/pages/settings/app_lock_provider.dart';
import 'package:humhub/util/app_lock_service.dart';

class AppLockConsent extends ConsumerWidget {
  const AppLockConsent({super.key});

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

  Future<void> _onChanged(BuildContext context, WidgetRef ref, bool value) async {
    final loc = AppLocalizations.of(context)!;
    final notifier = ref.read(appLockProvider.notifier);

    if (!value) {
      await notifier.setEnabled(false);
      if (context.mounted) Toast.show(context, loc.data_sharing_saved);
      return;
    }

    // Require one successful unlock before turning this on, so nobody can
    // lock themselves out of the app by accident.
    final verified = await AppLockService.authenticate(loc.app_lock_auth_reason_enable);
    if (!context.mounted) return;
    if (verified) {
      await notifier.setEnabled(true);
      if (context.mounted) Toast.show(context, loc.data_sharing_saved);
    } else {
      Toast.show(context, loc.app_lock_verification_failed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLock = ref.watch(appLockProvider);
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.app_lock_title, style: headerTextStyle),
        const SizedBox(height: 10),
        ListTileTheme(
          data: tileThemeData,
          child: CheckboxListTile(
            value: appLock.enabled,
            activeColor: Theme.of(context).primaryColor,
            checkColor: Theme.of(context).primaryColor,
            side: borderSide,
            onChanged: appLock.isSupported ? (value) => _onChanged(context, ref, value ?? false) : null,
            title: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(loc.app_lock_checkbox_title, style: headerTextStyle),
            ),
            subtitle: Text(
              appLock.isSupported ? loc.app_lock_checkbox_subtitle : loc.app_lock_unsupported_hint,
              style: contentTextStyle,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ],
    );
  }
}
