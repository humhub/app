import 'dart:convert';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:humhub/models/global_package_info.dart';
import 'package:humhub/util/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class FileDownloadManager {
  final InAppWebViewController controller;
  final DownloadStartRequest downloadStartRequest;
  final String? filename;
  final Function(Exception ex)? onError;
  final Function(File file, String filename) onSuccess;
  final Function(double progress)? onProgress;
  final Function()? onStart;

  static const String _jsCode = """
    function downloadFile(url) {
        fetch(url)
            .then(async response => {
                const reader = response.body.getReader();
                const contentLength = response.headers.get('Content-Length');
                let receivedLength = 0;

                try {
                    while (true) {
                        const { done, value } = await reader.read();
                        if (done) {
                            window.flutter_inappwebview.callHandler('onDownloadComplete');
                            break;
                        }

                        receivedLength += value.length;

                        // Convert chunk to Base64
                        const base64Chunk = arrayBufferToBase64(value.buffer);
                        window.flutter_inappwebview.callHandler('onChunk', base64Chunk);

                        if (contentLength) {
                            const progress = (receivedLength / contentLength) * 100;
                            window.flutter_inappwebview.callHandler('onProgress', progress);
                        }
                    }
                } catch (error) {
                    console.error('Stream error:', error);
                    window.flutter_inappwebview.callHandler('onError', error.toString());
                }
            })
            .catch(error => {
                console.error('Fetch error:', error);
                window.flutter_inappwebview.callHandler('onError', error.toString());
            });
    }

    function arrayBufferToBase64(buffer) {
        let binary = '';
        const bytes = new Uint8Array(buffer);
        const len = bytes.byteLength;

        for (let i = 0; i < len; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        return btoa(binary);
    }
  """;

  const FileDownloadManager({
    required this.controller,
    required this.downloadStartRequest,
    required this.onSuccess,
    this.filename,
    this.onError,
    this.onProgress,
    this.onStart,
  });

  void download() {
    PermissionHandler.runWithPermissionCheck(
      permissions: [],
      action: () => _download(),
    );
  }

  Future<void> _download() async {
    try {
      onStart?.call();

      Directory? directory = await _getDownloadDirectory();
      if (directory == null) throw Exception("no_download_folder_found");

      String endFilename = filename ?? downloadStartRequest.suggestedFilename ?? await _generateFilename();
      String filePath = await _generateUniqueFilePath(directory, endFilename);
      File file = File(filePath);
      IOSink fileSink = file.openWrite();

      // Inject JavaScript for file download
      await controller.evaluateJavascript(source: _jsCode);
      await controller.evaluateJavascript(
        source: "downloadFile('${downloadStartRequest.url}');",
      );

      // Handle chunked data
      controller.addJavaScriptHandler(
        handlerName: 'onChunk',
        callback: (args) async {
          String base64Chunk = args[0];
          List<int> chunkBytes = base64Decode(base64Chunk);
          fileSink.add(chunkBytes); // Write to file
        },
      );

      // Handle progress
      controller.addJavaScriptHandler(
        handlerName: 'onProgress',
        callback: (args) {
          double progress = double.parse(args[0].toString());
          onProgress?.call(progress);
        },
      );

      // Handle download completion
      controller.addJavaScriptHandler(
        handlerName: 'onDownloadComplete',
        callback: (args) async {
          await fileSink.close();
          onSuccess(file, endFilename);
        },
      );

      // Handle errors
      controller.addJavaScriptHandler(
        handlerName: 'onError',
        callback: (args) async {
          String errorMessage = args[0].toString();
          await fileSink.close();
          file.deleteSync();
          onError?.call(Exception(errorMessage));
        },
      );
    } catch (e) {
      if (e is Exception) onError?.call(e);
    }
  }

  // ignore: unused_element
  Future<(File file, String filename)> _saveFile(String base64Data) async {
    final decodedBytes = base64Decode(base64Data.split(",").last);

    Directory? directory = await _getDownloadDirectory();
    if (directory == null) throw Exception("no_download_folder_found");

    String endFilename = filename ?? downloadStartRequest.suggestedFilename ?? await _generateFilename();
    String filePath = await _generateUniqueFilePath(directory, endFilename);

    File file = File(filePath);
    await file.writeAsBytes(decodedBytes);
    if (!await file.exists()) throw Exception("file_was_not_created");

    return (file, endFilename);
  }

  Future<String> _generateFilename() async {
    String appName = GlobalPackageInfo.info.appName.replaceAll(' ', '_');
    return '${appName}file';
  }

  Future<String> _generateUniqueFilePath(Directory directory, String baseFilename) async {
    String filePath = '${directory.path}/$baseFilename';
    int counter = 1;

    while (File(filePath).existsSync()) {
      String newFilename = '($counter)$baseFilename';
      filePath = '${directory.path}/$newFilename';
      counter++;
    }

    return filePath;
  }

  Future<Directory?> _getDownloadDirectory() async {
    Directory? directory;

    if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      String check = (await getExternalStorageDirectory())?.path ?? '';

      bool dirDownloadExists = await Directory(check).exists();
      if (dirDownloadExists) {
        directory = Directory(check);
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
    }

    return directory;
  }
}
