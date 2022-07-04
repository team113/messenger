import '/fluent/fluent_localization.dart';

extension Translate on String {
  String td({Map<String, dynamic> args = const {}}) {
    if (LocalizationUtils.bundle == null) {
      print('bundle = null');
      return this;
    }
    return LocalizationUtils.bundle.getTranslatedValue(this, args: args);
  }
}
