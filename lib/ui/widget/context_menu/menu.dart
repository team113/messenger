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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/themes.dart';
import 'overlay.dart';

/// Styled context menu of [actions].
class ContextMenu extends StatelessWidget {
  const ContextMenu({Key? key, required this.actions}) : super(key: key);

  /// List of [ContextMenuButton]s to display in this [ContextMenu].
  final List<ContextMenuButton> actions;

  @override
  Widget build(BuildContext context) {
    // Close this context menu if [actions] are empty.
    if (actions.isEmpty) {
      scheduleMicrotask(() => ContextMenuOverlay.of(context).hide());
      return const SizedBox.shrink();
    }

    // Border radius is based on the [ContextMenuOverlay]'s alignment.
    Alignment quadrant = ContextMenuOverlay.of(context).alignment;
    BorderRadius borderRadius = BorderRadius.only(
      topLeft: quadrant.x > 0 && quadrant.y > 0
          ? Radius.zero
          : const Radius.circular(10),
      topRight: quadrant.x < 0 && quadrant.y > 0
          ? Radius.zero
          : const Radius.circular(10),
      bottomLeft: quadrant.x > 0 && quadrant.y < 0
          ? Radius.zero
          : const Radius.circular(10),
      bottomRight: quadrant.x < 0 && quadrant.y < 0
          ? Radius.zero
          : const Radius.circular(10),
    );

    List<Widget> widgets = [];
    for (int i = 0; i < actions.length; ++i) {
      // Adds a button.
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: actions[i],
        ),
      );

      // Adds a divider if required.
      if (i < actions.length - 1) {
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            color: const Color(0x99000000),
            height: 1,
            width: double.infinity,
          ),
        );
      }
    }

    return Container(
      decoration: const BoxDecoration(
        boxShadow: [CustomBoxShadow(blurRadius: 6, color: Color(0x20000000))],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xE6FFFFFF),
            borderRadius: borderRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets,
          ),
        ),
      ),
    );
  }
}

/// Styled button used in [ContextMenu].
class ContextMenuButton extends StatefulWidget {
  const ContextMenuButton({
    Key? key,
    required this.label,
    this.leading,
    this.onPressed,
  }) : super(key: key);

  /// Label of this [ContextMenuButton].
  final String label;

  /// Optional leading widget, typically an [Icon].
  final Widget? leading;

  /// Callback, called when button is pressed.
  final VoidCallback? onPressed;

  @override
  State<ContextMenuButton> createState() => _ContextMenuButtonState();
}

/// State of the [ContextMenuButton] used to implement hover effect.
class _ContextMenuButtonState extends State<ContextMenuButton> {
  /// Indicator whether mouse is hovered over this button.
  bool isMouseOver = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isMouseOver = true),
      onTapUp: (_) {
        setState(() => isMouseOver = false);
        widget.onPressed?.call();
        ContextMenuOverlay.of(context).hide();
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => isMouseOver = true),
        onExit: (_) => setState(() => isMouseOver = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isMouseOver ? const Color(0x22000000) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: context.theme.outlinedButtonTheme.style!.textStyle!
                    .resolve({MaterialState.disabled})!.copyWith(
                        color: Colors.black),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
