import 'package:flutter/material.dart';

class FileUploadSettings {
  final String fileUploadUrl;
  final String contentCreateUrl;
  final int maxFileSize;
  final List<String>? allowedExtensions;
  final Size? imageMaxResolution;
  final int? imageJpegQuality;
  final int? imagePngCompressionLevel;
  final int? imageWebpQuality;
  final int imageMaxProcessingMP;
  final bool denyDoubleFileExtensions;
  final List<dynamic> converterOptions;

  FileUploadSettings({
    required this.fileUploadUrl,
    required this.contentCreateUrl,
    required this.maxFileSize,
    this.allowedExtensions,
    this.imageMaxResolution,
    this.imageJpegQuality,
    this.imagePngCompressionLevel,
    this.imageWebpQuality,
    required this.imageMaxProcessingMP,
    required this.denyDoubleFileExtensions,
    required this.converterOptions,
  });

  factory FileUploadSettings.fromJson(Map<String, dynamic> json) {
    return FileUploadSettings(
      fileUploadUrl: json['fileUploadUrl'] as String,
      contentCreateUrl: json['contentCreateUrl'] as String,
      maxFileSize: json['maxFileSize'] as int,
      allowedExtensions: (json['allowedExtensions'] as String?)
          ?.split(',')
          .map((e) => e.trim()) // Optional: To remove any extra spaces
          .toList(),
      imageMaxResolution: json['imageMaxResolution'] != null
          ? (() {
              final parts = (json['imageMaxResolution'] as String).split('x');
              return Size(
                double.parse(parts[0]), // Parse width
                double.parse(parts[1]), // Parse height
              );
            })()
          : null,
      imageJpegQuality: json['imageJpegQuality'] as int?,
      imagePngCompressionLevel: json['imagePngCompressionLevel'] as int?,
      imageWebpQuality: json['imageWebpQuality'] as int?,
      imageMaxProcessingMP: json['imageMaxProcessingMP'] as int,
      denyDoubleFileExtensions: json['denyDoubleFileExtensions'] as bool,
      converterOptions: (json['converterOptions'] as List<dynamic>).map((e) => e).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileUploadUrl': fileUploadUrl,
      'contentCreateUrl': contentCreateUrl,
      'maxFileSize': maxFileSize,
      'allowedExtensions': allowedExtensions?.join(','),
      'imageMaxResolution': imageMaxResolution != null
          ? '${imageMaxResolution!.width.toInt()}x${imageMaxResolution!.height.toInt()}'
          : null,
      'imageJpegQuality': imageJpegQuality,
      'imagePngCompressionLevel': imagePngCompressionLevel,
      'imageWebpQuality': imageWebpQuality,
      'imageMaxProcessingMP': imageMaxProcessingMP,
      'denyDoubleFileExtensions': denyDoubleFileExtensions,
      'converterOptions': converterOptions,
    };
  }
}
