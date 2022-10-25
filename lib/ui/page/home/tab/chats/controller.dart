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
import 'dart:collection';

import 'package:get/get.dart';

import '/api/backend/schema.graphql.dart' show Muting;
import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart'
    show
        CallAlreadyJoinedException,
        CallDoesNotExistException,
        CallIsInPopupException;
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/user.dart';
import '/provider/gql/exceptions.dart'
    show HideChatException, RemoveChatMemberException, ToggleChatMuteException;
import '/routes.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of the [HomeTab.chats] tab .
class ChatsTabController extends GetxController {
  ChatsTabController(
    this.pop,
    this._chatService,
    this._callService,
    this._authService,
    this._userService,
  );

  /// Reactive list of sorted [Chat]s.
  late final RxList<RxChat> chats;

  /// Status of a [muteChat] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [muteChat] is executing.
  /// - `status.isLoading`, meaning [muteChat] is executing.
  /// - `status.isError`, meaning [muteChat] got an error.
  final Rx<RxStatus> muteStatus = Rx<RxStatus>(RxStatus.empty());

  /// List of the mute periods.
  ///
  /// `null` meaning mute forever.
  final List<Duration?> muteDateTimes = const [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 6),
    Duration(hours: 12),
    Duration(days: 1),
    Duration(days: 7),
    null,
  ];

  /// Indicates whether the mute chat dialog is opened or not.
  final RxBool isMuteDialogOpened = RxBool(false);

  /// Pops the mute chat dialog.
  final Function() pop;

  /// [Chat]s service used to update the [chats].
  final ChatService _chatService;

  /// Calls service used to join the ongoing call in the [Chat].
  final CallService _callService;

  /// [AuthService] used to get [me] value.
  final AuthService _authService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// Subscription for [ChatService.chats] changes.
  late final StreamSubscription _chatsSubscription;

  /// Map of [_ChatSortingData]s used to sort the [chats].
  final HashMap<ChatId, _ChatSortingData> _sortingData =
      HashMap<ChatId, _ChatSortingData>();

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Indicates whether [ContactService] is ready to be used.
  RxBool get chatsReady => _chatService.isReady;

  @override
  void onInit() {
    chats = RxList<RxChat>(_chatService.chats.values.toList());
    _sortChats();

    for (RxChat chat in chats) {
      _sortingData[chat.chat.value.id] =
          _ChatSortingData(chat.chat, _sortChats);
    }

    _chatsSubscription = _chatService.chats.changes.listen((event) {
      switch (event.op) {
        case OperationKind.added:
          chats.add(event.value!);
          _sortChats();
          _sortingData[event.value!.chat.value.id] ??=
              _ChatSortingData(event.value!.chat, _sortChats);
          break;

        case OperationKind.removed:
          if (isMuteDialogOpened.value) {
            pop();
          }
          _sortingData.remove(event.key)?.dispose();
          chats.removeWhere((e) => e.chat.value.id == event.key);
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    super.onInit();
  }

  @override
  void onClose() {
    for (var data in _sortingData.values) {
      data.dispose();
    }
    _chatsSubscription.cancel();

    super.onClose();
  }

  /// Joins the call in the [Chat] identified by the provided [id] [withVideo]
  /// or without.
  Future<void> joinCall(ChatId id, {bool withVideo = false}) async {
    try {
      await _callService.join(id, withVideo: withVideo);
    } on CallAlreadyJoinedException catch (e) {
      MessagePopup.error(e);
    } on CallDoesNotExistException catch (e) {
      MessagePopup.error(e);
    } on CallIsInPopupException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Leaves the [Chat] identified by the provided [id].
  Future<void> leaveChat(ChatId id) async {
    try {
      await _chatService.removeChatMember(id, me!);
      if (router.route == '${Routes.chat}/$id') {
        router.pop();
      }
    } on RemoveChatMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Hides the [Chat] identified by the provided [id].
  Future<void> hideChat(ChatId id) async {
    try {
      await _chatService.hideChat(id);
      if (router.route == '${Routes.chat}/$id') {
        router.go('/');
      }
    } on HideChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Unmutes the [Chat] identified by the provided [id].
  Future<void> unmuteChat(ChatId id) async {
    try {
      await _chatService.toggleChatMute(id, null);
    } on ToggleChatMuteException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Mutes the [Chat] identified by the provided [id].
  Future<void> muteChat(ChatId id, {Duration? duration}) async {
    muteStatus.value = RxStatus.loading();
    try {
      PreciseDateTime? dateTime;
      if (duration != null) {
        dateTime = PreciseDateTime.now().add(duration);
      }

      await _chatService.toggleChatMute(id, Muting(duration: dateTime));
    } on ToggleChatMuteException catch (e) {
      muteStatus.value = RxStatus.error(e.toMessage());
    } catch (e) {
      muteStatus.value = RxStatus.error(e.toString());
      rethrow;
    }
  }

  /// Returns an [User] from [UserService] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Sorts the [chats] by the [Chat.updatedAt] and [Chat.ongoingCall] values.
  void _sortChats() {
    chats.sort((a, b) {
      if (a.chat.value.ongoingCall != null &&
          b.chat.value.ongoingCall == null) {
        return -1;
      } else if (a.chat.value.ongoingCall == null &&
          b.chat.value.ongoingCall != null) {
        return 1;
      }

      return b.chat.value.updatedAt.compareTo(a.chat.value.updatedAt);
    });
  }
}

/// Container of data used to sort a [Chat].
class _ChatSortingData {
  /// Returns a [_ChatSortingData] capturing the provided [chat] changes to
  /// invoke a [sort] on [Chat.updatedAt] or [Chat.ongoingCall] updates.
  _ChatSortingData(Rx<Chat> chat, [void Function()? sort]) {
    updatedAt = chat.value.updatedAt;
    hasCall = chat.value.ongoingCall != null;

    worker = ever(
      chat,
      (Chat chat) {
        bool hasCall = chat.ongoingCall != null;
        if (chat.updatedAt != updatedAt || hasCall != hasCall) {
          sort?.call();
          updatedAt = chat.updatedAt;
          hasCall = hasCall;
        }
      },
    );
  }

  /// Worker capturing the [Chat] changes to invoke sorting on [updatedAt] and
  /// [hasCall] mismatches.
  late final Worker worker;

  /// Previously captured [Chat.updatedAt] value.
  late PreciseDateTime updatedAt;

  /// Previously captured indicator of [Chat.ongoingCall] being non-`null`.
  late bool hasCall;

  /// Disposes this [_ChatSortingData].
  void dispose() => worker.dispose();
}
