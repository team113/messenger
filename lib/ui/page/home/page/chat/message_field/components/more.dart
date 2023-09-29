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
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'buttons.dart';

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

            return _MenuButton(
              e,
              pinned: contains,
              onPinned: contains || c.canPin.value
                  ? () {
                      if (c.buttons.contains(e)) {
                        c.buttons.remove(e);
                      } else {
                        c.buttons.add(e);
                      }
                    }
                  : null,
              onPressed: c.toggleMore,
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
              onPointerDown: (_) {
                c.toggleMore();
              },
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
              onPointerDown: (_) {
                c.toggleMore();
              },
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
              onPointerDown: (_) {
                c.toggleMore();
              },
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

/// Visual representation of a [ChatButton].
class _MenuButton extends StatefulWidget {
  const _MenuButton(
    this.button, {
    this.onPressed,
    this.onPinned,
    this.pinned = false,
  });

  /// [ChatButton] of this [_MenuButton].
  final ChatButton button;

  /// Callback, called when this [_MenuButton] is pressed.
  final void Function()? onPressed;

  /// Callback, called when this [_MenuButton] is pinned.
  final void Function()? onPinned;

  /// Indicator whether this [_MenuButton] is pinned.
  final bool pinned;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

/// State of a [_MenuButton] maintaining a [_hovered] indicator.
class _MenuButtonState extends State<_MenuButton> {
  /// Indicator whether this [_MenuButton] is hovered.
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;
    bool disabled = widget.button.onPressed == null;

    return IgnorePointer(
      ignoring: disabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        opaque: false,
        child: WidgetButton(
          onPressed: () {
            widget.button.onPressed?.call();
            widget.onPressed?.call();
          },
          child: Container(
            width: double.infinity,
            color: _hovered ? style.colors.onBackgroundOpacity2 : null,
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16),
                SizedBox(
                  width: 26,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 100),
                    scale: _hovered ? 1.05 : 1,
                    child: Transform.translate(
                      offset: widget.button.offsetMini,
                      child: SvgImage.asset(
                        'assets/icons/${widget.button.assetMini ?? widget.button.asset}${disabled ? '_disabled' : ''}.svg',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.button.hint,
                  style: disabled
                      ? style.fonts.bodyLargePrimaryHighlightLightest
                      : style.fonts.bodyLargePrimary,
                ),
                const Spacer(),
                const SizedBox(width: 16),
                WidgetButton(
                  onPressed: widget.onPinned ?? () {},
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: Center(
                      child: AnimatedButton(
                        child: AnimatedSwitcher(
                          duration: 100.milliseconds,
                          child: widget.pinned
                              ? const SvgImage.asset(
                                  'assets/icons/unpin.svg',
                                  key: Key('Unpin'),
                                  width: 15.5,
                                  height: 17,
                                )
                              : Transform.translate(
                                  offset: const Offset(0.5, 0),
                                  child: SvgImage.asset(
                                    'assets/icons/pin${widget.onPinned == null || disabled ? '_disabled' : ''}.svg',
                                    key: const Key('Pin'),
                                    width: 9.65,
                                    height: 17,
                                  ),
                                ),
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
    );
  }
}
