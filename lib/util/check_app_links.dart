import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class AppLinksManager {
  static const String _packageName = 'com.humhub.app';
  static const String _channelName = 'app_links_channel';

  final BuildContext context;
  final MethodChannel _methodChannel;

  AppLinksManager(this.context) : _methodChannel = const MethodChannel(_channelName);

  Future<List<String>> _getUnsupportedLinks() async {
    if (!Platform.isAndroid) return [];

    try {
      final result = await _methodChannel.invokeMethod('checkOpenByDefault', {'packageName': _packageName});

      return (result['unsupportedUrls'] as List).cast<String>();
    } catch (e) {
      debugPrint('Error checking supported links: $e');
      return [];
    }
  }

  Future<void> checkAndShowLinksDialog() async {
    final unsupportedLinks = await _getUnsupportedLinks();
    if (unsupportedLinks.isEmpty) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => _buildDialog(unsupportedLinks),
    );
  }

  Widget _buildDialog(List<String> unsupportedLinks) {
    return AlertDialog(
      title: const Text('Enable Supported Links'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please enable all supported links in App Settings:'),
            const SizedBox(height: 12),
            ..._buildLinksList(unsupportedLinks),
          ],
        ),
      ),
      actions: _buildDialogActions(context),
    );
  }

  List<Widget> _buildLinksList(List<String> links) {
    return links
        .map((link) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '• $link',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ))
        .toList();
  }

  List<Widget> _buildDialogActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () async {
          await openAppSettings();
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
        child: const Text('Open Settings'),
      ),
    ];
  }
}
