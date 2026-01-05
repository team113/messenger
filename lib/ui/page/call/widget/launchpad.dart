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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/page/call/component/common.dart';

/// Decorated [Wrap] with the provided [children].
class Launchpad extends StatelessWidget {
  const Launchpad({
    super.key,
    this.onEnter,
    this.onHover,
    this.onExit,
    this.onAccept,
    this.onWillAccept,
    this.children = const [],
  });

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
  /// [Launchpad].
  final void Function(CallButton)? onAccept;

  /// Callback, called to determine whether this [Launchpad] is interested in
  /// receiving a given piece of data being dragged over this [Launchpad].
  final bool Function(CallButton?)? onWillAccept;

  /// Widgets to put inside this [Launchpad].
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: DragTarget<CallButton>(
          onAcceptWithDetails: (e) => onAccept?.call(e.data),
          onWillAcceptWithDetails: (e) => onWillAccept?.call(e.data) ?? true,
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
                    ),
                  ],
                ),
                margin: const EdgeInsets.all(2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: onWillAccept != null
                        ? candidate.any(onWillAccept!)
                              ? style.colors.primaryAuxiliaryOpacity95
                              : style.colors.primaryAuxiliaryOpacity90
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
                          children: children,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
