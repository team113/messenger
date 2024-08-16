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

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/util/new_type.dart';
import 'precise_date_time/precise_date_time.dart';

/// Session of a [MyUser] being signed-in.
class Session implements Comparable<Session> {
  const Session({
    required this.id,
    required this.ip,
    required this.userAgent,
    required this.lastActivatedAt,
  });

  /// Unique ID of this [Session].
  final SessionId id;

  /// [IpAddress] of the device, that used this [Session] last time.
  final IpAddress ip;

  /// [UserAgent] of the device, that used this [Session] last time.
  final UserAgent userAgent;

  /// [DateTime] when this [Session] was activated last time (either created or
  /// refreshed).
  final PreciseDateTime lastActivatedAt;

  @override
  int compareTo(Session other) {
    final result = other.lastActivatedAt.compareTo(lastActivatedAt);
    if (result == 0) {
      return id.val.compareTo(other.id.val);
    }

    return result;
  }
}

/// Type of [Session]'s ID.
class SessionId extends NewType<String> {
  const SessionId(super.val);
}

/// Type of [MyUser]'s user agent.
///
/// Its values are always considered to be non-empty, and meet the following
/// requirements:
/// - consist only from ASCII characters;
/// - contain at least one non-space-like character.
class UserAgent extends NewType<String> {
  const UserAgent(super.val);
}

/// Either an IPv4 or IPv6 address.
class IpAddress extends NewType<String> {
  const IpAddress(super.val);
}

/// Token used for authenticating a [Session].
class AccessToken {
  const AccessToken(this.secret, this.expireAt);

  /// Secret part of this [AccessToken].
  ///
  /// This one should be used as a [Bearer authentication token][1].
  ///
  /// [1]: https://tools.ietf.org/html/rfc6750#section-2.1
  final AccessTokenSecret secret;

  /// [DateTime] of this [AccessToken] expiration.
  ///
  /// Once expired, it's not usable anymore and the [Session] should be
  /// refreshed to get a new [AccessToken].
  ///
  /// Client applications are supposed to use this field for tracking
  /// [AccessToken]'s expiration and refresh the [Session] before an
  /// authentication error occurs.
  final PreciseDateTime expireAt;
}

/// Type of [AccessToken]'s secret.
class AccessTokenSecret extends NewType<String> {
  const AccessTokenSecret(super.val);
}

/// Token used for refreshing a [Session].
class RefreshToken {
  const RefreshToken(this.secret, this.expireAt);

  /// Secret part of this [RefreshToken].
  ///
  /// This one should be used for refreshing the [Session] renewal and is
  /// **NOT** usable as a [Bearer authentication token][1].
  ///
  /// [1]: https://tools.ietf.org/html/rfc6750#section-2.1
  final RefreshTokenSecret secret;

  /// [DateTime] of this [RefreshToken] expiration.
  ///
  /// Once expired, it's not usable anymore and a new [Session] should be
  /// renewed to get a new [RefreshToken].
  ///
  /// Client applications are supposed to use this field for tracking
  /// [RefreshToken]'s expiration and sign out [MyUser]s properly.
  ///
  /// Expiration of a [RefreshToken] is not prolonged on refreshing, and remains
  /// the same for all the [RefreshToken]s obtained.
  final PreciseDateTime expireAt;
}

/// Type of [RefreshToken]'s secret.
class RefreshTokenSecret extends NewType<String> {
  const RefreshTokenSecret(super.val);
}

/// Container of a [AccessToken] and a [RefreshToken] representing the current
/// [MyUser] credentials.
class Credentials {
  const Credentials(this.access, this.refresh, this.sessionId, this.userId);

  /// Created or refreshed [AccessToken] for authenticating the [Session].
  ///
  /// It will expire in 30 minutes after creation.
  final AccessToken access;

  /// [RefreshToken] of these [Credentials].
  final RefreshToken refresh;

  /// ID of the [Session] these [Credentials] represent.
  final SessionId sessionId;

  /// ID of the currently authenticated [MyUser].
  final UserId userId;

  /// Constructs [Credentials] from the provided [data].
  factory Credentials.fromJson(Map<dynamic, dynamic> data) {
    return Credentials(
      AccessToken(
        AccessTokenSecret(data['access']['secret']),
        PreciseDateTime.parse(data['access']['expireAt']),
      ),
      RefreshToken(
        RefreshTokenSecret(data['refresh']['secret']),
        PreciseDateTime.parse(data['refresh']['expireAt']),
      ),
      SessionId(data['sessionId']),
      UserId(data['userId']),
    );
  }

  /// Returns a [Map] containing data of these [Credentials].
  Map<String, dynamic> toJson() {
    return {
      'access': {
        'secret': access.secret.val,
        'expireAt': access.expireAt.toString(),
      },
      'refresh': {
        'secret': refresh.secret.val,
        'expireAt': refresh.expireAt.toString(),
      },
      'sessionId': sessionId.val,
      'userId': userId.val,
    };
  }

  @override
  String toString() => 'Credentials(userId: $userId)';
}
