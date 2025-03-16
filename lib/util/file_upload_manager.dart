import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/file_upload_settings.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/models/shared_file_item.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/show_dialog.dart';
import 'package:humhub/util/web_view_global_controller.dart';
import 'package:loggy/loggy.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'intent/intent_state.dart';

class FileUploadManager {
  final InAppWebViewController webViewController;
  final IntentNotifier intentNotifier;
  final FileUploadSettings? fileUploadSettings;
  final HumHub? humhub;
  final BuildContext context;

  const FileUploadManager({
    required this.webViewController,
    required this.intentNotifier,
    required this.fileUploadSettings,
    required this.context,
    this.humhub,
  });

  Future<void> upload({bool showShareModal = true}) async {
    if (!context.mounted || intentNotifier.currentState.isSharedFilesNullOrEmpty()) return;
    List<SharedMediaFile>? files = intentNotifier.useSharedFiles()!;
    List<String>? errors = _validateRequest(files);
    if (!errors.isNullOrEmpty) {
      ShowDialog.of(context).intentErrors(errors!);
      return;
    }
    List<dynamic> requestData = await _getRequestData(files, fileUploadSettings!);
    if (requestData.isNullOrEmpty) {
      if (context.mounted) {
        ShowDialog.of(context).intentErrors(errors!);
      }
      return;
    }
    ajaxPostFiles(
      data: requestData,
      onResponse: (files) {
        List<String>? errors = _validateResponse(files);
        if (!errors.isNullOrEmpty) {
          ShowDialog.of(context).intentErrors(errors!);
          return;
        }
        List<SharedFileItemSuccess> successFiles = files!.whereType<SharedFileItemSuccess>().toList();
        if (showShareModal) {
          _showFileShareModal(successFiles);
        }
      },
    );
  }

  List<String>? _validateRequest(List<SharedMediaFile>? files) {
    List<String> errors = [];
    if (fileUploadSettings == null) {
      errors.add('Sharing files for this instance is not supported, contact admin');
      logError(errors);
      return errors;
    }

    if (files.isNullOrEmpty) {
      errors.add('No files found to share');
      logError(errors);
      return errors;
    }
    if (intentNotifier.filesSumSizeMb > 70) {
      errors.add('Files to big to share, limit is 70MB');
      logError(errors);
      return errors;
    }

    for (SharedMediaFile file in files!) {
      if (fileUploadSettings!.allowedExtensions != null && !fileUploadSettings!.allowedExtensions!.contains(file.fileExtension)) {
        errors.add('File ${file.thumbnail} of type ${file.type.value} is not supported');
        logError(errors);
        continue;
      }
    }
    return errors.isEmpty ? null : errors;
  }

  List<String>? _validateResponse(List<SharedFileItem>? files) {
    List<String> errors = [];
    if (files.isNullOrEmpty) {
      errors.add('No files were uploaded, contact admin for support');
      logError(errors);
      return errors;
    }
    List<SharedFileItemError> errorFiles = files!.whereType<SharedFileItemError>().toList();
    List<SharedFileItemSuccess> successFiles = files.whereType<SharedFileItemSuccess>().toList();
    for (var errorFile in errorFiles) {
      errors.addAll(errorFile.errors);
      logError(errors);
    }

    if (successFiles.isNullOrEmpty) {
      errors.add('No files were uploaded, contact admin for support');
      logError(errors);
    }
    return errors.isNullOrEmpty ? null : errors;
  }

  Future<List<Map<String, String>>> _getRequestData(List<SharedMediaFile> sharedFiles, FileUploadSettings settings) async {
    List<Map<String, String>> data = [];

    for (SharedMediaFile sharedMediaFile in sharedFiles) {
      Uint8List byteData;
      String filename = sharedMediaFile.path.split('/').last;

      if (sharedMediaFile.type == SharedMediaType.image) {
        File file = File(sharedMediaFile.path);
        Uint8List? compressedImageByteData = await FlutterImageCompress.compressWithFile(
          file.path,
          quality: settings.imageJpegQuality ?? 60,
          numberOfRetries: 3,
        );
        byteData = compressedImageByteData ?? await File(sharedMediaFile.path).readAsBytes();
      } else {
        byteData = await File(sharedMediaFile.path).readAsBytes();
      }

      String base64String = base64Encode(byteData);

      data.add({
        'base64': base64String,
        'filename': filename,
        'mimeType': sharedMediaFile.mimeTypeFromPath ?? 'application/octet-stream',
      });
    }

    return data;
  }

  Future<void> ajaxPostFiles({
    required List<dynamic> data,
    Function(List<SharedFileItem>? files)? onResponse,
  }) async {
    String jsonHeaders = jsonEncode(humhub?.customHeaders ?? {});
    String jsonData = jsonEncode(data);

    String jsCode = """
        new Promise((resolve, reject) => {
            try {
              var formData = new FormData();
              var parsedData = JSON.parse('$jsonData');
    
              // File processing remains the same
              for (var key in parsedData) {
                var value = parsedData[key];
                var binaryString = atob(value.base64);
                var binaryLength = binaryString.length;
                var binaryArray = new Uint8Array(binaryLength);
    
                for (var i = 0; i < binaryLength; i++) {
                  binaryArray[i] = binaryString.charCodeAt(i);
                }
    
                var blob = new Blob([binaryArray], { type: value.mimeType });
                var file = new File([blob], value.filename, { type: value.mimeType });
                formData.append('files[]', file);
              }
    
              // jQuery AJAX implementation
              \$.ajax({
                url: '${fileUploadSettings!.fileUploadUrl}',
                method: 'POST',
                data: formData,
                processData: false,
                contentType: false,
                headers: JSON.parse('$jsonHeaders'),
                success: function(data) {
                  window.flutter_inappwebview.callHandler('onAjaxSuccess', data);
                  resolve(data);
                },
                error: function(xhr) {
                  var error = {
                    status: xhr.status || 'unknown',
                    error: xhr.responseText || xhr.statusText
                  };
                  window.flutter_inappwebview.callHandler('onAjaxError', error);
                  reject(error);
                }
              });
            } catch (e) {
              console.error('Error in AJAX request:', e);
              window.flutter_inappwebview.callHandler('onAjaxError', { 
                status: 'exception', 
                error: e.message 
              });
              reject(e);
            }
          });
      """;

    await webViewController.evaluateJavascript(source: jsCode);
    if (onResponse != null) {
      webViewController.addJavaScriptHandler(
        handlerName: 'onAjaxSuccess',
        callback: (args) {
          if (args.isNotEmpty) {
            onResponse(SharedFileItem.listFromJson(args[0]['files']));
          } else {
            onResponse(null);
          }
        },
      );

      webViewController.addJavaScriptHandler(
        handlerName: 'onAjaxError',
        callback: (args) {
          onResponse(null);
        },
      );
    }
  }

  _showFileShareModal(List<SharedFileItemSuccess> successFiles) async {
    // Use asMap after converting to List
    String guids = successFiles.asMap().entries.map((entry) {
      int index = entry.key;
      SharedFileItemSuccess file = entry.value;
      return 'fileList[$index]=${file.guid}';
    }).join('&');

    String jsCode = """
    \$('#globalModal').modal('show');
    \$('#globalModal .modal-content').load('${fileUploadSettings!.shareIntendTargetUrl}?$guids');
  """;

    await webViewController.evaluateJavascript(source: jsCode);
  }
}

class FileUploadManagerWidget extends ConsumerStatefulWidget {
  final Widget child;
  const FileUploadManagerWidget({super.key, required this.child});

  @override
  ConsumerState<FileUploadManagerWidget> createState() => _FileUploadManagerWidgetState();
}

class _FileUploadManagerWidgetState extends ConsumerState<FileUploadManagerWidget> {
  @override
  Widget build(BuildContext context) {
    ref.listen(
      intentProvider,
      (previous, next) async {
        FileUploadManager(
                webViewController: WebViewGlobalController.value!,
                intentNotifier: ref.read(intentProvider.notifier),
                fileUploadSettings: ref.read(humHubProvider).fileUploadSettings,
                context: context)
            .upload();
      },
    );

    return widget.child;
  }
}
