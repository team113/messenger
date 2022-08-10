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

import '../model/chat_call.dart';
import '../model/chat_item.dart';
import '../model/chat.dart';
import '../model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/store/event/chat_call.dart';
import '/store/event/incoming_chat_call.dart';
import '/util/localized_exception.dart';
import '/util/obs/obs.dart';

/// [OngoingCall]s repository interface.
abstract class AbstractCallRepository {
  /// Map of the current [OngoingCall]s.
  RxObsMap<ChatId, Rx<OngoingCall>> get calls;

  /// Returns reactive [OngoingCall] if there's any identified by [chatId].
  Rx<OngoingCall>? operator [](ChatId chatId);

  /// Replaces the value of [OngoingCall] identified by [chatId] to [call].
  void operator []=(ChatId chatId, Rx<OngoingCall> call);

  /// Adds [call] identified by [chatId] to the [calls] map.
  void add(Rx<OngoingCall> call);

  /// Switches the [OngoingCall] identified by its [chatId] to the specified
  /// [newChatId].
  void move(ChatId chatId, ChatId newChatId);

  /// Removes the [OngoingCall] identified by [chatId] from the [calls] map.
  Rx<OngoingCall>? remove(ChatId chatId);

  /// Returns `true` if an [OngoingCall] identified by [chatId] exists in the
  /// [calls] map.
  bool contains(ChatId chatId);

  /// Starts a new [OngoingCall] in the specified [chatId] by the authenticated
  /// [MyUser].
  Future<void> start(Rx<OngoingCall> call);

  /// Joins the current [OngoingCall] in the specified [chatId] by the
  /// authenticated [MyUser].
  Future<void> join(Rx<OngoingCall> call);

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

  /// Returns the subscription of [IncomingChatCallsTopEvent]s.
  ///
  /// [count] determines the length of the list of incoming [ChatCall]s which
  /// updates will be notified via events.
  Future<Stream<IncomingChatCallsTopEvent>> events(int count);
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
  @override
  String toMessage() => 'err_call_already_joined'.l10n;
}

/// Cannot join or start an [OngoingCall] as it's maintained in a separate
/// popup window.
class CallIsInPopupException with LocalizedExceptionMixin implements Exception {
  @override
  String toMessage() => 'err_call_is_in_popup'.l10n;
}
