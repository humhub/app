import 'package:flutter/material.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/override_locale.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LocaleSwitch extends StatefulWidget {
  final double width;
  static Key userProfileLocaleDropdown = const Key('user_profile_locale_dropdown');
  const LocaleSwitch({
    Key? key,
    this.showTitle = false,
    this.forceLight = false,
    this.width = 100,
  }) : super(key: key);

  final bool showTitle;
  final bool forceLight;

  @override
  State<LocaleSwitch> createState() => _LocaleSwitchState();
}

class _LocaleSwitchState extends State<LocaleSwitch> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: DropdownButtonFormField<int>(
        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
        key: LocaleSwitch.userProfileLocaleDropdown,
        selectedItemBuilder: (_) {
          return _items
              .map(
                (e) => Text(
                  e.toUpperCase(),
                ),
              )
              .toList();
        },
        dropdownColor: widget.forceLight ? Colors.white : Theme.of(context).colorScheme.background,
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
        isExpanded: true,
        value: _value(context),
        icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
        items: _items
            .mapIndexed(
              (text, index) => DropdownMenuItem(
                value: index,
                child: Text(
                  text.toUpperCase(),
                ),
              ),
            )
            .toList(),
        onChanged: (index) {
          if (index == null) return;
          Locale? locale = AppLocalizations.supportedLocales.elementAt(index);
          OverrideLocale.of(context).changeLocale(locale);
        },
      ),
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
