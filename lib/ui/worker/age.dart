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

import 'package:age_range_signals/age_range_signals.dart';

import '/domain/service/disposable_service.dart';
import '/util/platform_utils.dart';
import '/util/log.dart';

/// Worker responsible for [AgeRangeSignals] related age verification.
class AgeWorker extends DisposableService {
  AgeWorker();

  @override
  void onInit() {
    _initialize();
    super.onInit();
  }

  /// Initializes the [AgeRangeSignals].
  Future<void> _initialize() async {
    // `AgeRangeSignals` works only on iOS and Android.
    if (PlatformUtils.isWeb || PlatformUtils.isDesktop) {
      return;
    }

    // Initialize with age gates on iOS (required); Android is a no-op.
    if (PlatformUtils.isIOS) {
      await AgeRangeSignals.instance.initialize(ageGates: [13, 16, 18]);
    }

    try {
      final AgeSignalsResult result = await AgeRangeSignals.instance
          .checkAgeSignals();

      // Simply log the results, since the app is all ages available.
      Log.debug(
        '_initialize() -> Age signals status: ${result.status}',
        '$runtimeType',
      );
    } on AgeSignalsException catch (e) {
      // Do not block the app usage.
      Log.warning(
        '_initialize() -> checkAgeSignals() failed with: ${e.message}',
        '$runtimeType',
      );
    }
  }
}
