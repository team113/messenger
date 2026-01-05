// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/session.dart';
import '/store/model/session.dart';

// ignore: todo
// TODO: Change List<Object?> to List<String>.
// Needs https://github.com/google/json_serializable.dart/issues/806

// SessionVersion

SessionVersion fromGraphQLSessionVersionToDartSessionVersion(String v) =>
    SessionVersion.parse(v);
String fromDartSessionVersionToGraphQLSessionVersion(SessionVersion v) =>
    v.toString();
List<SessionVersion> fromGraphQLListSessionVersionToDartListSessionVersion(
  List<Object?> v,
) => v
    .map((e) => fromGraphQLSessionVersionToDartSessionVersion(e as String))
    .toList();
List<String> fromDartListSessionVersionToGraphQLListSessionVersion(
  List<SessionVersion> v,
) => v.map((e) => fromDartSessionVersionToGraphQLSessionVersion(e)).toList();
List<SessionVersion>?
fromGraphQLListNullableSessionVersionToDartListNullableSessionVersion(
  List<Object?>? v,
) => v
    ?.map((e) => fromGraphQLSessionVersionToDartSessionVersion(e as String))
    .toList();
List<String>?
fromDartListNullableSessionVersionToGraphQLListNullableSessionVersion(
  List<SessionVersion>? v,
) => v?.map((e) => fromDartSessionVersionToGraphQLSessionVersion(e)).toList();

SessionVersion? fromGraphQLSessionVersionNullableToDartSessionVersionNullable(
  String? v,
) => v == null ? null : SessionVersion.parse(v);
String? fromDartSessionVersionNullableToGraphQLSessionVersionNullable(
  SessionVersion? v,
) => v?.toString();
List<SessionVersion?>
fromGraphQLListSessionVersionNullableToDartListSessionVersionNullable(
  List<Object?> v,
) => v
    .map(
      (e) => fromGraphQLSessionVersionNullableToDartSessionVersionNullable(
        e as String?,
      ),
    )
    .toList();
List<String?>
fromDartListSessionVersionNullableToGraphQLListSessionVersionNullable(
  List<SessionVersion?> v,
) => v
    .map(
      (e) => fromDartSessionVersionNullableToGraphQLSessionVersionNullable(e),
    )
    .toList();
List<SessionVersion?>?
fromGraphQLListNullableSessionVersionNullableToDartListNullableSessionVersionNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLSessionVersionNullableToDartSessionVersionNullable(
        e as String?,
      ),
    )
    .toList();
List<String?>?
fromDartListNullableSessionVersionNullableToGraphQLListNullableSessionVersionNullable(
  List<SessionVersion?>? v,
) => v
    ?.map(
      (e) => fromDartSessionVersionNullableToGraphQLSessionVersionNullable(e),
    )
    .toList();

// SessionId

SessionId fromGraphQLSessionIdToDartSessionId(String v) => SessionId(v);
String fromDartSessionIdToGraphQLSessionId(SessionId v) => v.toString();
List<SessionId> fromGraphQLListSessionIdToDartListSessionId(List<Object?> v) =>
    v.map((e) => fromGraphQLSessionIdToDartSessionId(e as String)).toList();
List<String> fromDartListSessionIdToGraphQLListSessionId(List<SessionId> v) =>
    v.map((e) => fromDartSessionIdToGraphQLSessionId(e)).toList();
List<SessionId>? fromGraphQLListNullableSessionIdToDartListNullableSessionId(
  List<Object?>? v,
) => v?.map((e) => fromGraphQLSessionIdToDartSessionId(e as String)).toList();
List<String>? fromDartListNullableSessionIdToGraphQLListNullableSessionId(
  List<SessionId>? v,
) => v?.map((e) => fromDartSessionIdToGraphQLSessionId(e)).toList();

SessionId? fromGraphQLSessionIdNullableToDartSessionIdNullable(String? v) =>
    v == null ? null : SessionId(v);
String? fromDartSessionIdNullableToGraphQLSessionIdNullable(SessionId? v) =>
    v?.toString();
List<SessionId?> fromGraphQLListSessionIdNullableToDartListSessionIdNullable(
  List<Object?> v,
) => v
    .map(
      (e) => fromGraphQLSessionIdNullableToDartSessionIdNullable(e as String?),
    )
    .toList();
List<String?> fromDartListSessionIdNullableToGraphQLListSessionIdNullable(
  List<SessionId?> v,
) => v
    .map((e) => fromDartSessionIdNullableToGraphQLSessionIdNullable(e))
    .toList();
List<SessionId?>?
fromGraphQLListNullableSessionIdNullableToDartListNullableSessionIdNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLSessionIdNullableToDartSessionIdNullable(e as String?),
    )
    .toList();
List<String?>?
fromDartListNullableSessionIdNullableToGraphQLListNullableSessionIdNullable(
  List<SessionId?>? v,
) => v
    ?.map((e) => fromDartSessionIdNullableToGraphQLSessionIdNullable(e))
    .toList();

// AccessTokenSecret

AccessTokenSecret fromGraphQLAccessTokenSecretToDartAccessTokenSecret(
  String v,
) => AccessTokenSecret(v);
String fromDartAccessTokenSecretToGraphQLAccessTokenSecret(
  AccessTokenSecret v,
) => v.toString();
List<AccessTokenSecret>
fromGraphQLListAccessTokenSecretToDartListAccessTokenSecret(List<Object?> v) =>
    v
        .map(
          (e) =>
              fromGraphQLAccessTokenSecretToDartAccessTokenSecret(e as String),
        )
        .toList();
List<String> fromDartListAccessTokenSecretToGraphQLListAccessTokenSecret(
  List<AccessTokenSecret> v,
) => v
    .map((e) => fromDartAccessTokenSecretToGraphQLAccessTokenSecret(e))
    .toList();
List<AccessTokenSecret>?
fromGraphQLListNullableAccessTokenSecretToDartListNullableAccessTokenSecret(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLAccessTokenSecretToDartAccessTokenSecret(e as String),
    )
    .toList();
List<String>?
fromDartListNullableAccessTokenSecretToGraphQLListNullableAccessTokenSecret(
  List<AccessTokenSecret>? v,
) => v
    ?.map((e) => fromDartAccessTokenSecretToGraphQLAccessTokenSecret(e))
    .toList();

AccessTokenSecret?
fromGraphQLAccessTokenSecretNullableToDartAccessTokenSecretNullable(
  String? v,
) => v == null ? null : AccessTokenSecret(v);
String? fromDartAccessTokenSecretNullableToGraphQLAccessTokenSecretNullable(
  AccessTokenSecret? v,
) => v?.toString();
List<AccessTokenSecret?>
fromGraphQLListAccessTokenSecretNullableToDartListAccessTokenSecretNullable(
  List<Object?> v,
) => v
    .map(
      (e) =>
          fromGraphQLAccessTokenSecretNullableToDartAccessTokenSecretNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>
fromDartListAccessTokenSecretNullableToGraphQLListAccessTokenSecretNullable(
  List<AccessTokenSecret?> v,
) => v
    .map(
      (e) =>
          fromDartAccessTokenSecretNullableToGraphQLAccessTokenSecretNullable(
            e,
          ),
    )
    .toList();
List<AccessTokenSecret?>?
fromGraphQLListNullableAccessTokenSecretNullableToDartListNullableAccessTokenSecretNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) =>
          fromGraphQLAccessTokenSecretNullableToDartAccessTokenSecretNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>?
fromDartListNullableAccessTokenSecretNullableToGraphQLListNullableAccessTokenSecretNullable(
  List<AccessTokenSecret?>? v,
) => v
    ?.map(
      (e) =>
          fromDartAccessTokenSecretNullableToGraphQLAccessTokenSecretNullable(
            e,
          ),
    )
    .toList();

// AccessTokenSecretInput

AccessTokenSecretInput
fromGraphQLAccessTokenSecretInputToDartAccessTokenSecretInput(String v) =>
    AccessTokenSecretInput(v);
String fromDartAccessTokenSecretInputToGraphQLAccessTokenSecretInput(
  AccessTokenSecretInput v,
) => v.toString();
List<AccessTokenSecretInput>
fromGraphQLListAccessTokenSecretInputToDartListAccessTokenSecretInput(
  List<Object?> v,
) => v
    .map(
      (e) => fromGraphQLAccessTokenSecretInputToDartAccessTokenSecretInput(
        e as String,
      ),
    )
    .toList();
List<String>
fromDartListAccessTokenSecretInputToGraphQLListAccessTokenSecretInput(
  List<AccessTokenSecretInput> v,
) => v
    .map(
      (e) => fromDartAccessTokenSecretInputToGraphQLAccessTokenSecretInput(e),
    )
    .toList();
List<AccessTokenSecretInput>?
fromGraphQLListNullableAccessTokenSecretInputToDartListNullableAccessTokenSecretInput(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLAccessTokenSecretInputToDartAccessTokenSecretInput(
        e as String,
      ),
    )
    .toList();
List<String>?
fromDartListNullableAccessTokenSecretInputToGraphQLListNullableAccessTokenSecretInput(
  List<AccessTokenSecretInput>? v,
) => v
    ?.map(
      (e) => fromDartAccessTokenSecretInputToGraphQLAccessTokenSecretInput(e),
    )
    .toList();

AccessTokenSecretInput?
fromGraphQLAccessTokenSecretInputNullableToDartAccessTokenSecretInputNullable(
  String? v,
) => v == null ? null : AccessTokenSecretInput(v);
String?
fromDartAccessTokenSecretInputNullableToGraphQLAccessTokenSecretInputNullable(
  AccessTokenSecretInput? v,
) => v?.toString();
List<AccessTokenSecretInput?>
fromGraphQLListAccessTokenSecretInputNullableToDartListAccessTokenSecretInputNullable(
  List<Object?> v,
) => v
    .map(
      (e) =>
          fromGraphQLAccessTokenSecretInputNullableToDartAccessTokenSecretInputNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>
fromDartListAccessTokenSecretInputNullableToGraphQLListAccessTokenSecretInputNullable(
  List<AccessTokenSecretInput?> v,
) => v
    .map(
      (e) =>
          fromDartAccessTokenSecretInputNullableToGraphQLAccessTokenSecretInputNullable(
            e,
          ),
    )
    .toList();
List<AccessTokenSecretInput?>?
fromGraphQLListNullableAccessTokenSecretInputNullableToDartListNullableAccessTokenSecretInputNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) =>
          fromGraphQLAccessTokenSecretInputNullableToDartAccessTokenSecretInputNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>?
fromDartListNullableAccessTokenSecretInputNullableToGraphQLListNullableAccessTokenSecretInputNullable(
  List<AccessTokenSecretInput?>? v,
) => v
    ?.map(
      (e) =>
          fromDartAccessTokenSecretInputNullableToGraphQLAccessTokenSecretInputNullable(
            e,
          ),
    )
    .toList();

// UserAgent

UserAgent fromGraphQLUserAgentToDartUserAgent(String v) => UserAgent(v);
String fromDartUserAgentToGraphQLUserAgent(UserAgent v) => v.val;
List<UserAgent> fromGraphQLListUserAgentToDartListUserAgent(List<Object?> v) =>
    v.map((e) => fromGraphQLUserAgentToDartUserAgent(e as String)).toList();
List<String> fromDartListUserAgentToGraphQLListUserAgent(List<UserAgent> v) =>
    v.map((e) => fromDartUserAgentToGraphQLUserAgent(e)).toList();
List<UserAgent>? fromGraphQLListNullableUserAgentToDartListNullableUserAgent(
  List<Object?>? v,
) => v?.map((e) => fromGraphQLUserAgentToDartUserAgent(e as String)).toList();
List<String>? fromDartListNullableUserAgentToGraphQLListNullableUserAgent(
  List<UserAgent>? v,
) => v?.map((e) => fromDartUserAgentToGraphQLUserAgent(e)).toList();

UserAgent? fromGraphQLUserAgentNullableToDartUserAgentNullable(String? v) =>
    v == null ? null : UserAgent(v);
String? fromDartUserAgentNullableToGraphQLUserAgentNullable(UserAgent? v) =>
    v?.val;
List<UserAgent?> fromGraphQLListUserAgentNullableToDartListUserAgentNullable(
  List<Object?> v,
) => v
    .map(
      (e) => fromGraphQLUserAgentNullableToDartUserAgentNullable(e as String?),
    )
    .toList();
List<String?> fromDartListUserAgentNullableToGraphQLListUserAgentNullable(
  List<UserAgent?> v,
) => v
    .map((e) => fromDartUserAgentNullableToGraphQLUserAgentNullable(e))
    .toList();
List<UserAgent?>?
fromGraphQLListNullableUserAgentNullableToDartListNullableUserAgentNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLUserAgentNullableToDartUserAgentNullable(e as String?),
    )
    .toList();
List<String?>?
fromDartListNullableUserAgentNullableToGraphQLListNullableUserAgentNullable(
  List<UserAgent?>? v,
) => v
    ?.map((e) => fromDartUserAgentNullableToGraphQLUserAgentNullable(e))
    .toList();

// RefreshTokenSecret

RefreshTokenSecret fromGraphQLRefreshTokenSecretToDartRefreshTokenSecret(
  String v,
) => RefreshTokenSecret(v);
String fromDartRefreshTokenSecretToGraphQLRefreshTokenSecret(
  RefreshTokenSecret v,
) => v.val;
List<RefreshTokenSecret>
fromGraphQLListRefreshTokenSecretToDartListRefreshTokenSecret(
  List<Object?> v,
) => v
    .map(
      (e) => fromGraphQLRefreshTokenSecretToDartRefreshTokenSecret(e as String),
    )
    .toList();
List<String> fromDartListRefreshTokenSecretToGraphQLListRefreshTokenSecret(
  List<RefreshTokenSecret> v,
) => v
    .map((e) => fromDartRefreshTokenSecretToGraphQLRefreshTokenSecret(e))
    .toList();
List<RefreshTokenSecret>?
fromGraphQLListNullableRefreshTokenSecretToDartListNullableRefreshTokenSecret(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLRefreshTokenSecretToDartRefreshTokenSecret(e as String),
    )
    .toList();
List<String>?
fromDartListNullableRefreshTokenSecretToGraphQLListNullableRefreshTokenSecret(
  List<RefreshTokenSecret>? v,
) => v
    ?.map((e) => fromDartRefreshTokenSecretToGraphQLRefreshTokenSecret(e))
    .toList();

RefreshTokenSecret?
fromGraphQLRefreshTokenSecretNullableToDartRefreshTokenSecretNullable(
  String? v,
) => v == null ? null : RefreshTokenSecret(v);
String? fromDartRefreshTokenSecretNullableToGraphQLRefreshTokenSecretNullable(
  RefreshTokenSecret? v,
) => v?.val;
List<RefreshTokenSecret?>
fromGraphQLListRefreshTokenSecretNullableToDartListRefreshTokenSecretNullable(
  List<Object?> v,
) => v
    .map(
      (e) =>
          fromGraphQLRefreshTokenSecretNullableToDartRefreshTokenSecretNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>
fromDartListRefreshTokenSecretNullableToGraphQLListRefreshTokenSecretNullable(
  List<RefreshTokenSecret?> v,
) => v
    .map(
      (e) =>
          fromDartRefreshTokenSecretNullableToGraphQLRefreshTokenSecretNullable(
            e,
          ),
    )
    .toList();
List<RefreshTokenSecret?>?
fromGraphQLListNullableRefreshTokenSecretNullableToDartListNullableRefreshTokenSecretNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) =>
          fromGraphQLRefreshTokenSecretNullableToDartRefreshTokenSecretNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>?
fromDartListNullableRefreshTokenSecretNullableToGraphQLListNullableRefreshTokenSecretNullable(
  List<RefreshTokenSecret?>? v,
) => v
    ?.map(
      (e) =>
          fromDartRefreshTokenSecretNullableToGraphQLRefreshTokenSecretNullable(
            e,
          ),
    )
    .toList();

// RefreshTokenSecretInput

RefreshTokenSecretInput
fromGraphQLRefreshTokenSecretInputToDartRefreshTokenSecretInput(String v) =>
    RefreshTokenSecretInput(v);
String fromDartRefreshTokenSecretInputToGraphQLRefreshTokenSecretInput(
  RefreshTokenSecretInput v,
) => v.val;
List<RefreshTokenSecretInput>
fromGraphQLListRefreshTokenSecretInputToDartListRefreshTokenSecretInput(
  List<Object?> v,
) => v
    .map(
      (e) => fromGraphQLRefreshTokenSecretInputToDartRefreshTokenSecretInput(
        e as String,
      ),
    )
    .toList();
List<String>
fromDartListRefreshTokenSecretInputToGraphQLListRefreshTokenSecretInput(
  List<RefreshTokenSecretInput> v,
) => v
    .map(
      (e) => fromDartRefreshTokenSecretInputToGraphQLRefreshTokenSecretInput(e),
    )
    .toList();
List<RefreshTokenSecretInput>?
fromGraphQLListNullableRefreshTokenSecretInputToDartListNullableRefreshTokenSecretInput(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLRefreshTokenSecretInputToDartRefreshTokenSecretInput(
        e as String,
      ),
    )
    .toList();
List<String>?
fromDartListNullableRefreshTokenSecretInputToGraphQLListNullableRefreshTokenSecretInput(
  List<RefreshTokenSecretInput>? v,
) => v
    ?.map(
      (e) => fromDartRefreshTokenSecretInputToGraphQLRefreshTokenSecretInput(e),
    )
    .toList();

RefreshTokenSecretInput?
fromGraphQLRefreshTokenSecretInputNullableToDartRefreshTokenSecretInputNullable(
  String? v,
) => v == null ? null : RefreshTokenSecretInput(v);
String?
fromDartRefreshTokenSecretInputNullableToGraphQLRefreshTokenSecretInputNullable(
  RefreshTokenSecretInput? v,
) => v?.val;
List<RefreshTokenSecretInput?>
fromGraphQLListRefreshTokenSecretInputNullableToDartListRefreshTokenSecretInputNullable(
  List<Object?> v,
) => v
    .map(
      (e) =>
          fromGraphQLRefreshTokenSecretInputNullableToDartRefreshTokenSecretInputNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>
fromDartListRefreshTokenSecretInputNullableToGraphQLListRefreshTokenSecretInputNullable(
  List<RefreshTokenSecretInput?> v,
) => v
    .map(
      (e) =>
          fromDartRefreshTokenSecretInputNullableToGraphQLRefreshTokenSecretInputNullable(
            e,
          ),
    )
    .toList();
List<RefreshTokenSecretInput?>?
fromGraphQLListNullableRefreshTokenSecretInputNullableToDartListNullableRefreshTokenSecretInputNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) =>
          fromGraphQLRefreshTokenSecretInputNullableToDartRefreshTokenSecretInputNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>?
fromDartListNullableRefreshTokenSecretInputNullableToGraphQLListNullableRefreshTokenSecretInputNullable(
  List<RefreshTokenSecretInput?>? v,
) => v
    ?.map(
      (e) =>
          fromDartRefreshTokenSecretInputNullableToGraphQLRefreshTokenSecretInputNullable(
            e,
          ),
    )
    .toList();

// SessionsListVersion

SessionsListVersion fromGraphQLSessionsListVersionToDartSessionsListVersion(
  String v,
) => SessionsListVersion(v);
String fromDartSessionsListVersionToGraphQLSessionsListVersion(
  SessionsListVersion v,
) => v.toString();
List<SessionsListVersion>
fromGraphQLListSessionsListVersionToDartListSessionsListVersion(
  List<Object?> v,
) => v
    .map(
      (e) =>
          fromGraphQLSessionsListVersionToDartSessionsListVersion(e as String),
    )
    .toList();
List<String> fromDartListSessionsListVersionToGraphQLListSessionsListVersion(
  List<SessionsListVersion> v,
) => v
    .map((e) => fromDartSessionsListVersionToGraphQLSessionsListVersion(e))
    .toList();
List<SessionsListVersion>?
fromGraphQLListNullableSessionsListVersionToDartListNullableSessionsListVersion(
  List<Object?>? v,
) => v
    ?.map(
      (e) =>
          fromGraphQLSessionsListVersionToDartSessionsListVersion(e as String),
    )
    .toList();
List<String>?
fromDartListNullableSessionsListVersionToGraphQLListNullableSessionsListVersion(
  List<SessionsListVersion>? v,
) => v
    ?.map((e) => fromDartSessionsListVersionToGraphQLSessionsListVersion(e))
    .toList();

SessionsListVersion?
fromGraphQLSessionsListVersionNullableToDartSessionsListVersionNullable(
  String? v,
) => v == null ? null : SessionsListVersion(v);
String? fromDartSessionsListVersionNullableToGraphQLSessionsListVersionNullable(
  SessionsListVersion? v,
) => v?.toString();
List<SessionsListVersion?>
fromGraphQLListSessionsListVersionNullableToDartListSessionsListVersionNullable(
  List<Object?> v,
) => v
    .map(
      (e) =>
          fromGraphQLSessionsListVersionNullableToDartSessionsListVersionNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>
fromDartListSessionsListVersionNullableToGraphQLListSessionsListVersionNullable(
  List<SessionsListVersion?> v,
) => v
    .map(
      (e) =>
          fromDartSessionsListVersionNullableToGraphQLSessionsListVersionNullable(
            e,
          ),
    )
    .toList();
List<SessionsListVersion?>?
fromGraphQLListNullableSessionsListVersionNullableToDartListNullableSessionsListVersionNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) =>
          fromGraphQLSessionsListVersionNullableToDartSessionsListVersionNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>?
fromDartListNullableSessionsListVersionNullableToGraphQLListNullableSessionsListVersionNullable(
  List<SessionsListVersion?>? v,
) => v
    ?.map(
      (e) =>
          fromDartSessionsListVersionNullableToGraphQLSessionsListVersionNullable(
            e,
          ),
    )
    .toList();

// Ip -> IpAddress

IpAddress fromGraphQLIpToDartIpAddress(String v) => IpAddress(v);
String fromDartIpAddressToGraphQLIp(IpAddress v) => v.val;
List<IpAddress> fromGraphQLListIpToDartListIpAddress(List<Object?> v) =>
    v.map((e) => fromGraphQLIpToDartIpAddress(e as String)).toList();
List<String> fromDartListIpAddressToGraphQLListDataTime(List<IpAddress> v) =>
    v.map((e) => fromDartIpAddressToGraphQLIp(e)).toList();
List<IpAddress>? fromGraphQLListNullableIpToDartListNullableIpAddress(
  List<Object?>? v,
) => v?.map((e) => fromGraphQLIpToDartIpAddress(e as String)).toList();
List<String>? fromDartListNullableIpAddressToGraphQLListNullableIp(
  List<IpAddress>? v,
) => v?.map((e) => fromDartIpAddressToGraphQLIp(e)).toList();

IpAddress? fromGraphQLIpNullableToDartIpAddressNullable(String? v) =>
    v == null ? null : IpAddress(v);
String? fromDartIpAddressNullableToGraphQLIpNullable(IpAddress? v) => v?.val;

List<IpAddress?> fromGraphQLListIpNullableToDartListIpAddressNullable(
  List<Object?> v,
) => v
    .map((e) => fromGraphQLIpNullableToDartIpAddressNullable(e as String?))
    .toList();
List<String?> fromDartListIpAddressNullableToGraphQLListIpNullable(
  List<IpAddress?> v,
) => v.map((e) => fromDartIpAddressNullableToGraphQLIpNullable(e)).toList();
