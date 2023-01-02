// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/domain/model/chat_call.dart';
import '/store/model/chat_call.dart';

// ignore: todo
// TODO: Change List<Object?> to List<String>.
// Needs https://github.com/google/json_serializable.dart/issues/806

// ChatCallCredentials

ChatCallCredentials fromGraphQLChatCallCredentialsToDartChatCallCredentials(
        String v) =>
    ChatCallCredentials(v);
String fromDartChatCallCredentialsToGraphQLChatCallCredentials(
        ChatCallCredentials v) =>
    v.val;
List<ChatCallCredentials>
    fromGraphQLListChatCallCredentialsToDartListChatCallCredentials(
            List<Object?> v) =>
        v
            .map((e) => fromGraphQLChatCallCredentialsToDartChatCallCredentials(
                e as String))
            .toList();
List<String> fromDartListChatCallCredentialsToGraphQLListChatCallCredentials(
        List<ChatCallCredentials> v) =>
    v
        .map((e) => fromDartChatCallCredentialsToGraphQLChatCallCredentials(e))
        .toList();
List<ChatCallCredentials>?
    fromGraphQLListNullableChatCallCredentialsToDartListNullableChatCallCredentials(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatCallCredentialsToDartChatCallCredentials(
                    e as String))
            .toList();
List<String>?
    fromDartListNullableChatCallCredentialsToGraphQLListNullableChatCallCredentials(
            List<ChatCallCredentials>? v) =>
        v
            ?.map((e) =>
                fromDartChatCallCredentialsToGraphQLChatCallCredentials(e))
            .toList();

ChatCallCredentials?
    fromGraphQLChatCallCredentialsNullableToDartChatCallCredentialsNullable(
            String? v) =>
        v == null ? null : ChatCallCredentials(v);
String? fromDartChatCallCredentialsNullableToGraphQLChatCallCredentialsNullable(
        ChatCallCredentials? v) =>
    v?.val;
List<ChatCallCredentials?>
    fromGraphQLListChatCallCredentialsNullableToDartListChatCallCredentialsNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatCallCredentialsNullableToDartChatCallCredentialsNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListChatCallCredentialsNullableToGraphQLListChatCallCredentialsNullable(
            List<ChatCallCredentials?> v) =>
        v
            .map((e) =>
                fromDartChatCallCredentialsNullableToGraphQLChatCallCredentialsNullable(
                    e))
            .toList();
List<ChatCallCredentials?>?
    fromGraphQLListNullableChatCallCredentialsNullableToDartListNullableChatCallCredentialsNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatCallCredentialsNullableToDartChatCallCredentialsNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatCallCredentialsNullableToGraphQLListNullableChatCallCredentialsNullable(
            List<ChatCallCredentials?>? v) =>
        v
            ?.map((e) =>
                fromDartChatCallCredentialsNullableToGraphQLChatCallCredentialsNullable(
                    e))
            .toList();

// ChatCallRoomJoinLink

ChatCallRoomJoinLink fromGraphQLChatCallRoomJoinLinkToDartChatCallRoomJoinLink(
        String v) =>
    ChatCallRoomJoinLink(v);
String fromDartChatCallRoomJoinLinkToGraphQLChatCallRoomJoinLink(
        ChatCallRoomJoinLink v) =>
    v.val;
List<ChatCallRoomJoinLink>
    fromGraphQLListChatCallRoomJoinLinkToDartListChatCallRoomJoinLink(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatCallRoomJoinLinkToDartChatCallRoomJoinLink(
                    e as String))
            .toList();
List<String> fromDartListChatCallRoomJoinLinkToGraphQLListChatCallRoomJoinLink(
        List<ChatCallRoomJoinLink> v) =>
    v
        .map(
            (e) => fromDartChatCallRoomJoinLinkToGraphQLChatCallRoomJoinLink(e))
        .toList();
List<ChatCallRoomJoinLink>?
    fromGraphQLListNullableChatCallRoomJoinLinkToDartListNullableChatCallRoomJoinLink(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatCallRoomJoinLinkToDartChatCallRoomJoinLink(
                    e as String))
            .toList();
List<String>?
    fromDartListNullableChatCallRoomJoinLinkToGraphQLListNullableChatCallRoomJoinLink(
            List<ChatCallRoomJoinLink>? v) =>
        v
            ?.map((e) =>
                fromDartChatCallRoomJoinLinkToGraphQLChatCallRoomJoinLink(e))
            .toList();

ChatCallRoomJoinLink?
    fromGraphQLChatCallRoomJoinLinkNullableToDartChatCallRoomJoinLinkNullable(
            String? v) =>
        v == null ? null : ChatCallRoomJoinLink(v);
String?
    fromDartChatCallRoomJoinLinkNullableToGraphQLChatCallRoomJoinLinkNullable(
            ChatCallRoomJoinLink? v) =>
        v?.val;
List<ChatCallRoomJoinLink?>
    fromGraphQLListChatCallRoomJoinLinkNullableToDartListChatCallRoomJoinLinkNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatCallRoomJoinLinkNullableToDartChatCallRoomJoinLinkNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListChatCallRoomJoinLinkNullableToGraphQLListChatCallRoomJoinLinkNullable(
            List<ChatCallRoomJoinLink?> v) =>
        v
            .map((e) =>
                fromDartChatCallRoomJoinLinkNullableToGraphQLChatCallRoomJoinLinkNullable(
                    e))
            .toList();
List<ChatCallRoomJoinLink?>?
    fromGraphQLListNullableChatCallRoomJoinLinkNullableToDartListNullableChatCallRoomJoinLinkNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatCallRoomJoinLinkNullableToDartChatCallRoomJoinLinkNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatCallRoomJoinLinkNullableToGraphQLListNullableChatCallRoomJoinLinkNullable(
            List<ChatCallRoomJoinLink?>? v) =>
        v
            ?.map((e) =>
                fromDartChatCallRoomJoinLinkNullableToGraphQLChatCallRoomJoinLinkNullable(
                    e))
            .toList();

// IncomingChatCallsCursor

IncomingChatCallsCursor
    fromGraphQLIncomingChatCallsCursorToDartIncomingChatCallsCursor(String v) =>
        IncomingChatCallsCursor(v);
String fromDartIncomingChatCallsCursorToGraphQLIncomingChatCallsCursor(
        IncomingChatCallsCursor v) =>
    v.val;
List<IncomingChatCallsCursor>
    fromGraphQLListIncomingChatCallsCursorToDartListIncomingChatCallsCursor(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLIncomingChatCallsCursorToDartIncomingChatCallsCursor(
                    e as String))
            .toList();
List<String>
    fromDartListIncomingChatCallsCursorToGraphQLListIncomingChatCallsCursor(
            List<IncomingChatCallsCursor> v) =>
        v
            .map((e) =>
                fromDartIncomingChatCallsCursorToGraphQLIncomingChatCallsCursor(
                    e))
            .toList();
List<IncomingChatCallsCursor>?
    fromGraphQLListNullableIncomingChatCallsCursorToDartListNullableIncomingChatCallsCursor(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLIncomingChatCallsCursorToDartIncomingChatCallsCursor(
                    e as String))
            .toList();
List<String>?
    fromDartListNullableIncomingChatCallsCursorToGraphQLListNullableIncomingChatCallsCursor(
            List<IncomingChatCallsCursor>? v) =>
        v
            ?.map((e) =>
                fromDartIncomingChatCallsCursorToGraphQLIncomingChatCallsCursor(
                    e))
            .toList();

IncomingChatCallsCursor?
    fromGraphQLIncomingChatCallsCursorNullableToDartIncomingChatCallsCursorNullable(
            String? v) =>
        v == null ? null : IncomingChatCallsCursor(v);
String?
    fromDartIncomingChatCallsCursorNullableToGraphQLIncomingChatCallsCursorNullable(
            IncomingChatCallsCursor? v) =>
        v?.val;
List<IncomingChatCallsCursor?>
    fromGraphQLListIncomingChatCallsCursorNullableToDartListIncomingChatCallsCursorNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLIncomingChatCallsCursorNullableToDartIncomingChatCallsCursorNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListIncomingChatCallsCursorNullableToGraphQLListIncomingChatCallsCursorNullable(
            List<IncomingChatCallsCursor?> v) =>
        v
            .map((e) =>
                fromDartIncomingChatCallsCursorNullableToGraphQLIncomingChatCallsCursorNullable(
                    e))
            .toList();
List<IncomingChatCallsCursor?>?
    fromGraphQLListNullableIncomingChatCallsCursorNullableToDartListNullableIncomingChatCallsCursorNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLIncomingChatCallsCursorNullableToDartIncomingChatCallsCursorNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableIncomingChatCallsCursorNullableToGraphQLListNullableIncomingChatCallsCursorNullable(
            List<IncomingChatCallsCursor?>? v) =>
        v
            ?.map((e) =>
                fromDartIncomingChatCallsCursorNullableToGraphQLIncomingChatCallsCursorNullable(
                    e))
            .toList();

// ChatCallDeviceId

ChatCallDeviceId fromGraphQLChatCallDeviceIdToDartChatCallDeviceId(String v) =>
    ChatCallDeviceId(v);
String fromDartChatCallDeviceIdToGraphQLChatCallDeviceId(ChatCallDeviceId v) =>
    v.val;
List<ChatCallDeviceId>
    fromGraphQLListChatCallDeviceIdToDartListChatCallDeviceId(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatCallDeviceIdToDartChatCallDeviceId(e as String))
            .toList();
List<String> fromDartListChatCallDeviceIdToGraphQLListChatCallDeviceId(
        List<ChatCallDeviceId> v) =>
    v.map((e) => fromDartChatCallDeviceIdToGraphQLChatCallDeviceId(e)).toList();
List<ChatCallDeviceId>?
    fromGraphQLListNullableChatCallDeviceIdToDartListNullableChatCallDeviceId(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatCallDeviceIdToDartChatCallDeviceId(e as String))
            .toList();
List<String>?
    fromDartListNullableChatCallDeviceIdToGraphQLListNullableChatCallDeviceId(
            List<ChatCallDeviceId>? v) =>
        v
            ?.map((e) => fromDartChatCallDeviceIdToGraphQLChatCallDeviceId(e))
            .toList();

ChatCallDeviceId?
    fromGraphQLChatCallDeviceIdNullableToDartChatCallDeviceIdNullable(
            String? v) =>
        v == null ? null : ChatCallDeviceId(v);
String? fromDartChatCallDeviceIdNullableToGraphQLChatCallDeviceIdNullable(
        ChatCallDeviceId? v) =>
    v?.val;
List<ChatCallDeviceId?>
    fromGraphQLListChatCallDeviceIdNullableToDartListChatCallDeviceIdNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatCallDeviceIdNullableToDartChatCallDeviceIdNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListChatCallDeviceIdNullableToGraphQLListChatCallDeviceIdNullable(
            List<ChatCallDeviceId?> v) =>
        v
            .map((e) =>
                fromDartChatCallDeviceIdNullableToGraphQLChatCallDeviceIdNullable(
                    e))
            .toList();
List<ChatCallDeviceId?>?
    fromGraphQLListNullableChatCallDeviceIdNullableToDartListNullableChatCallDeviceIdNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatCallDeviceIdNullableToDartChatCallDeviceIdNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatCallDeviceIdNullableToGraphQLListNullableChatCallDeviceIdNullable(
            List<ChatCallDeviceId?>? v) =>
        v
            ?.map((e) =>
                fromDartChatCallDeviceIdNullableToGraphQLChatCallDeviceIdNullable(
                    e))
            .toList();
