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

import 'package:get/get.dart';

import '/domain/model/link.dart';
import '/domain/model/my_user.dart';
import '/domain/repository/paginated.dart';
import '/domain/service/auth.dart';
import '/domain/service/link.dart';
import '/domain/service/my_user.dart';

/// Controller of the [LinkView].
class LinkController extends GetxController {
  LinkController(this._myUserService, this._linkService, this._authService);

  /// [Paginated] containing the [DirectLink] leading to this [MyUser].
  late final Paginated<DirectLinkSlug, DirectLink> links;

  /// Service responsible for [MyUser] management.
  final MyUserService _myUserService;

  /// [AuthService] used to retrieve the [UserId] of the currently authenticated
  /// [MyUser].
  final AuthService _authService;

  /// [LinkService] maintaining the [DirectLink]s.
  final LinkService _linkService;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Indicates whether currently authenticated [MyUser] is a support.
  bool get isSupport => _authService.userId?.isSupport == true;

  @override
  void onInit() {
    links = _linkService.links(userId: _authService.userId);
    links.ensureInitialized();

    super.onInit();
  }

  /// Creates a new [DirectLink] with the specified [DirectLinkSlug] and deletes
  /// the current active [DirectLink] of the authenticated [MyUser] (if any).
  Future<void> linkLink(DirectLinkSlug slug) async {
    await _linkService.updateLink(slug, _authService.userId);
  }

  /// Deletes the provided [DirectLinkSlug] from the authenticated [MyUser].
  Future<void> unlinkLink(DirectLinkSlug slug) async {
    await _linkService.updateLink(slug, null);
  }
}
