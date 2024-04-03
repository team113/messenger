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

import 'package:hive_flutter/adapters.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/util/log.dart';
import 'base.dart';

// TODO: Encrypt stored data.
/// [Hive] storage for a [Credentials].
class CredentialsHiveProvider extends HiveBaseProvider<Credentials> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch(key: 0);

  @override
  String get boxName => 'credentials';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');

    Hive.maybeRegisterAdapter(AccessTokenAdapter());
    Hive.maybeRegisterAdapter(CredentialsAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(RefreshTokenAdapter());
    Hive.maybeRegisterAdapter(RememberedSessionAdapter());
    Hive.maybeRegisterAdapter(SessionAdapter());
    Hive.maybeRegisterAdapter(UserIdAdapter());
  }

  /// Returns the stored [Credentials] from [Hive].
  Credentials? get() {
    Log.trace('getCredentials()', '$runtimeType');
    return getSafe(0);
  }

  /// Stores new [Credentials] to [Hive].
  Future<void> set(Credentials credentials) async {
    Log.trace('setCredentials($credentials)', '$runtimeType');
    await putSafe(0, credentials);
  }
}
