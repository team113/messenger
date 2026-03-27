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

import 'log.dart';

/// [Timer] exposing its [future] to be awaited.
class AwaitableTimer {
  AwaitableTimer(Duration d, FutureOr Function() callback) {
    _timer = Timer(d, () async {
      try {
        _completer.complete(await callback());
      } on StateError {
        // No-op, as [Future] is allowed to be completed.
      } catch (e, stackTrace) {
        try {
          _completer.completeError(e, stackTrace);
        } on StateError {
          // [_completer]'s future is allowed to be competed at this point.
          Log.error(
            'Callback completed with the following exception: $e',
            '$runtimeType',
          );
        }
      }
    });
  }

  /// [Timer] executing the callback.
  late final Timer _timer;

  /// [Completer] completing when [_timer] is done executing.
  final _completer = Completer();

  /// [Future] completing when this [AwaitableTimer] is finished.
  Future get future => _completer.future;

  /// Cancels this [AwaitableTimer].
  void cancel() {
    try {
      _timer.cancel();
      _completer.complete();
    } on StateError {
      // [_completer]'s future is allowed to be competed at this point.
    }
  }
}
