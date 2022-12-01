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

import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/store/model/chat_item.dart';
import '/store/model/chat.dart';

// ignore: todo
// TODO: Change List<Object?> to List<String>.
// Needs https://github.com/google/json_serializable.dart/issues/806

// ChatId

ChatId fromGraphQLChatIdToDartChatId(String v) => ChatId(v);
String fromDartChatIdToGraphQLChatId(ChatId v) => v.val;
List<ChatId> fromGraphQLListChatIdToDartListChatId(List<Object?> v) =>
    v.map((e) => fromGraphQLChatIdToDartChatId(e as String)).toList();
List<String> fromDartListChatIdToGraphQLListChatId(List<ChatId> v) =>
    v.map((e) => fromDartChatIdToGraphQLChatId(e)).toList();
List<ChatId>? fromGraphQLListNullableChatIdToDartListNullableChatId(
        List<Object?>? v) =>
    v?.map((e) => fromGraphQLChatIdToDartChatId(e as String)).toList();
List<String>? fromDartListNullableChatIdToGraphQLListNullableChatId(
        List<ChatId>? v) =>
    v?.map((e) => fromDartChatIdToGraphQLChatId(e)).toList();

ChatId? fromGraphQLChatIdNullableToDartChatIdNullable(String? v) =>
    v == null ? null : ChatId(v);
String? fromDartChatIdNullableToGraphQLChatIdNullable(ChatId? v) => v?.val;
List<ChatId?> fromGraphQLListChatIdNullableToDartListChatIdNullable(
        List<Object?> v) =>
    v
        .map((e) => fromGraphQLChatIdNullableToDartChatIdNullable(e as String?))
        .toList();
List<String?> fromDartListChatIdNullableToGraphQLListChatIdNullable(
        List<ChatId?> v) =>
    v.map((e) => fromDartChatIdNullableToGraphQLChatIdNullable(e)).toList();
List<ChatId?>?
    fromGraphQLListNullableChatIdNullableToDartListNullableChatIdNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatIdNullableToDartChatIdNullable(e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatIdNullableToGraphQLListNullableChatIdNullable(
            List<ChatId?>? v) =>
        v
            ?.map((e) => fromDartChatIdNullableToGraphQLChatIdNullable(e))
            .toList();

// ChatItemId

ChatItemId fromGraphQLChatItemIdToDartChatItemId(String v) => ChatItemId(v);
String fromDartChatItemIdToGraphQLChatItemId(ChatItemId v) => v.val;
List<ChatItemId> fromGraphQLListChatItemIdToDartListChatItemId(
        List<Object?> v) =>
    v.map((e) => fromGraphQLChatItemIdToDartChatItemId(e as String)).toList();
List<String> fromDartListChatItemIdToGraphQLListChatItemId(
        List<ChatItemId> v) =>
    v.map((e) => fromDartChatItemIdToGraphQLChatItemId(e)).toList();
List<ChatItemId>? fromGraphQLListNullableChatItemIdToDartListNullableChatItemId(
        List<Object?>? v) =>
    v?.map((e) => fromGraphQLChatItemIdToDartChatItemId(e as String)).toList();
List<String>? fromDartListNullableChatItemIdToGraphQLListNullableChatItemId(
        List<ChatItemId>? v) =>
    v?.map((e) => fromDartChatItemIdToGraphQLChatItemId(e)).toList();

ChatItemId? fromGraphQLChatItemIdNullableToDartChatItemIdNullable(String? v) =>
    v == null ? null : ChatItemId(v);
String? fromDartChatItemIdNullableToGraphQLChatItemIdNullable(ChatItemId? v) =>
    v?.val;
List<ChatItemId?> fromGraphQLListChatItemIdNullableToDartListChatItemIdNullable(
        List<Object?> v) =>
    v
        .map((e) =>
            fromGraphQLChatItemIdNullableToDartChatItemIdNullable(e as String?))
        .toList();
List<String?> fromDartListChatItemIdNullableToGraphQLListChatItemIdNullable(
        List<ChatItemId?> v) =>
    v
        .map((e) => fromDartChatItemIdNullableToGraphQLChatItemIdNullable(e))
        .toList();
List<ChatItemId?>?
    fromGraphQLListNullableChatItemIdNullableToDartListNullableChatItemIdNullable(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLChatItemIdNullableToDartChatItemIdNullable(
                e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatItemIdNullableToGraphQLListNullableChatItemIdNullable(
            List<ChatItemId?>? v) =>
        v
            ?.map(
                (e) => fromDartChatItemIdNullableToGraphQLChatItemIdNullable(e))
            .toList();

// ChatName

ChatName fromGraphQLChatNameToDartChatName(String v) => ChatName.unchecked(v);
String fromDartChatNameToGraphQLChatName(ChatName v) => v.val;
List<ChatName> fromGraphQLListChatNameToDartListChatName(List<Object?> v) =>
    v.map((e) => fromGraphQLChatNameToDartChatName(e as String)).toList();
List<String> fromDartListChatNameToGraphQLListChatName(List<ChatName> v) =>
    v.map((e) => fromDartChatNameToGraphQLChatName(e)).toList();
List<ChatName>? fromGraphQLListNullableChatNameToDartListNullableChatName(
        List<Object?>? v) =>
    v?.map((e) => fromGraphQLChatNameToDartChatName(e as String)).toList();
List<String>? fromDartListNullableChatNameToGraphQLListNullableChatName(
        List<ChatName>? v) =>
    v?.map((e) => fromDartChatNameToGraphQLChatName(e)).toList();

ChatName? fromGraphQLChatNameNullableToDartChatNameNullable(String? v) =>
    v == null ? null : ChatName.unchecked(v);
String? fromDartChatNameNullableToGraphQLChatNameNullable(ChatName? v) =>
    v?.val;
List<ChatName?> fromGraphQLListChatNameNullableToDartListChatNameNullable(
        List<Object?> v) =>
    v
        .map((e) =>
            fromGraphQLChatNameNullableToDartChatNameNullable(e as String?))
        .toList();
List<String?> fromDartListChatNameNullableToGraphQLListChatNameNullable(
        List<ChatName?> v) =>
    v.map((e) => fromDartChatNameNullableToGraphQLChatNameNullable(e)).toList();
List<ChatName?>?
    fromGraphQLListNullableChatNameNullableToDartListNullableChatNameNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatNameNullableToDartChatNameNullable(e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatNameNullableToGraphQLListNullableChatNameNullable(
            List<ChatName?>? v) =>
        v
            ?.map((e) => fromDartChatNameNullableToGraphQLChatNameNullable(e))
            .toList();

// ChatVersion

ChatVersion fromGraphQLChatVersionToDartChatVersion(String v) => ChatVersion(v);
String fromDartChatVersionToGraphQLChatVersion(ChatVersion v) => v.toString();
List<ChatVersion> fromGraphQLListChatVersionToDartListChatVersion(
        List<Object?> v) =>
    v.map((e) => fromGraphQLChatVersionToDartChatVersion(e as String)).toList();
List<String> fromDartListChatVersionToGraphQLListChatVersion(
        List<ChatVersion> v) =>
    v.map((e) => fromDartChatVersionToGraphQLChatVersion(e)).toList();
List<ChatVersion>?
    fromGraphQLListNullableChatVersionToDartListNullableChatVersion(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLChatVersionToDartChatVersion(e as String))
            .toList();
List<String>? fromDartListNullableChatVersionToGraphQLListNullableChatVersion(
        List<ChatVersion>? v) =>
    v?.map((e) => fromDartChatVersionToGraphQLChatVersion(e)).toList();

ChatVersion? fromGraphQLChatVersionNullableToDartChatVersionNullable(
        String? v) =>
    v == null ? null : ChatVersion(v);
String? fromDartChatVersionNullableToGraphQLChatVersionNullable(
        ChatVersion? v) =>
    v?.toString();
List<ChatVersion?>
    fromGraphQLListChatVersionNullableToDartListChatVersionNullable(
            List<Object?> v) =>
        v
            .map((e) => fromGraphQLChatVersionNullableToDartChatVersionNullable(
                e as String?))
            .toList();
List<String?> fromDartListChatVersionNullableToGraphQLListChatVersionNullable(
        List<ChatVersion?> v) =>
    v
        .map((e) => fromDartChatVersionNullableToGraphQLChatVersionNullable(e))
        .toList();
List<ChatVersion?>?
    fromGraphQLListNullableChatVersionNullableToDartListNullableChatVersionNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatVersionNullableToDartChatVersionNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatVersionNullableToGraphQLListNullableChatVersionNullable(
            List<ChatVersion?>? v) =>
        v
            ?.map((e) =>
                fromDartChatVersionNullableToGraphQLChatVersionNullable(e))
            .toList();

// ChatMessageText

ChatMessageText fromGraphQLChatMessageTextToDartChatMessageText(String v) =>
    ChatMessageText(v);
String fromDartChatMessageTextToGraphQLChatMessageText(ChatMessageText v) =>
    v.val;
List<ChatMessageText> fromGraphQLListChatMessageTextToDartListChatMessageText(
        List<Object?> v) =>
    v
        .map(
            (e) => fromGraphQLChatMessageTextToDartChatMessageText(e as String))
        .toList();
List<String> fromDartListChatMessageTextToGraphQLListChatMessageText(
        List<ChatMessageText> v) =>
    v.map((e) => fromDartChatMessageTextToGraphQLChatMessageText(e)).toList();
List<ChatMessageText>?
    fromGraphQLListNullableChatMessageTextToDartListNullableChatMessageText(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatMessageTextToDartChatMessageText(e as String))
            .toList();
List<String>?
    fromDartListNullableChatMessageTextToGraphQLListNullableChatMessageText(
            List<ChatMessageText>? v) =>
        v
            ?.map((e) => fromDartChatMessageTextToGraphQLChatMessageText(e))
            .toList();

ChatMessageText?
    fromGraphQLChatMessageTextNullableToDartChatMessageTextNullable(
            String? v) =>
        v == null ? null : ChatMessageText(v);
String? fromDartChatMessageTextNullableToGraphQLChatMessageTextNullable(
        ChatMessageText? v) =>
    v?.val;
List<ChatMessageText?>
    fromGraphQLListChatMessageTextNullableToDartListChatMessageTextNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatMessageTextNullableToDartChatMessageTextNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListChatMessageTextNullableToGraphQLListChatMessageTextNullable(
            List<ChatMessageText?> v) =>
        v
            .map((e) =>
                fromDartChatMessageTextNullableToGraphQLChatMessageTextNullable(
                    e))
            .toList();
List<ChatMessageText?>?
    fromGraphQLListNullableChatMessageTextNullableToDartListNullableChatMessageTextNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatMessageTextNullableToDartChatMessageTextNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatMessageTextNullableToGraphQLListNullableChatMessageTextNullable(
            List<ChatMessageText?>? v) =>
        v
            ?.map((e) =>
                fromDartChatMessageTextNullableToGraphQLChatMessageTextNullable(
                    e))
            .toList();

// ChatItemVersion

ChatItemVersion fromGraphQLChatItemVersionToDartChatItemVersion(String v) =>
    ChatItemVersion(v);
String fromDartChatItemVersionToGraphQLChatItemVersion(ChatItemVersion v) =>
    v.toString();
List<ChatItemVersion> fromGraphQLListChatItemVersionToDartListChatItemVersion(
        List<Object?> v) =>
    v
        .map(
            (e) => fromGraphQLChatItemVersionToDartChatItemVersion(e as String))
        .toList();
List<String> fromDartListChatItemVersionToGraphQLListChatItemVersion(
        List<ChatItemVersion> v) =>
    v.map((e) => fromDartChatItemVersionToGraphQLChatItemVersion(e)).toList();
List<ChatItemVersion>?
    fromGraphQLListNullableChatItemVersionToDartListNullableChatItemVersion(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatItemVersionToDartChatItemVersion(e as String))
            .toList();
List<String>?
    fromDartListNullableChatItemVersionToGraphQLListNullableChatItemVersion(
            List<ChatItemVersion>? v) =>
        v
            ?.map((e) => fromDartChatItemVersionToGraphQLChatItemVersion(e))
            .toList();

ChatItemVersion?
    fromGraphQLChatItemVersionNullableToDartChatItemVersionNullable(
            String? v) =>
        v == null ? null : ChatItemVersion(v);
String? fromDartChatItemVersionNullableToGraphQLChatItemVersionNullable(
        ChatItemVersion? v) =>
    v?.toString();
List<ChatItemVersion?>
    fromGraphQLListChatItemVersionNullableToDartListChatItemVersionNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatItemVersionNullableToDartChatItemVersionNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListChatItemVersionNullableToGraphQLListChatItemVersionNullable(
            List<ChatItemVersion?> v) =>
        v
            .map((e) =>
                fromDartChatItemVersionNullableToGraphQLChatItemVersionNullable(
                    e))
            .toList();
List<ChatItemVersion?>?
    fromGraphQLListNullableChatItemVersionNullableToDartListNullableChatItemVersionNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatItemVersionNullableToDartChatItemVersionNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatItemVersionNullableToGraphQLListNullableChatItemVersionNullable(
            List<ChatItemVersion?>? v) =>
        v
            ?.map((e) =>
                fromDartChatItemVersionNullableToGraphQLChatItemVersionNullable(
                    e))
            .toList();

// AttachmentId

AttachmentId fromGraphQLAttachmentIdToDartAttachmentId(String v) =>
    AttachmentId(v);
String fromDartAttachmentIdToGraphQLAttachmentId(AttachmentId v) => v.val;
List<AttachmentId> fromGraphQLListAttachmentIdToDartListAttachmentId(
        List<Object?> v) =>
    v
        .map((e) => fromGraphQLAttachmentIdToDartAttachmentId(e as String))
        .toList();
List<String> fromDartListAttachmentIdToGraphQLListAttachmentId(
        List<AttachmentId> v) =>
    v.map((e) => fromDartAttachmentIdToGraphQLAttachmentId(e)).toList();
List<AttachmentId>?
    fromGraphQLListNullableAttachmentIdToDartListNullableAttachmentId(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLAttachmentIdToDartAttachmentId(e as String))
            .toList();
List<String>? fromDartListNullableAttachmentIdToGraphQLListNullableAttachmentId(
        List<AttachmentId>? v) =>
    v?.map((e) => fromDartAttachmentIdToGraphQLAttachmentId(e)).toList();

AttachmentId? fromGraphQLAttachmentIdNullableToDartAttachmentIdNullable(
        String? v) =>
    v == null ? null : AttachmentId(v);
String? fromDartAttachmentIdNullableToGraphQLAttachmentIdNullable(
        AttachmentId? v) =>
    v?.val;
List<AttachmentId?>
    fromGraphQLListAttachmentIdNullableToDartListAttachmentIdNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLAttachmentIdNullableToDartAttachmentIdNullable(
                    e as String?))
            .toList();
List<String?> fromDartListAttachmentIdNullableToGraphQLListAttachmentIdNullable(
        List<AttachmentId?> v) =>
    v
        .map(
            (e) => fromDartAttachmentIdNullableToGraphQLAttachmentIdNullable(e))
        .toList();
List<AttachmentId?>?
    fromGraphQLListNullableAttachmentIdNullableToDartListNullableAttachmentIdNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLAttachmentIdNullableToDartAttachmentIdNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableAttachmentIdNullableToGraphQLListNullableAttachmentIdNullable(
            List<AttachmentId?>? v) =>
        v
            ?.map((e) =>
                fromDartAttachmentIdNullableToGraphQLAttachmentIdNullable(e))
            .toList();

// ChatItemsCursor

ChatItemsCursor fromGraphQLChatItemsCursorToDartChatItemsCursor(String v) =>
    ChatItemsCursor(v);
String fromDartChatItemsCursorToGraphQLChatItemsCursor(ChatItemsCursor v) =>
    v.val;
List<ChatItemsCursor> fromGraphQLListChatItemsCursorToDartListChatItemsCursor(
        List<Object?> v) =>
    v
        .map(
            (e) => fromGraphQLChatItemsCursorToDartChatItemsCursor(e as String))
        .toList();
List<String> fromDartListChatItemsCursorToGraphQLListChatItemsCursor(
        List<ChatItemsCursor> v) =>
    v.map((e) => fromDartChatItemsCursorToGraphQLChatItemsCursor(e)).toList();
List<ChatItemsCursor>?
    fromGraphQLListNullableChatItemsCursorToDartListNullableChatItemsCursor(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatItemsCursorToDartChatItemsCursor(e as String))
            .toList();
List<String>?
    fromDartListNullableChatItemsCursorToGraphQLListNullableChatItemsCursor(
            List<ChatItemsCursor>? v) =>
        v
            ?.map((e) => fromDartChatItemsCursorToGraphQLChatItemsCursor(e))
            .toList();

ChatItemsCursor?
    fromGraphQLChatItemsCursorNullableToDartChatItemsCursorNullable(
            String? v) =>
        v == null ? null : ChatItemsCursor(v);
String? fromDartChatItemsCursorNullableToGraphQLChatItemsCursorNullable(
        ChatItemsCursor? v) =>
    v?.val;
List<ChatItemsCursor?>
    fromGraphQLListChatItemsCursorNullableToDartListChatItemsCursorNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatItemsCursorNullableToDartChatItemsCursorNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListChatItemsCursorNullableToGraphQLListChatItemsCursorNullable(
            List<ChatItemsCursor?> v) =>
        v
            .map((e) =>
                fromDartChatItemsCursorNullableToGraphQLChatItemsCursorNullable(
                    e))
            .toList();
List<ChatItemsCursor?>?
    fromGraphQLListNullableChatItemsCursorNullableToDartListNullableChatItemsCursorNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatItemsCursorNullableToDartChatItemsCursorNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatItemsCursorNullableToGraphQLListNullableChatItemsCursorNullable(
            List<ChatItemsCursor?>? v) =>
        v
            ?.map((e) =>
                fromDartChatItemsCursorNullableToGraphQLChatItemsCursorNullable(
                    e))
            .toList();

// RecentChatsCursor

RecentChatsCursor fromGraphQLRecentChatsCursorToDartRecentChatsCursor(
        String v) =>
    RecentChatsCursor(v);
String fromDartRecentChatsCursorToGraphQLRecentChatsCursor(
        RecentChatsCursor v) =>
    v.val;
List<RecentChatsCursor>
    fromGraphQLListRecentChatsCursorToDartListRecentChatsCursor(
            List<Object?> v) =>
        v
            .map((e) => fromGraphQLRecentChatsCursorToDartRecentChatsCursor(
                e as String))
            .toList();
List<String> fromDartListRecentChatsCursorToGraphQLListRecentChatsCursor(
        List<RecentChatsCursor> v) =>
    v
        .map((e) => fromDartRecentChatsCursorToGraphQLRecentChatsCursor(e))
        .toList();
List<RecentChatsCursor>?
    fromGraphQLListNullableRecentChatsCursorToDartListNullableRecentChatsCursor(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLRecentChatsCursorToDartRecentChatsCursor(
                e as String))
            .toList();
List<String>?
    fromDartListNullableRecentChatsCursorToGraphQLListNullableRecentChatsCursor(
            List<RecentChatsCursor>? v) =>
        v
            ?.map((e) => fromDartRecentChatsCursorToGraphQLRecentChatsCursor(e))
            .toList();

RecentChatsCursor?
    fromGraphQLRecentChatsCursorNullableToDartRecentChatsCursorNullable(
            String? v) =>
        v == null ? null : RecentChatsCursor(v);
String? fromDartRecentChatsCursorNullableToGraphQLRecentChatsCursorNullable(
        RecentChatsCursor? v) =>
    v?.val;
List<RecentChatsCursor?>
    fromGraphQLListRecentChatsCursorNullableToDartListRecentChatsCursorNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLRecentChatsCursorNullableToDartRecentChatsCursorNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListRecentChatsCursorNullableToGraphQLListRecentChatsCursorNullable(
            List<RecentChatsCursor?> v) =>
        v
            .map((e) =>
                fromDartRecentChatsCursorNullableToGraphQLRecentChatsCursorNullable(
                    e))
            .toList();
List<RecentChatsCursor?>?
    fromGraphQLListNullableRecentChatsCursorNullableToDartListNullableRecentChatsCursorNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLRecentChatsCursorNullableToDartRecentChatsCursorNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableRecentChatsCursorNullableToGraphQLListNullableRecentChatsCursorNullable(
            List<RecentChatsCursor?>? v) =>
        v
            ?.map((e) =>
                fromDartRecentChatsCursorNullableToGraphQLRecentChatsCursorNullable(
                    e))
            .toList();

// ChatFavoritePosition

ChatFavoritePosition fromGraphQLChatFavoritePositionToDartChatFavoritePosition(
        double v) =>
    ChatFavoritePosition(v);
double fromDartChatFavoritePositionToGraphQLChatFavoritePosition(
        ChatFavoritePosition v) =>
    v.val;
List<ChatFavoritePosition>
    fromGraphQLListChatFavoritePositionToDartListChatFavoritePosition(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatFavoritePositionToDartChatFavoritePosition(
                    e as double))
            .toList();
List<double> fromDartListChatFavoritePositionToGraphQLListChatFavoritePosition(
        List<ChatFavoritePosition> v) =>
    v
        .map(
            (e) => fromDartChatFavoritePositionToGraphQLChatFavoritePosition(e))
        .toList();
List<ChatFavoritePosition>?
    fromGraphQLListNullableChatFavoritePositionToDartListNullableChatFavoritePosition(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatFavoritePositionToDartChatFavoritePosition(
                    e as double))
            .toList();
List<double>?
    fromDartListNullableChatFavoritePositionToGraphQLListNullableChatFavoritePosition(
            List<ChatFavoritePosition>? v) =>
        v
            ?.map((e) =>
                fromDartChatFavoritePositionToGraphQLChatFavoritePosition(e))
            .toList();

ChatFavoritePosition?
    fromGraphQLChatFavoritePositionNullableToDartChatFavoritePositionNullable(
            double? v) =>
        v == null ? null : ChatFavoritePosition(v);
double?
    fromDartChatFavoritePositionNullableToGraphQLChatFavoritePositionNullable(
            ChatFavoritePosition? v) =>
        v?.val;
List<ChatFavoritePosition?>
    fromGraphQLListChatFavoritePositionNullableToDartListChatFavoritePositionNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatFavoritePositionNullableToDartChatFavoritePositionNullable(
                    e as double?))
            .toList();
List<double?>
    fromDartListChatFavoritePositionNullableToGraphQLListChatFavoritePositionNullable(
            List<ChatFavoritePosition?> v) =>
        v
            .map((e) =>
                fromDartChatFavoritePositionNullableToGraphQLChatFavoritePositionNullable(
                    e))
            .toList();
List<ChatFavoritePosition?>?
    fromGraphQLListNullableChatFavoritePositionNullableToDartListNullableChatFavoritePositionNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatFavoritePositionNullableToDartChatFavoritePositionNullable(
                    e as double?))
            .toList();
List<double?>?
    fromDartListNullableChatFavoritePositionNullableToGraphQLListNullableChatFavoritePositionNullable(
            List<ChatFavoritePosition?>? v) =>
        v
            ?.map((e) =>
                fromDartChatFavoritePositionNullableToGraphQLChatFavoritePositionNullable(
                    e))
            .toList();

// FavoriteChatsListVersion

FavoriteChatsListVersion
    fromGraphQLFavoriteChatsListVersionToDartFavoriteChatsListVersion(
            String v) =>
        FavoriteChatsListVersion(v);
String fromDartFavoriteChatsListVersionToGraphQLFavoriteChatsListVersion(
        FavoriteChatsListVersion v) =>
    v.toString();
List<FavoriteChatsListVersion>
    fromGraphQLListFavoriteChatsListVersionToDartListFavoriteChatsListVersion(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLFavoriteChatsListVersionToDartFavoriteChatsListVersion(
                    e as String))
            .toList();
List<String>
    fromDartListFavoriteChatsListVersionToGraphQLListFavoriteChatsListVersion(
            List<FavoriteChatsListVersion> v) =>
        v
            .map((e) =>
                fromDartFavoriteChatsListVersionToGraphQLFavoriteChatsListVersion(
                    e))
            .toList();
List<FavoriteChatsListVersion>?
    fromGraphQLListNullableFavoriteChatsListVersionToDartListNullableFavoriteChatsListVersion(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLFavoriteChatsListVersionToDartFavoriteChatsListVersion(
                    e as String))
            .toList();
List<String>?
    fromDartListNullableFavoriteChatsListVersionToGraphQLListNullableFavoriteChatsListVersion(
            List<FavoriteChatsListVersion>? v) =>
        v
            ?.map((e) =>
                fromDartFavoriteChatsListVersionToGraphQLFavoriteChatsListVersion(
                    e))
            .toList();

FavoriteChatsListVersion?
    fromGraphQLFavoriteChatsListVersionNullableToDartFavoriteChatsListVersionNullable(
            String? v) =>
        v == null ? null : FavoriteChatsListVersion(v);
String?
    fromDartFavoriteChatsListVersionNullableToGraphQLFavoriteChatsListVersionNullable(
            FavoriteChatsListVersion? v) =>
        v?.toString();
List<FavoriteChatsListVersion?>
    fromGraphQLListFavoriteChatsListVersionNullableToDartListFavoriteChatsListVersionNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLFavoriteChatsListVersionNullableToDartFavoriteChatsListVersionNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListFavoriteChatsListVersionNullableToGraphQLListFavoriteChatsListVersionNullable(
            List<FavoriteChatsListVersion?> v) =>
        v
            .map((e) =>
                fromDartFavoriteChatsListVersionNullableToGraphQLFavoriteChatsListVersionNullable(
                    e))
            .toList();
List<FavoriteChatsListVersion?>?
    fromGraphQLListNullableFavoriteChatsListVersionNullableToDartListNullableFavoriteChatsListVersionNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLFavoriteChatsListVersionNullableToDartFavoriteChatsListVersionNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableFavoriteChatsListVersionNullableToGraphQLListNullableFavoriteChatsListVersionNullable(
            List<FavoriteChatsListVersion?>? v) =>
        v
            ?.map((e) =>
                fromDartFavoriteChatsListVersionNullableToGraphQLFavoriteChatsListVersionNullable(
                    e))
            .toList();
