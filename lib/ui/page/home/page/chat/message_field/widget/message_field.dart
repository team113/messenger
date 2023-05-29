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

import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/attachment_selector.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';

class MessageField extends StatelessWidget {
  const MessageField({
    super.key,
    required this.canAttach,
    required this.canForward,
    required this.forwarding,
    required this.field,
    required this.fieldKey,
    required this.sendKey,
    required this.pickFile,
    required this.pickImageFromCamera,
    required this.pickMedia,
    required this.pickVideoFromCamera,
    required this.onChanged,
  });

  /// Indicator whether [Attachment]s can be attached to this
  /// [MessageFieldView].
  final bool canAttach;

  /// Indicator whether forwarding is possible within this [MessageFieldView].
  final bool canForward;

  /// Indicator whether forwarding mode is enabled.
  final RxBool forwarding;

  /// [TextFieldState] for a [ChatMessageText].
  final TextFieldState field;

  /// [Key] of a [ReactiveTextField] this [MessageFieldView] has.
  final Key? fieldKey;

  /// [Key] of a send button this [MessageFieldView] has.
  final Key? sendKey;

  /// Opens a file choose popup and adds the selected files to the attachments.
  final Future<void> Function() pickFile;

  /// Opens the camera app and adds the captured image to the attachments.
  final Future<void> Function() pickImageFromCamera;

  /// Opens a media choose popup and adds the selected files to the
  /// attachments.
  final Future<void> Function() pickMedia;

  /// Opens the camera app and adds the captured video to the attachments.
  final Future<void> Function() pickVideoFromCamera;

  /// Callback, called on the [ReactiveTextField] changes.
  final void Function()? onChanged;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(color: style.cardColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          WidgetButton(
            onPressed: canAttach
                ? !PlatformUtils.isMobile || PlatformUtils.isWeb
                    ? pickFile
                    : () async {
                        field.focus.unfocus();
                        await AttachmentSourceSelector.show(
                          context,
                          onPickFile: pickFile,
                          onTakePhoto: pickImageFromCamera,
                          onPickMedia: pickMedia,
                          onTakeVideo: pickVideoFromCamera,
                        );
                      }
                : null,
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
                  state: field,
                  hint: 'label_send_message_hint'.l10n,
                  minLines: 1,
                  maxLines: 7,
                  filled: false,
                  dense: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  style: style.boldBody.copyWith(fontSize: 17),
                  type: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
          ),
          GestureDetector(
            onLongPress: canForward ? forwarding.toggle : null,
            child: WidgetButton(
              onPressed: field.submit,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: 300.milliseconds,
                    child: forwarding.value
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
