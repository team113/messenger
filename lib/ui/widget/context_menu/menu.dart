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

import 'package:flutter/material.dart';

import '/themes.dart';
import '/util/platform_utils.dart';

/// Styled context menu of [actions].
class ContextMenu extends StatelessWidget {
  const ContextMenu({super.key, required this.actions, this.enlarged});

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
          ),
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
    this.trailing,
    this.inverted,
    this.enlarged,
    this.onPressed,
    this.spacer,
    this.spacerInverted,
  });

  /// Label of this [ContextMenuButton].
  final String label;

  /// Optional trailing widget.
  final Widget? trailing;

  /// Optional inverted [trailing] widget, displayed when this
  /// [ContextMenuButton] is hovered.
  final Widget? inverted;

  /// Indicator whether this [ContextMenuButton] should be enlarged.
  ///
  /// Intended to be used only for [Routes.style] page.
  final bool? enlarged;

  /// Callback, called when button is pressed.
  final void Function()? onPressed;

  /// Optional leading widget to display.
  final Widget? spacer;

  /// Optional [spacer] widget to display when hovered instead of [spacer].
  final Widget? spacerInverted;

  @override
  State<ContextMenuButton> createState() => _ContextMenuButtonState();
}

/// State of the [ContextMenuButton] used to implement hover effect.
class _ContextMenuButtonState extends State<ContextMenuButton> {
  /// Indicator whether mouse is hovered over this button.
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final bool isMobile = widget.enlarged ?? context.isMobile;

    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) {
        setState(() => _hovered = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _hovered = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          padding: isMobile
              ? EdgeInsets.fromLTRB(
                  widget.trailing == null ? 18 : 5,
                  15,
                  18,
                  15,
                )
              : EdgeInsets.fromLTRB(widget.trailing == null ? 8 : 0, 6, 12, 6),
          margin: isMobile ? null : const EdgeInsets.fromLTRB(4, 0, 4, 0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: isMobile
                ? style.contextMenuRadius
                : BorderRadius.circular(7),
            color: _hovered && widget.onPressed != null
                ? isMobile
                      ? style.contextMenuHoveredColor
                      : style.colors.primary
                : style.colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.trailing != null) ...[
                if (isMobile)
                  SizedBox(
                    width: 40,
                    child: Align(
                      alignment: Alignment.center,
                      child: widget.trailing!,
                    ),
                  )
                else
                  SizedBox(
                    width: 36,
                    child: Transform.scale(
                      scale: 0.8,
                      child: Align(
                        alignment: Alignment.center,
                        child: _hovered && widget.onPressed != null
                            ? (widget.inverted ?? widget.trailing)
                            : widget.trailing,
                      ),
                    ),
                  ),
              ],
              Text(
                widget.label,
                style:
                    (widget.onPressed == null
                            ? style
                                  .fonts
                                  .normal
                                  .regular
                                  .secondaryHighlightDarkest
                            : (_hovered && !isMobile
                                  ? style.fonts.normal.regular.onPrimary
                                  : style.fonts.normal.regular.onBackground))
                        .copyWith(
                          fontSize: isMobile
                              ? style.fonts.medium.regular.onBackground.fontSize
                              : style.fonts.small.regular.onBackground.fontSize,
                        ),
              ),
              if (widget.spacer != null) ...[
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: DefaultTextStyle(
                      style:
                          (widget.onPressed == null
                                  ? style
                                        .fonts
                                        .normal
                                        .regular
                                        .secondaryHighlightDarkest
                                  : (_hovered && !isMobile
                                        ? style.fonts.normal.regular.onPrimary
                                        : style.fonts.normal.regular.primary))
                              .copyWith(
                                fontSize: isMobile
                                    ? style
                                          .fonts
                                          .medium
                                          .regular
                                          .onBackground
                                          .fontSize
                                    : style
                                          .fonts
                                          .small
                                          .regular
                                          .onBackground
                                          .fontSize,
                              ),
                      textAlign: TextAlign.end,
                      child: _hovered && widget.onPressed != null
                          ? widget.spacerInverted ?? widget.spacer!
                          : widget.spacer!,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
