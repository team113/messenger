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

import 'package:hive/hive.dart';

import '/domain/model_type_id.dart';
import '/domain/model/user.dart';
import '/util/new_type.dart';
import 'precise_date_time/precise_date_time.dart';

part 'session.g.dart';

/// Session of a [MyUser] being signed-in.
@HiveType(typeId: ModelTypeId.session)
class Session extends HiveObject {
  Session(this.token, this.expireAt);

  /// Unique authentication token of this [Session].
  @HiveField(0)
  final AccessToken token;

  /// [PreciseDateTime] of this [Session] expiration.
  @HiveField(1)
  final PreciseDateTime expireAt;
}

/// Unique authentication token of a [Session].
@HiveType(typeId: ModelTypeId.accessToken)
class AccessToken extends NewType<String> {
  const AccessToken(String val) : super(val);
}

/// Remembered session of a [MyUser] allowing to renew his [Session]s.
@HiveType(typeId: ModelTypeId.rememberedSession)
class RememberedSession extends HiveObject {
  RememberedSession(this.token, this.expireAt);

  /// Unique remember token of this [RememberedSession].
  ///
  /// This one should be used for a [Session] renewal and is **NOT** usable as a
  /// [Bearer authentication token][1].
  ///
  /// [1]: https://tools.ietf.org/html/rfc6750#section-2.1
  @HiveField(0)
  final RememberToken token;

  /// [PreciseDateTime] of this [RememberedSession] expiration.
  ///
  /// Once expired, it's not usable anymore and a new [RememberedSession]
  /// should be created.
  @HiveField(1)
  final PreciseDateTime expireAt;
}

/// Unique authentication token of a [RememberedSession].
@HiveType(typeId: ModelTypeId.rememberedToken)
class RememberToken extends NewType<String> {
  const RememberToken(String val) : super(val);
}

/// Container of a [Session] and a [RememberedSession] representing the current
/// [MyUser] credentials.
@HiveType(typeId: ModelTypeId.credentials)
class Credentials {
  const Credentials(this.session, this.rememberedSession, this.userId);

  /// [Session] of these [Credentials].
  @HiveField(0)
  final Session session;

  /// [RememberedSession] of these [Credentials].
  @HiveField(1)
  final RememberedSession rememberedSession;

  /// ID of the currently authenticated [MyUser].
  @HiveField(2)
  final UserId userId;

  /// Constructs [Credentials] from the provided [data].
  factory Credentials.fromJson(Map<dynamic, dynamic> data) {
    return Credentials(
      Session(
        AccessToken(data['session']['token']),
        PreciseDateTime.parse(data['session']['expireAt']),
      ),
      RememberedSession(
        RememberToken(data['remembered']['token']),
        PreciseDateTime.parse(data['remembered']['expireAt']),
      ),
      UserId(data['userId']),
    );
  }

  /// Returns a [Map] containing data of these [Credentials].
  Map<String, dynamic> toJson() {
    return {
      'session': {
        'token': session.token.val,
        'expireAt': session.expireAt.toString(),
      },
      'remembered': {
        'token': rememberedSession.token.val,
        'expireAt': rememberedSession.expireAt.toString(),
      },
      'userId': userId.val,
    };
  }
}
