import 'package:hive/hive.dart';

import '/domain/model_type_id.dart';

part 'localization_settings.g.dart';

/// Overall application settings used by the whole app.
@HiveType(typeId: ModelTypeId.localeSettings)
class LocalizationSettings extends HiveObject {
  LocalizationSettings({this.locale});

  @HiveField(0)
  String? locale;
}
