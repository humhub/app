import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:humhub/l10n/generated/app_localizations.dart';
import 'package:humhub/util/const.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileActionsBottomSheet {
  FileActionsBottomSheet._();

  static Future<void> show(BuildContext context, File file, String filename) async {
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget actionTile({required IconData icon, required String label, required String value}) {
          return InkWell(
            onTap: () => Navigator.of(ctx).pop(value),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF0A1033)),
                  const SizedBox(width: 18),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF0A1033),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          bottom: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 84,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  actionTile(icon: Icons.open_in_new_outlined, label: l10n.open, value: 'open'),
                  const SizedBox(height: 6),
                  actionTile(icon: Icons.share_outlined, label: l10n.share, value: 'share'),
                  const SizedBox(height: 6),
                  actionTile(icon: Icons.download_outlined, label: l10n.save, value: 'save'),
                  const SizedBox(height: 6),
                  actionTile(icon: Icons.close, label: l10n.cancel, value: 'cancel'),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!context.mounted) return;
    if (action == 'open') {
      OpenFile.open(file.path);
    } else if (action == 'share') {
      await _share(context, file, filename);
    } else if (action == 'save') {
      await _save(context, file, filename);
    }
  }

  static Future<void> _save(BuildContext context, File file, String filename) async {
    final mimeType = lookupMimeType(filename);
    final savedLabel = AppLocalizations.of(context)!.file_download;
    final savedPath = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        sourceFilePath: file.path,
        fileName: filename,
        mimeTypesFilter: [if (mimeType != null) mimeType],
      ),
    );
    if (savedPath != null) {
      Keys.scaffoldMessengerStateKey.currentState?.showSnackBar(
        SnackBar(content: Text(savedLabel)),
      );
    }
  }

  static Future<void> _share(BuildContext context, File file, String filename) async {
    final mimeType = lookupMimeType(filename);
    final origin = _shareOrigin(context);
    if (Platform.isIOS) {
      final tempDir = await getTemporaryDirectory();
      final tempFile = await file.copy('${tempDir.path}/$filename');
      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: mimeType)],
        sharePositionOrigin: origin,
      );
      return;
    }
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      sharePositionOrigin: origin,
    );
  }

  static Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
