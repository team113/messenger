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

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../menu_interceptor/menu_interceptor.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/selector.dart';
import '/util/platform_utils.dart';
import 'menu.dart';
import 'menu_overlay.dart';
import 'mobile.dart';

/// Region of a context menu over a [child], showed on a secondary mouse click
/// or a long tap.
///
/// Depending on the current platform it displays:
/// - [ContextMenu] or [Selector] on desktop;
/// - [FloatingContextMenu] on mobile.
class ContextMenuRegion extends StatefulWidget {
  const ContextMenuRegion({
    super.key,
    this.child,
    this.builder,
    this.enabled = true,
    this.moveDownwards = true,
    this.preventContextMenu = true,
    this.enableLongTap = true,
    this.enablePrimaryTap = false,
    this.enableSecondaryTap = true,
    this.alignment = Alignment.bottomCenter,
    this.actions = const [],
    this.selector,
    this.selectorClosable = true,
    this.width = 260,
    this.margin = EdgeInsets.zero,
    this.indicateOpenedMenu = false,
    this.unconstrained = false,
  });

  /// Widget to wrap this region over.
  ///
  /// Ignored, if [builder] is specified.
  final Widget? child;

  /// Builder building a [Widget] to wrap this region over depending on whether
  /// the [ContextMenu] is displayed.
  ///
  /// [child] is ignored, if [builder] is specified.
  final Widget Function(bool)? builder;

  /// Indicator whether this region should be enabled.
  final bool enabled;

  /// Indicator whether a [FloatingContextMenu] this region displays should
  /// animate the [child] moving downwards.
  final bool moveDownwards;

  /// [Alignment] of a [FloatingContextMenu] this region displays.
  final Alignment alignment;

  /// [ContextMenuItem]s representing the actions of the context menu.
  final List<ContextMenuItem> actions;

  /// Indicator whether a default context menu should be prevented or not.
  ///
  /// Only effective under the web, since only web has a default context menu.
  final bool preventContextMenu;

  /// Indicator whether context menu should be displayed on a long tap.
  final bool enableLongTap;

  /// Indicator whether context menu should be displayed on a primary tap.
  final bool enablePrimaryTap;

  /// Indicator whether context menu should be displayed on a secondary tap.
  final bool enableSecondaryTap;

  /// [GlobalKey] of a [Selector.buttonKey].
  ///
  /// If specified, then this [ContextMenuRegion] will display a [Selector]
  /// instead of a [ContextMenu].
  final GlobalKey? selector;

  /// Indicator whether [Selector.onPointerUp] should pop the [Navigator].
  ///
  /// If `false`, then [ContextMenuItem]s pressed should pop it themselves.
  final bool selectorClosable;

  /// Width of a [Selector].
  ///
  /// Only meaningful, if [selector] is specified.
  final double width;

  /// Margin to apply to a [Selector] on desktop or to [FloatingContextMenu] on
  /// mobile.
  final EdgeInsets margin;

  /// Indicator whether this [ContextMenuRegion] should display a [ColoredBox]
  /// above the [child] when a [ContextMenu] is opened.
  final bool indicateOpenedMenu;

  /// Indicator whether the [child] should be unconstrained.
  final bool unconstrained;

  @override
  State<ContextMenuRegion> createState() => _ContextMenuRegionState();
}

/// State of a [ContextMenuRegion] keeping the [_darkened] indicator.
class _ContextMenuRegionState extends State<ContextMenuRegion> {
  /// Indicator whether a [ColoredBox] should be displayed above the provided
  /// child.
  bool _darkened = false;

  /// Indicator whether [ContextMenu] is displayed.
  bool _displayed = false;

  /// [OverlayEntry] displaying a currently opened [ContextMenuOverlay].
  OverlayEntry? _entry;

  /// [RouterState.routes] subscription closing the [ContextMenu] whenever the
  /// current route changes.
  StreamSubscription? _routesSubscription;

  @override
  void initState() {
    // Close the [ContextMenu], when the route changes.
    _routesSubscription = router.routes.listen((e) {
      if (_entry?.mounted == true) {
        _entry?.remove();
        _entry = null;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _routesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget builder() {
      if (widget.builder == null) {
        return widget.child!;
      }

      return widget.builder!(_displayed);
    }

    final Widget child;

    if (_darkened && PlatformUtils.isDesktop) {
      final style = Theme.of(context).style;

      child = Stack(
        children: [
          builder(),
          Positioned.fill(
            child: ColoredBox(
              color: style.cardColor.darken(0.03).withValues(alpha: 0.4),
            ),
          ),
        ],
      );
    } else {
      child = builder();
    }

    if (widget.enabled && widget.actions.isNotEmpty) {
      Widget menu;

      if (PlatformUtils.isMobile && widget.selector == null) {
        menu = FloatingContextMenu(
          alignment: widget.alignment,
          moveDownwards: widget.moveDownwards,
          actions: widget.actions,
          margin: widget.margin,
          unconstrained: widget.unconstrained,
          onOpened: () => _displayed = true,
          onClosed: () => _displayed = false,
          child: widget.builder == null
              ? child
              // Wrap [widget.builder] with [Builder] to trigger
              // [ContextMenuRegion.builder] on [setState].
              : Builder(builder: (_) => widget.builder!(_displayed)),
        );
      } else {
        menu = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPressStart: widget.enableLongTap
              ? (d) => _show(d.globalPosition)
              : null,
          child: widget.builder == null ? child : widget.builder!(_displayed),
        );

        if (widget.enablePrimaryTap) {
          menu = MouseRegion(
            opaque: false,
            cursor: SystemMouseCursors.click,
            child: menu,
          );
        }
      }

      return ContextMenuInterceptor(
        enabled: widget.preventContextMenu,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (d) {
            if ((widget.enableSecondaryTap &&
                    d.buttons & kSecondaryButton != 0) ||
                (widget.enablePrimaryTap && d.buttons & kPrimaryButton != 0)) {
              _show(d.position);
            }
          },
          child: menu,
        ),
      );
    }

    return child;
  }

  /// Shows the [ContextMenu] wrapping the [ContextMenuRegion.actions].
  Future<void> _show(Offset position) async {
    final style = Theme.of(context).style;

    if (widget.actions.isEmpty) {
      return;
    }

    if (_displayed) {
      _entry?.remove();
      _entry = null;
      _displayed = false;

      // Ensure that the old [ContextMenu]'s closing callbacks are processed
      // before opening a new one.
      await Future.microtask(() {});
    }

    if (!mounted) {
      return;
    }

    HapticFeedback.lightImpact();

    _displayed = true;
    if (widget.indicateOpenedMenu) {
      _darkened = true;
    }

    setState(() {});

    if (widget.selector != null) {
      await Selector.show<ContextMenuItem>(
        context: context,
        items: widget.actions,
        width: widget.width,
        margin: widget.margin,
        buttonBuilder: (i, b) {
          if (PlatformUtils.isMobile) {
            return Column(mainAxisSize: MainAxisSize.min, children: [b]);
          }

          return Padding(
            padding: EdgeInsets.only(
              top: i == 0 ? 4 : 0,
              bottom: i == widget.actions.length - 1 ? 4 : 0,
            ),
            child: b,
          );
        },
        itemBuilder: (b) {
          if (b is ContextMenuButton) {
            return Row(
              children: [
                Text(b.label, style: style.fonts.normal.regular.onBackground),
                if (b.trailing != null) ...[
                  const SizedBox(width: 12),
                  b.trailing!,
                ],
              ],
            );
          }

          return const SizedBox();
        },
        onSelected: (b) => b is ContextMenuButton ? b.onPressed?.call() : {},
        buttonKey: widget.selector,
        alignment: Alignment(-widget.alignment.x, -widget.alignment.y),
        onPointerUp: widget.selectorClosable
            ? (context) => Navigator.of(context).pop()
            : null,
      );

      _displayed = false;
      if (widget.indicateOpenedMenu) {
        _darkened = false;
      }
      if (mounted) {
        setState(() {});
      }
    } else {
      _entry = OverlayEntry(
        builder: (_) {
          return ContextMenuOverlay(
            position: position,
            actions: widget.actions,
            onClosed: () => _darkened = false,
            onDismissed: () {
              _displayed = false;
              if (mounted) {
                setState(() {});
              }

              _entry?.remove();
              _entry = null;
            },
          );
        },
      );

      Overlay.of(context, rootOverlay: true).insert(_entry!);
    }
  }
}
