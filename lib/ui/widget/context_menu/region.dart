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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../menu_interceptor/menu_interceptor.dart';
import '/themes.dart';
import '/ui/widget/selector.dart';
import '/util/platform_utils.dart';
import 'menu.dart';
import 'mobile.dart';

/// Region of a context menu over a [child], showed on a secondary mouse click
/// or a long tap.
///
/// Depending on the current platform it displays:
/// - [ContextMenu] or [Selector] on desktop;
/// - [FloatingContextMenu] on mobile.
class ContextMenuRegion extends StatefulWidget {
  const ContextMenuRegion({
    Key? key,
    required this.child,
    this.enabled = true,
    this.moveDownwards = true,
    this.preventContextMenu = true,
    this.enableLongTap = true,
    this.alignment = Alignment.bottomCenter,
    this.actions = const [],
    this.selector,
    this.width = 260,
    this.margin = EdgeInsets.zero,
    this.darkenable = false,
  }) : super(key: key);

  /// Widget to wrap this region over.
  final Widget child;

  /// Indicator whether this region should be enabled.
  final bool enabled;

  /// Indicator whether a [FloatingContextMenu] this region displays should
  /// animate the [child] moving downwards.
  final bool moveDownwards;

  /// [Alignment] of a [FloatingContextMenu] this region displays.
  final Alignment alignment;

  /// [ContextMenuButton]s representing the actions of the context menu.
  final List<ContextMenuButton> actions;

  /// Indicator whether a default context menu should be prevented or not.
  ///
  /// Only effective under the web, since only web has a default context menu.
  final bool preventContextMenu;

  /// Indicator whether context menu should be displayed on a long tap.
  final bool enableLongTap;

  /// [GlobalKey] of a [Selector.buttonKey].
  ///
  /// If specified, then this [ContextMenuRegion] will display a [Selector]
  /// instead of a [ContextMenu].
  final GlobalKey? selector;

  /// Width of a [Selector].
  ///
  /// Only meaningful, if [selector] is specified.
  final double width;

  /// Margin to apply to a [Selector] on desktop or to [FloatingContextMenu] on
  /// mobile.
  final EdgeInsets margin;

  /// Indicator whether this [ContextMenuRegion] can be darkened.
  final bool darkenable;

  @override
  State<ContextMenuRegion> createState() => _ContextMenuRegionState();
}

class _ContextMenuRegionState extends State<ContextMenuRegion> {
  /// Indicator whether to darken this [ContextMenuRegion].
  bool _darkened = false;

  @override
  Widget build(BuildContext context) {
    final Widget child;

    if (_darkened && PlatformUtils.isDesktop) {
      final Style style = Theme.of(context).extension<Style>()!;
      child = Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: Container(
              color: style.cardHoveredColor.withOpacity(0.4),
            ),
          ),
        ],
      );
    } else {
      child = widget.child;
    }

    if (widget.enabled && widget.actions.isNotEmpty) {
      return ContextMenuInterceptor(
        enabled: widget.preventContextMenu,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (d) {
            if (d.buttons & kSecondaryButton != 0) {
              _show(context, d.position);
            }
          },
          child: PlatformUtils.isMobile
              ? FloatingContextMenu(
                  alignment: widget.alignment,
                  moveDownwards: widget.moveDownwards,
                  actions: widget.actions,
                  margin: widget.margin,
                  child: child,
                )
              : GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPressStart: widget.enableLongTap
                      ? (d) => _show(context, d.globalPosition)
                      : null,
                  child: child,
                ),
        ),
      );
    }

    return child;
  }

  /// Shows the [ContextMenu] wrapping the [widget.actions].
  Future<void> _show(BuildContext context, Offset position) async {
    if (widget.actions.isEmpty) {
      return;
    }

    if (widget.darkenable) {
      setState(() => _darkened = true);
    }

    if (widget.selector != null) {
      await Selector.show<ContextMenuButton>(
        context: context,
        items: widget.actions,
        width: widget.width,
        margin: widget.margin,
        buttonBuilder: (i, b) {
          return Padding(
            padding: EdgeInsets.only(
              top: i == 0 ? 6 : 0,
              bottom: i == widget.actions.length - 1 ? 6 : 0,
            ),
            child: b,
          );
        },
        itemBuilder: (b) {
          final TextStyle? thin = Theme.of(context)
              .textTheme
              .caption
              ?.copyWith(color: Colors.black);
          return Row(
            children: [
              if (b.leading != null) ...[b.leading!, const SizedBox(width: 12)],
              Text(b.label, style: thin?.copyWith(fontSize: 15)),
              if (b.trailing != null) ...[
                const SizedBox(width: 12),
                b.trailing!,
              ],
            ],
          );
        },
        onSelected: (b) => b.onPressed?.call(),
        buttonKey: widget.selector,
        alignment: Alignment(-widget.alignment.x, -widget.alignment.y),
      );
    } else {
      await showDialog(
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
                      child: ContextMenu(actions: widget.actions),
                    ),
                  )
                ],
              ),
            );
          });
        },
      );
    }

    if (widget.darkenable) {
      setState(() => _darkened = false);
    }
  }
}
