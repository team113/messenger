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

import 'dart:async';

import 'package:get/get.dart';

import '../../provider/hive/calls_settings.dart';
import '../model/chat.dart';
import '../model/chat_call.dart';
import '../model/chat_item.dart';
import '../model/my_user.dart';
import '../model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/store/event/chat_call.dart';
import '/util/localized_exception.dart';
import '/util/obs/obs.dart';
import '/util/web/web_utils.dart';

/// [OngoingCall]s repository interface.
abstract class AbstractCallRepository {
  /// Map of the current [OngoingCall]s.
  RxObsMap<ChatId, Rx<OngoingCall>> get calls;

  /// Returns reactive [OngoingCall] if there's any identified by [chatId].
  Rx<OngoingCall>? operator [](ChatId chatId);

  /// Replaces the value of [OngoingCall] identified by [chatId] to [call].
  void operator []=(ChatId chatId, Rx<OngoingCall> call);

  /// Adds the provided [ChatCall] to the [calls], if not already.
  Rx<OngoingCall>? add(ChatCall call);

  /// Transforms the provided [WebStoredCall] into an [OngoingCall] and adds it,
  /// if not already.
  Rx<OngoingCall> addStored(
    WebStoredCall stored, {
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
  });

  /// Switches the [OngoingCall] identified by its [chatId] to the specified
  /// [newChatId].
  void move(ChatId chatId, ChatId newChatId);

  /// Ends an [OngoingCall] happening in the [Chat] identified by the provided
  /// [chatId].
  Rx<OngoingCall>? remove(ChatId chatId);

  /// Returns `true` if an [OngoingCall] identified by [chatId] exists in the
  /// [calls] map.
  bool contains(ChatId chatId);

  /// Starts a new [OngoingCall] in the specified [chatId] by the authenticated
  /// [MyUser].
  Future<Rx<OngoingCall>> start(
    ChatId chatId, {
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
  });

  /// Joins the current [OngoingCall] in the specified [chatId] by the
  /// authenticated [MyUser].
  Future<Rx<OngoingCall>?> join(
    ChatId chatId,
    ChatItemId? callId, {
    bool withAudio = true,
    bool withVideo = false,
    bool withScreen = false,
  });

  /// Leaves the current [OngoingCall] in the specified [chatId] by the
  /// authenticated [MyUser].
  Future<void> leave(ChatId chatId, ChatCallDeviceId deviceId);

  /// Declines the current [OngoingCall] in the specified [chatId] by the
  /// authenticated [MyUser].
  Future<void> decline(ChatId chatId);

  /// Raises/lowers a hand of the authenticated [MyUser] in the specified
  /// [ChatCall].
  Future<void> toggleHand(ChatId chatId, bool raised);

  /// Moves an ongoing [ChatCall] in a [Chat]-dialog to a newly created
  /// [Chat]-group, optionally adding new members.
  Future<void> transformDialogCallIntoGroupCall(
    ChatId chatId,
    List<UserId> additionalMemberIds,
    ChatName? groupName,
  );

  /// Redials a [User] who left or declined the ongoing [ChatCall] in the
  /// specified [Chat]-group by the authenticated [MyUser].
  Future<void> redialChatCallMember(ChatId chatId, UserId memberId);

  /// Generates the [ChatCallCredentials] for a [Chat] identified by the
  /// provided [id].
  ///
  /// These [ChatCallCredentials] are considered temporary. Use
  /// [transferCredentials] to persist them, once [ChatItemId] of the
  /// [OngoingCall] is acquired.
  ChatCallCredentials generateCredentials(ChatId id);

  /// Transfers the [ChatCallCredentials] from the provided [Chat] to the
  /// specified [OngoingCall].
  void transferCredentials(ChatId chatId, ChatItemId callId);

  /// Returns the [ChatCallCredentials] for an [OngoingCall] identified by the
  /// provided [id].
  ChatCallCredentials getCredentials(ChatItemId id);

  /// Moves the [ChatCallCredentials] from the [callId] to the [newCallId].
  void moveCredentials(ChatItemId callId, ChatItemId newCallId);

  /// Removes the [ChatCallCredentials] of an [OngoingCall] identified by the
  /// provided [id].
  Future<void> removeCredentials(ChatItemId id);

  /// Removes a [Chat] identified by the provided [id] from the [chats].
  Future<void> setPrefs(CallPreferences prefs);

  /// Removes a [Chat] identified by the provided [id] from the [chats].
  CallPreferences? getPrefs(ChatId id);

  /// Subscribes to [ChatCallEvent]s of an [OngoingCall].
  ///
  /// This subscription is mandatory to be created after executing [start] or
  /// [join] as represents a heartbeat indication of the authenticated
  /// [MyUser]'s participation in an [OngoingCall]. Stopping or breaking this
  /// subscription without leaving the [OngoingCall] will end up by kicking the
  /// authenticated [MyUser] from this [OngoingCall] by timeout.
  Future<Stream<ChatCallEvents>> heartbeat(
    ChatItemId id,
    ChatCallDeviceId deviceId,
  );
}

/// Cannot create a new [OngoingCall] in the specified [Chat], because it exists
/// already.
class CallAlreadyExistsException
    with LocalizedExceptionMixin
    implements Exception {
  @override
  String toMessage() => 'err_call_already_exists'.l10n;
}

/// Cannot join an [OngoingCall] as it doesn't exist on the client-side.
class CallDoesNotExistException
    with LocalizedExceptionMixin
    implements Exception {
  @override
  String toMessage() => 'err_call_not_found'.l10n;
}

/// Cannot join or start an [OngoingCall] as the authenticated [MyUser] has
/// already joined it.
class CallAlreadyJoinedException
    with LocalizedExceptionMixin
    implements Exception {
  const CallAlreadyJoinedException(this.deviceId);

  /// [ChatCallDeviceId] of the already joined device.
  final ChatCallDeviceId deviceId;

  @override
  String toMessage() => 'err_call_already_joined'.l10n;
}

/// Cannot join or start an [OngoingCall] as it's maintained in a separate
/// popup window.
class CallIsInPopupException with LocalizedExceptionMixin implements Exception {
  @override
  String toMessage() => 'err_call_is_in_popup'.l10n;
}
