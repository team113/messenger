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

import 'dart:typed_data';

import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/settings.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show UseChatDirectLinkException;
import '/routes.dart';
import '/ui/widget/text_field.dart';

/// Possible [LinkView] screens.
enum LinkScreen { link, input }

/// Controller of the [LinkView].
class LinkController extends GetxController {
  LinkController(
    this._myUserService,
    this._settingsRepo,
    this._authService, {
    this.pop,
  });

  /// Currently displayed [LinkScreen] of [LinkView] this controller is attached
  /// to.
  final Rx<LinkScreen> screen = Rx(LinkScreen.link);

  /// [TextFieldState] of a [ChatDirectLink] input.
  late final TextFieldState link =
      TextFieldState(onSubmitted: (_) => openLink());

  /// Callback, called when a [LinkView] this controller is bound to should be
  /// popped from the [Navigator].
  final void Function()? pop;

  /// Service responsible for [MyUser] management.
  final MyUserService _myUserService;

  /// Settings repository, used to update the [background].
  final AbstractSettingsRepository _settingsRepo;

  /// [AuthService] for opening the [ChatDirectLink].
  final AuthService _authService;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the current background's [Uint8List] value.
  Rx<Uint8List?> get background => _settingsRepo.background;

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug] and
  /// deletes the current active [ChatDirectLink] of the authenticated [MyUser]
  /// (if any).
  Future<void> createChatDirectLink(ChatDirectLinkSlug slug) async {
    await _myUserService.createChatDirectLink(slug);
  }

  /// Deletes the current [ChatDirectLink] of the authenticated [MyUser].
  Future<void> deleteChatDirectLink() async {
    await _myUserService.deleteChatDirectLink();
  }

  /// Opens the [link].
  Future<void> openLink() async {
    if (link.isEmpty.value) {
      return;
    }

    link.error.value = null;

    final trailing = link.text.substring(link.text.lastIndexOf('/') + 1);
    final slug = ChatDirectLinkSlug.tryParse(trailing);
    if (slug != null) {
      link.status.value = RxStatus.loading();

      try {
        final ChatId chatId = await _authService.useChatDirectLink(slug);
        pop?.call();
        router.chat(chatId);
      } on UseChatDirectLinkException catch (e) {
        link.error.value = e.toMessage();
      } catch (e) {
        link.error.value = 'err_data_transfer'.l10n;
        link.resubmitOnError.value = true;
        link.unsubmit();
        rethrow;
      } finally {
        link.status.value = RxStatus.empty();
      }
    }
  }
}
