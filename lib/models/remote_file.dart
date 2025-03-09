class FileItem {
  final bool error;
  final String name;
  final String guid;
  final int size;
  final String mimeType;
  final String mimeIcon;
  final String sizeFormat;
  final String url;
  final String relUrl;
  final String openLink;
  final String thumbnailUrl;

  FileItem({
    required this.error,
    required this.name,
    required this.guid,
    required this.size,
    required this.mimeType,
    required this.mimeIcon,
    required this.sizeFormat,
    required this.url,
    required this.relUrl,
    required this.openLink,
    required this.thumbnailUrl,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      error: json['error'] as bool,
      name: json['name'] as String,
      guid: json['guid'] as String,
      size: json['size'] as int,
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
    'guid': guid,
    'size': size,
    'mimeType': mimeType,
    'mimeIcon': mimeIcon,
    'size_format': sizeFormat,
    'url': url,
    'relUrl': relUrl,
    'openLink': openLink,
    'thumbnailUrl': thumbnailUrl,
  };

  static List<FileItem> listFromJson(Map<String, dynamic> json) {
    final filesList = json['files'] as List<dynamic>;
    return filesList
        .map((fileJson) => FileItem.fromJson(fileJson as Map<String, dynamic>))
        .toList();
  }
}