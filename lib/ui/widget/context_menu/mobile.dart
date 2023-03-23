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

import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/context_menu/menu.dart';

/// Animated context menu optimized and decorated for mobile screens.
class FloatingContextMenu extends StatefulWidget {
  const FloatingContextMenu({
    super.key,
    this.alignment = Alignment.bottomCenter,
    required this.actions,
    required this.child,
    this.moveDownwards = true,
    this.margin = EdgeInsets.zero,
    this.onOpened,
    this.onClosed,
    this.unconstrained = false,
  });

  /// [Widget] this [FloatingContextMenu] is about.
  final Widget child;

  /// [ContextMenuItem]s representing actions of this [FloatingContextMenu].
  final List<ContextMenuItem> actions;

  /// [Alignment] of this [FloatingContextMenu].
  final Alignment alignment;

  /// Indicator whether this [FloatingContextMenu] should animate the [child]
  /// moving downwards.
  final bool moveDownwards;

  /// Margin to apply to this [FloatingContextMenu].
  final EdgeInsets margin;

  /// Callback, called when this [FloatingContextMenu] opens.
  final void Function()? onOpened;

  /// Callback, called when this [FloatingContextMenu] closes.
  final void Function()? onClosed;

  /// Indicator whether the [child] should be unconstrained.
  final bool unconstrained;

  @override
  State<FloatingContextMenu> createState() => _FloatingContextMenuState();
}

/// State of a [FloatingContextMenu] maintaining the [OverlayEntry] with
/// [_AnimatedMenu].
class _FloatingContextMenuState extends State<FloatingContextMenu> {
  /// [OverlayEntry] to maintain.
  OverlayEntry? _entry;

  /// [GlobalKey] of the [FloatingContextMenu.child] to get its position.
  final GlobalKey _globalKey = GlobalKey();

  /// [GlobalKey] of the [FloatingContextMenu.actions] to get their height.
  final GlobalKey _actionsKey = GlobalKey();

  /// [Rect] of the [FloatingContextMenu.child] to animate the [_entry] to.
  Rect? _rect;

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => _populateEntry(context),
      child: KeyedSubtree(
        key: _globalKey,
        child: _entry == null || !widget.moveDownwards
            ? widget.child
            : SizedBox(
                width: _rect?.width ?? 1,
                height: _rect?.height ?? 1,
              ),
      ),
    );
  }

  /// Populates the [_entry] with [_AnimatedMenu].
  Future<void> _populateEntry(BuildContext context) async {
    HapticFeedback.selectionClick();

    widget.onOpened?.call();

    _rect = _globalKey.globalPaintBounds;
    _entry = OverlayEntry(builder: (context) {
      return _AnimatedMenu(
        globalKey: _globalKey,
        actionsKey: _actionsKey,
        alignment: widget.alignment,
        actions: widget.actions,
        showAbove: !widget.moveDownwards,
        margin: widget.margin,
        unconstrained: widget.unconstrained,
        onClosed: () {
          widget.onClosed?.call();

          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (_entry?.mounted == true) {
              _entry?.remove();
              _entry = null;
            }
            if (mounted) {
              setState(() {});
            }
          });
        },
        child: widget.child,
      );
    });

    setState(() {});

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }
}

/// Animated floating context menu.
class _AnimatedMenu extends StatefulWidget {
  const _AnimatedMenu({
    required this.child,
    required this.globalKey,
    required this.actionsKey,
    required this.actions,
    required this.alignment,
    required this.showAbove,
    required this.margin,
    this.onClosed,
    this.unconstrained = false,
    Key? key,
  }) : super(key: key);

  /// [Widget] this [_AnimatedMenu] is bound to.
  final Widget child;

  /// [GlobalKey] of the [child].
  final GlobalKey globalKey;

  /// [GlobalKey] of the [actions].
  final GlobalKey actionsKey;

  /// Callback, called when this [_AnimatedMenu] is closed.
  final void Function()? onClosed;

  /// [ContextMenuItem]s to display in this [_AnimatedMenu].
  final List<ContextMenuItem> actions;

  /// [Alignment] of this [_AnimatedMenu].
  final Alignment alignment;

  /// Indicator whether this [_AnimatedMenu] should be displayed above the
  /// [child] or otherwise animate the [child] moving downwards.
  final bool showAbove;

  /// Margin to apply to this [_AnimatedMenu].
  final EdgeInsets margin;

  /// Indicator whether the [child] should be unconstrained.
  final bool unconstrained;

  @override
  State<_AnimatedMenu> createState() => _AnimatedMenuState();
}

/// State of an [_AnimatedMenu] maintaining the animation.
class _AnimatedMenuState extends State<_AnimatedMenu>
    with SingleTickerProviderStateMixin {
  /// [AnimationController] controlling the animation.
  late final AnimationController _fading;

  /// [Rect] of the [_AnimatedMenu.child].
  late Rect _bounds;

  /// [Rect] of the [_AnimatedMenu.actions].
  Rect? _actionsBounds;

  /// [Offset] of a [PointerDownEvent] used to [_dismiss] this [_AnimatedMenu]
  /// when it's low enough.
  Offset? _pointerDown;

  @override
  void initState() {
    _fading = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      debugLabel: '$runtimeType',
    )
      ..addStatusListener(
        (status) {
          switch (status) {
            case AnimationStatus.dismissed:
              widget.onClosed?.call();
              break;

            case AnimationStatus.reverse:
            case AnimationStatus.forward:
            case AnimationStatus.completed:
              // No-op.
              break;
          }
        },
      )
      ..forward();

    _bounds = widget.globalKey.globalPaintBounds ?? Rect.zero;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actionsBounds = widget.actionsKey.globalPaintBounds;
    });

    super.initState();
  }

  @override
  void dispose() {
    _fading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Animation<double> fade = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _fading,
            curve: const Interval(0, 0.3, curve: Curves.ease),
          ),
        );

        Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _fading, curve: Curves.ease));

        return GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: _dismiss,
          child: AnimatedBuilder(
            animation: _fading,
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _dismiss,
                    child: ConditionalBackdropFilter(
                      condition: !widget.showAbove,
                      filter: ImageFilter.blur(
                        sigmaX: 0.01 + 10 * _fading.value,
                        sigmaY: 0.01 + 10 * _fading.value,
                      ),
                      child: Container(
                        color: Color.fromARGB(
                          (kCupertinoModalBarrierColor.alpha * _fading.value)
                              .toInt(),
                          kCupertinoModalBarrierColor.red,
                          kCupertinoModalBarrierColor.green,
                          kCupertinoModalBarrierColor.blue,
                        ),
                      ),
                    ),
                  ),
                  if (_fading.value == 1)
                    SingleChildScrollView(
                      reverse: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!widget.showAbove)
                            SafeArea(
                              right: false,
                              top: true,
                              left: false,
                              bottom: false,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left:
                                      widget.unconstrained ? 10 : _bounds.left,
                                ),
                                child: SizedBox(
                                  width: widget.unconstrained
                                      ? null
                                      : _bounds.width,
                                  height: widget.unconstrained
                                      ? null
                                      : _bounds.height,
                                  child: widget.child,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          _contextMenu(fade, slide),
                        ],
                      ),
                    )
                  else ...[
                    if (!widget.showAbove)
                      Positioned(
                        left: widget.unconstrained
                            ? (10 * _fading.value +
                                _bounds.left * (1 - _fading.value))
                            : _bounds.left,
                        width: widget.unconstrained
                            ? (_bounds.width +
                                    (constraints.maxWidth - _bounds.width) *
                                        _fading.value) -
                                (20 * _fading.value)
                            : _bounds.width,
                        height: widget.unconstrained
                            ? (_bounds.height +
                                (constraints.maxHeight / 2 - _bounds.height) *
                                    _fading.value)
                            : _bounds.height,
                        bottom: (1 - _fading.value) *
                                (constraints.maxHeight -
                                    _bounds.top -
                                    _bounds.height) +
                            (10 +
                                    router.context!.mediaQueryPadding.bottom +
                                    (_actionsBounds?.height ??
                                        widget.actions.length * 50)) *
                                _fading.value,
                        child: IgnorePointer(child: widget.child),
                      ),
                    _contextMenu(fade, slide),
                  ]
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Returns a visual representation of the context menu itself.
  Widget _contextMenu(Animation<double> fade, Animation<Offset> slide) {
    final double width = MediaQuery.of(context).size.width;
    EdgeInsets padding;

    if (widget.alignment == Alignment.bottomLeft ||
        widget.alignment == Alignment.bottomRight) {
      const double minWidth = 230;
      final double menuWidth = _bounds.right - _bounds.left;

      if (widget.alignment == Alignment.bottomLeft) {
        padding = EdgeInsets.only(
          left: _bounds.left - 5,
          right: menuWidth < minWidth
              ? width - _bounds.left - minWidth
              : width - _bounds.right - 5,
        );
      } else {
        padding = EdgeInsets.only(
          left: menuWidth < minWidth
              ? _bounds.right - minWidth
              : _bounds.left - 5,
          right: width - _bounds.right - 5,
        );
      }

      if (padding.left < 3) {
        padding = EdgeInsets.only(
          left: 3,
          right: width - minWidth - 8,
        );
      }
    } else if (widget.unconstrained) {
      padding = const EdgeInsets.only(left: 0, right: 0);
    } else {
      padding = EdgeInsets.only(
        left: max(0, _bounds.left - 10),
        right: max(0, width - _bounds.right - 10),
      );
    }

    return Align(
      alignment: widget.alignment,
      child: Padding(
        padding: widget.margin.add(padding),
        child: SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: fade,
            child: Padding(
              key: widget.actionsKey,
              padding: EdgeInsets.only(
                bottom: 10 + router.context!.mediaQueryPadding.bottom,
              ),
              child: _actions(),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the [_AnimatedMenu.actions].
  Widget _actions() {
    List<Widget> widgets = [];

    for (int i = 0; i < widget.actions.length; ++i) {
      if (widget.actions[i] is! ContextMenuDivider) {
        widgets.add(widget.actions[i]);

        // Add a divider, if required.
        if (i < widget.actions.length - 1) {
          widgets.add(
            Container(
              color: const Color(0x11000000),
              height: 1,
              width: double.infinity,
            ),
          );
        }
      }
    }

    final Style style = Theme.of(context).extension<Style>()!;

    return Listener(
      onPointerUp: (d) {
        if (_pointerDown != null &&
            (_pointerDown!.distance - d.position.distance).abs() < 7) {
          _dismiss();
        }
      },
      onPointerDown: (d) => _pointerDown = d.position,
      child: ClipRRect(
        borderRadius: style.contextMenuRadius,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minWidth: 240),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: style.contextMenuBackgroundColor,
            borderRadius: style.contextMenuRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets,
          ),
        ),
      ),
    );
  }

  /// Starts a dismiss animation.
  void _dismiss() {
    HapticFeedback.selectionClick();
    _bounds = widget.globalKey.globalPaintBounds ?? _bounds;
    _fading.reverse();
  }
}
