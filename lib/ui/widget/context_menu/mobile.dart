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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/widget/conditional_backdrop.dart';
import 'package:messenger/ui/page/home/widget/gallery_popup.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/overlay.dart';

class FloatingContextMenu extends StatefulWidget {
  const FloatingContextMenu({
    Key? key,
    this.alignment = Alignment.bottomCenter,
    required this.actions,
    required this.child,
    this.id,
  }) : super(key: key);

  final Widget child;

  /// List of [ContextMenuButton]s to display in this [ContextMenu].
  final List<ContextMenuButton> actions;

  final Alignment alignment;
  final String? id;

  @override
  State<FloatingContextMenu> createState() => _FloatingContextMenuState();
}

class _FloatingContextMenuState extends State<FloatingContextMenu> {
  OverlayEntry? _entry;

  final GlobalKey _key = GlobalKey();
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

  final Widget child;
  final GlobalKey globalKey;
  final void Function()? onClosed;

  /// List of [ContextMenuButton]s to display in this [ContextMenu].
  final List<ContextMenuButton> actions;

  final Alignment alignment;

  final String? id;

  @override
  State<_AnimatedMenu> createState() => _AnimatedMenuState();
}

class _AnimatedMenuState extends State<_AnimatedMenu>
    with SingleTickerProviderStateMixin {
  /// [AnimationController] controlling the opening and closing animation.
  late final AnimationController _fading;

  /// [Rect] of an [Object] to animate this [NekoView] from/to.
  late Rect _bounds;

  /// Discard the first [LayoutBuilder] frame since no widget is drawn yet.
  bool _firstLayout = true;

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

    _bounds = _calculatePosition() ?? Rect.zero;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_firstLayout) {
          _firstLayout = false;
        }

        var curved = CurvedAnimation(
          parent: _fading,
          curve: Curves.ease,
          reverseCurve: Curves.ease,
        );

        var fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _fading,
          curve: const Interval(0, 0.3, curve: Curves.ease),
        ));

        RelativeRectTween tween() => RelativeRectTween(
              begin: RelativeRect.fromSize(_bounds, constraints.biggest),
              end: RelativeRect.fill,
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
                  if (false)
                    Positioned(
                      left: widget.alignment == Alignment.bottomLeft ? 0 : null,
                      right:
                          widget.alignment == Alignment.bottomRight ? 0 : null,
                      bottom: (1 - _fading.value) *
                          (constraints.maxHeight -
                              _bounds.top -
                              _bounds.height),
                      child: ConstrainedBox(
                        constraints: constraints,
                        child: SingleChildScrollView(
                          reverse: true,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: widget.alignment == Alignment.bottomLeft
                                  ? _bounds.left
                                  : 0,
                              right: widget.alignment == Alignment.bottomRight
                                  ? 10
                                  : 0,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  widget.alignment == Alignment.bottomLeft
                                      ? CrossAxisAlignment.start
                                      : CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: _bounds.width,
                                  height: _bounds.height,
                                  child: widget.child,
                                ),
                                Align(
                                  alignment: widget.alignment,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 220),
                                    child: SizeTransition(
                                      sizeFactor: _fading,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            4, 0, 4, 4),
                                        child: FadeTransition(
                                          opacity: fade,
                                          child: _menu(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (true)
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
                  if (true)
                    Align(
                      alignment: widget.alignment,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: widget.alignment == Alignment.bottomLeft
                              ? _bounds.left
                              : 0,
                          right: widget.alignment == Alignment.bottomRight
                              ? 10
                              : 0,
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
                  if (false)
                    AnimatedBuilder(
                      animation: _fading,
                      builder: (context, child) {
                        return PositionedTransition(
                          rect: tween().animate(curved),
                          child: GestureDetector(
                            behavior: HitTestBehavior.deferToChild,
                            onTap: _dismiss,
                            child: Center(
                              child: SingleChildScrollView(
                                reverse: true,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizeTransition(
                                      sizeFactor: _fading,
                                      child: const SizedBox(height: 16),
                                    ),
                                    SizedBox(
                                      width: _bounds.width,
                                      height: _bounds.height,
                                      child: widget.child,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: SizeTransition(
                                        sizeFactor: _fading,
                                        child: FadeTransition(
                                          opacity: fade,
                                          child: _menu(),
                                        ),
                                      ),
                                    ),
                                    SizeTransition(
                                      sizeFactor: _fading,
                                      child: const SizedBox(height: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _menu() {
    List<Widget> widgets = [];

    /*widgets.add(
      Container(
        height: 30,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.only(left: 8),
                  //   child: Text('Информация'),
                  // ),
                ],
              ),
            ),
            TextButton(onPressed: _dismiss, child: Text('Done')),
          ],
        ),
      ),
    );

    widgets.add(
      Container(
        color: const Color(0x22000000),
        height: 1,
        width: double.infinity,
      ),
    );*/

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

    // for (int i = 0; i < widget.actions.length; ++i) {
    //   // Adds a button.
    //   widgets.add(widget.actions[i]);

    //   // Adds a divider if required.
    //   if (i < widget.actions.length - 1) {
    //     widgets.add(
    //       Container(
    //         color: const Color(0x22000000),
    //         height: 1,
    //         width: double.infinity,
    //       ),
    //     );
    //   }
    // }

    return Listener(
      onPointerUp: (d) => _dismiss(),
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
    Future.delayed(
        Duration.zero, () => ContextMenuOverlay.of(context).id.value = null);

    HapticFeedback.selectionClick();
    _bounds = _calculatePosition() ?? _bounds;
    _fading.reverse();
  }

  /// Returns a [Rect] of an [Object] identified by the provided initial
  /// [GlobalKey].
  Rect? _calculatePosition() => widget.globalKey.globalPaintBounds;
}

class ContextMenuActions extends StatelessWidget {
  const ContextMenuActions({
    Key? key,
    this.actions = const [],
    this.onDismissed,
    this.backdrop = false,
    this.width = 220,
  }) : super(key: key);

  final double width;

  /// List of [ContextMenuButton]s to display in this [ContextMenu].
  final List<ContextMenuButton> actions;

  final void Function()? onDismissed;

  final bool backdrop;

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    for (int i = 0; i < actions.length; ++i) {
      // Adds a button.
      widgets.add(
        Listener(
          // onPointerUp: (d) {
          //   if (actions[i].close) {
          //     onDismissed?.call();
          //   }
          // },
          child: actions[i],
        ),
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

    return Listener(
      // onPointerUp: (d) => onDismissed?.call(),
      child: Container(
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
      ),
    );
  }
}
