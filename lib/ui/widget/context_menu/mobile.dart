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
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/widget/conditional_backdrop.dart';
import 'package:messenger/ui/page/home/widget/gallery_popup.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';

/// Context menu for mobile platform.
class FloatingContextMenu extends StatefulWidget {
  const FloatingContextMenu({
    Key? key,
    this.alignment = Alignment.bottomCenter,
    required this.actions,
    required this.child,
  }) : super(key: key);

  /// Menu alignment directions.
  final Alignment alignment;

  /// List of [ContextMenuButton]s to display in this [ContextMenu].
  final List<ContextMenuButton> actions;

  /// Widget for displaying the menu.
  final Widget child;

  @override
  State<FloatingContextMenu> createState() => _FloatingContextMenuState();
}

/// State of a [FloatingContextMenu].
class _FloatingContextMenuState extends State<FloatingContextMenu> {
  /// Place in an [Overlay] that can contain a widget.
  OverlayEntry? _entry;

  /// Key that is unique across the entire app.
  final GlobalKey _key = GlobalKey();

  /// [Rect] representing this [_key].
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

  /// Sets [_entry].
  void _populateEntry(BuildContext context) {
    _rect = _key.globalPaintBounds;
    HapticFeedback.selectionClick();
    _entry = OverlayEntry(
      builder: (context) {
        return _AnimatedMenu(
          globalKey: _key,
          alignment: widget.alignment,
          actions: widget.actions,
          onClosed: () {
            _entry?.remove();
            _entry = null;
          },
          child: widget.child,
        );
      },
    );
    Overlay.of(context, rootOverlay: true)?.insert(_entry!);
  }
}

/// Actually creates a menu.
class _AnimatedMenu extends StatefulWidget {
  const _AnimatedMenu({
    Key? key,
    this.onClosed,
    required this.globalKey,
    required this.actions,
    required this.alignment,
    required this.child,
  }) : super(key: key);

  /// Callback, called when menu closes.
  final void Function()? onClosed;

  /// Key that is unique across the entire app.
  final GlobalKey globalKey;

  /// List of [ContextMenuButton]s to display in this [ContextMenu].
  final List<ContextMenuButton> actions;

  /// Menu alignment directions.
  final Alignment alignment;

  /// Widget for displaying the menu.
  final Widget child;

  @override
  State<_AnimatedMenu> createState() => _AnimatedMenuState();
}

/// State of a [_AnimatedMenu].
class _AnimatedMenuState extends State<_AnimatedMenu>
    with SingleTickerProviderStateMixin {
  /// [AnimationController] controlling the opening and closing animation.
  late final AnimationController _fading;

  /// [Rect] of an [Object] to animate positioned.
  late Rect _bounds;

  @override
  void initState() {
    _fading = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )
      ..addStatusListener(
        (AnimationStatus status) {
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

    _bounds = _calculatePosition() ?? Rect.zero;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Animation<double> fade = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _fading,
            curve: const Interval(0, 0.3, curve: Curves.ease),
          ),
        );

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
                    child: AnimatedBuilder(
                      animation: _fading,
                      builder: (context, child) => ConditionalBackdropFilter(
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
                  ),
                  Positioned(
                    left: _bounds.left,
                    width: _bounds.width,
                    height: _bounds.height,
                    bottom: (1 - _fading.value) *
                            (constraints.maxHeight -
                                _bounds.top -
                                _bounds.height) +
                        (10 + widget.actions.length * 50) * _fading.value,
                    child: widget.child,
                  ),
                  Align(
                    alignment: widget.alignment,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: widget.alignment == Alignment.bottomLeft
                            ? _bounds.left
                            : 0,
                        right:
                            widget.alignment == Alignment.bottomRight ? 10 : 0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                          child: SizeTransition(
                            sizeFactor: _fading,
                            child: FadeTransition(
                              opacity: fade,
                              child: _menu(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Creates menu buttons.
  Widget _menu() {
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
      onPointerUp: (_) => _dismiss(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 0),
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
    HapticFeedback.selectionClick();
    _bounds = _calculatePosition() ?? _bounds;
    _fading.reverse();
  }

  /// Returns a [Rect] of an [Object] identified by the provided initial
  /// [GlobalKey].
  Rect? _calculatePosition() => widget.globalKey.globalPaintBounds;
}

/// Context menu for all platforms except mobile.
class ContextMenuActions extends StatelessWidget {
  const ContextMenuActions({
    Key? key,
    this.actions = const [],
    this.backdrop = false,
    this.width = 220,
  }) : super(key: key);


  /// List of [ContextMenuButton]s to display in this [ContextMenu].
  final List<ContextMenuButton> actions;

  /// Indicator whether set background color.
  final bool backdrop;

  /// Menu width.
  final double width;

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    for (int i = 0; i < actions.length; ++i) {
      // Adds a button.
      widgets.add(actions[i]);

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
        color: backdrop ? const Color(0xFFF2F2F2) : const Color(0xAAFFFFFF),
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
