// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:convert';
import 'dart:math';

import 'package:json_annotation/json_annotation.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/util/new_type.dart';
import 'precise_date_time/precise_date_time.dart';

part 'session.g.dart';

/// Session of a [MyUser] being signed-in.
@JsonSerializable()
class Session implements Comparable<Session> {
  const Session({
    required this.id,
    required this.ip,
    required this.userAgent,
    required this.lastActivatedAt,
  });

  /// Constructs a [Session] from the provided [json].
  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);

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

  /// Returns a [Map] representing this [Session].
  Map<String, dynamic> toJson() => _$SessionToJson(this);
}

/// Type of [Session]'s ID.
class SessionId extends NewType<String> {
  const SessionId(super.val);

  /// Constructs a [SessionId] from the provided [val].
  factory SessionId.fromJson(String val) = SessionId;

  /// Returns a [String] representing this [SessionId].
  String toJson() => val;
}

/// Type of [MyUser]'s user agent.
///
/// Its values are always considered to be non-empty, and meet the following
/// requirements:
/// - consist only from ASCII characters;
/// - contain at least one non-space-like character.
class UserAgent extends NewType<String> {
  const UserAgent(super.val);

  /// Constructs a [UserAgent] from the provided [val].
  factory UserAgent.fromJson(String val) = UserAgent;

  /// Returns a [String] representing this [UserAgent].
  String toJson() => val;
}

/// Either an IPv4 or IPv6 address.
class IpAddress extends NewType<String> {
  const IpAddress(super.val);

  /// Constructs a [IpAddress] from the provided [val].
  factory IpAddress.fromJson(String val) = IpAddress;

  /// Returns a [String] representing this [IpAddress].
  String toJson() => val;
}

/// Geographical location information regarding certain [IpAddress].
@JsonSerializable()
class IpGeoLocation {
  const IpGeoLocation({
    required this.country,
    required this.countryCode,
    required this.city,
  });

  /// Constructs an [IpGeoLocation] from the provided [json].
  factory IpGeoLocation.fromJson(Map<String, dynamic> json) =>
      _$IpGeoLocationFromJson(json);

  /// Localized name of the country.
  final String country;

  /// Country code.
  @JsonKey(name: 'country_code')
  final String countryCode;

  /// Localized name of the city.
  final String city;

  /// Returns a [Map] representing this [IpGeoLocation].
  Map<String, dynamic> toJson() => _$IpGeoLocationToJson(this);
}

/// Token used for authenticating a [Session].
@JsonSerializable()
class AccessToken {
  const AccessToken(this.secret, this.expireAt);

  /// Constructs [AccessToken] from the provided [json].
  factory AccessToken.fromJson(Map<String, dynamic> json) =>
      _$AccessTokenFromJson(json);

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

  /// Returns a [Map] containing data of these [AccessToken].
  Map<String, dynamic> toJson() => _$AccessTokenToJson(this);

  @override
  String toString() => 'AccessToken(secret: ***, expireAt: $expireAt)';
}

/// Type of [AccessToken]'s secret.
class AccessTokenSecret extends NewType<String> {
  const AccessTokenSecret(super.val);

  /// Constructs a [AccessTokenSecret] from the provided [val].
  factory AccessTokenSecret.fromJson(String val) = AccessTokenSecret;

  /// Returns a [String] representing this [AccessTokenSecret].
  String toJson() => val;
}

/// Input for creating a [AccessTokenSecret].
///
/// Must represent 32 random bytes encoded as valid `Base64` string.
///
/// Use a cryptographically secure random generator to produce array of bytes
/// for this value.
class AccessTokenSecretInput extends NewType<String> {
  const AccessTokenSecretInput(super.val);

  /// Constructs a [AccessTokenSecretInput] from the provided [val].
  factory AccessTokenSecretInput.fromJson(String val) = AccessTokenSecretInput;

  /// Returns a [String] representing this [AccessTokenSecretInput].
  String toJson() => val;
}

/// Token used for refreshing a [Session].
@JsonSerializable()
class RefreshToken {
  const RefreshToken(this.secret, this.expireAt);

  /// Constructs [RefreshToken] from the provided [json].
  factory RefreshToken.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenFromJson(json);

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

  /// Returns a [Map] containing data of this [RefreshToken].
  Map<String, dynamic> toJson() => _$RefreshTokenToJson(this);

  @override
  String toString() => 'RefreshToken(secret: $secret, expireAt: $expireAt)';
}

/// Type of [RefreshToken]'s secret.
class RefreshTokenSecret extends NewType<String> {
  const RefreshTokenSecret(super.val);

  /// Constructs a [RefreshTokenSecret] from the provided [val].
  factory RefreshTokenSecret.fromJson(String val) = RefreshTokenSecret;

  /// Returns a [String] representing this [RefreshTokenSecret].
  String toJson() => val;
}

/// Input for creating a [RefreshTokenSecret].
///
/// Must represent 32 random bytes encoded as valid `Base64` string.
///
/// Use a cryptographically secure random generator to produce array of bytes
/// for this value.
class RefreshTokenSecretInput extends NewType<String> {
  const RefreshTokenSecretInput(super.val);

  /// Constructs a [RefreshTokenSecretInput] from the provided [val].
  factory RefreshTokenSecretInput.fromJson(String val) =
      RefreshTokenSecretInput;

  /// Returns a [String] representing this [RefreshTokenSecretInput].
  String toJson() => val;
}

/// Container of a [AccessToken] and a [RefreshToken] representing the current
/// [MyUser] credentials.
@JsonSerializable()
class Credentials {
  const Credentials(this.access, this.refresh, this.session, this.userId);

  /// Created or refreshed [AccessToken] for authenticating the [Session].
  ///
  /// It will expire in 30 minutes after creation.
  final AccessToken access;

  /// [RefreshToken] of these [Credentials].
  final RefreshToken refresh;

  /// [Session] these [Credentials] represent.
  final Session session;

  /// ID of the currently authenticated [MyUser].
  final UserId userId;

  /// Constructs [Credentials] from the provided [json].
  factory Credentials.fromJson(Map<String, dynamic> json) {
    try {
      return _$CredentialsFromJson(json);
    } catch (_) {
      // TODO: Remove when clients migrate from old `Credentials` storage.
      try {
        return Credentials(
          AccessToken(
            AccessTokenSecret(json['access']['secret']),
            PreciseDateTime.parse(json['access']['expireAt']),
          ),
          RefreshToken(
            RefreshTokenSecret(json['refresh']['secret']),
            PreciseDateTime.parse(json['refresh']['expireAt']),
          ),
          Session(
            id: SessionId(json['sessionId'] ?? ''),
            ip: IpAddress('127.0.0.0'),
            userAgent: UserAgent(''),
            lastActivatedAt: PreciseDateTime.now(),
          ),
          UserId(json['userId']),
        );
      } catch (_) {
        // No-op.
      }

      rethrow;
    }
  }

  /// Returns a [Map] containing data of these [Credentials].
  Map<String, dynamic> toJson() => _$CredentialsToJson(this);

  @override
  String toString() =>
      'Credentials(userId: $userId, sessionId: ${session.id}, access: $access refresh: $refresh)';
}

/// [RefreshTokenSecretInput] and [AccessTokenSecretInput].
class RefreshSessionSecrets {
  RefreshSessionSecrets(this.refresh, this.access);

  factory RefreshSessionSecrets.generate() {
    return RefreshSessionSecrets(
      RefreshTokenSecretInput(
        base64Encode(List.generate(32, (_) => Random.secure().nextInt(255))),
      ),
      AccessTokenSecretInput(
        base64Encode(List.generate(32, (_) => Random.secure().nextInt(255))),
      ),
    );
  }

  /// [RefreshTokenSecretInput] itself.
  final RefreshTokenSecretInput refresh;

  /// [AccessTokenSecretInput] itself.
  final AccessTokenSecretInput access;

  @override
  String toString() => 'RefreshSessionSecrets($refresh, $access)';
}
