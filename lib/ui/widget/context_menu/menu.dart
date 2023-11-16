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
  const ContextMenu({
    super.key,
    required this.actions,
    this.enlarged,
  });

  /// List of [Widget]s to display in this [ContextMenu].
  final List<Widget> actions;

  /// Indicator whether this [ContextMenu] should be enlarged.
  ///
  /// Intended to be used only for [Routes.style] page.
  final bool? enlarged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final bool isMobile = enlarged ?? context.isMobile;

    final List<Widget> widgets = [];

    for (int i = 0; i < actions.length; ++i) {
      // Adds a button.
      widgets.add(actions[i]);

      // Adds a divider if required.
      if (isMobile && i < actions.length - 1) {
        widgets.add(
          Container(
            color: style.colors.onBackgroundOpacity7,
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
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: style.colors.onBackgroundOpacity27,
            blurStyle: BlurStyle.outer.workaround,
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
              if (!isMobile) const SizedBox(height: 4),
              ...widgets,
              if (!isMobile) const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// [Widget] to be displayed in a [ContextMenu].
mixin ContextMenuItem on Widget {}

/// [ContextMenuItem] representing a divider in [ContextMenu].
class ContextMenuDivider extends StatelessWidget with ContextMenuItem {
  const ContextMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      width: double.infinity,
      height: 1,
      color: style.colors.secondaryHighlightDark,
    );
  }
}

/// [ContextMenuItem] representing a styled button used in [ContextMenu].
class ContextMenuButton extends StatefulWidget with ContextMenuItem {
  const ContextMenuButton({
    super.key,
    required this.label,
    this.leading,
    this.trailing,
    this.showTrailing = false,
    this.enlarged,
    this.onPressed,
  });

  /// Label of this [ContextMenuButton].
  final String label;

  /// Optional leading widget, typically an [Icon].
  final Widget? leading;

  /// Optional trailing widget.
  final Widget? trailing;

  /// Indicator whether the [trailing] should always be displayed.
  ///
  /// On mobile platforms the provided [trailing] is always displayed.
  final bool showTrailing;

  /// Indicator whether this [ContextMenuButton] should be enlarged.
  ///
  /// Intended to be used only for [Routes.style] page.
  final bool? enlarged;

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
    final style = Theme.of(context).style;

    final bool isMobile = widget.enlarged ?? context.isMobile;

    return GestureDetector(
      onTapDown: (_) => setState(() => isMouseOver = true),
      onTapUp: (_) {
        setState(() => isMouseOver = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => isMouseOver = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => isMouseOver = true),
        onExit: (_) => setState(() => isMouseOver = false),
        child: Container(
          padding: isMobile
              ? const EdgeInsets.symmetric(horizontal: 18, vertical: 15)
              : const EdgeInsets.fromLTRB(11, 6, 11, 6),
          margin: isMobile ? null : const EdgeInsets.fromLTRB(4, 0, 4, 0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: context.isMobile
                ? style.contextMenuRadius
                : BorderRadius.circular(7),
            color: isMouseOver
                ? isMobile
                    ? style.contextMenuHoveredColor
                    : style.colors.primary
                : style.colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) ...[
                Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme:
                        IconThemeData(color: style.colors.primaryHighlight),
                  ),
                  child: widget.leading!,
                ),
                const SizedBox(width: 14),
              ],
              Text(
                widget.label,
                style: (isMouseOver && !isMobile
                        ? style.fonts.normal.regular.onPrimary
                        : style.fonts.normal.regular.onBackground)
                    .copyWith(
                  fontSize: isMobile
                      ? style.fonts.medium.regular.onBackground.fontSize
                      : style.fonts.small.regular.onBackground.fontSize,
                ),
              ),
              if ((isMobile || widget.showTrailing) &&
                  widget.trailing != null) ...[
                const SizedBox(width: 36),
                const Spacer(),
                Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme:
                        IconThemeData(color: style.colors.primaryHighlight),
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
