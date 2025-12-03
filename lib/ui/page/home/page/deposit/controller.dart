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

import '/domain/model/country.dart';
import '/domain/model/deposit.dart';
import '/domain/model/session.dart';
import '/domain/service/session.dart';
import '/ui/page/home/tab/wallet/widget/deposit_expandable.dart';

/// Controller of a [DepositView] page.
class DepositController extends GetxController {
  DepositController(this._sessionService);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// Balance [MyUser] has in its wallet to display.
  final RxDouble balance = RxDouble(0);

  /// [DepositKind]s being expanded currently.
  final RxSet<DepositKind> expanded = RxSet();

  /// [DepositFields] to pass to a [DepositExpandable].
  final Rx<DepositFields> fields = Rx(DepositFields());

  /// [SessionService] used for [IpGeoLocation] retrieving.
  final SessionService _sessionService;

  @override
  void onInit() {
    _fetchIp();
    super.onInit();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Fetches the current [IpGeoLocation] to update [IsoCode].
  Future<void> _fetchIp() async {
    final IpGeoLocation ip = await _sessionService.fetch();
    fields.value.applyCountry(IsoCode.fromJson(ip.countryCode));
    fields.refresh();
  }
}
