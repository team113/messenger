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
import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/message_field.dart';
import 'widget/message_header.dart';

/// View for writing and editing a [ChatMessage] or a [ChatForward].
class MessageFieldView extends StatelessWidget {
  const MessageFieldView({
    super.key,
    this.controller,
    this.onChanged,
    this.onItemPressed,
    this.fieldKey,
    this.sendKey,
    this.canForward = false,
    this.canAttach = true,
    this.constraints,
  });

  /// Optionally provided external [MessageFieldController].
  final MessageFieldController? controller;

  /// [Key] of a [ReactiveTextField] this [MessageFieldView] has.
  final Key? fieldKey;

  /// [Key] of a send button this [MessageFieldView] has.
  final Key? sendKey;

  /// Indicator whether forwarding is possible within this [MessageFieldView].
  final bool canForward;

  /// Indicator whether [Attachment]s can be attached to this
  /// [MessageFieldView].
  final bool canAttach;

  /// Callback, called when a [ChatItem] being a reply or edited is pressed.
  final Future<void> Function(ChatItemId id)? onItemPressed;

  /// Callback, called on the [ReactiveTextField] changes.
  final void Function()? onChanged;

  /// [BoxConstraints] replies, attachments and quotes are allowed to occupy.
  final BoxConstraints? constraints;

  /// Returns a [ThemeData] to decorate a [ReactiveTextField] with.
  static ThemeData theme(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide.none,
    );

    return Theme.of(context).copyWith(
      shadowColor: style.colors.onBackgroundOpacity27,
      iconTheme: IconThemeData(color: style.colors.primaryHighlight),
      inputDecorationTheme: InputDecorationTheme(
        border: border,
        errorBorder: border,
        enabledBorder: border,
        focusedBorder: border,
        disabledBorder: border,
        focusedErrorBorder: border,
        focusColor: style.colors.onPrimary,
        fillColor: style.colors.onPrimary,
        hoverColor: style.colors.transparent,
        filled: true,
        isDense: true,
        contentPadding: EdgeInsets.fromLTRB(
          15,
          PlatformUtils.isDesktop ? 30 : 23,
          15,
          0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      init: controller ?? MessageFieldController(Get.find(), Get.find()),
      global: false,
      builder: (MessageFieldController c) {
        return Theme(
          data: theme(context),
          child: SafeArea(
            child: Container(
              key: const Key('SendField'),
              decoration: BoxDecoration(
                borderRadius: style.cardRadius,
                boxShadow: [
                  CustomBoxShadow(
                    blurRadius: 8,
                    color: style.colors.onBackgroundOpacity13,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MessageHeader(
                      attachments: c.attachments,
                      hoveredAttachment: c.hoveredAttachment,
                      field: c.field,
                      edited: c.edited,
                      scrollController: c.scrollController,
                      quotes: c.quotes,
                      replied: c.replied,
                      boxConstraints: constraints,
                      me: c.me,
                      hoveredReply: c.hoveredReply,
                      getUser: c.getUser,
                      onItemPressed: onItemPressed,
                    ),
                    MessageField(
                      canAttach: canAttach,
                      canForward: canForward,
                      forwarding: c.forwarding,
                      field: c.field,
                      fieldKey: fieldKey,
                      sendKey: sendKey,
                      pickFile: c.pickFile,
                      pickImageFromCamera: c.pickImageFromCamera,
                      pickMedia: c.pickMedia,
                      pickVideoFromCamera: c.pickVideoFromCamera,
                      onChanged: onChanged,
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
