abstract class SharedFileItem {
  final bool error;
  final String name;
  final int size;

  SharedFileItem({
    required this.error,
    required this.name,
    required this.size,
  });

  static List<SharedFileItem> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => SharedFileItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  factory SharedFileItem.fromJson(Map<String, dynamic> json) {
    if (json['error'] == true) {
      return SharedFileItemError.fromJson(json);
    } else {
      return SharedFileItemSuccess.fromJson(json);
    }
  }
}

class SharedFileItemSuccess extends SharedFileItem {
  final String guid;
  final String mimeType;
  final String mimeIcon;
  final String sizeFormat;
  final String url;
  final String relUrl;
  final String openLink;
  final String thumbnailUrl;

  SharedFileItemSuccess({
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

  factory SharedFileItemSuccess.fromJson(Map<String, dynamic> json) {
    return SharedFileItemSuccess(
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

class SharedFileItemError extends SharedFileItem {
  final List<String> errors;

  SharedFileItemError({
    required super.error,
    required super.name,
    required super.size,
    required this.errors,
  });

  factory SharedFileItemError.fromJson(Map<String, dynamic> json) {
    return SharedFileItemError(
      error: json['error'] as bool,
      name: json['name'] as String? ?? '',
      size: int.tryParse(json['size'].toString()) ?? 0, // Handle possible string size
      errors: (json['errors'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'error': error,
        'name': name,
        'size': size,
        'errors': errors,
      };
}
