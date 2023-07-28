// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:rive/rive.dart';

export 'view.dart';

/// List of [StyleView] page sections.
enum StyleTab { colors, typography, multimedia, elements }

/// Controller of a [StyleView].
class StyleController extends GetxController {
  StyleController();

  /// Indicator whether the [StyleView] should be compact, meaning minimal
  /// [Padding]s.
  ///
  /// Intended for the [StyleView] to be used as a reference.
  final RxBool dense = RxBool(false);

  /// Indicator whether the [Color]s of the [StyleView] should be inverted.
  ///
  /// Meant to be used as a light/dart theme switch.
  final RxBool inverted = RxBool(false);

  /// Selected [StyleTab].
  final Rx<StyleTab> tab = Rx(StyleTab.colors);

  /// [PageController] controlling the [PageView] of [StyleView].
  final PageController pages = PageController();

  /// Current logo's animation frame.
  RxInt logoFrame = RxInt(0);

  /// TODO: docs
  RxBool isPlaying = RxBool(false);

  /// [SMITrigger] triggering the blinking animation.
  SMITrigger? blink;

  /// [Timer] periodically increasing the [logoFrame].
  Timer? _animationTimer;

  /// TODO: add new player
  // AudioPlayer? _audioPlayer;

  @override
  void onClose() {
    _animationTimer?.cancel();
    super.onClose();
  }

  /// Resets the [logoFrame] and starts the blinking animation.
  void animate() {
    blink?.fire();

    logoFrame.value = 1;
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(
      const Duration(milliseconds: 45),
      (t) {
        ++logoFrame.value;
        if (logoFrame >= 9) t.cancel();
      },
    );
  }
}
