import 'package:flutter/gestures.dart';

/// [OneSequenceGestureRecognizer] rejecting the secondary mouse button events.
class DisableSecondaryButtonRecognizer extends OneSequenceGestureRecognizer {
  @override
  String get debugDescription => 'DisableSecondaryButtonRecognizer';

  @override
  void didStopTrackingLastPointer(int pointer) {
    // No-op.
  }

  @override
  void handleEvent(PointerEvent event) {
    // No-op.
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);

    if (event.buttons == kPrimaryButton) {
      resolve(GestureDisposition.rejected);
    } else {
      resolve(GestureDisposition.accepted);
    }
  }
}
