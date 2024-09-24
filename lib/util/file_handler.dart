import 'dart:convert';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:humhub/util/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class FileHandler {
  final InAppWebViewController controller;
  final DownloadStartRequest downloadStartRequest;
  final String? filename;
  final Function(Exception ex)? onError;
  final Function(File file, String filename) onSuccess;
  static const String _jsCode = """
    function downloadFile(url) {
        fetch(url, {
            headers: {
                // Include necessary headers for authentication if needed
                'Authorization': 'Bearer <your_token>'
            }
        })
        .then(response => response.blob())
        .then(blob => {
            const reader = new FileReader();
            reader.readAsDataURL(blob); 
            reader.onloadend = function() {
                const base64data = reader.result;
                // Send the base64 content to Flutter
                window.flutter_inappwebview.callHandler('downloadFile', base64data);
            }
        })
        .catch(error => console.error('Error downloading file:', error));
    }
  """;

  const FileHandler({
    required this.controller,
    required this.downloadStartRequest,
    required this.onSuccess,
    this.filename,
    this.onError,
  });

  download() {
    PermissionHandler.runWithPermissionCheck(
      permissions: [],
      action: () => _download(),
    );
  }

  _download() async {
    try {
      await controller.evaluateJavascript(source: _jsCode);
      await controller.evaluateJavascript(source: "downloadFile('${downloadStartRequest.url.toString()}');");
      controller.addJavaScriptHandler(
          handlerName: 'downloadFile',
          callback: (args) async {
            String base64Data = args[0];
            var (file, filename) = await _saveFile(base64Data);
            onSuccess(file, filename);
          });
    } catch (er) {
      if (er is Exception && onError != null) {
        onError!(er);
      }
      //rethrow;
    }
  }

  Future<(File file, String filename)> _saveFile(String base64Data) async {
    // Decode base64 string to binary data
    final decodedBytes = base64Decode(base64Data.split(",").last); // In case there's a base64 header

    // Get the directory for storing files
    Directory? directory = await _getDownloadDirectory();
    if (directory == null) throw Exception("no_download_folder_found");
    // Set a default filename if not provided
    String endFilename = filename ?? downloadStartRequest.suggestedFilename ?? await _generateFilename();

    // Generate a unique file path
    String filePath = await _generateUniqueFilePath(directory, endFilename);

    // Write the decoded data to the file
    File file = File(filePath);
    await file.writeAsBytes(decodedBytes);
    if (!await file.exists()) throw Exception("file_was_not_created");
    return (file, endFilename);
  }

  Future<String> _generateFilename() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appName = packageInfo.appName;
    String filename = '${appName}file';

    // Replace spaces with underscores
    filename = filename.replaceAll(' ', '_');

    return filename;
  }

  Future<String> _generateUniqueFilePath(Directory directory, String baseFilename) async {
    String filePath = '${directory.path}/$baseFilename';
    int counter = 1;

    while (File(filePath).existsSync()) {
      // Append a number in parentheses to the baseFilename
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
