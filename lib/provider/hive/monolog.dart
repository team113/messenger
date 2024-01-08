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
import 'package:messenger/domain/model_type_id.dart';

import '/domain/model/chat.dart';
import 'base.dart';

part 'monolog.g.dart';

/// [Hive] storage for [ChatId] of a [Chat]-monolog of the authenticated
/// [MyUser].
class MonologHiveProvider extends HiveBaseProvider<HiveMonolog> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'monolog';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(HiveMonologAdapter());
    Hive.maybeRegisterAdapter(ChatIdAdapter());
  }

  /// Returns the stored [ChatId] from [Hive].
  HiveMonolog? get() => getSafe(0);

  /// Saves the provided [ChatId] to [Hive].
  Future<void> set(HiveMonolog id) => putSafe(0, id);
}

@HiveType(typeId: ModelTypeId.hiveMonolog)
class HiveMonolog {
  const HiveMonolog(this.id, this.isHidden);

  @HiveField(0)
  final ChatId id;

  @HiveField(1)
  final bool isHidden;
}
