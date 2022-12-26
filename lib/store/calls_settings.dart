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

import 'dart:async';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:messenger/domain/repository/calls_settings.dart';
import 'package:messenger/provider/hive/calls_settings.dart';
import 'package:messenger/util/obs/obs.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/chat.dart';
import '/provider/hive/application_settings.dart';

/// Application settings repository.
class CallsSettingsRepository extends DisposableInterface
    implements AbstractCallsSettingsRepository {
  CallsSettingsRepository(this._callsSettingsLocal);

  /// [ApplicationSettings] local [Hive] storage.
  final CallsSettingsHiveProvider _callsSettingsLocal;

  /// [ApplicationSettingsHiveProvider.boxEvents] subscription.
  StreamIterator? _settingsSubscription;

  @override
  RxObsMap<ChatId, CallPreferences> prefs =
      RxObsMap<ChatId, CallPreferences>({});

  @override
  void onInit() {
    _initSettingsSubscription();

    super.onInit();
  }

  @override
  void onClose() {
    _settingsSubscription?.cancel();
    super.onClose();
  }

  // @override
  // Future<void> setCallPreferences(ChatId id, CallPreferences preferences) =>
  //     _settingsLocal.setCallPreferences(id, preferences);

  /// Initializes [ApplicationSettingsHiveProvider.boxEvents] subscription.
  Future<void> _initSettingsSubscription() async {
    for (var e in _callsSettingsLocal.prefs) {
      prefs[e.chatId] = e;
    }
    _settingsSubscription = StreamIterator(_callsSettingsLocal.boxEvents);
    while (await _settingsSubscription!.moveNext()) {
      BoxEvent event = _settingsSubscription!.current;
      if (event.deleted) {
        print('deleted');
        prefs.remove(event.key);
      } else {
        print('updated');
        prefs[ChatId(event.key)] = event.value;
        prefs.refresh();
      }
    }
  }

  @override
  Future<void> put(CallPreferences prefs) async {
    await _callsSettingsLocal.put(prefs);
    print('put');
  }
}
