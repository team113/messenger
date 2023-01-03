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

import 'package:get/get.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/provider/gql/exceptions.dart'
    show CreateChatDirectLinkException;
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/util/message_popup.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/service/my_user.dart';

class ChatsMoreController extends GetxController {
  ChatsMoreController(this._myUserService);

  final Rx<Presence?> presence = Rx(null);

  late final TextFieldState status;

  /// [MyUser.chatDirectLink]'s copyable state.
  late final TextFieldState link;

  final MyUserService _myUserService;

  Timer? _statusTimer;

  Worker? _worker;

  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Sets the [MyUser.presence] to the provided value.
  Future<void> setPresence(Presence presence) =>
      _myUserService.updateUserPresence(presence);

  @override
  void onInit() {
    presence.value = myUser.value?.presence;

    _worker = debounce(
      presence,
      (Presence? presence) {
        if (myUser.value?.presence != presence && presence != null) {
          setPresence(presence);
        }
      },
      time: 250.milliseconds,
    );

    status = TextFieldState(
      text: myUser.value?.status?.val,
      approvable: true,
      onChanged: (s) => s.error.value = null,
      onSubmitted: (s) async {
        try {
          if (s.text.isNotEmpty) {
            UserTextStatus(s.text);
          }
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (s.error.value == null) {
          _statusTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService.updateUserStatus(
              s.text.isNotEmpty ? UserTextStatus(s.text) : null,
            );
            s.status.value = RxStatus.success();
            _statusTimer = Timer(
              const Duration(milliseconds: 1500),
              () => s.status.value = RxStatus.empty(),
            );
          } catch (e) {
            s.error.value = e.toString();
            s.status.value = RxStatus.empty();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

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
            // await _myUserService.createChatDirectLink(slug!);
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

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }
}
