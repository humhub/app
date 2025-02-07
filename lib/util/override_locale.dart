import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OverrideLocale extends StatefulWidget {
  final Widget Function(Locale? locale) builder;

  const OverrideLocale({
    super.key,
    required this.builder,
  });

  @override
  OverrideLocaleState createState() => OverrideLocaleState();

  static OverrideLocaleModel of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<OverrideLocaleModel>();
    assert(
      result != null,
      'No OverrideLocale found in context'
      'Place OverrideLocale widget as high in widget tree as possible.',
    );
    return result!;
  }
}

class OverrideLocaleState extends State<OverrideLocale> {
  Locale? locale;

  @override
  void initState() {
    _loadFromPrefs();
    super.initState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.get("override_locale");
    final locale = saved != null ? Locale(saved as String) : null;
    setState(() {
      this.locale = locale;
    });
  }

  Future<void> _save(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove("override_locale");
    } else {
      await prefs.setString(
        "override_locale",
        locale.languageCode,
      );
    }
    setState(() {
      this.locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverrideLocaleModel(
      locale: locale,
      changeLocale: _save,
      child: widget.builder(locale),
    );
  }
}

class OverrideLocaleModel extends InheritedWidget {
  final Locale? locale;
  final ValueSetter<Locale?> changeLocale;

  const OverrideLocaleModel({
    super.key,
    required this.locale,
    required this.changeLocale,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant OverrideLocaleModel oldWidget) => locale != oldWidget.locale;
}
