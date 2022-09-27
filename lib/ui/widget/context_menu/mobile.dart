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

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/routes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/overlay.dart';

/// Region to show context menu with animation below the [child] on a long tap.
class FloatingContextMenu extends StatefulWidget {
  const FloatingContextMenu({
    Key? key,
    this.alignment = Alignment.bottomCenter,
    required this.actions,
    required this.child,
    this.id,
  }) : super(key: key);

  /// Widget to show context menu on.
  final Widget child;

  /// List of [ContextMenuButton]s to display in this [FloatingContextMenu].
  final List<ContextMenuButton> actions;

  /// [Alignment] of this [FloatingContextMenu].
  final Alignment alignment;

  /// ID of this [FloatingContextMenu].
  final String? id;

  @override
  State<FloatingContextMenu> createState() => _FloatingContextMenuState();
}

/// State of [FloatingContextMenu] used to show context menu.
class _FloatingContextMenuState extends State<FloatingContextMenu> {
  /// [OverlayEntry] of this [FloatingContextMenu].
  OverlayEntry? _entry;

  /// [GlobalKey] of this [FloatingContextMenu].
  final GlobalKey _key = GlobalKey();

  /// Global [Rect] of the child [Widget].
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
      onLongPress: () {
        _populateEntry(context);
      },
      child: KeyedSubtree(
        key: _key,
        child: _entry == null
            ? widget.child
            : SizedBox(
                width: _rect?.width ?? 1,
                height: _rect?.height ?? 1,
              ),
      ),
    );
  }

  /// Shows context menu with [widget.actions].
  void _populateEntry(BuildContext context) {
    _rect = _key.globalPaintBounds;
    HapticFeedback.selectionClick();
    _entry = OverlayEntry(builder: (context) {
      return _AnimatedMenu(
        globalKey: _key,
        alignment: widget.alignment,
        actions: widget.actions,
        id: widget.id,
        onClosed: () {
          _entry?.remove();
          _entry = null;
          setState(() {});
        },
        child: widget.child,
      );
    });

    setState(() {});

    Overlay.of(context, rootOverlay: true)?.insert(_entry!);
  }
}

/// Animated context menu.
class _AnimatedMenu extends StatefulWidget {
  const _AnimatedMenu({
    required this.child,
    required this.globalKey,
    required this.actions,
    required this.alignment,
    this.id,
    this.onClosed,
    Key? key,
  }) : super(key: key);

  /// [Widget] context menu called on.
  final Widget child;

  /// [GlobalKey] of the [child].
  final GlobalKey globalKey;

  /// Callback, called when a close action of this [_AnimatedMenu] is triggered.
  final void Function()? onClosed;

  /// List of [ContextMenuButton]s to display in this [_AnimatedMenu].
  final List<ContextMenuButton> actions;

  /// [Alignment] of this [_AnimatedMenu].
  final Alignment alignment;

  /// ID of this [_AnimatedMenu].
  final String? id;

  @override
  State<_AnimatedMenu> createState() => _AnimatedMenuState();
}

/// State of [_AnimatedMenu] used to play animation.
class _AnimatedMenuState extends State<_AnimatedMenu>
    with SingleTickerProviderStateMixin {
  /// [AnimationController] controlling the opening and closing animation.
  late final AnimationController _fading;

  /// Global [Rect] of the [widget.child].
  late Rect _bounds;

  @override
  void initState() {
    Future.delayed(Duration.zero,
        () => ContextMenuOverlay.of(context).id.value = widget.id);

    _fading = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _fading,
          curve: const Interval(0, 0.3, curve: Curves.ease),
        ));

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
                          SafeArea(
                            bottom: false,
                            left: false,
                            right: false,
                            child: Padding(
                              padding: EdgeInsets.only(left: _bounds.left),
                              child: SizedBox(
                                width: _bounds.width,
                                height: _bounds.height,
                                child: widget.child,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          _contextMenu(fade),
                        ],
                      ),
                    )
                  else ...[
                    _contextMenu(fade),
                    Positioned(
                      left: _bounds.left,
                      width: _bounds.width,
                      height: _bounds.height,
                      bottom: (1 - _fading.value) *
                              (constraints.maxHeight -
                                  _bounds.top -
                                  _bounds.height) +
                          (10 +
                                  router.context!.mediaQueryPadding.bottom +
                                  widget.actions.length * 50) *
                              _fading.value,
                      child: widget.child,
                    ),
                  ]
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Returns context menu visual representation.
  Widget _contextMenu(Animation<double> fade) {
    return Align(
      alignment: widget.alignment,
      child: Padding(
        padding: EdgeInsets.only(
          left: widget.alignment == Alignment.bottomLeft ? _bounds.left : 0,
          right: widget.alignment == Alignment.bottomRight ? 10 : 0,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: SizeTransition(
              sizeFactor: _fading,
              child: FadeTransition(
                opacity: fade,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: router.context!.mediaQueryPadding.bottom,
                  ),
                  child: _actions(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns [widget.actions] buttons.
  Widget _actions() {
    List<Widget> widgets = [];

    for (int i = 0; i < widget.actions.length; ++i) {
      // Adds a button.
      widgets.add(widget.actions[i]);

      // Adds a divider if required.
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

    return Listener(
      onPointerUp: (d) => _dismiss(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xAAFFFFFF),
            borderRadius: BorderRadius.circular(10),
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
    Future.delayed(
        Duration.zero, () => ContextMenuOverlay.of(context).id.value = null);

    HapticFeedback.selectionClick();
    _bounds = widget.globalKey.globalPaintBounds ?? _bounds;
    _fading.reverse();
  }
}
