import 'dart:math';

import '../l10n/l10n.dart';

/// Utility class for handling file size formatting.
class FileUtils {
  /// List of suffixes representing different file size units.
  static List<String> suffixes = [
    'label_b'.l10n,
    'label_kb'.l10n,
    'label_mb'.l10n,
    'label_gb'.l10n,
    'label_tb'.l10n,
    'label_pb'.l10n,
  ];

  /// Formats the given file size in bytes into a human-readable string.
  ///
  /// The method calculates the appropriate unit (bytes, kilobytes, megabytes,
  /// gigabytes, terabytes, petabytes) and formats the size accordingly.
  ///
  /// Throws [ArgumentError] if the provided file size is negative.
  ///
  /// Example:
  /// ```dart
  /// print(FileUtils.formatSize(bytes: 1000)); // Output: "1000 B"
  /// print(FileUtils.formatSize(bytes: 2048)); // Output: "2.0 KB"
  /// ```
  static String formatSize({required int bytes}) {
    if (bytes == 0) {
      return '0 ${suffixes[0]}';
    }

    if (bytes < 0) {
      throw ArgumentError('File size must be a non-negative integer.');
    }

    final i = (log(bytes) / log(1024)).floor();
    final sizeValue = bytes / pow(1024, i);

    return '${i == 0 ? sizeValue.round() : sizeValue.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
