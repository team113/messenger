import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widget/padding.dart';
import '/domain/model/chat.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
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
    return Obx(() {
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
    });
  }
}
