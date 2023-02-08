import 'dart:async';

import 'package:async/async.dart';

/// Extension adding convenient execution wrapper to [StreamQueue].
extension StreamQueueExtension on StreamQueue {
  /// Executes this [StreamQueue] is an async loop invoking the provided
  /// [onEvent] on every [T] event happening.
  Future<void> execute<T>(FutureOr<void> Function(T) onEvent) async {
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
}
