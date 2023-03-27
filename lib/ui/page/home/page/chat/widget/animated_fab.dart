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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';

/// Animated button with expandable on toggle [actions].
class AnimatedFab extends StatefulWidget {
  const AnimatedFab({
    Key? key,
    required this.closedIcon,
    required this.openedIcon,
    this.labelStyle,
    this.actions = const [],
    this.height = 400,
  }) : super(key: key);

  /// Icon in a closed state.
  final Widget closedIcon;

  /// Icon in an opened (expanded) state.
  final Widget openedIcon;

  /// Style of labels in [actions].
  final TextStyle? labelStyle;

  /// List of [AnimatedFabAction] that should be expanded.
  final List<AnimatedFabAction> actions;

  /// Height of the expanded state of this [AnimatedFab].
  final double height;

  @override
  State<AnimatedFab> createState() => _AnimatedFabState();
}

/// Configurable single action of an [AnimatedFab].
class AnimatedFabAction {
  const AnimatedFabAction({
    required this.icon,
    this.label,
    this.onTap,
    this.noAnimation = false,
  });

  /// Icon of this action.
  final Widget icon;

  /// Label of this action.
  final String? label;

  /// Callback, called when this action is invoked.
  final void Function()? onTap;

  /// Indicator whether closing animation should be played when this action is
  /// invoked or not.
  final bool noAnimation;
}

/// State of [AnimatedFab] used to animate it.
class _AnimatedFabState extends State<AnimatedFab>
    with SingleTickerProviderStateMixin {
  /// [AnimationController] of expandable actions.
  late final AnimationController _controller;

  /// [GlobalKey] of this [Widget] used to position its overlay correctly.
  final GlobalKey _key = GlobalKey();

  /// [GlobalKey] of an animated button used to share it between overlays.
  final GlobalKey _fabKey = GlobalKey();

  /// [OverlayEntry] of this [AnimatedFab].
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      debugLabel: '$runtimeType',
    )..addStatusListener(
        (status) {
          switch (status) {
            case AnimationStatus.dismissed:
              _overlayEntry?.remove();
              setState(() => _overlayEntry = null);
              break;

            case AnimationStatus.reverse:
            case AnimationStatus.forward:
              _populateOverlay();
              break;

            case AnimationStatus.completed:
              // No-op.
              break;
          }
        },
      );

    super.initState();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        key: _key,
        child: _overlayEntry == null
            ? Container(key: _fabKey, child: _fab())
            : _fab(),
      );

  /// Populates the [_overlayEntry].
  void _populateOverlay() {
    if (!mounted || _overlayEntry != null) return;

    Offset offset = Offset.zero;
    final keyContext = _key.currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      offset = box.localToGlobal(Offset.zero);
    }

    // Discard the first [LayoutBuilder] frame since no widget is drawn yet.
    bool firstLayout = true;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => LayoutBuilder(
        builder: (context, constraints) {
          if (!firstLayout) {
            final keyContext = _key.currentContext;
            if (keyContext != null) {
              final box = keyContext.findRenderObject() as RenderBox;
              offset = box.localToGlobal(Offset.zero);
            }
          } else {
            firstLayout = false;
          }

          return Stack(
            children: [
              GestureDetector(
                onTap: _toggleOverlay,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      color: Theme.of(context)
                          .extension<Style>()!
                          .onBackground
                          .withOpacity(0.25 * _controller.value),
                    );
                  },
                ),
              ),
              Positioned(
                left: offset.dx,
                top: offset.dy,
                child: Container(key: _fabKey, child: _fab()),
              ),
              ...widget.actions.mapIndexed(
                (i, e) {
                  var animation = Tween(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Interval(
                        i / widget.actions.length,
                        1.0,
                        curve: Curves.ease,
                      ),
                    ),
                  );

                  final cosTween = Tween(
                    begin: offset.dx,
                    end: offset.dx +
                        5 +
                        widget.height *
                            (1 -
                                cos(
                                  (pi / 4) * (i + 1) / (widget.actions.length),
                                )),
                  );

                  final sinTween = Tween(
                    begin: offset.dy,
                    end: offset.dy -
                        (i * i * 1.1) -
                        widget.height *
                            sin(
                              (pi / 4) * (i + 1) / (widget.actions.length),
                            ),
                  );

                  void onTap() {
                    e.onTap?.call();
                    if (e.noAnimation) {
                      _controller.value = 0;
                    } else {
                      _controller.reverse(from: _controller.value);
                    }
                  }

                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Positioned(
                        left: cosTween.evaluate(animation),
                        top: sinTween.evaluate(animation),
                        child: child!,
                      );
                    },
                    child: FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _button(icon: e.icon, onTap: onTap),
                            if (e.label != null) ...[
                              const SizedBox(width: 5),
                              Material(
                                borderRadius: BorderRadius.circular(10),
                                color: Theme.of(context)
                                    .extension<Style>()!
                                    .onPrimary,
                                shadowColor: Theme.of(context)
                                    .extension<Style>()!
                                    .transparentOpacity81,
                                elevation: 6,
                                child: InkWell(
                                  onTap: onTap,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      e.label!,
                                      style: widget.labelStyle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ],
          );
        },
      ),
    );

    setState(() {});

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  /// Toggles overlay state based on [_controller]'s status.
  void _toggleOverlay() {
    switch (_controller.status) {
      case AnimationStatus.dismissed:
      case AnimationStatus.reverse:
        _controller.forward();
        break;

      case AnimationStatus.completed:
      case AnimationStatus.forward:
        _controller.reverse();
        break;
    }
  }

  /// Returns an [InkWell] circular button with an [icon].
  Widget _button({
    void Function()? onTap,
    required Widget icon,
  }) =>
      Material(
        type: MaterialType.circle,
        color: Theme.of(context).extension<Style>()!.onPrimary,
        shadowColor: Theme.of(context).extension<Style>()!.transparentOpacity67,
        elevation: 6,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle),
            width: 42,
            height: 42,
            child: Center(child: icon),
          ),
        ),
      );

  /// Returns an animated circular button toggling overlay.
  Widget _fab() {
    return _button(
      icon: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) => Transform.rotate(
          angle: _controller.value * pi / 2,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _controller.value < 0.4
                ? widget.closedIcon
                : Transform.rotate(
                    angle: -pi / 2,
                    child: Center(child: widget.openedIcon),
                  ),
          ),
        ),
      ),
      onTap: _toggleOverlay,
    );
  }
}
