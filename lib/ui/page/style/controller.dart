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

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' show PageController;
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// [StyleView] section.
enum StyleTab { colors, typography, widgets, icons }

/// Controller of a [StyleView].
class StyleController extends GetxController {
  /// Indicator whether the [Color]s of the [StyleView] should be inverted.
  ///
  /// Meant to be used as a light/dart theme switch.
  final RxBool inverted = RxBool(false);

  /// Selected [StyleTab].
  final Rx<StyleTab> tab = Rx(StyleTab.colors);

  /// [PageController] controlling the [PageView] of [StyleView].
  final PageController pages = PageController();

  /// [Sentry] transaction monitoring this [StyleController] readiness.
  final ISentrySpan _ready = Sentry.startTransaction(
    'ui.style.ready',
    'ui',
    autoFinishAfter: const Duration(minutes: 2),
  )..startChild('ready');

  @override
  void onReady() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _ready.finish());
    super.onReady();
  }
}
