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

import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model_type_id.dart';
import 'base.dart';

part 'background.g.dart';

/// [Hive] storage for [HiveBackground].
class BackgroundHiveProvider extends HiveBaseProvider<HiveBackground> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'background';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(HiveBackgroundAdapter());
  }

  /// Returns the stored [Uint8List] from [Hive].
  Uint8List? get get => getSafe(0)?.bytes;

  /// Saves the provided [Uint8List] in [Hive].
  Future<void> set(Uint8List bytes) => putSafe(0, HiveBackground(bytes));

  /// Deletes the stored [Uint8List].
  Future<void> delete() => deleteSafe(0);
}

@HiveType(typeId: ModelTypeId.hiveBackground)
class HiveBackground extends HiveObject {
  HiveBackground(this.bytes);

  @HiveField(0)
  final Uint8List bytes;
}
