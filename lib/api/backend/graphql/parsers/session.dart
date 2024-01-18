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

import '/domain/model/session.dart';
import '/store/model/session.dart';

// ignore: todo
// TODO: Change List<Object?> to List<String>.
// Needs https://github.com/google/json_serializable.dart/issues/806

// AccessToken

AccessToken fromGraphQLAccessTokenToDartAccessToken(String v) => AccessToken(v);
String fromDartAccessTokenToGraphQLAccessToken(AccessToken v) => v.val;
List<AccessToken> fromGraphQLListAccessTokenToDartListAccessToken(
        List<Object?> v) =>
    v.map((e) => fromGraphQLAccessTokenToDartAccessToken(e as String)).toList();
List<String> fromDartListAccessTokenToGraphQLListAccessToken(
        List<AccessToken> v) =>
    v.map((e) => fromDartAccessTokenToGraphQLAccessToken(e)).toList();
List<AccessToken>?
    fromGraphQLListNullableAccessTokenToDartListNullableAccessToken(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLAccessTokenToDartAccessToken(e as String))
            .toList();
List<String>? fromDartListNullableAccessTokenToGraphQLListNullableAccessToken(
        List<AccessToken>? v) =>
    v?.map((e) => fromDartAccessTokenToGraphQLAccessToken(e)).toList();

AccessToken? fromGraphQLAccessTokenNullableToDartAccessTokenNullable(
        String? v) =>
    v == null ? null : AccessToken(v);
String? fromDartAccessTokenNullableToGraphQLAccessTokenNullable(
        AccessToken? v) =>
    v?.val;
List<AccessToken?>
    fromGraphQLListAccessTokenNullableToDartListAccessTokenNullable(
            List<Object?> v) =>
        v
            .map((e) => fromGraphQLAccessTokenNullableToDartAccessTokenNullable(
                e as String?))
            .toList();
List<String?> fromDartListAccessTokenNullableToGraphQLListAccessTokenNullable(
        List<AccessToken?> v) =>
    v
        .map((e) => fromDartAccessTokenNullableToGraphQLAccessTokenNullable(e))
        .toList();
List<AccessToken?>?
    fromGraphQLListNullableAccessTokenNullableToDartListNullableAccessTokenNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLAccessTokenNullableToDartAccessTokenNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableAccessTokenNullableToGraphQLListNullableAccessTokenNullable(
            List<AccessToken?>? v) =>
        v
            ?.map((e) =>
                fromDartAccessTokenNullableToGraphQLAccessTokenNullable(e))
            .toList();

// RefreshToken

RefreshToken fromGraphQLRefreshTokenToDartRefreshToken(String v) =>
    RefreshToken(v);
String fromDartRefreshTokenToGraphQLRefreshToken(RefreshToken v) => v.val;
List<RefreshToken> fromGraphQLListRefreshTokenToDartListRefreshToken(
        List<Object?> v) =>
    v
        .map((e) => fromGraphQLRefreshTokenToDartRefreshToken(e as String))
        .toList();
List<String> fromDartListRefreshTokenToGraphQLListRefreshToken(
        List<RefreshToken> v) =>
    v.map((e) => fromDartRefreshTokenToGraphQLRefreshToken(e)).toList();
List<RefreshToken>?
    fromGraphQLListNullableRefreshTokenToDartListNullableRefreshToken(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLRefreshTokenToDartRefreshToken(e as String))
            .toList();
List<String>? fromDartListNullableRefreshTokenToGraphQLListNullableRefreshToken(
        List<RefreshToken>? v) =>
    v?.map((e) => fromDartRefreshTokenToGraphQLRefreshToken(e)).toList();

RefreshToken? fromGraphQLRefreshTokenNullableToDartRefreshTokenNullable(
        String? v) =>
    v == null ? null : RefreshToken(v);
String? fromDartRefreshTokenNullableToGraphQLRefreshTokenNullable(
        RefreshToken? v) =>
    v?.val;
List<RefreshToken?>
    fromGraphQLListRefreshTokenNullableToDartListRefreshTokenNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLRefreshTokenNullableToDartRefreshTokenNullable(
                    e as String?))
            .toList();
List<String?> fromDartListRefreshTokenNullableToGraphQLListRefreshTokenNullable(
        List<RefreshToken?> v) =>
    v
        .map(
            (e) => fromDartRefreshTokenNullableToGraphQLRefreshTokenNullable(e))
        .toList();
List<RefreshToken?>?
    fromGraphQLListNullableRefreshTokenNullableToDartListNullableRefreshTokenNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLRefreshTokenNullableToDartRefreshTokenNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableRefreshTokenNullableToGraphQLListNullableRefreshTokenNullable(
            List<RefreshToken?>? v) =>
        v
            ?.map((e) =>
                fromDartRefreshTokenNullableToGraphQLRefreshTokenNullable(e))
            .toList();

// SessionVersion

SessionVersion fromGraphQLSessionVersionToDartSessionVersion(String v) =>
    SessionVersion.parse(v);
String fromDartSessionVersionToGraphQLSessionVersion(SessionVersion v) =>
    v.toString();
List<SessionVersion> fromGraphQLListSessionVersionToDartListSessionVersion(
        List<Object?> v) =>
    v
        .map((e) => fromGraphQLSessionVersionToDartSessionVersion(e as String))
        .toList();
List<String> fromDartListSessionVersionToGraphQLListSessionVersion(
        List<SessionVersion> v) =>
    v.map((e) => fromDartSessionVersionToGraphQLSessionVersion(e)).toList();
List<SessionVersion>?
    fromGraphQLListNullableSessionVersionToDartListNullableSessionVersion(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLSessionVersionToDartSessionVersion(e as String))
            .toList();
List<String>?
    fromDartListNullableSessionVersionToGraphQLListNullableSessionVersion(
            List<SessionVersion>? v) =>
        v
            ?.map((e) => fromDartSessionVersionToGraphQLSessionVersion(e))
            .toList();

SessionVersion? fromGraphQLSessionVersionNullableToDartSessionVersionNullable(
        String? v) =>
    v == null ? null : SessionVersion.parse(v);
String? fromDartSessionVersionNullableToGraphQLSessionVersionNullable(
        SessionVersion? v) =>
    v?.toString();
List<SessionVersion?>
    fromGraphQLListSessionVersionNullableToDartListSessionVersionNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLSessionVersionNullableToDartSessionVersionNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListSessionVersionNullableToGraphQLListSessionVersionNullable(
            List<SessionVersion?> v) =>
        v
            .map((e) =>
                fromDartSessionVersionNullableToGraphQLSessionVersionNullable(
                    e))
            .toList();
List<SessionVersion?>?
    fromGraphQLListNullableSessionVersionNullableToDartListNullableSessionVersionNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLSessionVersionNullableToDartSessionVersionNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableSessionVersionNullableToGraphQLListNullableSessionVersionNullable(
            List<SessionVersion?>? v) =>
        v
            ?.map((e) =>
                fromDartSessionVersionNullableToGraphQLSessionVersionNullable(
                    e))
            .toList();

// RememberedSessionVersion

RememberedSessionVersion
    fromGraphQLRememberedSessionVersionToDartRememberedSessionVersion(
            String v) =>
        RememberedSessionVersion.parse(v);
String fromDartRememberedSessionVersionToGraphQLRememberedSessionVersion(
        RememberedSessionVersion v) =>
    v.toString();
List<RememberedSessionVersion>
    fromGraphQLListRememberedSessionVersionToDartListRememberedSessionVersion(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLRememberedSessionVersionToDartRememberedSessionVersion(
                    e as String))
            .toList();
List<String>
    fromDartListRememberedSessionVersionToGraphQLListRememberedSessionVersion(
            List<RememberedSessionVersion> v) =>
        v
            .map((e) =>
                fromDartRememberedSessionVersionToGraphQLRememberedSessionVersion(
                    e))
            .toList();
List<RememberedSessionVersion>?
    fromGraphQLListNullableRememberedSessionVersionToDartListNullableRememberedSessionVersion(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLRememberedSessionVersionToDartRememberedSessionVersion(
                    e as String))
            .toList();
List<String>?
    fromDartListNullableRememberedSessionVersionToGraphQLListNullableRememberedSessionVersion(
            List<RememberedSessionVersion>? v) =>
        v
            ?.map((e) =>
                fromDartRememberedSessionVersionToGraphQLRememberedSessionVersion(
                    e))
            .toList();

RememberedSessionVersion?
    fromGraphQLRememberedSessionVersionNullableToDartRememberedSessionVersionNullable(
            String? v) =>
        v == null ? null : RememberedSessionVersion.parse(v);
String?
    fromDartRememberedSessionVersionNullableToGraphQLRememberedSessionVersionNullable(
            RememberedSessionVersion? v) =>
        v?.toString();
List<RememberedSessionVersion?>
    fromGraphQLListRememberedSessionVersionNullableToDartListRememberedSessionVersionNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLRememberedSessionVersionNullableToDartRememberedSessionVersionNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListRememberedSessionVersionNullableToGraphQLListRememberedSessionVersionNullable(
            List<RememberedSessionVersion?> v) =>
        v
            .map((e) =>
                fromDartRememberedSessionVersionNullableToGraphQLRememberedSessionVersionNullable(
                    e))
            .toList();
List<RememberedSessionVersion?>?
    fromGraphQLListNullableRememberedSessionVersionNullableToDartListNullableRememberedSessionVersionNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLRememberedSessionVersionNullableToDartRememberedSessionVersionNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableRememberedSessionVersionNullableToGraphQLListNullableRememberedSessionVersionNullable(
            List<RememberedSessionVersion?>? v) =>
        v
            ?.map((e) =>
                fromDartRememberedSessionVersionNullableToGraphQLRememberedSessionVersionNullable(
                    e))
            .toList();
