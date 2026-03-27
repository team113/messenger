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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/page/home/page/chat/message_field/widget/more_button.dart';
import '/ui/page/home/page/my_profile/welcome_field/controller.dart';
import '/util/global_key.dart';
import '/util/platform_utils.dart';

/// Visual representation of the [WelcomeFieldController.panel].
///
/// Intended to be drawn in the overlay.
class MessageFieldMore extends StatefulWidget {
  const MessageFieldMore(this.c, {super.key, this.onDismissed});

  /// [WelcomeFieldController] this [MessageFieldMore] is bound to.
  final WelcomeFieldController c;

  /// Callback, called when animation of this [MessageFieldMore] is
  /// [AnimationStatus.dismissed].
  final void Function()? onDismissed;

  @override
  State<MessageFieldMore> createState() => _MessageFieldMoreState();
}

/// State of a [MessageFieldMore] maintaining the [_controller].
class _MessageFieldMoreState extends State<MessageFieldMore>
    with TickerProviderStateMixin {
  /// Controller animating [FadeTransition].
  late AnimationController _controller;

  /// Animation of [FadeTransition] and [SlideTransition].
  late Animation<double> _animation;

  /// [Worker] reacting on the [WelcomeFieldController.moreOpened] changes
  /// [dismiss]ing this [MessageFieldMore]
  Worker? _worker;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.ease);

    _worker = ever(widget.c.moreOpened, (opened) {
      if (!opened) {
        dismiss();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _worker?.dispose();
    _worker = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final Rect? rect = widget.c.fieldKey.globalPaintBounds;

        final double left = rect?.left ?? 0;
        final double right = rect == null
            ? 0
            : (constraints.maxWidth - rect.right);
        final double bottom = rect == null
            ? 0
            : (constraints.maxHeight - rect.bottom + rect.height);

        final List<Widget> widgets = [];
        for (int i = 0; i < widget.c.panel.length; ++i) {
          widgets.add(
            ChatMoreWidget(widget.c.panel.elementAt(i), onPressed: dismiss),
          );
        }

        final Widget actions = Column(
          mainAxisSize: MainAxisSize.min,
          children: widgets,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Listener(
                onPointerDown: (_) => dismiss(),
                child: Container(
                  width: rect?.left ?? constraints.maxWidth,
                  height: constraints.maxHeight,
                  color: style.colors.transparent,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Listener(
                onPointerDown: (_) => dismiss(),
                child: Container(
                  margin: EdgeInsets.only(
                    left: (rect?.left ?? constraints.maxWidth) + 50,
                  ),
                  width:
                      constraints.maxWidth -
                      (rect?.left ?? constraints.maxWidth) -
                      50,
                  height: constraints.maxHeight,
                  color: style.colors.transparent,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Listener(
                onPointerDown: (_) => dismiss(),
                child: Container(
                  margin: EdgeInsets.only(
                    left: (rect?.left ?? constraints.maxWidth),
                  ),
                  width: 50,
                  height: rect?.top ?? 0,
                  color: style.colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: left,
              right: context.isNarrow ? right : null,
              bottom: 0,
              child: SlideTransition(
                position: Tween(
                  begin: context.isMobile ? const Offset(0, 1) : Offset.zero,
                  end: Offset.zero,
                ).animate(_animation),
                child: FadeTransition(
                  opacity: Tween(
                    begin: context.isMobile ? 1.0 : 0.0,
                    end: 1.0,
                  ).animate(_animation),
                  child: Container(
                    margin: EdgeInsets.only(bottom: bottom + 10),
                    decoration: BoxDecoration(
                      color: style.colors.onPrimary,
                      borderRadius: style.cardRadius,
                      boxShadow: [
                        CustomBoxShadow(
                          blurRadius: 8,
                          color: style.colors.onBackgroundOpacity13,
                        ),
                      ],
                    ),
                    child: context.isNarrow
                        ? actions
                        : IntrinsicWidth(child: actions),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Dismisses this [MessageFieldMore] with animation.
  Future<void> dismiss() async {
    _worker?.dispose();
    _worker = null;

    await _controller.reverse();
    widget.onDismissed?.call();

    if (widget.c.moreOpened.isTrue) {
      widget.c.toggleMore();
    }
  }
}
