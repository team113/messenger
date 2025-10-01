// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller of the `HomeTab.partner` tab.
class PartnerTabController extends GetxController {
  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// Balance of the current [MyUser] available for withdrawal.
  final RxDouble balance = RxDouble(0);

  /// Balance of the current [MyUser] not currently available for withdrawal (in
  /// hold).
  final RxDouble hold = RxDouble(0);

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
