import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:humhub/components/toast.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/override_locale.dart';
import 'package:humhub/l10n/generated/app_localizations.dart';

class LanguageSwitcher extends StatefulWidget {
  const LanguageSwitcher({
    super.key,
    this.showTitle = false,
    this.forceLight = false,
    this.onChange,
  });

  final bool showTitle;
  final bool forceLight;
  final void Function(Locale oldLocale, Locale newLocale)? onChange;

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  int? selectedIndex;

  Color borderColor = Color(0xFFE5E5E5);
  double borderWidth = 1.5;

  TextStyle textStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 15.0,
    height: 1.5,
    letterSpacing: 0.25,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    selectedIndex = _value(context);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items.toList();
    final selectedLocale = selectedIndex != null ? items[selectedIndex!] : items[0];

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: constraints.maxWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: MenuAnchor(
          style: MenuStyle(
            backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
            elevation: WidgetStateProperty.all<double>(0),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0), side: BorderSide(color: borderColor, width: borderWidth)),
            ),
          ),
          alignmentOffset: Offset(-13, 12),
          builder: (BuildContext context, MenuController controller, Widget? child) {
            return InkWell(
              onTap: () {
                setState(() {
                  controller.isOpen ? controller.close() : controller.open();
                });
              },
              child: Row(
                children: [
                  SvgPicture.asset(
                    Assets.localeFlag(selectedLocale),
                    height: 27,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(languageNameGetters[selectedLocale]?.call(AppLocalizations.of(context)!) ?? selectedLocale, style: textStyle),
                  ),
                  Icon(
                    size: 28,
                    Icons.keyboard_arrow_down,
                    color: borderColor,
                  ),
                ],
              ),
            );
          },
          menuChildren: items
              .mapIndexed(
                (localeString, index) => SizedBox(
                  width: constraints.maxWidth,
                  child: MenuItemButton(
                    leadingIcon: SvgPicture.asset(
                      Assets.localeFlag(localeString),
                      height: 27,
                    ),
                    onPressed: () {
                      final oldLocale = AppLocalizations.supportedLocales[selectedIndex ?? 0];
                      setState(() {
                        selectedIndex = index;
                      });
                      final newLocale = AppLocalizations.supportedLocales[index];
                      OverrideLocale.of(context).changeLocale(newLocale);

                      if (oldLocale != newLocale) {
                        Future.delayed(Duration(milliseconds: 100), (){
                          if(!context.mounted) return;
                          Toast.show(context, AppLocalizations.of(context)!.language_saved);
                        });

                      }
                    },
                    child: Text(languageNameGetters[localeString]?.call(AppLocalizations.of(context)!) ?? localeString, style: textStyle),
                  ),
                ),
              )
              .toList(),
        ),
      );
    });
  }

  Iterable<String> get _items => [
        ...AppLocalizations.supportedLocales.map((l) => l.languageCode),
      ];

  int _value(BuildContext context) {
    String localDef = Localizations.localeOf(context).languageCode;
    final index = AppLocalizations.supportedLocales.indexWhere(
      (locale) => localDef == locale.languageCode,
    );
    return index >= 0 ? index : 0;
  }

  final languageNameGetters = <String, String Function(AppLocalizations)>{
    'en': (l10n) => '${l10n.language_en} (EN)',
    'de': (l10n) => '${l10n.language_de} (DE)',
    'fr': (l10n) => '${l10n.language_fr} (FR)',
  };
}
