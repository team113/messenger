import '/fluent/fluent_localization.dart';

extension Translate on String {
  String td({Map<String, dynamic> args = const {}}) {
    return LocalizationUtils.bundle.getTranslatedValue(this, args: args);
  }
}
