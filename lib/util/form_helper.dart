import 'package:flutter/cupertino.dart';

class FormHelper {
  final key = GlobalKey<FormState>();
  final model = <String, String?>{};

  FormFieldSetter<String> onSaved(String name) => (value) => model[name] = value;

  ValueGetter<String?> get(String name) => () => model[name];

  bool validate() => key.currentState?.validate() ?? false;

  void save() => key.currentState?.save();
}