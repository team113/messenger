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

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

export 'view.dart';

/// [Routes.work] page controller.
class WorkController extends GetxController {
  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [ISentrySpan] being a [Sentry] transaction monitoring this
  /// [WorkController] readiness.
  final ISentrySpan _ready = Sentry.startTransaction(
    'ui.work.ready',
    'ui',
    autoFinishAfter: const Duration(minutes: 2),
  )..startChild('ready');

  @override
  void onReady() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _ready.finish());
    super.onReady();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
