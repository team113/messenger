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

import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/provider/gql/exceptions.dart' show UseChatDirectLinkException;
import '/routes.dart';
import '/util/message_popup.dart';

/// Controller of the [WorkTab.frontend] section of [Routes.work] page.
class FrontendWorkController extends GetxController {
  FrontendWorkController(this._authService);

  /// [RxStatus] of the [useLink] being invoked.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning [useLink] isn't in progress.
  /// - `status.isLoading`, meaning [useLink] is fetching its data.
  final Rx<RxStatus> linkStatus = Rx(RxStatus.empty());

  /// [AuthService] for using the [_link].
  final AuthService _authService;

  /// [ChatDirectLinkSlug] to use in the [useLink].
  static const ChatDirectLinkSlug _link = ChatDirectLinkSlug.unchecked(
    'HR-Gapopa',
  );

  /// Returns the authorization [RxStatus].
  Rx<RxStatus> get status => _authService.status;

  /// Uses the [ChatDirectLinkSlug].
  Future<void> useLink({bool? signedUp}) async {
    linkStatus.value = RxStatus.loading();

    try {
      if (status.value.isEmpty) {
        router.home(signedUp: signedUp);
      }

      router.dialog(
        await _authService.useChatDirectLink(_link),
        _authService.userId,
      );

      linkStatus.value = RxStatus.empty();
    } on UseChatDirectLinkException catch (e) {
      linkStatus.value = RxStatus.empty();
      MessagePopup.error(e.toMessage());
    } catch (e) {
      linkStatus.value = RxStatus.empty();
      MessagePopup.error(e);
      rethrow;
    }
  }
}
