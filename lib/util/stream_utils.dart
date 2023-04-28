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

import 'package:async/async.dart';

/// Extension adding convenient execution wrapper to [StreamQueue].
extension StreamQueueExtension<T> on StreamQueue<T> {
  /// Executes this [StreamQueue] in an async loop invoking the provided
  /// [onEvent] on every [T] event happening.
  Future<void> execute(FutureOr<void> Function(T) onEvent) async {
    try {
      while (await hasNext) {
        T? event;

        try {
          event = await next;
        } catch (_) {
          // No-op.
        }

        if (event != null) {
          await onEvent(event);
        }
      }
    } on StateError catch (e) {
      if (e.message != 'Already cancelled') {
        rethrow;
      }
    }
  }

  /// Cancels the underlying event source.
  ///
  /// If [immediate] is `true`, the source is instead canceled immediately. Any
  /// pending events are completed as though the underlying stream had closed.
  void close({bool immediate = false}) {
    try {
      cancel(immediate: immediate);
    } on StateError catch (e) {
      if (e.message != 'Already cancelled') {
        rethrow;
      }
    }
  }
}
