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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of a [MuteChatView].
class MuteChatController extends GetxController {
  MuteChatController(this.id, this.pop, this._chatService);

  /// [ChatId] of muting [Chat].
  final ChatId id;

  /// Status of a [mute] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [mute] is executing.
  /// - `status.isLoading`, meaning [mute] is executing.
  /// - `status.isError`, meaning [mute] got an error.
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  /// Selected mute period.
  final Rx<int?> selectedMute = Rx<int?>(null);

  /// List of the mute periods.
  final List<MuteLabel> muteDateTimes = [
    MuteLabel(
      'label_multiple_minutes'.l10nfmt({'quantity': 15}),
      duration: const Duration(minutes: 15),
    ),
    MuteLabel(
      'label_multiple_minutes'.l10nfmt({'quantity': 30}),
      duration: const Duration(minutes: 30),
    ),
    MuteLabel(
      'label_multiple_hours'.l10nfmt({'quantity': 1}),
      duration: const Duration(hours: 1),
    ),
    MuteLabel(
      'label_multiple_hours'.l10nfmt({'quantity': 6}),
      duration: const Duration(hours: 6),
    ),
    MuteLabel(
      'label_multiple_hours'.l10nfmt({'quantity': 12}),
      duration: const Duration(hours: 12),
    ),
    MuteLabel(
      'label_multiple_days'.l10nfmt({'quantity': 1}),
      duration: const Duration(days: 1),
    ),
    MuteLabel(
      'label_multiple_days'.l10nfmt({'quantity': 7}),
      duration: const Duration(days: 7),
    ),
    MuteLabel(
      'label_forever'.l10n,
      key: const Key('MuteForever'),
    ),
  ];

  /// [Chat]s service used to mute [Chat].
  final ChatService _chatService;

  /// Pops the [MuteChatView] this controller is bound to.
  final Function() pop;

  /// Subscription for the [ChatService.chats] changes.
  late final StreamSubscription _chatsSubscription;

  @override
  void onInit() {
    _chatsSubscription = _chatService.chats.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          // No-op.
          break;

        case OperationKind.removed:
          if (e.key == id) {
            pop();
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
    _chatsSubscription.cancel();
    super.onClose();
  }

  /// Mute [Chat] for selected period.
  Future<void> mute() async {
    status.value = RxStatus.loading();
    try {
      PreciseDateTime? dateTime;
      Duration? duration = muteDateTimes[selectedMute.value!].duration;
      if (duration != null) {
        dateTime = PreciseDateTime.now().add(duration);
      }

      await _chatService.toggleChatMute(id, Muting(duration: dateTime));
      pop();
    } on ToggleChatMuteException catch (e) {
      status.value = RxStatus.error(e.toMessage());
    } catch (e) {
      status.value = RxStatus.error(e.toString());
      rethrow;
    }
  }
}

/// Mute duration and its label wrapper.
class MuteLabel {
  MuteLabel(this.label, {this.duration, this.key});

  /// Unique key of [MuteLabel] class.
  final Key? key;

  /// Label of mute period.
  final String label;

  /// Muting [Duration].
  final Duration? duration;
}
