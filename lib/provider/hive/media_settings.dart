// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/media_settings.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for [MediaSettings].
class MediaSettingsHiveProvider extends HiveBaseProvider<MediaSettings> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'media_settings';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');
    Hive.maybeRegisterAdapter(MediaSettingsAdapter());
  }

  /// Returns the stored [MediaSettings] from [Hive].
  MediaSettings? get settings => getSafe(0);

  /// Saves the provided [MediaSettings] in [Hive].
  Future<void> set(MediaSettings mediaSettings) async {
    Log.trace('set($mediaSettings)', '$runtimeType');
    await putSafe(0, mediaSettings);
  }

  /// Stores a new video device [id] to [Hive].
  Future<void> setVideoDevice(String id) async {
    Log.trace('setVideoDevice($id)', '$runtimeType');
    await putSafe(0, (box.get(0) ?? MediaSettings())..videoDevice = id);
  }

  /// Stores a new audio device [id] to [Hive].
  Future<void> setAudioDevice(String id) async {
    Log.trace('setAudioDevice($id)', '$runtimeType');
    await putSafe(0, (box.get(0) ?? MediaSettings())..audioDevice = id);
  }

  /// Stores a new output device [id] to [Hive].
  Future<void> setOutputDevice(String id) async {
    Log.trace('setOutputDevice($id)', '$runtimeType');
    await putSafe(0, (box.get(0) ?? MediaSettings())..outputDevice = id);
  }
}
