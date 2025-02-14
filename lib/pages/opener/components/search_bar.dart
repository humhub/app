import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/openers/opener_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  final OpenerController openerControlLer;

  const SearchBarWidget({
    super.key,
    required this.openerControlLer,
  });

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AnimatedOpacity(
            opacity: ref.watch(textFieldVisibilityProvider) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              child: Column(
                children: [
                  TextFormField(
                    keyboardType: TextInputType.url,
                    controller: widget.openerControlLer.urlTextController,
                    cursorColor: Theme.of(context).textTheme.bodySmall?.color,
                    onSaved: widget.openerControlLer.helper
                        .onSaved(widget.openerControlLer.formUrlKey),
                    onEditingComplete: connect,
                    onChanged: (value) {
                      final cursorPosition = widget.openerControlLer
                          .urlTextController.selection.baseOffset;
                      final trimmedValue = value.trim();
                      widget.openerControlLer.urlTextController.value =
                          TextEditingValue(
                        text: trimmedValue,
                        selection: TextSelection.collapsed(
                            offset: cursorPosition > trimmedValue.length
                                ? trimmedValue.length
                                : cursorPosition),
                      );
                    },
                    style: const TextStyle(
                      decoration: TextDecoration.none,
                    ),
                    decoration: _openerDecoration(context),
                    validator: (value) =>
                        widget.openerControlLer.validateUrl(value, context),
                    autocorrect: false,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: Text(
                      AppLocalizations.of(context)!.opener_enter_url,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: AnimatedOpacity(
              opacity: ref.watch(visibilityProvider) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: TextButton(
                  onPressed: connect,
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
          ),
        ],
      ),
    );
  }

  connect() async {
    setState(() {
      _isLoading = true;
    });
    try {
      widget.openerControlLer.helper
          .onSaved(widget.openerControlLer.formUrlKey);
      bool isSuc = await widget.openerControlLer.connect();
      Future.delayed(const Duration(seconds: 1), () {
        if (isSuc) {
          ref.watch(searchBarVisibilityNotifier.notifier).toggleVisibility();
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
        suffixIcon: _isLoading
            ? Container(
                margin: const EdgeInsets.all(14),
                width: 4,
                height: 4,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: HumhubTheme.primaryColor,
                ),
              )
            : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelText: AppLocalizations.of(context)!.url.toUpperCase(),
        labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodySmall?.color),
      );
}
