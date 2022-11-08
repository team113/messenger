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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/themes.dart';

/// Styled context menu of [actions].
class ContextMenu extends StatelessWidget {
  const ContextMenu({Key? key, required this.actions}) : super(key: key);

  /// List of [ContextMenuButton]s to display in this [ContextMenu].
  final List<ContextMenuButton> actions;

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    for (int i = 0; i < actions.length; ++i) {
      // Adds a button.
      widgets.add(actions[i]);

      // Adds a divider if required.
      if (i < actions.length - 1) {
        widgets.add(
          Container(
            color: const Color(0x11000000),
            height: 1,
            width: double.infinity,
          ),
        );
      }
    }

    Style style = Theme.of(context).extension<Style>()!;

    return Container(
      width: 220,
      margin: const EdgeInsets.only(left: 1, top: 1),
      decoration: BoxDecoration(
        color: style.contextMenuBackgroundColor,
        borderRadius: style.contextMenuRadius,
        boxShadow: const [
          CustomBoxShadow(
            blurRadius: 8,
            color: Color(0x33000000),
            blurStyle: BlurStyle.outer,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: style.contextMenuRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
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
  }) : super(key: key);

  /// Label of this [ContextMenuButton].
  final String label;

  /// Optional leading widget, typically an [Icon].
  final Widget? leading;

  /// Optional trailing widget.
  final Widget? trailing;

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
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => isMouseOver = true),
        onExit: (_) => setState(() => isMouseOver = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: isMouseOver
                ? Theme.of(context).extension<Style>()!.contextMenuHoveredColor
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) ...[
                Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: const IconThemeData(color: Colors.blue),
                  ),
                  child: widget.leading!,
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  widget.label,
                  style: context.theme.outlinedButtonTheme.style!.textStyle!
                      .resolve({MaterialState.disabled})!.copyWith(
                          color: Colors.black),
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 14),
                Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: const IconThemeData(color: Colors.blue),
                  ),
                  child: widget.leading!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
