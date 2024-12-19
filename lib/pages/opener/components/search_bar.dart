import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/openers/opener_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:humhub/util/providers.dart';

class SearchBarWidget extends ConsumerWidget {
  final OpenerController openerControlLer;

  const SearchBarWidget({
    Key? key,
    required this.openerControlLer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: AnimatedOpacity(
              opacity: ref.watch(textFieldVisibilityProvider) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Column(
                  children: [
                    FutureBuilder<String>(
                      future: ref.read(humHubProvider).getLastUrl(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          openerControlLer.urlTextController.text = snapshot.data!;
                          return TextFormField(
                            keyboardType: TextInputType.url,
                            controller: openerControlLer.urlTextController,
                            cursorColor: Theme.of(context).textTheme.bodySmall?.color,
                            onSaved: openerControlLer.helper.onSaved(openerControlLer.formUrlKey),
                            onEditingComplete: () {
                              openerControlLer.helper.onSaved(openerControlLer.formUrlKey);
                              openerControlLer.connect();
                            },
                            onChanged: (value) {
                              final cursorPosition = openerControlLer.urlTextController.selection.baseOffset;
                              final trimmedValue = value.trim();
                              openerControlLer.urlTextController.value = TextEditingValue(
                                text: trimmedValue,
                                selection: TextSelection.collapsed(
                                    offset:
                                        cursorPosition > trimmedValue.length ? trimmedValue.length : cursorPosition),
                              );
                            },
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                            ),
                            decoration: _openerDecoration(context),
                            validator: (value) => openerControlLer.validateUrl(value, context),
                            autocorrect: false,
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        AppLocalizations.of(context)!.opener_enter_url,
                        style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: ref.watch(visibilityProvider) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: TextButton(
                onPressed: () {
                  openerControlLer.connect().then((value) {
                    ref
                        .watch(searchBarVisibilityNotifier.notifier)
                        .toggleVisibility(!ref.watch(searchBarVisibilityNotifier));
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: HumhubTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  minimumSize: const Size(140, 55),
                ),
                child: Text(
                  AppLocalizations.of(context)!.connect,
                  style: TextStyle(
                    color: HumhubTheme.primaryColor,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _openerDecoration(BuildContext context) => InputDecoration(
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelText: AppLocalizations.of(context)!.url.toUpperCase(),
        labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color),
      );
}
