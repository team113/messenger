// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:medea_jason/medea_jason.dart' show NoiseSuppressionLevel;

import '/domain/model/application_settings.dart';
import '/domain/model/media_settings.dart';
import '/domain/model/user.dart';
import 'drift.dart';

/// [DtoSettings] to be stored in a [Table].
@DataClassName('SettingsRow')
class Settings extends Table {
  @override
  Set<Column> get primaryKey => {userId};

  TextColumn get userId => text().nullable()();
  BoolColumn get enablePopups => boolean().nullable()();
  TextColumn get locale => text().nullable()();
  BoolColumn get showIntroduction => boolean().nullable()();
  RealColumn get sideBarWidth => real().nullable()();
  TextColumn get callButtons => text().withDefault(const Constant('[]'))();
  TextColumn get pinnedActions => text().withDefault(const Constant('[]'))();
  TextColumn get videoDevice => text().nullable()();
  TextColumn get audioDevice => text().nullable()();
  TextColumn get outputDevice => text().nullable()();
  TextColumn get screenDevice => text().nullable()();
  BoolColumn get noiseSuppression => boolean().nullable()();
  TextColumn get noiseSuppressionLevel => text().nullable()();
  BoolColumn get echoCancellation => boolean().nullable()();
  BoolColumn get autoGainControl => boolean().nullable()();
  BoolColumn get highPassFilter => boolean().nullable()();
  TextColumn get muteKeys => text().nullable()();
  RealColumn get videoVolume => real().nullable()();
  IntColumn get logLevel => integer().withDefault(const Constant(0))();
}

/// [DriftProviderBase] for manipulating the persisted [DtoSettings].
class SettingsDriftProvider extends DriftProviderBase {
  SettingsDriftProvider(super.database);

  /// [StreamController] emitting [DtoSettings]s in [watch].
  final Map<UserId, StreamController<DtoSettings?>> _controllers = {};

  /// [DtoSettings]s that have started the [upsert]ing, but not yet finished it.
  final Map<UserId, DtoSettings> _cache = {};

  /// Creates or updates the provided [settings] in the database.
  Future<DtoSettings> upsert(UserId userId, DtoSettings settings) async {
    _cache[userId] = settings;

    final result = await safe((db) async {
      final DtoSettings stored = _SettingsDb.fromDb(
        await db
            .into(db.settings)
            .insertReturning(
              settings.toDb(userId),
              mode: InsertMode.insertOrReplace,
            ),
      );

      _controllers[userId]?.add(stored);

      return stored;
    });

    return result ?? settings;
  }

  /// Returns the [DtoSettings] stored in the database by the provided [id], if
  /// any.
  Future<DtoSettings?> read(UserId id) async {
    final DtoSettings? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<DtoSettings?>((db) async {
      final stmt = db.select(db.settings)
        ..where((u) => u.userId.equals(id.val));
      final SettingsRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _SettingsDb.fromDb(row);
    }, exclusive: false);
  }

  /// Deletes the [DtoSettings] identified by the provided [id] from the
  /// database.
  Future<void> delete(UserId id) async {
    _cache.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.settings)
        ..where((e) => e.userId.equals(id.val));
      await stmt.go();

      _controllers[id]?.add(null);
    });
  }

  /// Deletes all the [DtoSettings]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.settings).go();
    });
  }

  /// Returns the [Stream] of real-time changes happening with the [DtoSettings]
  /// identified by the provided [id].
  Stream<DtoSettings?> watch(UserId id) {
    return stream((db) {
      final stmt = db.select(db.settings)
        ..where((u) => u.userId.equals(id.val));

      StreamController<DtoSettings?>? controller = _controllers[id];
      if (controller == null) {
        controller = StreamController<DtoSettings?>.broadcast(sync: true);
        _controllers[id] = controller;
      }

      return StreamGroup.merge([
        controller.stream,
        stmt.watch().map((e) => e.isEmpty ? null : _SettingsDb.fromDb(e.first)),
      ]);
    });
  }
}

/// Extension adding conversion methods from [SettingsRow] to [DtoSettings].
extension _SettingsDb on DtoSettings {
  /// Constructs a [DtoSettings] from the provided [SettingsRow].
  static DtoSettings fromDb(SettingsRow e) {
    return DtoSettings(
      application: ApplicationSettings(
        enablePopups: e.enablePopups,
        locale: e.locale,
        showIntroduction: e.showIntroduction,
        sideBarWidth: e.sideBarWidth,
        callButtons: (jsonDecode(e.callButtons) as List)
            .cast<String>()
            .toList(),
        pinnedActions: (jsonDecode(e.pinnedActions) as List)
            .cast<String>()
            .toList(),
        muteKeys: (e.muteKeys ?? '[]')
            .replaceFirst('[', '')
            .replaceFirst(']', '')
            .split(', '),
        videoVolume: e.videoVolume ?? 1,
        logLevel: e.logLevel,
      ),
      media: MediaSettings(
        audioDevice: e.audioDevice,
        videoDevice: e.videoDevice,
        outputDevice: e.outputDevice,
        screenDevice: e.screenDevice,
        noiseSuppression: e.noiseSuppression,
        noiseSuppressionLevel: NoiseSuppressionLevel.values.firstWhereOrNull(
          (level) => level.name == e.noiseSuppressionLevel,
        ),
        echoCancellation: e.echoCancellation,
        autoGainControl: e.autoGainControl,
        highPassFilter: e.highPassFilter,
      ),
    );
  }

  /// Constructs a [SettingsRow] from this [DtoSettings].
  SettingsRow toDb(UserId userId) {
    return SettingsRow(
      userId: userId.val,
      enablePopups: application.enablePopups,
      locale: application.locale,
      showIntroduction: application.showIntroduction,
      sideBarWidth: application.sideBarWidth,
      callButtons: jsonEncode(application.callButtons.toList()),
      pinnedActions: jsonEncode(application.pinnedActions.toList()),
      audioDevice: media.audioDevice,
      videoDevice: media.videoDevice,
      screenDevice: media.screenDevice,
      outputDevice: media.outputDevice,
      noiseSuppression: media.noiseSuppression,
      noiseSuppressionLevel: media.noiseSuppressionLevel?.name,
      echoCancellation: media.echoCancellation,
      autoGainControl: media.autoGainControl,
      highPassFilter: media.highPassFilter,
      muteKeys: application.muteKeys?.toString(),
      videoVolume: application.videoVolume,
      logLevel: application.logLevel,
    );
  }
}

/// Stored in the local storage [ApplicationSettings] and [MediaSettings].
class DtoSettings {
  const DtoSettings({required this.application, required this.media});

  /// [ApplicationSettings] themselves.
  final ApplicationSettings application;

  /// [MediaSettings] themselves.
  final MediaSettings media;
}
