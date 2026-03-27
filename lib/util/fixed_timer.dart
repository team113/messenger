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

/// Periodic [Timer] executing the tick callbacks at the same time.
class FixedTimer {
  FixedTimer._(this._subscription);

  /// Creates a new [FixedTimer].
  ///
  /// The [callback] is invoked repeatedly with duration intervals until
  /// [cancel]ed.
  ///
  /// All [FixedTimer]s with same [duration] invoke [callback] at the same time.
  factory FixedTimer.periodic(Duration duration, void Function() callback) {
    StreamController? controller = _controllers[duration];
    if (controller == null) {
      controller = StreamController.broadcast(
        onCancel: () {
          _controllers.remove(duration)?.close();
          _timers.remove(duration)?.cancel();
        },
      );

      _controllers[duration] = controller;
    }

    Timer? timer = _timers[duration];
    if (timer == null) {
      timer = Timer.periodic(duration, (_) => controller?.add(null));
      _timers[duration] = timer;
    }

    return FixedTimer._(controller.stream.listen((_) => callback()));
  }

  /// [StreamController]s updating the [FixedTimer]s and keeping them up.
  static final Map<Duration, StreamController<void>> _controllers = {};

  /// [Timer]s emitting periodic updates to the [_controllers].
  static final Map<Duration, Timer> _timers = {};

  /// [StreamSubscription] of the current [FixedTimer] keeping it up.
  final StreamSubscription<void> _subscription;

  /// Cancels this [FixedTimer].
  void cancel() {
    _subscription.cancel();
  }
}
