import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:humhub/models/manifest.dart';

class AuthWebViewArgs {
  final Manifest manifest;
  final URLRequest request;

  const AuthWebViewArgs({
    required this.manifest,
    required this.request,
  });
}
