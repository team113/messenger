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

import '../conditional_backdrop.dart';
import '/themes.dart';
import '/ui/page/call/component/common.dart';

/// `More` panel which contains the call panel.
class Launchpad extends StatelessWidget {
  const Launchpad({
    super.key,
    required this.enabled,
    required this.test,
    required this.panel,
    required this.displayMore,
    this.onEnter,
    this.onHover,
    this.onExit,
    this.onAccept,
    this.onWillAccept,
    this.children = const <Widget>[],
  });

  /// Indicator whether [Launchpad] is enabled.
  final bool enabled;

  /// [CallButton] list, which is a panel of buttons in [Launchpad].
  final List<CallButton> panel;

  /// Indicator whether additional elements should be displayed
  /// in [Launchpad].
  final bool displayMore;

  /// List of [Widget] that will be displayed in the [Launchpad].
  final List<Widget> children;

  /// Indicator whether at least one element from the [panel] list satisfies
  /// the condition set by the [test] function.
  final bool Function(CallButton?) test;

  /// Callback, called when the mouse cursor enters the area
  /// of this [Launchpad].
  final void Function(PointerEnterEvent)? onEnter;

  /// Callback, called when the mouse cursor moves in the area
  /// of this [Launchpad].
  final void Function(PointerHoverEvent)? onHover;

  /// Callback, called when the mouse cursor leaves the area
  /// of this [Launchpad].
  final void Function(PointerExitEvent)? onExit;

  /// Callback, called when accepting a draggable element.
  final void Function(CallButton)? onAccept;

  /// Callback, called when the dragged element is above
  /// the widget, but has not yet been released.
  final bool Function(CallButton?)? onWillAccept;

  @override
  Widget build(BuildContext context) {
    /// Builder function for the [DragTarget].
    ///
    /// It is responsible for displaying the visual interface when dragging
    /// elements onto the target.
    Widget launchpadBuilder(
      BuildContext context,
      List<CallButton?> candidate,
      List<dynamic> rejected,
    ) {
      return MouseRegion(
        onEnter: onEnter,
        onHover: onHover,
        onExit: onExit,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              CustomBoxShadow(
                color: Color(0x33000000),
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
                color: candidate.any(test)
                    ? const Color(0xE0165084)
                    : const Color(0x9D165084),
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
                      children: children,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: displayMore ? 1.0 : 0.0,
        child: displayMore
            ? DragTarget<CallButton>(
                onAccept: onAccept,
                onWillAccept: onWillAccept,
                builder: launchpadBuilder,
              )
            : const SizedBox(),
      ),
    );
  }
}
