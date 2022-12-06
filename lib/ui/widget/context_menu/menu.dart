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

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/call/widget/conditional_backdrop.dart';

import '/themes.dart';

/// Styled context menu of [actions].
class ContextMenu extends StatelessWidget {
  const ContextMenu({
    Key? key,
    required this.actions,
    this.width,
  }) : super(key: key);

  /// List of [ContextMenuButton]s to display in this [ContextMenu].
  final List<ContextMenuButton> actions;

  final double? width;

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    int length = 0;

    for (int i = 0; i < actions.length; ++i) {
      // Adds a button.
      widgets.add(actions[i]);

      length = max(actions[i].label.length, length);

      // Adds a divider if required.
      // if (i < actions.length - 1) {
      //   widgets.add(
      //     const SizedBox(height: 8),
      //     // Container(
      //     //   color: const Color(0x11000000),
      //     //   // color: const Color(0xFF202020),
      //     //   height: 1,
      //     //   width: double.infinity,
      //     // ),
      //   );
      // }
    }

    final Style style = Theme.of(context).extension<Style>()!;

    return Container(
      // width: (length * 15),
      margin: const EdgeInsets.only(left: 1, top: 1),
      decoration: BoxDecoration(
        // color: const Color(0xFF3A3A3A),
        color: style.contextMenuBackgroundColor,
        borderRadius: style.contextMenuRadius,
        border: Border.all(color: const Color(0xFFAAAAAA), width: 0.5),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x33000000),
            blurStyle: BlurStyle.outer,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: style.contextMenuRadius,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              ...widgets,
              const SizedBox(height: 6),
            ],
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
    this.trailing,
    this.onPressed,
    this.style,
  }) : super(key: key);

  /// Label of this [ContextMenuButton].
  final String label;

  /// Optional leading widget.
  final Widget? leading;

  /// Optional trailing widget, typically an [Icon].
  final Widget? trailing;

  /// Callback, called when button is pressed.
  final VoidCallback? onPressed;

  final TextStyle? style;

  @override
  State<ContextMenuButton> createState() => _ContextMenuButtonState();
}

/// State of the [ContextMenuButton] used to implement hover effect.
class _ContextMenuButtonState extends State<ContextMenuButton> {
  /// Indicator whether mouse is hovered over this button.
  bool isMouseOver = false;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GestureDetector(
      onTapDown: (_) => setState(() => isMouseOver = true),
      onTapUp: (_) {
        setState(() => isMouseOver = false);
        widget.onPressed?.call();
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => isMouseOver = true),
        onExit: (_) => setState(() => isMouseOver = false),
        child: Container(
          margin: const EdgeInsets.fromLTRB(6, 0, 6, 0),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          width: double.infinity,
          // height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: isMouseOver
                // ? Colors.white.withOpacity(0.1)
                // ? Theme.of(context).extension<Style>()!.contextMenuHoveredColor
                ? Theme.of(context).colorScheme.secondary
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: style.boldBody
                    .copyWith(
                      color: isMouseOver ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )
                    .merge(widget.style),
              ),
              // if (widget.trailing != null) ...[
              //   const Spacer(),
              //   const SizedBox(width: 14),
              //   Theme(
              //     data: Theme.of(context).copyWith(
              //       iconTheme: const IconThemeData(color: Colors.blue),
              //     ),
              //     child: widget.trailing!,
              //   ),
              // ],
            ],
          ),
          // child: Text(
          //   widget.label,
          //   style: style.boldBody
          //       .copyWith(
          //         color: isMouseOver ? Colors.white : Colors.black,
          //         fontSize: 14,
          //         fontWeight: FontWeight.w500,
          //       )
          //       .merge(widget.style),
          // ),
          // child: Row(
          //   mainAxisSize: MainAxisSize.min,
          //   children: [
          //     // if (widget.leading != null) ...[
          //     //   Theme(
          //     //     data: Theme.of(context).copyWith(
          //     //       iconTheme: const IconThemeData(color: Colors.blue),
          //     //     ),
          //     //     child: widget.leading!,
          //     //   ),
          //     //   const SizedBox(width: 14),
          //     // ],
          //     Expanded(
          //       child: Text(
          //         widget.label,
          //         style: style.boldBody
          //             .copyWith(
          //               color: isMouseOver ? Colors.white : Colors.black,
          //               fontSize: 14,
          //               fontWeight: FontWeight.w500,
          //             )
          //             .merge(widget.style),
          //       ),
          //     ),
          //   if (widget.trailing != null) ...[
          //     const SizedBox(width: 14),
          //     Theme(
          //       data: Theme.of(context).copyWith(
          //         iconTheme: const IconThemeData(color: Colors.blue),
          //       ),
          //       child: widget.trailing!,
          //     ),
          //   ],
          // ],
          // ),
        ),
      ),
    );
  }
}
