import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:messenger/l10n/l10n.dart';

import '/domain/model/user.dart';
import '/themes.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';
import '/util/platform_utils.dart';

/// [Widget] which returns a [WidgetButton] removing this [Chat] from the
/// blacklist.
class BlockedField extends StatelessWidget {
  const BlockedField({super.key, this.unblacklist});

  /// Removes a [User] being a recipient of this [chat] from the blacklist.
  final void Function()? unblacklist;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Theme(
      data: MessageFieldView.theme(context),
      child: SafeArea(
        child: Container(
          key: const Key('BlockedField'),
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            boxShadow: const [
              CustomBoxShadow(blurRadius: 8, color: Color(0x22000000)),
            ],
          ),
          child: ConditionalBackdropFilter(
            condition: style.cardBlur > 0,
            filter: ImageFilter.blur(
              sigmaX: style.cardBlur,
              sigmaY: style.cardBlur,
            ),
            borderRadius: style.cardRadius,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(color: style.cardColor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 5 + (PlatformUtils.isMobile ? 0 : 8),
                        bottom: 13,
                      ),
                      child: Transform.translate(
                        offset: Offset(0, PlatformUtils.isMobile ? 6 : 1),
                        child: WidgetButton(
                          onPressed: unblacklist,
                          child: IgnorePointer(
                            child: ReactiveTextField(
                              enabled: false,
                              state: TextFieldState(text: 'btn_unblock'.l10n),
                              filled: false,
                              dense: true,
                              textAlign: TextAlign.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              style: style.boldBody.copyWith(
                                fontSize: 17,
                                color: Theme.of(context).colorScheme.secondary,
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
      ),
    );
  }
}
