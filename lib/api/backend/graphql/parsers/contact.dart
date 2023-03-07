// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/contact.dart';
import '/store/model/contact.dart';

// ignore: todo
// TODO: Change List<Object?> to List<String>.
// Needs https://github.com/google/json_serializable.dart/issues/806

// ChatContactId

ChatContactId fromGraphQLChatContactIdToDartChatContactId(String v) =>
    ChatContactId(v);
String fromDartChatContactIdToGraphQLChatContactId(ChatContactId v) => v.val;
List<ChatContactId> fromGraphQLListChatContactIdToDartListChatContactId(
        List<Object?> v) =>
    v
        .map((e) => fromGraphQLChatContactIdToDartChatContactId(e as String))
        .toList();
List<String> fromDartListChatContactIdToGraphQLListChatContactId(
        List<ChatContactId> v) =>
    v.map((e) => fromDartChatContactIdToGraphQLChatContactId(e)).toList();
List<ChatContactId>?
    fromGraphQLListNullableChatContactIdToDartListNullableChatContactId(
            List<Object?>? v) =>
        v
            ?.map(
                (e) => fromGraphQLChatContactIdToDartChatContactId(e as String))
            .toList();
List<String>?
    fromDartListNullableChatContactIdToGraphQLListNullableChatContactId(
            List<ChatContactId>? v) =>
        v?.map((e) => fromDartChatContactIdToGraphQLChatContactId(e)).toList();

ChatContactId? fromGraphQLChatContactIdNullableToDartChatContactIdNullable(
        String? v) =>
    v == null ? null : ChatContactId(v);
String? fromDartChatContactIdNullableToGraphQLChatContactIdNullable(
        ChatContactId? v) =>
    v?.val;
List<ChatContactId?>
    fromGraphQLListChatContactIdNullableToDartListChatContactIdNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatContactIdNullableToDartChatContactIdNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListChatContactIdNullableToGraphQLListChatContactIdNullable(
            List<ChatContactId?> v) =>
        v
            .map((e) =>
                fromDartChatContactIdNullableToGraphQLChatContactIdNullable(e))
            .toList();
List<ChatContactId?>?
    fromGraphQLListNullableChatContactIdNullableToDartListNullableChatContactIdNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatContactIdNullableToDartChatContactIdNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatContactIdNullableToGraphQLListNullableChatContactIdNullable(
            List<ChatContactId?>? v) =>
        v
            ?.map((e) =>
                fromDartChatContactIdNullableToGraphQLChatContactIdNullable(e))
            .toList();

// ChatContactFavoritePosition

ChatContactFavoritePosition
    fromGraphQLChatContactFavoritePositionToDartChatContactFavoritePosition(
            double v) =>
        ChatContactFavoritePosition(v);
double fromDartChatContactFavoritePositionToGraphQLChatContactFavoritePosition(
        ChatContactFavoritePosition v) =>
    v.val;
List<ChatContactFavoritePosition>
    fromGraphQLListChatContactFavoritePositionToDartListChatContactFavoritePosition(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatContactFavoritePositionToDartChatContactFavoritePosition(
                    e as double))
            .toList();
List<double>
    fromDartListChatContactFavoritePositionToGraphQLListChatContactFavoritePosition(
            List<ChatContactFavoritePosition> v) =>
        v
            .map((e) =>
                fromDartChatContactFavoritePositionToGraphQLChatContactFavoritePosition(
                    e))
            .toList();
List<ChatContactFavoritePosition>?
    fromGraphQLListNullableChatContactFavoritePositionToDartListNullableChatContactFavoritePosition(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatContactFavoritePositionToDartChatContactFavoritePosition(
                    e as double))
            .toList();
List<double>?
    fromDartListNullableChatContactFavoritePositionToGraphQLListNullableChatContactFavoritePosition(
            List<ChatContactFavoritePosition>? v) =>
        v
            ?.map((e) =>
                fromDartChatContactFavoritePositionToGraphQLChatContactFavoritePosition(
                    e))
            .toList();

ChatContactFavoritePosition?
    fromGraphQLChatContactFavoritePositionNullableToDartChatContactFavoritePositionNullable(
            double? v) =>
        v == null ? null : ChatContactFavoritePosition(v);
double?
    fromDartChatContactFavoritePositionNullableToGraphQLChatContactFavoritePositionNullable(
            ChatContactFavoritePosition? v) =>
        v?.val;
List<ChatContactFavoritePosition?>
    fromGraphQLListChatContactFavoritePositionNullableToDartListChatContactFavoritePositionNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatContactFavoritePositionNullableToDartChatContactFavoritePositionNullable(
                    e as double?))
            .toList();
List<double?>
    fromDartListChatContactFavoritePositionNullableToGraphQLListChatContactFavoritePositionNullable(
            List<ChatContactFavoritePosition?> v) =>
        v
            .map((e) =>
                fromDartChatContactFavoritePositionNullableToGraphQLChatContactFavoritePositionNullable(
                    e))
            .toList();
List<ChatContactFavoritePosition?>?
    fromGraphQLListNullableChatContactFavoritePositionNullableToDartListNullableChatContactFavoritePositionNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatContactFavoritePositionNullableToDartChatContactFavoritePositionNullable(
                    e as double?))
            .toList();
List<double?>?
    fromDartListNullableChatContactFavoritePositionNullableToGraphQLListNullableChatContactFavoritePositionNullable(
            List<ChatContactFavoritePosition?>? v) =>
        v
            ?.map((e) =>
                fromDartChatContactFavoritePositionNullableToGraphQLChatContactFavoritePositionNullable(
                    e))
            .toList();

// ChatContactVersion

ChatContactVersion fromGraphQLChatContactVersionToDartChatContactVersion(
        String v) =>
    ChatContactVersion(v);
String fromDartChatContactVersionToGraphQLChatContactVersion(
        ChatContactVersion v) =>
    v.toString();
List<ChatContactVersion>
    fromGraphQLListChatContactVersionToDartListChatContactVersion(
            List<Object?> v) =>
        v
            .map((e) => fromGraphQLChatContactVersionToDartChatContactVersion(
                e as String))
            .toList();
List<String> fromDartListChatContactVersionToGraphQLListChatContactVersion(
        List<ChatContactVersion> v) =>
    v
        .map((e) => fromDartChatContactVersionToGraphQLChatContactVersion(e))
        .toList();
List<ChatContactVersion>?
    fromGraphQLListNullableChatContactVersionToDartListNullableChatContactVersion(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLChatContactVersionToDartChatContactVersion(
                e as String))
            .toList();
List<String>?
    fromDartListNullableChatContactVersionToGraphQLListNullableChatContactVersion(
            List<ChatContactVersion>? v) =>
        v
            ?.map(
                (e) => fromDartChatContactVersionToGraphQLChatContactVersion(e))
            .toList();

ChatContactVersion?
    fromGraphQLChatContactVersionNullableToDartChatContactVersionNullable(
            String? v) =>
        v == null ? null : ChatContactVersion(v);
String? fromDartChatContactVersionNullableToGraphQLChatContactVersionNullable(
        ChatContactVersion? v) =>
    v?.toString();
List<ChatContactVersion?>
    fromGraphQLListChatContactVersionNullableToDartListChatContactVersionNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatContactVersionNullableToDartChatContactVersionNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListChatContactVersionNullableToGraphQLListChatContactVersionNullable(
            List<ChatContactVersion?> v) =>
        v
            .map((e) =>
                fromDartChatContactVersionNullableToGraphQLChatContactVersionNullable(
                    e))
            .toList();
List<ChatContactVersion?>?
    fromGraphQLListNullableChatContactVersionNullableToDartListNullableChatContactVersionNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatContactVersionNullableToDartChatContactVersionNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatContactVersionNullableToGraphQLListNullableChatContactVersionNullable(
            List<ChatContactVersion?>? v) =>
        v
            ?.map((e) =>
                fromDartChatContactVersionNullableToGraphQLChatContactVersionNullable(
                    e))
            .toList();

// ChatContactsListVersion

ChatContactsListVersion
    fromGraphQLChatContactsListVersionToDartChatContactsListVersion(String v) =>
        ChatContactsListVersion(v);
String fromDartChatContactsListVersionToGraphQLChatContactsListVersion(
        ChatContactsListVersion v) =>
    v.toString();
List<ChatContactsListVersion>
    fromGraphQLListChatContactsListVersionToDartListChatContactsListVersion(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatContactsListVersionToDartChatContactsListVersion(
                    e as String))
            .toList();
List<String>
    fromDartListChatContactsListVersionToGraphQLListChatContactsListVersion(
            List<ChatContactsListVersion> v) =>
        v
            .map((e) =>
                fromDartChatContactsListVersionToGraphQLChatContactsListVersion(
                    e))
            .toList();
List<ChatContactsListVersion>?
    fromGraphQLListNullableChatContactsListVersionToDartListNullableChatContactsListVersion(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatContactsListVersionToDartChatContactsListVersion(
                    e as String))
            .toList();
List<String>?
    fromDartListNullableChatContactsListVersionToGraphQLListNullableChatContactsListVersion(
            List<ChatContactsListVersion>? v) =>
        v
            ?.map((e) =>
                fromDartChatContactsListVersionToGraphQLChatContactsListVersion(
                    e))
            .toList();

ChatContactsListVersion?
    fromGraphQLChatContactsListVersionNullableToDartChatContactsListVersionNullable(
            String? v) =>
        v == null ? null : ChatContactsListVersion(v);
String?
    fromDartChatContactsListVersionNullableToGraphQLChatContactsListVersionNullable(
            ChatContactsListVersion? v) =>
        v?.toString();
List<ChatContactsListVersion?>
    fromGraphQLListChatContactsListVersionNullableToDartListChatContactsListVersionNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatContactsListVersionNullableToDartChatContactsListVersionNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListChatContactsListVersionNullableToGraphQLListChatContactsListVersionNullable(
            List<ChatContactsListVersion?> v) =>
        v
            .map((e) =>
                fromDartChatContactsListVersionNullableToGraphQLChatContactsListVersionNullable(
                    e))
            .toList();
List<ChatContactsListVersion?>?
    fromGraphQLListNullableChatContactsListVersionNullableToDartListNullableChatContactsListVersionNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatContactsListVersionNullableToDartChatContactsListVersionNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatContactsListVersionNullableToGraphQLListNullableChatContactsListVersionNullable(
            List<ChatContactsListVersion?>? v) =>
        v
            ?.map((e) =>
                fromDartChatContactsListVersionNullableToGraphQLChatContactsListVersionNullable(
                    e))
            .toList();

// ChatContactsCursor

ChatContactsCursor fromGraphQLChatContactsCursorToDartChatContactsCursor(
        String v) =>
    ChatContactsCursor(v);
String fromDartChatContactsCursorToGraphQLChatContactsCursor(
        ChatContactsCursor v) =>
    v.toString();
List<ChatContactsCursor>
    fromGraphQLListChatContactsCursorToDartListChatContactsCursor(
            List<Object?> v) =>
        v
            .map((e) => fromGraphQLChatContactsCursorToDartChatContactsCursor(
                e as String))
            .toList();
List<String> fromDartListChatContactsCursorToGraphQLListChatContactsCursor(
        List<ChatContactsCursor> v) =>
    v
        .map((e) => fromDartChatContactsCursorToGraphQLChatContactsCursor(e))
        .toList();
List<ChatContactsCursor>?
    fromGraphQLListNullableChatContactsCursorToDartListNullableChatContactsCursor(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLChatContactsCursorToDartChatContactsCursor(
                e as String))
            .toList();
List<String>?
    fromDartListNullableChatContactsCursorToGraphQLListNullableChatContactsCursor(
            List<ChatContactsCursor>? v) =>
        v
            ?.map(
                (e) => fromDartChatContactsCursorToGraphQLChatContactsCursor(e))
            .toList();

ChatContactsCursor?
    fromGraphQLChatContactsCursorNullableToDartChatContactsCursorNullable(
            String? v) =>
        v == null ? null : ChatContactsCursor(v);
String? fromDartChatContactsCursorNullableToGraphQLChatContactsCursorNullable(
        ChatContactsCursor? v) =>
    v?.toString();
List<ChatContactsCursor?>
    fromGraphQLListChatContactsCursorNullableToDartListChatContactsCursorNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatContactsCursorNullableToDartChatContactsCursorNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListChatContactsCursorNullableToGraphQLListChatContactsCursorNullable(
            List<ChatContactsCursor?> v) =>
        v
            .map((e) =>
                fromDartChatContactsCursorNullableToGraphQLChatContactsCursorNullable(
                    e))
            .toList();
List<ChatContactsCursor?>?
    fromGraphQLListNullableChatContactsCursorNullableToDartListNullableChatContactsCursorNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatContactsCursorNullableToDartChatContactsCursorNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatContactsCursorNullableToGraphQLListNullableChatContactsCursorNullable(
            List<ChatContactsCursor?>? v) =>
        v
            ?.map((e) =>
                fromDartChatContactsCursorNullableToGraphQLChatContactsCursorNullable(
                    e))
            .toList();
