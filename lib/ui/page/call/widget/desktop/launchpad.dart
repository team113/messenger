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
class LaunchpadWidget extends StatelessWidget {
  const LaunchpadWidget({
    super.key,
    required this.displayMore,
    this.paneledItems = const <Widget>[],
    this.test,
    this.onEnter,
    this.onHover,
    this.onExit,
    this.onAccept,
    this.onWillAccept,
  });

  /// Indicator whether additional elements should be displayed
  /// in launchpad.
  final bool displayMore;

  /// Widgets to put inside a [Wrap].
  final List<Widget> paneledItems;

  /// Callback, called when at least one element from the panel list
  /// satisfies the condition set by the [test] function.
  final bool Function(CallButton?)? test;

  /// Callback, called when the mouse cursor enters the area of this
  /// [LaunchpadWidget].
  final void Function(PointerEnterEvent)? onEnter;

  /// Callback, called when the mouse cursor moves in the area of this
  /// [LaunchpadWidget].
  final void Function(PointerHoverEvent)? onHover;

  /// Callback, called when the mouse cursor leaves the area of this
  /// [LaunchpadWidget].
  final void Function(PointerExitEvent)? onExit;

  /// Callback, called when an acceptable piece of data was dropped over this
  /// drag target.
  final void Function(CallButton)? onAccept;

  /// Callback, called to determine whether this widget is interested in
  /// receiving a given piece of data being dragged over this drag target.
  final bool Function(CallButton?)? onWillAccept;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

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
                color: test != null
                    ? candidate.any(test!)
                        ? style.colors.onSecondaryOpacity88
                        : style.colors.onSecondaryOpacity60
                    : style.colors.onSecondaryOpacity88,
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
