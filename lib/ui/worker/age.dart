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

import 'package:age_range_signals/age_range_signals.dart';
import 'package:flutter/services.dart';

import '/domain/service/disposable_service.dart';
import '/util/platform_utils.dart';
import '/util/log.dart';

/// Worker responsible for [AgeRangeSignals] related age verification.
class AgeWorker extends Dependency {
  AgeWorker();

  @override
  void onInit() {
    _initialize();
    super.onInit();
  }

  /// Initializes the [AgeRangeSignals].
  Future<void> _initialize() async {
    // `AgeRangeSignals` work only on iOS and Android.
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
    } on MissingPluginException {
      // No-op.
    } on MissingEntitlementException catch (e) {
      Log.warning(
        'checkAgeSignals() -> setup required: ${e.message}\n${e.details}',
        '$runtimeType',
      );
    } on UserCancelledException catch (e) {
      Log.warning(
        'checkAgeSignals() -> user cancelled: ${e.message}',
        '$runtimeType',
      );
    } on NetworkErrorException catch (e) {
      Log.warning(
        'checkAgeSignals() -> network error: ${e.message}',
        '$runtimeType',
      );
    } on PlayServicesException catch (e) {
      Log.warning(
        'checkAgeSignals() -> Play Services required: ${e.message}',
        '$runtimeType',
      );
    } on UserNotSignedInException catch (e) {
      Log.warning(
        'checkAgeSignals() -> Sign in required: ${e.message}',
        '$runtimeType',
      );
    } on ApiNotAvailableException catch (e) {
      Log.warning(
        'checkAgeSignals() -> API not available: ${e.message}',
        '$runtimeType',
      );
    } on UnsupportedPlatformException catch (e) {
      Log.warning(
        'checkAgeSignals() -> Platform not supported: ${e.message}',
        '$runtimeType',
      );
    } on ApiErrorException catch (e) {
      Log.warning(
        'checkAgeSignals() -> API error: ${e.message}\n${e.details}',
        '$runtimeType',
      );
    } on AgeSignalsException catch (e) {
      Log.warning(
        '_initialize() -> checkAgeSignals() failed with: ${e.message}',
        '$runtimeType',
      );
    }
  }
}
