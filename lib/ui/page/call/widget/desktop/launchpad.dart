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

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/page/call/component/common.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';

/// Panel which containing the dragging and dropping elements.
class Launchpad extends StatelessWidget {
  const Launchpad({
    super.key,
    this.condition,
    this.onEnter,
    this.onHover,
    this.onExit,
    this.onAccept,
    this.onWillAccept,
    this.paneledItems = const <Widget>[],
  });

  /// Widgets to put inside a [Wrap].
  final List<Widget> paneledItems;

  /// Callback, called to check whether a certain condition is met in order to
  /// apply a certain decoration to a [AnimatedContainer].
  final bool Function(CallButton?)? condition;

  /// Callback, called when the mouse cursor enters the area of this
  /// [Launchpad].
  final void Function(PointerEnterEvent)? onEnter;

  /// Callback, called when the mouse cursor moves in the area of this
  /// [Launchpad].
  final void Function(PointerHoverEvent)? onHover;

  /// Callback, called when the mouse cursor leaves the area of this
  /// [Launchpad].
  final void Function(PointerExitEvent)? onExit;

  /// Callback, called when an acceptable piece of data was dropped over this
  /// drag target.
  final void Function(CallButton)? onAccept;

  /// Callback, called to determine whether this [Launchpad] is interested in
  /// receiving a given piece of data being dragged over a [DragTarget].
  final bool Function(CallButton?)? onWillAccept;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: DragTarget<CallButton>(
        onAccept: onAccept,
        onWillAccept: onWillAccept,
        builder: (context, candidate, _) {
          return MouseRegion(
            onEnter: onEnter,
            onHover: onHover,
            onExit: onExit,
            child: Container(
              decoration: BoxDecoration(
                color: style.colors.transparent,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  CustomBoxShadow(
                    color: style.colors.onBackgroundOpacity20,
                    blurRadius: 8,
                    blurStyle: BlurStyle.outer,
                  )
                ],
              ),
              margin: const EdgeInsets.all(2),
              child: ConditionalBackdropFilter(
                borderRadius: BorderRadius.circular(30),
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: condition != null
                        ? candidate.any(condition!)
                            ? style.colors.onSecondaryOpacity88
                            : style.colors.onSecondaryOpacity60
                        : null,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 35),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.start,
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          runSpacing: 21,
                          children: paneledItems,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
