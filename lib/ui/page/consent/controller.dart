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

import 'package:get/get.dart';

import '/provider/hive/consent.dart';

/// Controller of a [ConsentView].
class ConsentController extends GetxController {
  ConsentController(this._consentProvider, this.callback);

  /// Status of the [proceed] completing the [callback].
  final Rx<RxStatus> status = Rx(RxStatus.empty());

  /// Function to call after acquiring the user's consent.
  final Future<void> Function(bool) callback;

  /// [ConsentHiveProvider] providing and storing the consent itself.
  final ConsentHiveProvider _consentProvider;

  /// Stores the [consent] and invokes the [callback].
  Future<void> proceed(bool consent) async {
    status.value = RxStatus.loading();

    await _consentProvider.set(consent);
    await callback(consent);

    status.value = RxStatus.success();
  }
}
