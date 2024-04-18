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
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'credentials';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');

    Hive.maybeRegisterAdapter(AccessTokenAdapter());
    Hive.maybeRegisterAdapter(AccessTokenAdapter());
    Hive.maybeRegisterAdapter(AccessTokenSecretAdapter());
    Hive.maybeRegisterAdapter(CredentialsAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(RefreshTokenAdapter());
    Hive.maybeRegisterAdapter(RefreshTokenSecretAdapter());
    Hive.maybeRegisterAdapter(SessionAdapter());
    Hive.maybeRegisterAdapter(SessionIdAdapter());
    Hive.maybeRegisterAdapter(UserAgentAdapter());
    Hive.maybeRegisterAdapter(UserIdAdapter());
  }

  /// Returns [Credentials] from [Hive] by its [id].
  Credentials? get(UserId id) {
    Log.trace('get($id)', '$runtimeType');
    return getSafe(id.val);
  }

  /// Saves the provided [Credentials] to [Hive].
  Future<void> put(Credentials credentials) async {
    Log.trace('put($credentials)', '$runtimeType');
    await putSafe(credentials.userId.val, credentials);
  }

  /// Removes [Credentials] from [Hive] by its [id].
  Future<void> remove(UserId id) async {
    Log.trace('remove($id)', '$runtimeType');
    await deleteSafe(id.val);
  }
}
