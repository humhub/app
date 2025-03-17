import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/file_upload_settings.dart';
import 'package:humhub/models/shared_file_item.dart';
import 'package:humhub/util/extensions.dart';
import 'package:humhub/util/providers.dart';
import 'package:humhub/util/show_dialog.dart';
import 'package:humhub/util/web_view_global_controller.dart';
import 'package:loggy/loggy.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'intent/intent_state.dart';

/// Manages file uploads in the application
class FileUploadManager {
  final InAppWebViewController webViewController;
  final IntentNotifier intentNotifier;
  final FileUploadSettings? fileUploadSettings;
  final Map<String, String>? requestHeaders;
  final BuildContext context;

  /// Constructor for FileUploadManager
  ///
  /// [webViewController] is required for interacting with the web view
  /// [intentNotifier] is needed to access shared files
  /// [fileUploadSettings] contains configuration for file uploads
  /// [context] is necessary for showing dialogs and accessing localizations
  /// [requestHeaders] is optional and adds custom headers for requests
  const FileUploadManager({
    required this.webViewController,
    required this.intentNotifier,
    required this.fileUploadSettings,
    required this.context,
    this.requestHeaders,
  });

  /// Initiates the file upload process
  ///
  /// [showShareModal] determines whether to show a web share modal after upload
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
        ShowDialog.of(context).intentErrors([AppLocalizations.of(context)!.unexpected_error]);
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

  /// Validates the upload request
  ///
  /// [files] is the list of shared media files to be validated
  /// Returns a list of error messages, or null if no errors
  List<String>? _validateRequest(List<SharedMediaFile>? files) {
    List<String> errors = [];
    if (fileUploadSettings == null) {
      errors.add(AppLocalizations.of(context)!.sharing_not_supported);
      logError(errors);
      return errors;
    }

    if (files.isNullOrEmpty) {
      errors.add(AppLocalizations.of(context)!.no_files_to_share);
      logError(errors);
      return errors;
    }
    if (_filesSizeMb(files) > fileUploadSettings!.effectiveMaxFileSize) {
      int limit = fileUploadSettings!.effectiveMaxFileSize.round();
      errors.add(AppLocalizations.of(context)!.files_too_big(limit));
      logError(errors);
      return errors;
    }

    for (SharedMediaFile file in files!) {
      if (fileUploadSettings!.allowedExtensions != null && !fileUploadSettings!.allowedExtensions!.contains(file.fileExtension)) {
        errors.add(AppLocalizations.of(context)!.file_type_not_supported(file.thumbnail ?? '', file.type.value));
        logError(errors);
        continue;
      }
    }
    return errors.isEmpty ? null : errors;
  }

  /// Validates the upload response
  ///
  /// [files] is the list of shared file items returned from the upload
  /// Returns a list of error messages, or null if no errors
  List<String>? _validateResponse(List<SharedFileItem>? files) {
    List<String> errors = [];
    if (files.isNullOrEmpty) {
      errors.add(AppLocalizations.of(context)!.no_files_uploaded);
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
      errors.add(AppLocalizations.of(context)!.no_files_uploaded);
      logError(errors);
    }
    return errors.isNullOrEmpty ? null : errors;
  }

  /// Prepares the request data for file upload
  ///
  /// [sharedFiles] is the list of shared media files to be uploaded
  /// [settings] contains the file upload configuration
  /// Returns a list of maps containing file data
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

  /// Performs an AJAX POST request to upload files
  ///
  /// [data] is the file data to be uploaded
  /// [onResponse] is a callback function to handle the response
  Future<void> ajaxPostFiles({
    required List<dynamic> data,
    Function(List<SharedFileItem>? files)? onResponse,
  }) async {
    String jsonHeaders = jsonEncode(requestHeaders ?? {});
    String jsonData = jsonEncode(data);

    String jsCode = """
        new Promise((resolve, reject) => {
            try {
              var formData = new FormData();
              var parsedData = JSON.parse('$jsonData');
    
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

  /// Shows a modal dialog for sharing uploaded files
  ///
  /// [successFiles] is a list of successfully uploaded files
  _showFileShareModal(List<SharedFileItemSuccess> successFiles) async {
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

  double _filesSizeMb(List<SharedMediaFile>? files) {
    if (files.isNullOrEmpty) return 0;
    double totalSizeMB = 0.0;
    for (var file in files!) {
      File fileObj = File(file.path);
      int fileSizeBytes = fileObj.lengthSync();
      double fileSizeMB = fileSizeBytes / (1024 * 1024);
      totalSizeMB += fileSizeMB;
    }
    return totalSizeMB;
  }
}

/// Widget that manages file uploads in the context of the widget tree
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
