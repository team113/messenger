import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/message_field/controller.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/page/home/widget/gallery_popup.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

class MessageFieldDonate extends StatelessWidget {
  const MessageFieldDonate(this.c, {super.key, this.globalKey});

  final MessageFieldController c;
  final GlobalKey? globalKey;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return LayoutBuilder(builder: (context, constraints) {
      Rect? rect;

      double left = 0, right = 0, bottom = 0;

      try {
        rect = (globalKey ?? c.fieldKey).globalPaintBounds;

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
        final Rect? global = c.fieldKey.globalPaintBounds;

        // left = 0;
        // right = 0;
        left = global?.left ?? 10;
        right = global == null ? 0 : (constraints.maxWidth - global.right);
      }

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
            child: Column(
              children: [
                Container(
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
                  width: context.isNarrow ? double.infinity : 280,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...[10000, 5000, 1000, 500, 300, 100, 0].map((e) {
                          // TODO: Minimum is min(donate_min, paid_msg);
                          if (e != 0 && e < 400) {
                            return const SizedBox();
                          }

                          return Obx(() {
                            return _MenuButton(
                              e,
                              onPressed: (b) {
                                c.donation.value = b ?? e;
                                c.removeEntries<MessageFieldDonate>();
                              },
                              canSend: c.field.isEmpty.value &&
                                  c.attachments.isEmpty &&
                                  c.replied.isEmpty,
                              onSend: (b) async {
                                c.donate(b ?? e);
                                c.removeEntries<MessageFieldDonate>();
                              },
                            );
                          });
                        })
                      ],
                    ),
                  ),
                ),
              ],
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
    this.canSend = true,
    this.onSend,
  });

  final int button;
  final bool canSend;
  final void Function(int?)? onPressed;
  final void Function(int?)? onSend;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _hovered = false;
  bool _pressed = false;

  TextFieldState? _state;

  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    if (widget.button == 0) {
      _state = TextFieldState();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    if (widget.button == 0) {
      return Container(
        width: double.infinity,
        color: _hovered || _pressed ? style.colors.onBackgroundOpacity2 : null,
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16),
            Obx(() {
              int? sum =
                  int.tryParse(_state!.text.replaceAll(RegExp(r'\s+'), ''));
              if ((sum ?? 0) < 400) {
                sum = null;
              }

              return WidgetButton(
                onPressed: _state!.isEmpty.value || sum == null
                    ? null
                    : () {
                        widget.onPressed?.call(
                          int.parse(
                            _state!.text.replaceAll(RegExp(r'\s+'), ''),
                          ),
                        );
                      },
                child: SizedBox(
                  width: 26,
                  child: AnimatedButton(
                    enabled: !_state!.isEmpty.value && sum != null,
                    child: SvgImage.asset(
                      'assets/icons/donate_mini${sum == null ? '_grey' : ''}.svg',
                      width: 22.84,
                      height: 22,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 12),
            Expanded(
              child: Theme(
                data: MessageFieldView.theme(context),
                child: Transform.translate(
                  offset: Offset(
                    0,
                    PlatformUtils.isWeb
                        ? PlatformUtils.isMobile
                            ? 3
                            : -1
                        : -3,
                  ),
                  child: ReactiveTextField(
                    padding: EdgeInsets.zero,
                    hint: '0 (мин: ¤ 400)',
                    state: _state!,
                    prefixConstraints: const BoxConstraints(minWidth: 16),
                    prefixIcon: SizedBox(
                      child: Center(
                        widthFactor: 0.0,
                        child: Transform.translate(
                          offset: Offset(0, PlatformUtils.isWeb ? 3.5 : 4),
                          child: Text(
                            '¤ ',
                            style: style.fonts.medium.regular.onBackground,
                          ),
                        ),
                      ),
                    ),
                    onChanged: () {
                      String string = NumberFormat.decimalPattern()
                          .format(int.tryParse(_state!.text) ?? 0);

                      if (string == '0') {
                        string = '';
                      }

                      _state!.controller.value = TextEditingValue(
                        text: string,
                        selection:
                            TextSelection.collapsed(offset: string.length),
                      );

                      setState(() {});
                    },
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    style: style.fonts.medium.regular.onBackground,
                    prefixStyle: style.fonts.medium.regular.onBackground,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Builder(builder: (_) {
              int? sum =
                  int.tryParse(_state!.text.replaceAll(RegExp(r'\s+'), ''));
              if ((sum ?? 0) < 400) {
                sum = null;
              }

              return WidgetButton(
                onPressed: sum == null || !widget.canSend
                    ? null
                    : () => widget.onSend?.call(
                          int.tryParse(
                            _state!.text.replaceAll(RegExp(r'\s+'), ''),
                          ),
                        ),
                child: SizedBox(
                  height: 40,
                  width: 50,
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, 1),
                      child: AnimatedButton(
                        enabled: sum != null && widget.canSend,
                        child: SvgImage.asset(
                          'assets/icons/${widget.canSend ? 'send_mini3' : 'attachment_mini'}${sum == null ? '_grey' : ''}.svg',
                          width: widget.canSend ? 19.28 : 18.88 * 0.9,
                          height: widget.canSend ? 16.6 : 21 * 0.9,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: _hovered || _pressed ? style.colors.onBackgroundOpacity2 : null,
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedButton(
            decorator: (child) => Padding(
              padding: const EdgeInsets.only(left: 16),
              child: child,
            ),
            onPressed: () => widget.onPressed?.call(null),
            child: SizedBox(
              width: 26,
              child: AnimatedScale(
                key: _key,
                duration: const Duration(milliseconds: 100),
                scale: _hovered ? 1.05 : 1,
                child: const SvgImage.asset(
                  'assets/icons/donate_mini.svg',
                  width: 22.84,
                  height: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Transform.translate(
            offset: const Offset(0, 2),
            child: Text(
              '¤ ${widget.button.withSpaces()}',
              style: style.fonts.medium.regular.onBackground,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 16),
          if (!widget.canSend)
            const AnimatedButton(
              child: SizedBox(
                height: 40,
                width: 50,
                child: Center(
                  child: SvgImage.asset(
                    'assets/icons/attachment_mini.svg',
                    width: 18.88 * 0.9,
                    height: 21 * 0.9,
                  ),
                ),
              ),
            )
          else
            WidgetButton(
              onPressed: () => widget.onSend?.call(null),
              child: SizedBox(
                height: 40,
                width: 50,
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, 1),
                    child: const AnimatedButton(
                      child: SvgImage.asset(
                        'assets/icons/send_mini3.svg',
                        width: 19.28,
                        height: 16.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension on int {
  String withSpaces() => NumberFormat('#,##0').format(this);
}
