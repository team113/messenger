import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/message_field/controller.dart';
import 'package:messenger/ui/page/home/widget/gallery_popup.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import 'buttons.dart';

class MessageFieldOverlay extends StatelessWidget {
  const MessageFieldOverlay(this.c, {super.key});

  final MessageFieldController c;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return LayoutBuilder(builder: (context, constraints) {
      final Rect? rect = c.globalKey.globalPaintBounds;

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
              onPinned: () {
                if (c.buttons.contains(e)) {
                  c.buttons.remove(e);
                } else {
                  c.buttons.add(e);
                }
              },
              onPressed: () {
                c.entry?.remove();
                c.entry = null;
              },
            );
          }),
        );

        if (i != c.panel.length - 1) {
          widgets.add(
            Container(
              height: 0.5,
              width: double.infinity,
              color: style.colors.onBackgroundOpacity7,
            ),
          );
        }
      }

      final Widget actions = Column(
        mainAxisSize: MainAxisSize.min,
        children: widgets,
      );

      return Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            onPointerDown: (_) {
              c.entry?.remove();
              c.entry = null;
            },
            child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: Colors.transparent,
            ),
          ),
          Positioned(
            left: left,
            right: context.isNarrow ? right : null,
            // right: 0,
            bottom: bottom + 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                // color: candidate.any((e) => e?.c == c)
                //     ? const Color(0xE0165084)
                //     : const Color(0x9D165084),
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

class _MenuButton extends StatefulWidget {
  const _MenuButton(
    this.button, {
    this.onPressed,
    this.onPinned,
    this.pinned = false,
  });

  final ChatButton button;
  final void Function()? onPressed;
  final void Function()? onPinned;
  final bool pinned;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      opaque: false,
      child: WidgetButton(
        onDown: (_) => setState(() => _pressed = true),
        onUp: (_) => setState(() => _pressed = false),
        onPressed: () {
          widget.button.onPressed?.call();
          widget.onPressed?.call();
        },
        child: Container(
          width: double.infinity,
          color:
              _hovered || _pressed ? style.colors.onBackgroundOpacity2 : null,
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 16),
              Icon(
                widget.button.icon ?? Icons.attach_email,
                size: 24,
                color: style.colors.primary,
              ),
              // SvgImage.asset(
              //   'assets/icons/${e.asset}.svg',
              //   width: 60,
              //   height: 60,
              // ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Text(
                  widget.button.hint,
                  style: TextStyle(
                    fontSize: 15,
                    color: style.colors.primary,
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 16),
              WidgetButton(
                onPressed: widget.onPinned,
                child: SizedBox(
                  // color: Colors.red,
                  height: 40,
                  width: 40,
                  child: Center(
                    child: widget.pinned
                        ? SvgImage.asset(
                            'assets/icons/unpin3.svg',
                            width: 16.5,
                            height: 17.17,
                          )
                        : SvgImage.asset(
                            'assets/icons/pin1.svg',
                            width: 9.56,
                            height: 16.85,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
