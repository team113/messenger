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
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
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
        ClearChatException,
        FavoriteChatContactException,
        HideChatException,
        ToggleChatMuteException,
        UnfavoriteChatContactException,
        UnfavoriteChatException;
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
    this._myUserService,
    this._contactService,
    this._chatService,
    this._callService,
    this._settingsRepo, {
    this.scrollToPaid = false,
  });

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

  /// [ItemScrollController] of the profile's [ScrollablePositionedList].
  final ItemScrollController itemScrollController = ItemScrollController();

  /// [ItemPositionsListener] of the profile's [ScrollablePositionedList].
  final ItemPositionsListener positionsListener =
      ItemPositionsListener.create();

  final bool scrollToPaid;

  /// Temporary indicator whether the [user] is favorite.
  late final RxBool inFavorites;

  /// Indicator whether this [user] is already in the contacts list of the
  /// authenticated [MyUser].
  late final RxBool inContacts;

  /// [TextFieldState] for blacklisting reason.
  final TextFieldState reason = TextFieldState();

  final GlobalKey moreKey = GlobalKey();

  /// Status of a [blacklist] progression.
  ///
  /// May be:
  /// - `status.isLoading`, meaning [blacklist] is executing.
  /// - `status.isEmpty`, meaning no [blacklist] is executing.
  final Rx<RxStatus> blacklistStatus = Rx(RxStatus.empty());

  final RxBool displayName = RxBool(false);

  late final TextFieldState messageCost;
  late final TextFieldState callsCost;

  final RxBool verified = RxBool(false);
  // final RxBool verified = RxBool(true);
  final RxBool hintVerified = RxBool(false);

  final RxBool editing = RxBool(false);
  final TextFieldState name = TextFieldState(
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
    onSubmitted: (s) {
      // TODO
    },
  );

  /// [GlobalKey] of an [AvatarWidget] displayed used to open a [GalleryPopup].
  final GlobalKey avatarKey = GlobalKey();

  /// [UserService] fetching the [user].
  final UserService _userService;

  final MyUserService _myUserService;

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

  /// Settings repository, used to update the [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// Worker to react on [myUser] changes.
  Worker? _myUserWorker;

  Worker? _worker;

  /// Indicates whether this [user] is blacklisted.
  BlocklistRecord? get isBlocked => user?.user.value.isBlocked;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the current background's [Uint8List] value.
  Rx<Uint8List?> get background => _settingsRepo.background;

  void _scrollListener() {
    displayName.value = scrollController.position.pixels >= 365;
  }

  @override
  void onInit() {
    _fetchUser();

    // TODO: Refactor determination to be a [RxBool] in [RxUser] field.
    final RxChatContact? contact =
        _contactService.paginated.values.firstWhereOrNull(
      (e) => e.contact.value.users.every((m) => m.id == id),
    );

    inContacts = RxBool(contact != null);
    inFavorites = RxBool(contact?.contact.value.favoritePosition != null);

    _contactsSubscription = _contactService.paginated.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
        case OperationKind.updated:
          if (e.value!.contact.value.users.isNotEmpty &&
              e.value!.contact.value.users.every((e) => e.id == id)) {
            inContacts.value = true;

            if (e.value!.contact.value.favoritePosition != null) {
              inFavorites.value = true;
            } else {
              inFavorites.value = false;
            }
          }
          break;

        case OperationKind.removed:
          if (e.value?.contact.value.users.every((e) => e.id == id) == true) {
            inContacts.value = false;
          }
          break;
      }
    });

    if (scrollToPaid) {
      initialScrollIndex = isBlocked == null ? 2 : 3;
    } else {
      initialScrollIndex = 0;
    }

    verified.value = true;
    // verified.value =
    //     _myUserService.myUser.value?.emails.confirmed.isNotEmpty == true;

    _myUserWorker = ever(
      _myUserService.myUser,
      (MyUser? v) {
        verified.value = v?.emails.confirmed.isNotEmpty == true;
      },
    );

    scrollController.addListener(_scrollListener);

    super.onInit();
  }

  late final int initialScrollIndex;

  @override
  void onClose() {
    _myUserWorker?.dispose();
    user?.stopUpdates();
    _contactsSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _worker?.dispose();
    scrollController.removeListener(_scrollListener);
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
            _contactService.paginated.values.firstWhereOrNull(
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
      final RxChatContact? contact =
          _contactService.paginated.values.firstWhereOrNull(
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
      final RxChatContact? contact =
          _contactService.paginated.values.firstWhereOrNull(
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

  Future<void> report() async {
    const userId = UserId('18ff6b4f-1a81-47f9-a8ed-bf69a51bdae6');
    final user = await _userService.get(userId);
    router.chat(user?.user.value.dialog ?? ChatId.local(userId), push: true);
  }

  /// Fetches the [user] value from the [_userService].
  Future<void> _fetchUser() async {
    try {
      user = await _userService.get(id);
      user?.listenUpdates();

      if (user != null) {
        messageCost = TextFieldState(
          approvable: true,
          allowable: true,
          // text: user!.user.value.messageCost == 0
          //     ? '0.00'
          //     : '${user!.user.value.messageCost.toString()}.00',
          text: user!.user.value.messageCost.toString(),
          onChanged: (s) {
            user?.user.value.messageCost = int.tryParse(s.text) ?? 0;
            user?.dialog.value?.chat.refresh();
          },
          onSubmitted: (s) {
            // if (!s.text.contains('.')) {
            //   s.unchecked = '${s.text}.00';
            // }
          },
        );

        messageCost.isFocused.listen((b) {
          if (!b && messageCost.text.isEmpty) {
            messageCost.unchecked = '0';
          }
        });

        // messageCost.isFocused.listen((b) {
        //   if (b) {
        //     if (messageCost.hasAllowance.value) {
        //       messageCost.unchecked = messageCost.text.replaceAll('.00', '');
        //     }
        //   } else if (messageCost.text.isNotEmpty) {
        //     print('messageCost.text.isNotEmpty: `${messageCost.text}`');

        //     if (!messageCost.text.contains('.')) {
        //       messageCost.unchecked = '${messageCost.text}.00';
        //     } else if (messageCost.text.startsWith('.')) {
        //       messageCost.unchecked = '0${messageCost.text}';
        //     }

        //     int signs = messageCost.text.indexOf('.');
        //     if (signs != -1) {
        //       messageCost.unchecked = messageCost.text.substring(
        //         0,
        //         signs + max(2, messageCost.text.length - signs),
        //       );
        //     }
        //   } else {
        //     messageCost.unchecked = '0.00';
        //   }
        // });

        callsCost = TextFieldState(
          approvable: true,
          allowable: true,
          text: user!.user.value.callCost.toString(),
          // text: user!.user.value.callCost == 0
          //     ? '0.00'
          //     : '${user!.user.value.callCost.toString()}.00',
          onChanged: (s) {
            user?.user.value.callCost = int.tryParse(s.text) ?? 0;
            user?.dialog.value?.chat.refresh();
          },
          onSubmitted: (s) {
            // if (!s.text.contains('.')) {
            //   s.unchecked = '${s.text}.00';
            // }
          },
        );

        callsCost.isFocused.listen((b) {
          if (!b && callsCost.text.isEmpty) {
            callsCost.unchecked = '0';
          }
        });

        // callsCost.isFocused.listen((b) {
        //   if (b) {
        //     if (callsCost.hasAllowance.value) {
        //       callsCost.unchecked = callsCost.text.replaceAll('.00', '');
        //     }
        //   } else if (callsCost.text.isNotEmpty) {
        //     if (!callsCost.text.contains('.')) {
        //       callsCost.unchecked = '${callsCost.text}.00';
        //     }
        //   } else {
        //     callsCost.text = '0.00';
        //   }
        // });

        name.unchecked =
            user?.user.value.name?.val ?? user!.user.value.num.toString();

        _worker = ever(user!.user, (user) {
          if (!name.isFocused.value && !name.changed.value) {
            name.unchecked = user.name?.val ?? user.num.toString();
          }
        });
      }

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

  /// Returns a text represented status of this [User] based on its
  /// [User.presence] and [User.online] fields.
  String? getStatus2([PreciseDateTime? lastSeen]) {
    switch (presence) {
      case Presence.present:
        if (online) {
          return 'label_online'.l10n;
        } else if (lastSeenAt != null) {
          return 'Был ' +
              (lastSeen ?? lastSeenAt)!.val.toDifferenceAgo().toLowerCase();
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
