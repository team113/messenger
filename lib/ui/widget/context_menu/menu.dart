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

import 'package:flutter/material.dart';

import '/themes.dart';
import '/util/platform_utils.dart';

/// Styled context menu of [actions].
class ContextMenu extends StatelessWidget {
  const ContextMenu({super.key, required this.actions});

  /// List of [Widget]s to display in this [ContextMenu].
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<Style>()!;
    final List<Widget> widgets = [];

    for (int i = 0; i < actions.length; ++i) {
      // Adds a button.
      widgets.add(actions[i]);

      // Adds a divider if required.
      if (context.isMobile && i < actions.length - 1) {
        widgets.add(
          Container(
            color: style.transparentOpacity94,
            height: 1,
            width: double.infinity,
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(left: 1, top: 1),
      decoration: BoxDecoration(
        color: style.contextMenuBackgroundColor,
        borderRadius: style.contextMenuRadius,
        border: Border.all(color: style.primaryHighlightDarkest, width: 0.5),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: style.transparentOpacity81,
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
              if (!context.isMobile) const SizedBox(height: 6),
              ...widgets,
              if (!context.isMobile) const SizedBox(height: 6),
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
    final style = Theme.of(context).extension<Style>()!;

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
          padding: context.isMobile
              ? const EdgeInsets.symmetric(horizontal: 18, vertical: 15)
              : const EdgeInsets.fromLTRB(12, 6, 12, 6),
          margin:
              context.isMobile ? null : const EdgeInsets.fromLTRB(6, 0, 6, 0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: isMouseOver
                ? context.isMobile
                    ? Theme.of(context)
                        .extension<Style>()!
                        .contextMenuHoveredColor
                    : style.secondary
                : style.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) ...[
                Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: IconThemeData(
                        color: Theme.of(context)
                            .extension<Style>()!
                            .secondaryHighlight),
                  ),
                  child: widget.leading!,
                ),
                const SizedBox(width: 14),
              ],
              Text(
                widget.label,
                style: style.boldBody.copyWith(
                  color: (isMouseOver && !context.isMobile)
                      ? style.onPrimary
                      : style.onBackground,
                  fontSize: context.isMobile ? 17 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (PlatformUtils.isMobile && widget.trailing != null) ...[
                const SizedBox(width: 36),
                const Spacer(),
                Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: IconThemeData(
                        color: Theme.of(context)
                            .extension<Style>()!
                            .secondaryHighlight),
                  ),
                  child: widget.trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
