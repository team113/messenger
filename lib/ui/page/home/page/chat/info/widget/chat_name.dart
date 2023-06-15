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

import '/domain/model/chat.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/page/home/page/chat/widget/padding.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [Widget] which returns a [Chat.name] editable field.
class ChatName extends StatelessWidget {
  const ChatName(this.chat, this.name, {super.key});

  /// Reactive [Chat] with chat items.
  final RxChat? chat;

  /// [Chat.name] field state.
  final TextFieldState name;

  @override
  Widget build(BuildContext context) {
    return BasicPadding(
      ReactiveTextField(
        key: const Key('RenameChatField'),
        state: name,
        label: chat?.chat.value.name == null
            ? chat?.title.value
            : 'label_name'.l10n,
        hint: 'label_name_hint'.l10n,
        onSuffixPressed: name.text.isEmpty
            ? null
            : () {
                PlatformUtils.copy(text: name.text);
                MessagePopup.success('label_copied'.l10n);
              },
        trailing: name.text.isEmpty
            ? null
            : Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/copy.svg', height: 15),
                ),
              ),
      ),
    );
  }
}
