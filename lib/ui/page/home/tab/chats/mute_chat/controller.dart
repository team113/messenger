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

import 'package:get/get.dart';

import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';

export 'view.dart';

/// Controller of the group creation overlay.
class MuteChatController extends GetxController {
  MuteChatController(this.id, this.pop, this._chatService);

  final ChatId id;

  /// Status of a [createGroup] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [createGroup] is executing.
  /// - `status.isLoading`, meaning [createGroup] is executing.
  /// - `status.isError`, meaning [createGroup] got an error.
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  final Rx<int?> selectedMute = Rx<int?>(null);

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
    MuteLabel('label_forever'.l10n),
  ];

  /// [Chat]s service used to create a group [Chat].
  final ChatService _chatService;

  /// Pops the [CreateGroupView] this controller is bound to.
  final Function() pop;

  /// Unselects the specified [user].
  Future<void> mute() async {
    if (selectedMute.value == null) return;
    status.value = RxStatus.loading();
    try {
      await _chatService.toggleChatMute(
        id,
        Muting(duration: muteDateTimes[selectedMute.value!].dateTime),
      );
      pop();
    } on ToggleChatMuteException catch (e) {
      status.value = RxStatus.error(e.toMessage());
    } catch (e) {
      status.value = RxStatus.error(e.toString());
      rethrow;
    }
  }
}

class MuteLabel {
  MuteLabel(this.label, {Duration? duration}) {
    if (duration != null) {
      dateTime = PreciseDateTime.now().add(duration);
    }
  }

  final String label;

  PreciseDateTime? dateTime;
}
