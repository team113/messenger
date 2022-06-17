// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'package:get/get.dart';

import '/ui/widget/svg/svg.dart';

/// Styled popup window with a [text] used to serve as a hint.
class HintWidget extends StatefulWidget {
  const HintWidget({
    Key? key,
    required this.text,
    this.onTap,
  }) : super(key: key);

  /// Text of a hint.
  final String text;

  /// Callback, called when this hint is pressed.
  final GestureTapCallback? onTap;

  @override
  State<HintWidget> createState() => _HintWidgetState();
}

/// State of [HintWidget] used to keep track of [_buttons].
class _HintWidgetState extends State<HintWidget> {
  /// Bit field of [PointerDownEvent]'s buttons.
  ///
  /// [PointerUpEvent] doesn't contain the button being released, so it's
  /// required to store the buttons from.
  int _buttons = 0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (d) => _buttons = d.buttons,
      onPointerUp: (d) {
        if (_buttons & kPrimaryButton != 0) {
          widget.onTap?.call();
        }
      },
      child: Card(
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: InkWell(
          onTap: () {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child:
                      SvgLoader.asset('assets/images/head_60.svg', width: 58),
                ),
              ),
              Flexible(
                flex: 17,
                child: Text(
                  widget.text,
                  style: context.theme.outlinedButtonTheme.style!.textStyle!
                      .resolve({MaterialState.disabled})!.copyWith(
                          fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
