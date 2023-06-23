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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';

/// Custom-styled [ReactiveTextField] along with its buttons.
class CustomField extends StatelessWidget {
  const CustomField({
    super.key,
    required this.state,
    this.fieldKey,
    this.sendKey,
    this.onChanged,
    this.onPressed,
    this.onTrailingPressed,
    this.onLongPress,
    this.isForwarding = false,
  });

  /// [Key] of a [ReactiveTextField] this [CustomField] has.
  final Key? fieldKey;

  /// [Key] of a send button this [CustomField] has.
  final Key? sendKey;

  /// Reactive state of this [ReactiveTextField].
  final ReactiveFieldState state;

  /// Indicator whether forwarding mode is enabled.
  final bool isForwarding;

  /// Callback, called when [TextField] is changed.
  final void Function()? onChanged;

  /// Callback, called when the child is pressed.
  final void Function()? onPressed;

  /// Callback, called when the trailing is pressed.
  final void Function()? onTrailingPressed;

  /// Callback, called when the trailing is long pressed.
  final void Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(color: style.cardColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          WidgetButton(
            onPressed: onPressed,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: SvgImage.asset(
                  'assets/icons/attach.svg',
                  height: 22,
                  width: 22,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 5 + (PlatformUtils.isMobile ? 0 : 8),
                bottom: 13,
              ),
              child: Transform.translate(
                offset: Offset(0, PlatformUtils.isMobile ? 6 : 1),
                child: ReactiveTextField(
                  onChanged: onChanged,
                  key: fieldKey ?? const Key('MessageField'),
                  state: state,
                  hint: 'label_send_message_hint'.l10n,
                  minLines: 1,
                  maxLines: 7,
                  filled: false,
                  dense: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  style: fonts.bodyLarge,
                  type: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
          ),
          GestureDetector(
            onLongPress: onLongPress,
            child: WidgetButton(
              onPressed: onTrailingPressed,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: 300.milliseconds,
                    child: isForwarding
                        ? SvgImage.asset(
                            'assets/icons/forward.svg',
                            width: 26,
                            height: 22,
                          )
                        : SvgImage.asset(
                            'assets/icons/send.svg',
                            key: sendKey ?? const Key('Send'),
                            height: 22.85,
                            width: 25.18,
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
