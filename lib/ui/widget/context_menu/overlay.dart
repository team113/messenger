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
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

/// Overlay of a context menu.
///
/// Builds context menu in a [Stack] with a [child] as a first element.
class ContextMenuOverlay extends StatefulWidget {
  const ContextMenuOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// Overlay's [Stack] first child.
  final Widget child;

  @override
  ContextMenuOverlayState createState() => ContextMenuOverlayState();

  /// Finds the [ContextMenuOverlayState] from the closest instance of this
  /// class that encloses the given context.
  static ContextMenuOverlayState of(BuildContext context) {
    final ContextMenuOverlayState? result = context
        .dependOnInheritedWidgetOfExactType<_InheritedContextMenu>()
        ?.state;
    assert(result != null, 'No ContextMenuOverlayState found in context');
    return result!;
  }
}

/// State of a [ContextMenuOverlay].
class ContextMenuOverlayState extends State<ContextMenuOverlay> {
  /// Currently opened context menu.
  final Rx<Widget?> _menu = Rx(null);

  /// Size of the [ContextMenuOverlay].
  Size? _area;

  /// Position of the [_menu].
  Offset _position = Offset.zero;

  /// Alignment of this [_menu].
  ///
  /// See [alignment] for details.
  Alignment _alignment = Alignment.bottomRight;

  /// Alignment of current context menu.
  ///
  /// May be:
  /// - `bottomRight`, meaning [_menu] is placed in the bottom right quadrant.
  /// - `bottomLeft`, meaning [_menu] is placed in the bottom left quadrant.
  /// - `topRight`, meaning [_menu] is placed in the top right quadrant.
  /// - `topLeft`, meaning [_menu] is placed in the top left quadrant.
  Alignment get alignment => _alignment;

  /// Returns this [_menu] widget.
  Rx<Widget?> get menu => _menu;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        // Auto-close the menu when app size changes.
        // This is classic context menu behavior at the OS level.
        final Size size = constraints.biggest;
        if (size != _area) {
          _menu.value = null;
          _area = size;
        }

        // Determine on which quadrant of the app the menu in to make sure it
        // always stays in bounds.
        double qx = 1, qy = 1;
        if (_position.dx > (_area?.width ?? 0) / 2) qx = -1;
        if (_position.dy > (_area?.height ?? 0) / 2) qy = -1;
        _alignment = Alignment(qx, qy);

        return _InheritedContextMenu(
          state: this,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                widget.child,
                if (_menu.value != null) ...[
                  // Listens for taps outside the [_menu].
                  Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (d) {
                      // If [kSecondaryButton] was pressed outside the [_menu],
                      // then simulate the [PointerUpDown] and [PointerUpEvent]
                      // for every [RenderPointerListener] on
                      // [BoxHitTestResult]'s path.
                      if (d.buttons & kSecondaryButton != 0) {
                        Future.delayed(
                          Duration.zero,
                          () {
                            final renderObj = context.findRenderObject();
                            if (renderObj is RenderBox) {
                              final result = BoxHitTestResult();
                              if (renderObj.hitTest(result,
                                  position: d.localPosition)) {
                                for (HitTestEntry entry in result.path) {
                                  if (entry.target is RenderPointerListener) {
                                    var target =
                                        entry.target as RenderPointerListener;
                                    target.onPointerDown?.call(d);
                                    target.onPointerUp?.call(
                                      PointerUpEvent(
                                        timeStamp: d.timeStamp,
                                        pointer: d.pointer,
                                        kind: d.kind,
                                        device: d.device,
                                        position: d.position,
                                        buttons: d.buttons,
                                        obscured: d.obscured,
                                        pressure: d.pressure,
                                        pressureMin: d.pressureMin,
                                        pressureMax: d.pressureMax,
                                        distance: d.distance,
                                        distanceMax: d.distanceMax,
                                        size: d.size,
                                        radiusMajor: d.radiusMajor,
                                        radiusMinor: d.radiusMinor,
                                        radiusMin: d.radiusMin,
                                        radiusMax: d.radiusMax,
                                        orientation: d.orientation,
                                        tilt: d.tilt,
                                        embedderId: d.embedderId,
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          },
                        );
                      }

                      // And hide current menu.
                      hide();
                    },
                  ),
                  // Draws [_menu] at [_position] with [alignment] translation.
                  Positioned(
                    left: _position.dx,
                    top: _position.dy,
                    child: FractionalTranslation(
                      translation: Offset(
                        _alignment.x > 0 ? 0 : -1,
                        _alignment.y > 0 ? 0 : -1,
                      ),
                      child: IntrinsicWidth(child: _menu.value),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  /// Sets the current menu to [child] at [position].
  void show(Widget child, Offset position) => setState(() {
        _position = position;
        _menu.value = child;
      });

  /// Hides the current menu if there is one.
  void hide() => setState(() => _menu.value = null);
}

/// [InheritedWidget] of a [_ContextMenuOverlayState] used to implement
/// [ContextMenuOverlay.of] to show and hide the context menu from widget tree.
class _InheritedContextMenu extends InheritedWidget {
  const _InheritedContextMenu({
    Key? key,
    required Widget child,
    required this.state,
  }) : super(key: key, child: child);

  /// State of the [ContextMenuOverlay].
  final ContextMenuOverlayState state;

  @override
  bool updateShouldNotify(_InheritedContextMenu old) => old.state != state;
}
