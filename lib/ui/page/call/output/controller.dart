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

import 'package:get/get.dart';

import '/domain/model/ongoing_call.dart';
import '/util/media_utils.dart';

/// Controller of a [OutputRouteView].
class OutputRouteController extends GetxController {
  OutputRouteController({DeviceDetails? initial}) : selected = Rx(initial);

  /// List of [DeviceDetails] of all the available devices.
  final RxList<DeviceDetails> devices = RxList<DeviceDetails>([]);

  /// Currently selected output [DeviceDetails].
  final Rx<DeviceDetails?> selected;

  /// [StreamSubscription] to the [MediaUtilsImpl.onDeviceChange] changing the
  /// [devices].
  StreamSubscription? _subscription;

  @override
  void onInit() {
    enumerateDevices();

    _subscription = MediaUtils.onDeviceChange.listen((e) {
      devices.value = e.output().toList();
    });

    super.onInit();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  /// Enumerates the [devices].
  Future<void> enumerateDevices() async {
    devices.value = (await MediaUtils.enumerateDevices()).output().toList();
  }
}
