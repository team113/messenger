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
import 'package:flutter/scheduler.dart';

import '../selector.dart';
import '/themes.dart';
import '/util/global_key.dart';
import '/util/platform_utils.dart';
import 'region.dart';

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
    this.actions = const [],
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

  /// [ContextMenuItem] to display when this [ContextMenuButton] is chosen.
  final List<ContextMenuItem> actions;

  @override
  State<ContextMenuButton> createState() => _ContextMenuButtonState();
}

/// State of the [ContextMenuButton] used to implement hover effect.
class _ContextMenuButtonState extends State<ContextMenuButton> {
  /// Indicator whether mouse is hovered over this button.
  bool _hovered = false;

  /// Indicator whether the [_entry] is being hovered or not.
  bool _hoveredMenu = false;

  /// [OverlayEntry] displaying a currently opened [ContextMenuOverlay].
  OverlayEntry? _entry;

  /// [GlobalKey] of this [ContextMenuButton].
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final bool isMobile = widget.enlarged ?? context.isMobile;
    final bool enabled = widget.onPressed != null || widget.actions.isNotEmpty;

    return GestureDetector(
      key: _key,
      onTapDown: (_) => _toggleMouseOver(true),
      onTapUp: (d) {
        if (widget.actions.isEmpty) {
          _toggleMouseOver(false);
          widget.onPressed?.call();
        }
      },
      onTapCancel: () {
        if (widget.actions.isEmpty) {
          _toggleMouseOver(false);
        }
      },
      child: MouseRegion(
        onEnter: (_) => _toggleMouseOver(true),
        onExit: (_) {
          setState(() => _hovered = false);

          SchedulerBinding.instance.addPostFrameCallback((_) {
            _toggleMouseOver(false);
          });
        },
        child: Container(
          padding: isMobile
              ? EdgeInsets.fromLTRB(
                  widget.trailing == null ? 18 : 5,
                  15,
                  15,
                  15,
                )
              : EdgeInsets.fromLTRB(
                  widget.trailing == null ? 8 : 0,
                  6,
                  widget.actions.isEmpty ? 12 : 6,
                  6,
                ),
          margin: isMobile ? null : const EdgeInsets.fromLTRB(4, 0, 4, 0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: isMobile
                ? style.contextMenuRadius
                : BorderRadius.circular(7),
            color: _hovered && enabled
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
                        child: _hovered && enabled
                            ? (widget.inverted ?? widget.trailing)
                            : widget.trailing,
                      ),
                    ),
                  ),
              ],
              Text(
                widget.label,
                style:
                    (!enabled
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
                          (!enabled
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
                      child: _hovered && enabled
                          ? widget.spacerInverted ?? widget.spacer!
                          : widget.spacer!,
                    ),
                  ),
                ),
              ],
              if (widget.actions.isNotEmpty) ...[
                if (isMobile) const SizedBox(width: 4),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _hovered && enabled
                        ? Icon(
                            Icons.arrow_forward_ios,
                            color: style.colors.onPrimary,
                            size: 10,
                          )
                        : Icon(
                            Icons.arrow_forward_ios,
                            color: style.colors.onBackground,
                            size: 10,
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

  /// Toggles the [_hovered] to a [value], populating [_entry] when applicable.
  void _toggleMouseOver(bool value) {
    if (mounted) {
      setState(() => _hovered = value);
    }

    if (widget.actions.isEmpty) {
      return;
    }

    if (value && _entry == null) {
      bool registered = false;

      _entry = OverlayEntry(
        builder: (context) {
          double left = (_key.globalPaintBounds?.left ?? 0);
          double top = (_key.globalPaintBounds?.top ?? 0) - 6;

          double qx = 1, qy = 1;
          if (left > MediaQuery.of(context).size.width / 2) qx = -1;
          if (top > MediaQuery.of(context).size.height / 2) qy = -1;
          final Alignment alignment = PlatformUtils.isMobile
              ? Alignment(0, 0)
              : Alignment(qx, qy);

          if (alignment.x > 0) {
            left += (_key.globalPaintBounds?.width ?? 0);
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              if (PlatformUtils.isMobile)
                Listener(
                  onPointerDown: (_) => registered = true,
                  onPointerUp: (_) {
                    if (registered) {
                      _hoveredMenu = false;
                      _toggleMouseOver(false);
                      _hideAll();
                    }

                    registered = false;
                  },
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
                  ),
                ),
              Positioned(
                left:
                    left +
                    (alignment.x == 0
                        ? -10
                        : alignment.x > 0
                        ? -10
                        : 10),
                top:
                    top +
                    (alignment.y == 0
                        ? 0
                        : alignment.y > 0
                        ? 0
                        : PlatformUtils.isMobile
                        ? 56
                        : 38),
                child: FractionalTranslation(
                  translation: Offset(
                    alignment.x == 0
                        ? 0
                        : alignment.x > 0
                        ? 0
                        : -1,
                    alignment.y == 0
                        ? 0
                        : alignment.y > 0
                        ? 0
                        : -1,
                  ),
                  child: Listener(
                    onPointerDown: (_) => registered = true,
                    onPointerUp: (_) {
                      if (registered) {
                        _hoveredMenu = false;
                        _toggleMouseOver(false);
                        _hideAll();
                      }

                      registered = false;
                    },
                    child: MouseRegion(
                      opaque: true,
                      hitTestBehavior: HitTestBehavior.opaque,
                      onEnter: (_) => _hoveredMenu = true,
                      onExit: (_) {
                        _hoveredMenu = false;

                        if (_entry?.mounted == true) {
                          _entry?.remove();
                        }
                        _entry = null;
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                        child: ContextMenu(actions: widget.actions),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (_entry?.mounted == false) {
        Overlay.of(context, rootOverlay: true).insert(_entry!);
      }
    } else if (!_hoveredMenu) {
      if (_entry?.mounted == true) {
        _entry?.remove();
      }
      _entry = null;
    }
  }

  /// Hides all the overlays out there.
  void _hideAll() {
    for (var e in ContextMenuRegion.overlays.toList()) {
      if (e.mounted) {
        e.hide();
      }
    }

    for (var e in Selector.states.toList()) {
      if (e.mounted) {
        Navigator.of(e.context).pop();
      }
    }
  }
}
