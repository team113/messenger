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

import 'dart:ui';

import 'package:flutter/material.dart';

import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';

/// [Widget] which returns a [WidgetButton] for removing the [User] from the
/// blacklist.
class BlockedField extends StatelessWidget {
  const BlockedField({super.key, required this.unblacklist});

  /// Removes the [User] from the blacklist of the authenticated [RxUser].
  final Future<void> Function() unblacklist;

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
              CustomBoxShadow(
                blurRadius: 8,
                color: Color(0x22000000),
              ),
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
                              key: const Key('MessageField'),
                              state: TextFieldState(text: 'btn_unblock'.l10n),
                              filled: false,
                              dense: true,
                              textAlign: TextAlign.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              style: style.boldBody.copyWith(
                                fontSize: 17,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              type: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
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
