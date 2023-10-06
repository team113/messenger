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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';
import '/ui/page/home/page/chat/message_field/widget/more_button.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/util/platform_utils.dart';

/// Visual representation of the [MessageFieldController.panel].
///
/// Intended to be drawn in the overlay.
class MessageFieldMore extends StatelessWidget {
  const MessageFieldMore(this.c, {super.key});

  /// [MessageFieldController] this [MessageFieldMore] is bound to.
  final MessageFieldController c;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return LayoutBuilder(builder: (context, constraints) {
      final Rect? rect = c.fieldKey.globalPaintBounds;

      final double left = rect?.left ?? 0;
      final double right =
          rect == null ? 0 : (constraints.maxWidth - rect.right);
      final double bottom = rect == null
          ? 0
          : (constraints.maxHeight - rect.bottom + rect.height);

      final List<Widget> widgets = [];
      for (int i = 0; i < c.panel.length; ++i) {
        final e = c.panel.elementAt(i);

        widgets.add(
          Obx(() {
            final bool contains = c.buttons.contains(e);

            return ChatMoreWidget(
              e,
              pinned: contains,
              onPressed: c.toggleMore,
              onPin: contains || c.canPin.value
                  ? () {
                      if (c.buttons.contains(e)) {
                        c.buttons.remove(e);
                      } else {
                        c.buttons.add(e);
                      }
                    }
                  : null,
            );
          }),
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
              onPointerDown: (_) => c.toggleMore(),
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
              onPointerDown: (_) => c.toggleMore(),
              child: Container(
                margin: EdgeInsets.only(
                  left: (rect?.left ?? constraints.maxWidth) + 50,
                ),
                width: constraints.maxWidth -
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
              onPointerDown: (_) => c.toggleMore(),
              child: Container(
                margin:
                    EdgeInsets.only(left: (rect?.left ?? constraints.maxWidth)),
                width: 50,
                height: rect?.top ?? 0,
                color: style.colors.transparent,
              ),
            ),
          ),
          Positioned(
            left: left,
            right: context.isNarrow ? right : null,
            bottom: bottom + 10,
            child: Container(
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
              child:
                  context.isNarrow ? actions : IntrinsicWidth(child: actions),
            ),
          ),
        ],
      );
    });
  }
}
