// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/domain/model/call_preferences.dart';
import '/domain/model/chat.dart';
import 'base.dart';

/// [Hive] storage for [CallPreferences].
class CallsPreferencesHiveProvider extends HiveBaseProvider<CallPreferences> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'calls_preferences';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(CallPreferencesAdapter());
  }

  /// Puts the provided [CallPreferences] to [Hive].
  Future<void> put(ChatId chatId, CallPreferences prefs) =>
      putSafe(chatId.val, prefs);

  /// Returns a [CallPreferences] from [Hive] by its [id].
  CallPreferences? get(ChatId id) => getSafe(id.val);
}
