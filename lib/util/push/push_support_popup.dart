import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/api_provider.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:loggy/loggy.dart';

final _provider = StateProvider<GlobalKey<_PushStatusWrapperState>>(
  (ref) => GlobalKey<_PushStatusWrapperState>(),
);

class PushStatusWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const PushStatusWrapper({Key? key, required this.child}) : super(key: key);

  static ConsumerState<PushStatusWrapper> of(WidgetRef ref) {
    final state = ref.read(_provider).currentState;
    assert(state != null, 'ConfigurationCheckWrapper is uninitialized.');
    return state!;
  }

  @override
  ConsumerState<PushStatusWrapper> createState() => _PushStatusWrapperState();
}

class _PushStatusWrapperState extends ConsumerState<PushStatusWrapper> {
  bool _hasShownWarning = false;

  @override
  void initState() {
    super.initState();
    checkConfiguration();
  }

  Future<void> checkConfiguration() async {
    Manifest? manifest = ref.read(humHubProvider).manifest;
    if (manifest == null) return;
    try {
      PushStatus? status = await APIProvider.of(ref).request(PushStatus.get(baseUrl: manifest.baseUrl)).valueOrNull;
      if (status == null) return;

      if (status.code == 200) {
        _showConfigurationWarning(status);
      }
    } catch (e) {
      logError('Can\'t get push module status.');
    }
  }

  void _showConfigurationWarning(PushStatus status, {bool force = false}) {
    if (_hasShownWarning && !force) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (navigatorKey.currentState?.context.mounted ?? false) /*&& status.code != 200*/) {
        _hasShownWarning = true;
        showDialog(
          context: navigatorKey.currentState!.context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.push_not_configured, style: TextStyle(fontSize: 20),),
              actions: <Widget>[
                TextButton(
                  child: Text(AppLocalizations.of(context)!.ok, style: TextStyle(fontSize: 16),),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class PushStatus {
  final int code;
  final String message;

  PushStatus({
    required this.code,
    required this.message,
  });

  factory PushStatus.fromJson(Map<String, dynamic> json) {
    return PushStatus(
      code: json['code'] as int,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
      };

  static Future<PushStatus> Function(Dio dio) get({required String baseUrl}) => (dio) async {
        Response<dynamic> res = await dio.get('$baseUrl/fcm-push/status');
        print("object");
        return PushStatus.fromJson(res.data);
      };
}
