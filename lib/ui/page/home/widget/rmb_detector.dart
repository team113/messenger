// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '/ui/widget/menu_interceptor/menu_interceptor.dart';

/// Secondary button detector.
class RmbDetector extends StatefulWidget {
  const RmbDetector({
    super.key,
    required this.child,
    this.onPressed,
  });

  /// [Widget] to wrap this [RmbDetector] over.
  final Widget child;

  /// Callback, called when a secondary button is pressed.
  final void Function()? onPressed;

  @override
  State<RmbDetector> createState() => _RmbDetectorState();
}

/// State of a [RmbDetector] keeping the [_buttons].
class _RmbDetectorState extends State<RmbDetector> {
  /// Bytes of the pressed button.
  int _buttons = 0;

  @override
  Widget build(BuildContext context) {
    return ContextMenuInterceptor(
      child: Listener(
        onPointerDown: (d) => _buttons = d.buttons,
        onPointerUp: (d) {
          if (_buttons & kSecondaryButton != 0) {
            widget.onPressed?.call();
          }
        },
        child:
            GestureDetector(onLongPress: widget.onPressed, child: widget.child),
      ),
    );
  }
}
