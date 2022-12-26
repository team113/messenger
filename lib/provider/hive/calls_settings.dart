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

import '/domain/model_type_id.dart';
import '/domain/model/chat.dart';
import 'base.dart';

part 'calls_settings.g.dart';

/// [Hive] storage for [Chat]s.
class CallsSettingsHiveProvider extends HiveBaseProvider<CallPreferences> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'calls_settings';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(ChatIdAdapter());
    Hive.maybeRegisterAdapter(CallPreferencesAdapter());
  }

  /// Returns a list of [Chat]s from [Hive].
  Iterable<CallPreferences> get prefs => valuesSafe;

  /// Puts the provided [Chat] to [Hive].
  Future<void> put(CallPreferences prefs) =>
      putSafe(prefs.chatId.toString(), prefs);

  /// Returns a [Chat] from [Hive] by its [id].
  CallPreferences? get(ChatId id) => getSafe(id.val);

  /// Removes a [Chat] from [Hive] by the provided [id].
  Future<void> remove(ChatId id) => deleteSafe(id.val);
}

/// Preferences of a call containing its [width], [height] and position.
@HiveType(typeId: ModelTypeId.callPreferences)
class CallPreferences extends HiveObject {
  CallPreferences(
    this.chatId, {
    this.width,
    this.height,
    this.left,
    this.top,
    this.popupWidth,
    this.popupHeight,
    this.popupLeft,
    this.popupTop,
  });

  @HiveField(0)
  final ChatId chatId;

  @HiveField(1)
  double? width;

  /// Height of the call these [CallPreferences] are about.
  @HiveField(2)
  double? height;

  /// Left position of the call these [CallPreferences] are about.
  @HiveField(3)
  double? left;

  /// Top position of the call these [CallPreferences] are about.
  @HiveField(4)
  double? top;

  @HiveField(5)
  double? popupWidth;

  /// Height of the call these [CallPreferences] are about.
  @HiveField(6)
  double? popupHeight;

  /// Left position of the call these [CallPreferences] are about.
  @HiveField(7)
  double? popupLeft;

  /// Top position of the call these [CallPreferences] are about.
  @HiveField(8)
  double? popupTop;

  factory CallPreferences.fromJson(ChatId id, Map<dynamic, dynamic> data) {
    return CallPreferences(
      id,
      popupWidth: data['width'],
      popupHeight: data['height'],
      popupLeft: data['left'],
      popupTop: data['top'],
    );
  }

  /// Returns a [Map] containing data of these [CallPreferences].
  Map<String, dynamic> toJson() {
    return {
      'width': popupWidth,
      'height': popupHeight,
      'left': popupLeft,
      'top': popupTop,
    };
  }
}
