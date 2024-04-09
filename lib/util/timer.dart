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

import 'dart:async';

/// A synchronized periodic timer.
class SyncTimer {
  SyncTimer._(this._subscription);

  /// Creates a new [SyncTimer].
  ///
  /// The [callback] is invoked repeatedly with duration intervals until
  /// [cancel]ed.
  ///
  /// All [SyncTimer]s with same [duration] invoke [callback] in the same time.
  factory SyncTimer.periodic(
    Duration duration,
    void Function() callback,
  ) {
    StreamController? controller = _controllers[duration];
    Timer? timer = _timers[duration];
    if (controller == null) {
      controller = StreamController.broadcast();
      _controllers[duration] = controller;

      controller.onCancel = () {
        _controllers.remove(duration)?.close();
        _timers.remove(duration)?.cancel();
      };
    }

    if (timer == null) {
      timer = Timer.periodic(duration, (_) => controller?.add(null));
      _timers[duration] = timer;
    }

    return SyncTimer._(controller.stream.listen((_) => callback()));
  }

  /// [StreamController]s of this [SyncTimer].
  static final Map<Duration, StreamController<void>> _controllers = {};

  /// [Timer]s of this [SyncTimer].
  static final Map<Duration, Timer> _timers = {};

  /// [StreamSubscription]s of this [SyncTimer].
  final StreamSubscription<void> _subscription;

  /// Cancels this [SyncTimer].
  void cancel() {
    _subscription.cancel();
  }
}
