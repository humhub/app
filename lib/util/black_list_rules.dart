class BlackListRules {
  // Define the blacklist of URLs
  static const List<String> _blacklist = [
    'https://discord.com/',
  ];

  /// Checks if the provided [url] is on the blacklist.
  /// Returns true if the URL is blacklisted, false otherwise.
  static bool check(String url) {
    // Normalize the URL by trimming whitespace and converting to lowercase
    final normalizedUrl = url.trim().toLowerCase();

    // Check if the normalized URL is in the blacklist
    return _blacklist.contains(normalizedUrl);
  }
}