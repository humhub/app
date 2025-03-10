abstract class FileItemBase {
  final bool error;
  final String name;
  final int size;

  FileItemBase({
    required this.error,
    required this.name,
    required this.size,
  });

  static List<FileItemBase> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => FileItemBase.fromJson(json as Map<String, dynamic>)).toList();
  }

  factory FileItemBase.fromJson(Map<String, dynamic> json) {
    if (json['error'] == true) {
      return FileItemErrorResponse.fromJson(json);
    } else {
      return FileItemSuccessResponse.fromJson(json);
    }
  }
}

class FileItemSuccessResponse extends FileItemBase {
  final String guid;
  final String mimeType;
  final String mimeIcon;
  final String sizeFormat;
  final String url;
  final String relUrl;
  final String openLink;
  final String thumbnailUrl;

  FileItemSuccessResponse({
    required super.error,
    required super.name,
    required super.size,
    required this.guid,
    required this.mimeType,
    required this.mimeIcon,
    required this.sizeFormat,
    required this.url,
    required this.relUrl,
    required this.openLink,
    required this.thumbnailUrl,
  });

  factory FileItemSuccessResponse.fromJson(Map<String, dynamic> json) {
    return FileItemSuccessResponse(
      error: json['error'] as bool,
      name: json['name'] as String,
      size: json['size'] as int,
      guid: json['guid'] as String,
      mimeType: json['mimeType'] as String,
      mimeIcon: json['mimeIcon'] as String,
      sizeFormat: json['size_format'] as String,
      url: json['url'] as String,
      relUrl: json['relUrl'] as String,
      openLink: json['openLink'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'error': error,
    'name': name,
    'size': size,
    'guid': guid,
    'mimeType': mimeType,
    'mimeIcon': mimeIcon,
    'size_format': sizeFormat,
    'url': url,
    'relUrl': relUrl,
    'openLink': openLink,
    'thumbnailUrl': thumbnailUrl,
  };
}

class FileItemErrorResponse extends FileItemBase {
  final List<String> errors;

  FileItemErrorResponse({
    required super.error,
    required super.name,
    required super.size,
    required this.errors,
  });

  factory FileItemErrorResponse.fromJson(Map<String, dynamic> json) {
    return FileItemErrorResponse(
      error: json['error'] as bool,
      name: json['name'] as String? ?? '',
      size: int.tryParse(json['size'].toString()) ?? 0, // Handle possible string size
      errors: (json['errors'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'error': error,
    'name': name,
    'size': size,
    'errors': errors,
  };
}


