import '/fluent/fluent_localization.dart';

/// Extension on [String] that returns translated value depended from loaded
/// [LocalizationUtils.bundle].
extension Translate on String {
  /// Returns this translated [String] value depended from loaded
  /// [LocalizationUtils.bundle]
  String td({Map<String, dynamic> args = const {}}) {
    return LocalizationUtils.bundle.getTranslatedValue(this, args: args);
  }
}
