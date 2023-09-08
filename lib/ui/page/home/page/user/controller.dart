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

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart' show CallDoesNotExistException;
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show
        FavoriteChatContactException,
        HideChatException,
        ToggleChatMuteException,
        UnfavoriteChatContactException,
        ClearChatException;
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

  /// Temporary indicator whether the [user] is favorite.
  late final RxBool inFavorites;

  /// Indicator whether this [user] is already in the contacts list of the
  /// authenticated [MyUser].
  late final RxBool inContacts;

  /// [TextFieldState] for blacklisting reason.
  final TextFieldState reason = TextFieldState();

  /// Status of a [blacklist] progression.
  ///
  /// May be:
  /// - `status.isLoading`, meaning [blacklist] is executing.
  /// - `status.isEmpty`, meaning no [blacklist] is executing.
  final Rx<RxStatus> blacklistStatus = Rx(RxStatus.empty());

  /// [UserService] fetching the [user].
  final UserService _userService;

  /// [ContactService] maintaining [ChatContact]s of this [user].
  final ContactService _contactService;

  /// [ChatService] creating a [Chat] with this [user].
  final ChatService _chatService;

  /// [CallService] starting a new [OngoingCall] with this [user].
  final CallService _callService;

  /// [StreamSubscription] to [ContactService.contacts] determining the
  /// [inContacts] indicator.
  StreamSubscription? _contactsSubscription;

  /// [StreamSubscription] to [ContactService.favorites] determining the
  /// [inContacts] indicator.
  StreamSubscription? _favoritesSubscription;

  /// Indicates whether this [user] is blacklisted.
  BlocklistRecord? get isBlocked => user?.user.value.isBlocked;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  @override
  void onInit() {
    _fetchUser();

    inContacts = RxBool(
      _contactService.contacts.values
              .any((e) => e.contact.value.users.every((m) => m.id == id)) ||
          _contactService.favorites.values
              .any((e) => e.contact.value.users.every((m) => m.id == id)),
    );

    inFavorites = RxBool(
      _contactService.favorites.values
          .any((e) => e.contact.value.users.every((m) => m.id == id)),
    );

    _contactsSubscription = _contactService.contacts.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
        case OperationKind.updated:
          if (e.value!.contact.value.users.isNotEmpty &&
              e.value!.contact.value.users.every((e) => e.id == id)) {
            inContacts.value = true;
          }
          break;

        case OperationKind.removed:
          if (e.value?.contact.value.users.every((e) => e.id == id) == true) {
            inContacts.value = false;
          }
          break;
      }
    });

    _favoritesSubscription = _contactService.favorites.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          if (e.value?.contact.value.users.every((e) => e.id == id) == true) {
            inFavorites.value = true;
            inContacts.value = true;
          }
          break;

        case OperationKind.removed:
          if (e.value?.contact.value.users.every((e) => e.id == id) == true) {
            inFavorites.value = false;
          }
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
    user?.stopUpdates();
    _contactsSubscription?.cancel();
    _favoritesSubscription?.cancel();
    super.onClose();
  }

  /// Adds the [user] to the contacts list of the authenticated [MyUser].
  Future<void> addToContacts() async {
    if (!inContacts.value) {
      status.value = RxStatus.loadingMore();
      try {
        await _contactService.createChatContact(user!.user.value);
        inContacts.value = true;
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
    if (inContacts.value) {
      status.value = RxStatus.loadingMore();
      try {
        final RxChatContact? contact =
            _contactService.contacts.values.firstWhereOrNull(
                  (e) => e.contact.value.users.every((m) => m.id == user?.id),
                ) ??
                _contactService.favorites.values.firstWhereOrNull(
                  (e) => e.contact.value.users.every((m) => m.id == user?.id),
                );
        if (contact != null) {
          await _contactService.deleteContact(contact.contact.value.id);
        }
        inContacts.value = false;
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
    } on CallDoesNotExistException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Blacklists the [user] for the authenticated [MyUser].
  Future<void> blacklist() async {
    blacklistStatus.value = RxStatus.loading();
    try {
      await _userService.blockUser(
        id,
        reason.text.isEmpty ? null : BlocklistReason(reason.text),
      );
      reason.clear();
    } finally {
      blacklistStatus.value = RxStatus.empty();
    }
  }

  /// Removes the [user] from the blacklist of the authenticated [MyUser].
  Future<void> unblacklist() async {
    blacklistStatus.value = RxStatus.loading();
    try {
      await _userService.unblockUser(id);
    } finally {
      blacklistStatus.value = RxStatus.empty();
    }
  }

  /// Marks the [user] as favorited.
  Future<void> favoriteContact() async {
    try {
      RxChatContact? contact = _contactService.contacts.values.firstWhereOrNull(
        (e) => e.contact.value.users.every((m) => m.id == user?.id),
      );
      if (contact != null) {
        await _contactService.favoriteChatContact(contact.id);
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
      RxChatContact? contact =
          _contactService.favorites.values.firstWhereOrNull(
        (e) => e.contact.value.users.every((m) => m.id == user?.id),
      );
      if (contact != null) {
        await _contactService.unfavoriteChatContact(contact.id);
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
      user = await _userService.get(id);
      user?.listenUpdates();
      status.value = user == null ? RxStatus.empty() : RxStatus.success();
    } catch (e) {
      await MessagePopup.error(e);
      router.pop();
      rethrow;
    }
  }
}

/// Extension adding [UserView] related wrappers and helpers.
extension UserViewExt on User {
  /// Returns a text represented status of this [User] based on its
  /// [User.presence] and [User.online] fields.
  String? getStatus() {
    switch (presence) {
      case Presence.present:
        if (online) {
          return 'label_online'.l10n;
        } else if (lastSeenAt != null) {
          return '${'label_last_seen'.l10n} ${lastSeenAt!.val.toDifferenceAgo()}';
        } else {
          return 'label_offline'.l10n;
        }

      case Presence.away:
        if (online) {
          return 'label_away'.l10n;
        } else if (lastSeenAt != null) {
          return '${'label_last_seen'.l10n} ${lastSeenAt!.val.toDifferenceAgo()}';
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
