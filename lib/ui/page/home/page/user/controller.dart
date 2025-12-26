// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/api/backend/schema.dart' show UserPresence;
import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show
        ClearChatException,
        FavoriteChatContactException,
        HideChatException,
        JoinChatCallException,
        ToggleChatMuteException,
        UnblockUserException,
        UnfavoriteChatContactException,
        UnfavoriteChatException;
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

export 'view.dart';

/// Controller of the [Routes.user] page.
class UserController extends GetxController {
  UserController(
    this.id,
    this._userService,
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

  /// Status of the `ChatContact.avatar` upload or removal.
  final Rx<RxStatus> avatar = Rx<RxStatus>(RxStatus.empty());

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [ItemScrollController] of the profile's [ScrollablePositionedList].
  final ItemScrollController itemScrollController = ItemScrollController();

  /// [ItemPositionsListener] of the profile's [ScrollablePositionedList].
  final ItemPositionsListener positionsListener =
      ItemPositionsListener.create();

  /// [GlobalKey] of the more [ContextMenuRegion] button.
  final GlobalKey moreKey = GlobalKey();

  /// [TextFieldState] for blocking reason.
  final TextFieldState reason = TextFieldState(
    onFocus: (s) {
      s.error.value = null;

      if (s.text.trim().isNotEmpty) {
        try {
          BlocklistReason(s.text);
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      }
    },
  );

  /// [TextFieldState] for report reason.
  final TextFieldState reporting = TextFieldState();

  /// Status of a [block] progression.
  ///
  /// May be:
  /// - `status.isLoading`, meaning [block] is executing.
  /// - `status.isEmpty`, meaning no [block] is executing.
  final Rx<RxStatus> blocklistStatus = Rx(RxStatus.empty());

  /// Index of an item from the profile's [ScrollablePositionedList] that should
  /// be highlighted.
  final RxnInt highlighted = RxnInt();

  /// [UserService] fetching the [user].
  final UserService _userService;

  /// [ChatService] creating a [Chat] with this [user].
  final ChatService _chatService;

  /// [CallService] starting a new [OngoingCall] with this [user].
  final CallService _callService;

  /// [Worker] reacting on the [RxChatContact.contact] or [user] changes
  /// updating the [name].
  Worker? _worker;

  /// Subscription for the [user] changes.
  StreamSubscription? _userSubscription;

  /// [Sentry] transaction monitoring this [UserController] readiness.
  final ISentrySpan _ready = Sentry.startTransaction(
    'ui.user.ready',
    'ui',
    autoFinishAfter: const Duration(minutes: 2),
  )..startChild('ready');

  /// [Timer] resetting the [highlight] value after the [_highlightTimeout] has
  /// passed.
  Timer? _highlightTimer;

  /// [Duration] of the highlighting.
  static const Duration _highlightTimeout = Duration(seconds: 1);

  /// Indicates whether this [user] is blocked.
  BlocklistRecord? get isBlocked => user?.user.value.isBlocked;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  /// Indicates whether the contact's [chat] is a favorite.
  bool get isFavorite =>
      user?.dialog.value?.chat.value.favoritePosition != null;

  /// Indicates whether this [user] is a [Config.supportId].
  bool get isSupport => (user?.id ?? id).val == Config.supportId;

  @override
  void onInit() {
    _fetchUser();
    super.onInit();
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    _worker?.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Opens a [Chat]-dialog with this [user].
  void openChat() {
    if (user?.id == me) {
      router.chat(_chatService.monolog, mode: RouteAs.push);
    } else {
      router.chat(ChatId.local(user!.user.value.id), mode: RouteAs.push);
    }
  }

  /// Starts an [OngoingCall] in this [Chat] [withVideo] or without.
  Future<void> call(bool withVideo) async {
    try {
      await _callService.call(user!.user.value.dialog, withVideo: withVideo);
    } on JoinChatCallException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Joins an [OngoingCall] happening in the [RxUser.dialog].
  Future<void> joinCall() => _callService.join(user!.user.value.dialog);

  /// Drops the [OngoingCall] happening in the [RxUser.dialog].
  Future<void> dropCall() => _callService.leave(user!.user.value.dialog);

  /// Blocks the [user] for the authenticated [MyUser].
  Future<void> block() async {
    if (reason.error.value != null) {
      return;
    }

    blocklistStatus.value = RxStatus.loading();
    try {
      final String text = reason.text.trim();

      await _userService.blockUser(
        id,
        text.isEmpty ? null : BlocklistReason(text),
      );
      reason.clear();
    } on FormatException {
      reason.error.value = 'err_incorrect_input'.l10n;
    } catch (e) {
      MessagePopup.error('err_data_transfer'.l10n);
    } finally {
      blocklistStatus.value = RxStatus.empty();
    }
  }

  // TODO: Replace with GraphQL mutation when implemented.
  /// Reports the [user].
  Future<void> report() async {
    // TODO: Open support chat.
  }

  /// Removes the [user] from the blocklist of the authenticated [MyUser].
  Future<void> unblock() async {
    blocklistStatus.value = RxStatus.loading();
    try {
      await _userService.unblockUser(id);
    } on UnblockUserException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error('err_data_transfer'.l10n);
      rethrow;
    } finally {
      blocklistStatus.value = RxStatus.empty();
    }
  }

  /// Marks a [Chat]-dialog with the [user] as favorite.
  Future<void> favoriteChat() async {
    final ChatId? dialog = user?.user.value.dialog;
    try {
      if (dialog != null) {
        await _chatService.favoriteChat(dialog);
      }
    } on FavoriteChatContactException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error('err_data_transfer'.l10n);
      rethrow;
    }
  }

  /// Removes a [Chat]-dialog with the [user] from the favorites.
  Future<void> unfavoriteChat() async {
    final ChatId? dialog = user?.user.value.dialog;
    try {
      if (dialog != null) {
        await _chatService.unfavoriteChat(dialog);
      }
    } on UnfavoriteChatContactException catch (e) {
      MessagePopup.error(e.toMessage());
    } catch (e) {
      MessagePopup.error('err_data_transfer'.l10n);
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
        MessagePopup.error('err_data_transfer'.l10n);
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
        MessagePopup.error('err_data_transfer'.l10n);
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
        MessagePopup.error(e.toMessage());
      } catch (e) {
        MessagePopup.error('err_data_transfer'.l10n);
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
        MessagePopup.error('err_data_transfer'.l10n);
        rethrow;
      }
    }
  }

  /// Opens a file choose popup and updates the `ChatContact.avatar` with the
  /// selected image, if any.
  Future<void> pickAvatar() async {
    FilePickerResult? result = await PlatformUtils.pickFiles(
      type: FileType.image,
      withReadStream: !PlatformUtils.isWeb,
      withData: PlatformUtils.isWeb,
      lockParentWindow: true,
    );

    if (result != null) {
      updateAvatar(result.files.first);
    }
  }

  /// Resets the `ChatContact.avatar` to `null`.
  Future<void> deleteAvatar() => updateAvatar(null);

  /// Updates the `ChatContact.avatar` with the provided [image], or resets it
  /// to `null`.
  Future<void> updateAvatar(PlatformFile? image) async {
    avatar.value = RxStatus.loading();

    try {
      throw UnimplementedError();
    } on UnimplementedError catch (e) {
      avatar.value = RxStatus.empty();
      MessagePopup.error(e);
    } catch (e) {
      avatar.value = RxStatus.empty();
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Highlights the item with the provided [index].
  void highlight(int index) {
    highlighted.value = index;

    _highlightTimer?.cancel();
    _highlightTimer = Timer(_highlightTimeout, () {
      highlighted.value = null;
    });
  }

  /// Fetches the [user] value from the [_userService].
  Future<void> _fetchUser() async {
    try {
      final FutureOr<RxUser?> fetched = _userService.get(id);
      user = fetched is RxUser? ? fetched : await fetched;

      _userSubscription = user?.updates.listen((_) {});
      status.value = user == null ? RxStatus.empty() : RxStatus.success();

      SchedulerBinding.instance.addPostFrameCallback((_) => _ready.finish());
    } catch (e) {
      _ready.throwable = e;
      _ready.finish(status: const SpanStatus.internalError());

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
      case UserPresence.present:
        if (online) {
          return 'label_online'.l10n;
        } else if (lastSeenAt != null) {
          return (lastSeen ?? lastSeenAt)!.val.toDifferenceAgo();
        } else {
          return 'label_offline'.l10n;
        }

      case UserPresence.away:
        if (online) {
          return 'label_away'.l10n;
        } else if (lastSeenAt != null) {
          return (lastSeen ?? lastSeenAt)!.val.toDifferenceAgo();
        } else {
          return 'label_offline'.l10n;
        }

      case null:
        return 'label_hidden'.l10n;

      case UserPresence.artemisUnknown:
        return null;
    }
  }

  /// Returns the string representation of this [User] to display as a title.
  ///
  /// If [withDeletedLabel] is `true`, then returns the title with the deleted
  /// label for deleted users.
  String title({bool withDeletedLabel = true}) {
    if (isDeleted && withDeletedLabel) {
      return 'label_deleted_account'.l10n;
    }

    return contacts.firstOrNull?.name.val ?? name?.val ?? this.num.toString();
  }

  /// Returns the string representation of this [User] to display as a subtitle.
  String? getSubtitle([PreciseDateTime? lastSeen]) {
    switch (presence) {
      case UserPresence.present:
        if (online) {
          return 'label_online'.l10n;
        } else if (lastSeenAt != null) {
          return 'label_was_at'.l10nfmt({
            'at': (lastSeen ?? lastSeenAt)!.val.toDifferenceAgo().toLowerCase(),
          });
        } else {
          return 'label_offline'.l10n;
        }

      case UserPresence.away:
        if (online) {
          return 'label_away'.l10n;
        } else if (lastSeenAt != null) {
          return 'label_was_at'.l10nfmt({
            'at': (lastSeen ?? lastSeenAt)!.val.toDifferenceAgo().toLowerCase(),
          });
        } else {
          return 'label_offline'.l10n;
        }

      case null:
        return 'label_hidden'.l10n;

      case UserPresence.artemisUnknown:
        return null;
    }
  }
}

/// Extension adding [RxUser] related wrappers and helpers.
extension UserExt on RxUser {
  /// Returns the string representation of this [RxUser] to display as a title.
  ///
  /// If [withDeletedLabel] is `true`, then returns the title with the deleted
  /// label for deleted users.
  String title({bool withDeletedLabel = true}) =>
      contact.value?.contact.value.name.val ??
      user.value.title(withDeletedLabel: withDeletedLabel);
}

/// Extension adding an ability to get text represented indication of how long
/// ago a [DateTime] happened compared to [DateTime.now].
extension DateTimeToAgo on DateTime {
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
      'minutes': diff.inMinutes,
    });
  }
}
