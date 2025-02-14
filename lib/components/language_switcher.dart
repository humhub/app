import 'package:flutter/material.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/override_locale.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSwitcher extends StatefulWidget {
  static Key userProfileLocaleDropdown = const Key('user_profile_locale_dropdown');
  const LanguageSwitcher({
    super.key,
    this.showTitle = false,
    this.forceLight = false,
  });

  final bool showTitle;
  final bool forceLight;

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
      key: LanguageSwitcher.userProfileLocaleDropdown,
      isExpanded: true,
      selectedItemBuilder: (_) {
        return _items
            .map(
              (locale) => Row(
                children: [
                  Image.asset("assets/images/locale/${locale}_locale_flag.png", height: 30, width: 30),
                  const SizedBox(width: 20),
                  Text(
                    locale.toUpperCase(),
                    style: TextStyle(color: HumhubTheme.primaryColor, fontSize: 16),
                  ),
                ],
              ),
            )
            .toList();
      },
      dropdownColor: widget.forceLight ? Colors.white : Theme.of(context).colorScheme.surface,
      decoration: widget.showTitle
          ? InputDecoration(
              labelText: AppLocalizations.of(context)!.cancel,
              enabledBorder: InputBorder.none,
              fillColor: Colors.black,
            )
          : InputDecoration.collapsed(
              hintText: AppLocalizations.of(context)!.cancel,
            ).copyWith(
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
      value: _value(context),
      icon: Icon(Icons.arrow_drop_down, color: HumhubTheme.primaryColor),
      items: _items
          .mapIndexed(
            (localeString, index) => DropdownMenuItem(
              value: index,
              child: Row(
                children: [
                  Image.asset("assets/images/locale/${localeString}_locale_flag.png", height: 30, width: 30),
                  const SizedBox(width: 20),
                  Text(
                    localeString.toUpperCase(),
                    style: TextStyle(color: HumhubTheme.primaryColor, fontSize: 16),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (index) {
        if (index == null) return;
        Locale? locale = AppLocalizations.supportedLocales.elementAt(index);
        OverrideLocale.of(context).changeLocale(locale);
      },
    );
  }

  Iterable<String> get _items => [
        ...AppLocalizations.supportedLocales.map((l) => l.languageCode),
      ];

  int _value(BuildContext context) {
    String localDef = Localizations.localeOf(context).toString();
    final index = AppLocalizations.supportedLocales.indexWhere(
      (locale) => localDef == locale.languageCode,
    );
    return index;
  }
}
