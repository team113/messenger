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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../menu_interceptor/menu_interceptor.dart';
import '/util/platform_utils.dart';
import '/themes.dart';
import 'menu.dart';
import 'mobile.dart';
import 'overlay.dart';

/// Region of a context menu over a [child], showed on a secondary mouse click
/// or a long tap.
class ContextMenuRegion extends StatefulWidget {
  const ContextMenuRegion({
    Key? key,
    required this.child,
    this.enabled = true,
    this.preventContextMenu = true,
    this.usePointerDown = false,
    this.enableLongTap = true,
    this.alignment = Alignment.bottomCenter,
    this.actions,
    this.id,
  }) : super(key: key);

  /// Widget to wrap this region over.
  final Widget child;

  /// ID of this [ContextMenuRegion].
  final String? id;

  /// Indicator whether this region should be enabled.
  final bool enabled;

  /// [Alignment] of context menu on mobile.
  final Alignment alignment;

  /// [ContextMenuButton] to show.
  final List<ContextMenuButton>? actions;

  /// Indicator whether a default context menu should be prevented or not.
  ///
  /// Only effective under the web, since only web has a default context menu.
  final bool preventContextMenu;

  /// Indicator whether context menu should be displayed on pointer down.
  final bool usePointerDown;

  /// Indicator whether context menu should be displayed on long tap.
  final bool enableLongTap;

  @override
  State<ContextMenuRegion> createState() => _ContextMenuRegionState();
}

/// State of [ContextMenuRegion] used to keep track of [_buttons].
class _ContextMenuRegionState extends State<ContextMenuRegion> {
  /// Bit field of [PointerDownEvent]'s buttons.
  ///
  /// [PointerUpEvent] doesn't contain the button being released, so it's
  /// required to store the buttons from.
  int _buttons = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.enabled) {
      return ContextMenuInterceptor(
        enabled: widget.preventContextMenu,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (d) {
            if (widget.usePointerDown) {
              _buttons = 0;
              if (d.buttons & kSecondaryButton != 0) {
                _show(d.position);
              }
            } else {
              _buttons = d.buttons;
            }
          },
          onPointerUp: (d) {
            if (_buttons & kSecondaryButton != 0) {
              _show(d.position);
            }
          },
          child: Stack(
            children: [
              if (PlatformUtils.isMobile)
                FloatingContextMenu(
                  id: widget.id,
                  alignment: widget.alignment,
                  actions: widget.actions ?? [],
                  child: widget.child,
                )
              else
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPressStart: widget.enableLongTap
                      ? (d) => ContextMenuOverlay.of(context).show(
                            ContextMenuActions(
                              actions: widget.actions ?? [],
                            ),
                            d.globalPosition,
                          )
                      : null,
                  child: widget.child,
                ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }

  /// Shows context menu with [widget.actions].
  void _show(Offset position) {
    if (widget.actions?.isNotEmpty != true) {
      return;
    }

    showDialog(
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        return LayoutBuilder(builder: (context, constraints) {
          double qx = 1, qy = 1;
          if (position.dx > (constraints.maxWidth) / 2) qx = -1;
          if (position.dy > (constraints.maxHeight) / 2) qy = -1;
          Alignment alignment = Alignment(qx, qy);

          return Listener(
            onPointerUp: (d) => Navigator.of(context).pop(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: FractionalTranslation(
                    translation: Offset(
                      alignment.x > 0 ? 0 : -1,
                      alignment.y > 0 ? 0 : -1,
                    ),
                    child: ContextMenuActions(
                      actions: widget.actions ?? [],
                    ),
                  ),
                )
              ],
            ),
          );
        });
      },
    );

    return;
  }
}

/// Context menu actions buttons.
class ContextMenuActions extends StatelessWidget {
  const ContextMenuActions({
    Key? key,
    this.actions = const [],
    this.width = 220,
  }) : super(key: key);

  /// Width of this [ContextMenuActions].
  final double width;

  /// List of [ContextMenuButton]s to display in this [ContextMenu].
  final List<ContextMenuButton> actions;

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    for (int i = 0; i < actions.length; ++i) {
      // Adds a button.
      widgets.add(
        actions[i],
      );

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

    return Container(
      width: width,
      margin: const EdgeInsets.only(left: 1, top: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          CustomBoxShadow(
            blurRadius: 8,
            color: Color(0x33000000),
            blurStyle: BlurStyle.outer,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
        ),
      ),
    );
  }
}
