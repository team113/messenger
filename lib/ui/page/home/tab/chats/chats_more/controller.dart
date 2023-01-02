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

import '/api/backend/schema.dart' show Presence;
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show CreateChatDirectLinkException, ToggleMyUserMuteException;
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

class ChatsMoreController extends GetxController {
  ChatsMoreController(this._myUserService);

  /// [MyUser.chatDirectLink]'s copyable state.
  late final TextFieldState link;

  final MyUserService _myUserService;

  final RxBool muted = RxBool(false);

  final RxBool togglingSwitch = RxBool(false);

  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Sets the [MyUser.presence] to the provided value.
  Future<void> setPresence(Presence presence) =>
      _myUserService.updateUserPresence(presence);

  @override
  void onInit() {
    muted.value = myUser.value?.muted == null ? false : true;

    link = TextFieldState(
      text: myUser.value?.chatDirectLink?.slug.val ??
          ChatDirectLinkSlug.generate(10).val,
      approvable: true,
      submitted: myUser.value?.chatDirectLink != null,
      onChanged: (s) {
        s.error.value = null;

        try {
          ChatDirectLinkSlug(s.text);
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
      onSubmitted: (s) async {
        ChatDirectLinkSlug? slug;
        try {
          slug = ChatDirectLinkSlug(s.text);
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (slug == myUser.value?.chatDirectLink?.slug) {
          return;
        }

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await _myUserService.createChatDirectLink(slug!);
            await Future.delayed(const Duration(seconds: 1));
            s.status.value = RxStatus.empty();
          } on CreateChatDirectLinkException catch (e) {
            s.status.value = RxStatus.empty();
            s.error.value = e.toMessage();
          } catch (e) {
            s.status.value = RxStatus.empty();
            MessagePopup.error(e);
            s.unsubmit();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    super.onInit();
  }

  void toggleMute(bool val) async {
    if (togglingSwitch.value) return;
    try {
      togglingSwitch.value = true;
      muted.value = !val;
      await _myUserService.toggleMute(
        val == true ? null : MuteDuration.forever(),
      );
    } on ToggleMyUserMuteException catch (e) {
      muted.value = val;
      MessagePopup.error(e);
    } catch (e) {
      muted.value = val;
      MessagePopup.error(e);
    } finally {
      togglingSwitch.value = false;
    }
  }
}
