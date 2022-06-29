import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/localization_settings.dart';
import 'base.dart';

/// [Hive] storage for [ApplicationSettings].
class LocalizationSettingsHiveProvider
    extends HiveBaseProvider<LocalizationSettings> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'localization_settings';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(LocalizationSettingsAdapter());
  }

  /// Returns the stored [ApplicationSettings] from [Hive].
  LocalizationSettings? get settings => getSafe(0);

  /// Saves the provided [ApplicationSettings] in [Hive].
  Future<void> set(LocalizationSettings locale) => putSafe(0, locale);

  /// Stores a new [enabled] value of [ApplicationSettings.enablePopups] to
  /// [Hive].
  Future<void> setLocale(String locale) async =>
      await putSafe(0, (box.get(0) ?? LocalizationSettings())..locale = locale);
}
