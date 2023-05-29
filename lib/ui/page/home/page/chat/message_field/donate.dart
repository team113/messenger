import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/message_field/controller.dart';
import 'package:messenger/ui/page/home/widget/gallery_popup.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import 'buttons.dart';

class MessageFieldDonate extends StatelessWidget {
  const MessageFieldDonate(this.c, {super.key, this.globalKey});

  final MessageFieldController c;
  final GlobalKey? globalKey;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return LayoutBuilder(builder: (context, constraints) {
      Rect? rect;

      double left = 0, right = 0, bottom = 0;

      try {
        rect = (globalKey ?? c.globalKey).globalPaintBounds;

        if (globalKey != null) {
          left = (rect?.left ?? 0) - 80;
        } else {
          left = (rect?.left ?? 0);
        }

        right = rect == null ? 0 : (constraints.maxWidth - rect.right);
        bottom = rect == null
            ? 0
            : (constraints.maxHeight - rect.bottom + rect.height);
      } catch (_) {
        // No-op.
      }

      if (constraints.maxWidth - left < 280) {
        left = constraints.maxWidth - 290;
      }

      if (left < 10) left = 10;
      if (right < 10) right = 10;

      if (context.isNarrow) {
        final Rect? global = c.globalKey.globalPaintBounds;

        left = global?.left ?? 10;
        right = global == null ? 0 : (constraints.maxWidth - global.right);
      }

      print('$left $right');

      return Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            onPointerDown: (_) {
              c.removeEntries<MessageFieldDonate>();
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
            bottom: bottom + 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: style.cardRadius,
                boxShadow: [
                  CustomBoxShadow(
                    blurRadius: 8,
                    color: style.colors.onBackgroundOpacity13,
                  ),
                ],
              ),
              width: 280,
              // height: 250,
              // padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  // spacing: 8,
                  // runSpacing: 8,
                  children: [100, 1000, 2500, 5000, 7500, 10000, 0].map((e) {
                    return _MenuButton(
                      e,
                      onPressed: () => c.removeEntries<MessageFieldDonate>(),
                      onSend: (b) => c.donate(b ?? e),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _MenuButton extends StatefulWidget {
  const _MenuButton(this.button, {this.onPressed, this.onSend});

  final int button;
  final void Function()? onPressed;
  final void Function(int?)? onSend;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _hovered = false;
  bool _pressed = false;

  TextFieldState? _state;

  @override
  void initState() {
    if (widget.button == 0) {
      _state = TextFieldState();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final String prefix;

    if (widget.button >= 10000) {
      prefix = '_purple';
    } else if (widget.button >= 7500) {
      prefix = '_red';
    } else if (widget.button >= 5000) {
      prefix = '_green';
    } else if (widget.button >= 2500) {
      prefix = '_orange';
    } else if (widget.button >= 1000) {
      prefix = '_teal';
    } else {
      prefix = '';
    }

    if (widget.button == 0) {
      return Container(
        width: double.infinity,
        color: _hovered || _pressed ? style.colors.onBackgroundOpacity2 : null,
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16),
            SizedBox(
              width: 26,
              child: SvgImage.asset(
                'assets/icons/donate_mini$prefix.svg',
                width: 22.84,
                height: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Theme(
                data: MessageFieldView.theme(context),
                child: Transform.translate(
                  offset: const Offset(0, 2),
                  child: ReactiveTextField(
                    padding: EdgeInsets.zero,
                    hint: 'Указать сумму...',
                    state: _state!,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                    // prefixText: 'G',
                    style: TextStyle(
                      // color: style.colors.primary,
                      fontSize: 17,
                    ),
                    prefixStyle: TextStyle(
                      color: style.colors.primary,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Obx(() {
              if (_state!.isEmpty.value) {
                return const SizedBox();
              }

              return WidgetButton(
                onPressed: widget.button == 0
                    ? () => widget.onSend?.call(int.tryParse(_state!.text))
                    : () => widget.onSend?.call(null),
                child: Container(
                  // color: Colors.red,
                  height: 40,
                  width: 50,
                  child: Center(
                    child: SvgImage.asset(
                      'assets/icons/send_mini1.svg',
                      width: 19.92,
                      height: 17.24,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      opaque: false,
      child: WidgetButton(
        onDown: (_) => setState(() => _pressed = true),
        onUp: (_) => setState(() => _pressed = false),
        onPressed: () {
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
              SizedBox(
                width: 26,
                child: SvgImage.asset(
                  'assets/icons/donate_mini$prefix.svg',
                  width: 22.84,
                  height: 22,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Text(
                  'G${widget.button}',
                  style: TextStyle(
                    fontSize: 17,
                    color: style.colors.primary,
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 16),
              WidgetButton(
                onPressed: () => widget.onSend?.call(null),
                child: Container(
                  // color: Colors.red,
                  height: 40,
                  width: 50,
                  child: Center(
                    child: SvgImage.asset(
                      'assets/icons/send_mini1.svg',
                      width: 19.92,
                      height: 17.24,
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
