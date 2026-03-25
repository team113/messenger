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
import 'package:get/get.dart';

import '/config.dart';
import '/domain/model/link.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/link.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show UpdateDirectLinkException;
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

/// Possible [IntroductionViewStage] flow stage.
enum IntroductionViewStage { oneTime, signUp, link }

/// Controller of an [IntroductionView].
class IntroductionController extends GetxController {
  IntroductionController(
    this._myUserService,
    this._linkService, {
    IntroductionViewStage initial = IntroductionViewStage.oneTime,
  }) : stage = Rx(initial);

  /// [IntroductionViewStage] currently being displayed.
  final Rx<IntroductionViewStage> stage;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [TextFieldState] of the link to use in [createLink] method.
  late final TextFieldState link = TextFieldState(
    text: '$_origin${myUser.value?.num.val ?? DirectLinkSlug.generate(10).val}',
    editable: false,
  );

  /// [MyUser.name] field state.
  late final TextFieldState name = TextFieldState(
    text: myUser.value?.name?.val,
    onFocus: (s) async {
      s.error.value = null;

      if (s.text.trim().isNotEmpty) {
        try {
          UserName(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
          return;
        }
      }

      final UserName? name = UserName.tryParse(s.text);

      try {
        await _myUserService.updateUserName(name);
      } catch (_) {
        s.error.value = 'err_data_transfer'.l10n;
      }
    },
  );

  /// Origin to display withing the [link] field.
  late final String _origin = Config.link.substring(
    Config.link.indexOf(':') + 3,
  );

  /// [MyUserService] maintaining the [myUser].
  final MyUserService _myUserService;

  /// [LinkService] maintaining the [DirectLink]s.
  final LinkService _linkService;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Creates a [DirectLink] from the [link].
  Future<void> createLink() async {
    final String text = link.text.replaceFirst(_origin, '');

    if (!link.status.value.isEmpty) {
      return;
    }

    final UserId? meId = myUser.value?.id;
    if (meId == null) {
      return;
    }

    try {
      await _linkService.updateLink(DirectLinkSlug(text), meId);
    } on UpdateDirectLinkException catch (e) {
      link.error.value = e.toMessage();
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }
}
