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

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart'
    show
        CallAlreadyExistsException,
        CallAlreadyJoinedException,
        CallIsInPopupException;
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show
        ClearChatException,
        FavoriteChatContactException,
        HideChatException,
        JoinChatCallException,
        ToggleChatMuteException,
        UnfavoriteChatContactException,
        UnfavoriteChatException,
        UpdateChatContactNameException;
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of the [Routes.user] page.
class UserController extends GetxController {
  UserController(
    this.id,
    this._userService,
    this._contactService,
    this._chatService,
    this._callService,
  );

  /// ID of the [User] this [UserController] represents.
  final UserId id;

  /// Reactive [User] itself.
  RxUser? user;

  /// Reactive [ChatContact] linked to the [user].
  Rx<RxChatContact?> contact = Rx<RxChatContact?>(null);

  /// Status of the [user] fetching.
  ///
  /// May be:
  /// - `status.isLoading`, meaning [user] is being fetched from the service.
  /// - `status.isEmpty`, meaning [user] with specified [id] was not found.
  /// - `status.isSuccess`, meaning [user] is successfully fetched.
  /// - `status.isLoadingMore`, meaning a request is being made.
  Rx<RxStatus> status = Rx<RxStatus>(RxStatus.loading());

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [GlobalKey] of the more [ContextMenuRegion] button.
  final GlobalKey moreKey = GlobalKey();

  /// [TextFieldState] for blocking reason.
  final TextFieldState reason = TextFieldState();

  /// [TextFieldState] for [ChatContact] name editing.
  late final TextFieldState name;

  /// Indicator whether the editing mode is enabled.
  final RxBool editing = RxBool(false);

  /// Status of a [block] progression.
  ///
  /// May be:
  /// - `status.isLoading`, meaning [block] is executing.
  /// - `status.isEmpty`, meaning no [block] is executing.
  final Rx<RxStatus> blocklistStatus = Rx(RxStatus.empty());

  /// [UserService] fetching the [user].
  final UserService _userService;

  /// [ContactService] maintaining [ChatContact]s of this [user].
  final ContactService _contactService;

  /// [ChatService] creating a [Chat] with this [user].
  final ChatService _chatService;

  /// [CallService] starting a new [OngoingCall] with this [user].
  final CallService _callService;

  /// [StreamSubscription] to [ContactService.contacts] determining the
  /// [inContacts] and [inFavorites] indicators.
  StreamSubscription? _contactsSubscription;

  /// [Worker] reacting on the [contact] or [user] changes updating the [name].
  Worker? _worker;

  /// Indicates whether this [user] is blocked.
  BlocklistRecord? get isBlocked => user?.user.value.isBlocked;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  @override
  void onInit() {
    name = TextFieldState(
      approvable: true,
      onChanged: (s) {
        if (s.text.isNotEmpty) {
          try {
            UserName(s.text);
          } catch (e) {
            s.error.value = e.toString();
          }
        }
      },
      onSubmitted: (s) async {
        s.error.value = null;
        s.focus.unfocus();

        if (s.text == contact.value!.contact.value.name.val) {
          s.unsubmit();
          return;
        }

        UserName? name;
        try {
          name = UserName(s.text);
        } on FormatException catch (_) {
          s.status.value = RxStatus.empty();
          s.error.value = 'err_incorrect_input'.l10n;
          s.unsubmit();
          return;
        }

        if (s.error.value == null) {
          s.status.value = RxStatus.loading();
          s.editable.value = false;

          try {
            await _contactService.changeContactName(contact.value!.id, name);
            s.status.value = RxStatus.empty();
            s.unsubmit();
          } on UpdateChatContactNameException catch (e) {
            s.status.value = RxStatus.empty();
            s.error.value = e.toString();
          } catch (e) {
            s.status.value = RxStatus.empty();
            MessagePopup.error(e.toString());
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    _fetchUser();

    // TODO: Refactor determination to be a [RxBool] in [RxUser] field.
    contact.value = _contactService.contacts.values.firstWhereOrNull(
      (e) => e.contact.value.users.every((m) => m.id == id),
    );

    _updateWorker();

    _contactsSubscription = _contactService.contacts.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
        case OperationKind.updated:
          if (e.value!.contact.value.users.isNotEmpty &&
              e.value!.contact.value.users.every((e) => e.id == id)) {
            contact.value = e.value;
            _updateWorker();
          }
          break;

        case OperationKind.removed:
          if (e.value?.contact.value.users.every((e) => e.id == id) == true) {
            contact.value = null;
            editing.value = false;
            _updateWorker();
          }
          break;
      }
    });

    super.onInit();
  }

  @override
  void onClose() {
    user?.stopUpdates();
    _contactsSubscription?.cancel();
    _worker?.dispose();
    super.onClose();
  }

  /// Adds the [user] to the contacts list of the authenticated [MyUser].
  Future<void> addToContacts() async {
    if (contact.value == null) {
      status.value = RxStatus.loadingMore();
      try {
        await _contactService.createChatContact(user!.user.value);
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      } finally {
        status.value = RxStatus.success();
      }
    }
  }

  /// Removes the [user] from the contacts list of the authenticated [MyUser].
  Future<void> removeFromContacts() async {
    if (contact.value != null) {
      status.value = RxStatus.loadingMore();
      try {
        if (contact.value != null) {
          await _contactService.deleteContact(contact.value!.contact.value.id);
          contact.value = null;
          _updateWorker();
        }
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      } finally {
        status.value = RxStatus.success();
      }
    }
  }

  /// Opens a [Chat]-dialog with this [user].
  void openChat() {
    if (user?.id == me) {
      router.chat(_chatService.monolog, push: true);
    } else {
      router.chat(user!.user.value.dialog, push: true);
    }
  }

  /// Starts an [OngoingCall] in this [Chat] [withVideo] or without.
  Future<void> call(bool withVideo) async {
    try {
      await _callService.call(user!.user.value.dialog, withVideo: withVideo);
    } on JoinChatCallException catch (e) {
      MessagePopup.error(e);
    } on CallAlreadyJoinedException catch (e) {
      MessagePopup.error(e);
    } on CallAlreadyExistsException catch (e) {
      MessagePopup.error(e);
    } on CallIsInPopupException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Joins an [OngoingCall] happening in the [RxUser.dialog].
  Future<void> joinCall() => _callService.join(user!.user.value.dialog);

  /// Drops the [OngoingCall] happening in the [RxUser.dialog].
  Future<void> dropCall() => _callService.leave(user!.user.value.dialog);

  /// Blocks the [user] for the authenticated [MyUser].
  Future<void> block() async {
    blocklistStatus.value = RxStatus.loading();
    try {
      await _userService.blockUser(
        id,
        reason.text.isEmpty ? null : BlocklistReason(reason.text),
      );
      reason.clear();
    } finally {
      blocklistStatus.value = RxStatus.empty();
    }
  }

  /// Removes the [user] from the blocklist of the authenticated [MyUser].
  Future<void> unblock() async {
    blocklistStatus.value = RxStatus.loading();
    try {
      await _userService.unblockUser(id);
    } finally {
      blocklistStatus.value = RxStatus.empty();
    }
  }

  /// Marks the [user] as favorited.
  Future<void> favoriteContact() async {
    try {
      if (contact.value != null) {
        await _contactService.favoriteChatContact(contact.value!.id);
      }
    } on FavoriteChatContactException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Removes the [user] from the favorites.
  Future<void> unfavoriteContact() async {
    try {
      if (contact.value != null) {
        await _contactService.unfavoriteChatContact(contact.value!.id);
      }
    } on UnfavoriteChatContactException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Mutes a [Chat]-dialog with the [user].
  Future<void> muteChat() async {
    final ChatId? dialog = user?.user.value.dialog;

    if (dialog != null) {
      try {
        await _chatService.toggleChatMute(dialog, MuteDuration.forever());
      } on ToggleChatMuteException catch (e) {
        MessagePopup.error(e);
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      }
    }
  }

  /// Unmutes a [Chat]-dialog with the [user].
  Future<void> unmuteChat() async {
    final ChatId? dialog = user?.user.value.dialog;

    if (dialog != null) {
      try {
        await _chatService.toggleChatMute(dialog, null);
      } on ToggleChatMuteException catch (e) {
        MessagePopup.error(e);
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      }
    }
  }

  /// Hides a [Chat]-dialog with the [user].
  Future<void> hideChat() async {
    final ChatId? dialog = user?.user.value.dialog;

    if (dialog != null) {
      try {
        await _chatService.hideChat(dialog);
      } on HideChatException catch (e) {
        MessagePopup.error(e);
      } on UnfavoriteChatException catch (e) {
        MessagePopup.error(e);
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      }
    }
  }

  /// Clears a [Chat]-dialog history with the [user].
  Future<void> clearChat() async {
    final ChatId? dialog = user?.user.value.dialog;

    if (dialog != null) {
      try {
        await _chatService.clearChat(dialog);
      } on ClearChatException catch (e) {
        MessagePopup.error(e);
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      }
    }
  }

  /// Fetches the [user] value from the [_userService].
  Future<void> _fetchUser() async {
    try {
      final FutureOr<RxUser?> fetched = _userService.get(id);
      user = fetched is RxUser? ? fetched : await fetched;

      _updateWorker();

      user?.listenUpdates();
      status.value = user == null ? RxStatus.empty() : RxStatus.success();
    } catch (e) {
      await MessagePopup.error(e);
      router.pop();
      rethrow;
    }
  }

  /// Listens to the [contact] or [user] changes updating the [name].
  void _updateWorker() {
    if (contact.value != null) {
      name.unchecked = contact.value!.contact.value.name.val;

      _worker?.dispose();
      _worker = ever(contact.value!.contact, (contact) {
        if (!name.isFocused.value && !name.changed.value) {
          name.unchecked = contact.name.val;
        }
      });
    } else if (user != null) {
      name.unchecked =
          user!.user.value.name?.val ?? user!.user.value.num.toString();

      _worker?.dispose();
      _worker = ever(user!.user, (user) {
        if (!name.isFocused.value && !name.changed.value) {
          name.unchecked = user.name?.val ?? user.num.toString();
        }
      });
    }
  }
}

/// Extension adding [UserView] related wrappers and helpers.
extension UserViewExt on User {
  /// Returns a text represented status of this [User] based on its
  /// [User.presence] and [User.online] fields.
  String? getStatus([PreciseDateTime? lastSeen]) {
    switch (presence) {
      case Presence.present:
        if (online) {
          return 'label_online'.l10n;
        } else if (lastSeenAt != null) {
          return (lastSeen ?? lastSeenAt)!.val.toDifferenceAgo();
        } else {
          return 'label_offline'.l10n;
        }

      case Presence.away:
        if (online) {
          return 'label_away'.l10n;
        } else if (lastSeenAt != null) {
          return (lastSeen ?? lastSeenAt)!.val.toDifferenceAgo();
        } else {
          return 'label_offline'.l10n;
        }

      case null:
        return 'label_hidden'.l10n;

      case Presence.artemisUnknown:
        return null;
    }
  }
}

/// Extension adding an ability to get text represented indication of how long
/// ago a [DateTime] happened compared to [DateTime.now].
extension _DateTimeToAgo on DateTime {
  /// Returns text representation of a [difference] with [DateTime.now]
  /// indicating how long ago this [DateTime] happened compared to
  /// [DateTime.now].
  String toDifferenceAgo() {
    DateTime local = isUtc ? toLocal() : this;
    Duration diff = DateTime.now().difference(local);

    return 'label_ago'.l10nfmt({
      'years': diff.inDays ~/ 365,
      'months': diff.inDays ~/ 30,
      'weeks': diff.inDays ~/ 7,
      'days': diff.inDays,
      'hours': diff.inHours,
      'minutes': diff.inMinutes
    });
  }
}
