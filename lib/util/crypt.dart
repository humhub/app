import 'dart:convert';
import 'dart:math';

/// Utility class providing cryptographic and hashing functionality
class Crypt {
  /// Generates a random hexadecimal string of specified length
  ///
  /// Uses [Random.secure()] to generate cryptographically secure random numbers
  /// Returns a string of [length] characters using characters 0-9 and a-f
  static String generateRandomString(int length) {
    final random = Random.secure();
    const characters = '0123456789abcdef';
    return List.generate(
        length, (_) => characters[random.nextInt(characters.length)]).join();
  }

  /// Generates a deterministic hash of specified length from an input string
  ///
  /// Takes an [input] string and desired [length] of the output hash
  /// Uses a simple multiplication-based hashing algorithm
  /// Returns a hexadecimal string of exactly [length] characters
  static String generateHash(String input, int length) {
    final bytes = utf8.encode(input);
    int hash = 0;

    for (final byte in bytes) {
      hash = (hash * 31 + byte) & 0xFFFFFFFF;
    }

    final hashString = hash.toRadixString(16).padLeft(8, '0');

    if (length <= hashString.length) {
      return hashString.substring(0, length);
    } else {
      return hashString.padRight(length, '0');
    }
  }
}
