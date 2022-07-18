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
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:messenger/util/platform_utils.dart';

import '../menu_interceptor/menu_interceptor.dart';
import 'overlay.dart';

/// Region of a context [menu] over a [child], showed on a secondary mouse click
/// or a long tap.
class ContextMenuRegion extends StatefulWidget {
  const ContextMenuRegion({
    Key? key,
    required this.child,
    required this.menu,
    this.enabled = true,
    this.preventContextMenu = true,
    this.usePointerDown = false,
    this.enableLongTap = true,
    this.decoration,
  }) : super(key: key);

  /// Widget to wrap this region over.
  final Widget child;

  /// Context menu to show.
  final Widget menu;

  /// Indicator whether this region should be enabled.
  final bool enabled;

  /// Indicator whether a default context menu should be prevented or not.
  ///
  /// Only effective under the web, since only web has a default context menu.
  final bool preventContextMenu;

  /// If true shows context menu if user taps pointer down.
  /// Else context menu will be shown on pointer up.
  final bool usePointerDown;

  /// If true shows context menu on long tap press.
  final bool enableLongTap;

  /// On message select fill decoration.
  final BoxDecoration? decoration;

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
  Widget build(BuildContext context) => widget.enabled
      ? ContextMenuInterceptor(
          enabled: widget.preventContextMenu,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (d) {
              if (widget.usePointerDown) {
                _buttons = 0;
                if (d.buttons & kSecondaryButton != 0) {
                  ContextMenuOverlay.of(context).show(widget.menu, d.position);
                }
              } else {
                _buttons = d.buttons;
              }
            },
            onPointerUp: (d) {
              if (_buttons & kSecondaryButton != 0) {
                ContextMenuOverlay.of(context).show(widget.menu, d.position);
              }
            },
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPressStart: widget.enableLongTap
                      ? (d) => ContextMenuOverlay.of(context)
                          .show(widget.menu, d.globalPosition)
                      : null,
                  child: widget.child,
                ),
                if (context.isMobile)
                  Positioned.fill(
                    child: Obx(() {
                      if (ContextMenuOverlay.of(context).menu.value ==
                          widget.menu) {
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: widget.decoration?.copyWith(
                                color: const Color(0x11000000),
                              ) ??
                              const BoxDecoration(color: Color(0x22000000)),
                        );
                      }

                      return Container();
                    }),
                  ),
              ],
            ),
          ),
        )
      : widget.child;
}
