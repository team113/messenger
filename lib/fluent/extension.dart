import 'package:get/get.dart';
import 'package:messenger/fluent/fluent_localization.dart';

import 'localization_controller.dart';

extension Translate on String {
  String t({Map<String, dynamic> args = const {}}) {
    FluentLocalization? localizator =
        Get.find<LocalizationController>().localizator;
    return localizator == null
        ? this
        : localizator.getTranslatedValue(this, args: args);
  }
}
