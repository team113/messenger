// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/domain/service/blocklist.dart';
import '/domain/service/my_user.dart';
import '/domain/service/user.dart';
import '/util/obs/obs.dart';
import 'view.dart';

export 'view.dart';

/// Controller of a [BlocklistView].
class BlocklistController extends GetxController {
  BlocklistController(
    this._myUserService,
    this._userService,
    this._blocklistService, {
    this.pop,
  });

  /// Reactive list of sorted blocked [RxUser]s.
  final RxList<RxUser> blocklist = RxList();

  /// Callback, called when a [BlocklistView] this controller is bound to should
  /// be popped from the [Navigator].
  final void Function()? pop;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [MyUserService] used to getting [MyUser] value.
  final MyUserService _myUserService;

  /// [UserService] un-blocking the [User]s.
  final UserService _userService;

  /// [BlocklistService] maintaining the blocked [User]s.
  final BlocklistService _blocklistService;

  /// [StreamSubscription] to react on the [BlocklistService.blocklist] updates.
  late final StreamSubscription _blocklistSubscription;

  /// Indicator whether the [_scrollListener] is already invoked during the
  /// current frame.
  bool _scrollIsInvoked = false;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the [RxStatus] of the [blocklist] fetching and initialization.
  Rx<RxStatus> get status => _blocklistService.status;

  /// Indicates whether the [blocklist] have a next page.
  RxBool get hasNext => _blocklistService.hasNext;

  /// Total [BlocklistRecord]s count in the blocklist of the currently
  /// authenticated [MyUser].
  RxInt get blocklistCount => _blocklistService.count;

  @override
  void onInit() {
    scrollController.addListener(_scrollListener);

    blocklist.value = _blocklistService.blocklist.values.toList();
    _sort();

    _blocklistSubscription = _blocklistService.blocklist.items.changes.listen((
      e,
    ) {
      switch (e.op) {
        case OperationKind.added:
          blocklist.add(e.value!);
          _sort();
          break;

        case OperationKind.removed:
          blocklist.removeWhere((c) => c.id == e.key);
          _ensureScrollable();
          break;

        case OperationKind.updated:
          // No-op, as [blocklist] is never updated.
          break;
      }
    });

    super.onInit();
  }

  @override
  Future<void> onReady() async {
    await _blocklistService.around();

    _ensureScrollable();
    super.onReady();
  }

  @override
  void onClose() {
    _blocklistSubscription.cancel();
    scrollController.dispose();
    super.onClose();
  }

  /// Removes the [user] from the blocklist of the authenticated [MyUser].
  Future<void> unblock(RxUser user) async {
    if (blocklist.length == 1) {
      pop?.call();
    }

    await _userService.unblockUser(user.id);
  }

  /// Sorts the [blocklist] by the [User.isBlocked] value.
  void _sort() {
    blocklist.sort((a, b) {
      if (a.user.value.isBlocked == null || b.user.value.isBlocked == null) {
        return 0;
      }

      return b.user.value.isBlocked!.at.compareTo(a.user.value.isBlocked!.at);
    });
  }

  /// Requests the next page of [blocklist] based on the
  /// [ScrollController.position] value.
  void _scrollListener() {
    if (!_scrollIsInvoked) {
      _scrollIsInvoked = true;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollIsInvoked = false;

        if (scrollController.hasClients &&
            hasNext.isTrue &&
            _blocklistService.nextLoading.isFalse &&
            scrollController.position.pixels >
                scrollController.position.maxScrollExtent - 500 &&
            _blocklistService.blocklist.length >= _blocklistService.perPage) {
          _blocklistService.next();
        }
      });
    }
  }

  /// Ensures the [BlocklistView] is scrollable.
  Future<void> _ensureScrollable() async {
    if (isClosed) {
      return;
    }

    if (hasNext.isTrue) {
      await Future.delayed(1.milliseconds, () async {
        if (isClosed) {
          return;
        }

        if (!scrollController.hasClients) {
          return await _ensureScrollable();
        }

        // If the fetched initial page contains less elements than required to
        // fill the view and there's more pages available, then fetch those pages.
        if (scrollController.position.maxScrollExtent < 50 &&
            _blocklistService.nextLoading.isFalse &&
            _blocklistService.blocklist.length >= _blocklistService.perPage) {
          await _blocklistService.next();
          _ensureScrollable();
        }
      });
    }
  }
}
