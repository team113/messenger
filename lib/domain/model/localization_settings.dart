import 'package:hive/hive.dart';

import '/domain/model_type_id.dart';

part 'localization_settings.g.dart';

/// [LocalizationSettings] used for saving last showed [locale] of the
///  application.
@HiveType(typeId: ModelTypeId.localeSettings)
class LocalizationSettings extends HiveObject {
  LocalizationSettings({this.locale});

  /// [Locale] value converted to string.
  /// For example: "en_US", "ru_ru", etc.
  @HiveField(0)
  String? locale;
}
