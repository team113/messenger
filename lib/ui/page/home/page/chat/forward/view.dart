// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/call/widget/animated_delayed_scale.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/page/chat/widget/custom_drop_target.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View for forwarding the provided [quotes] into the selected [Chat]s.
///
/// Intended to be displayed with the [show] method.
class ChatForwardView extends StatelessWidget {
  const ChatForwardView({
    super.key,
    required this.from,
    required this.quotes,
    this.text,
    this.attachments = const [],
    this.onSent,
  });

  /// ID of the [Chat] the [quotes] are forwarded from.
  final ChatId from;

  /// [ChatItemQuoteInput]s to be forwarded.
  final List<ChatItemQuoteInput> quotes;

  /// Initial [String] to put in the send field.
  final String? text;

  /// Initial [Attachment]s to attach to the provided [quotes].
  final List<Attachment> attachments;

  /// Callback, called when the [quotes] are sent.
  final void Function()? onSent;

  /// Maximum height of the [ChatForwardView].
  static const double _maxHeight = 812;

  /// Displays a [ChatForwardView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context,
    ChatId from,
    List<ChatItemQuoteInput> quotes, {
    String? text,
    List<Attachment> attachments = const [],
    void Function()? onSent,
  }) {
    final Style style = Theme.of(context).style;

    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: _maxHeight,
      ),
      mobilePadding: const EdgeInsets.only(bottom: 12),
      desktopPadding: const EdgeInsets.only(bottom: 10),
      background: style.colors.background,
      child: ChatForwardView(
        key: const Key('ChatForwardView'),
        from: from,
        quotes: quotes,
        text: text,
        attachments: attachments,
        onSent: onSent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: ChatForwardController(
        Get.find(),
        Get.find(),
        Get.find(),
        from: from,
        quotes: quotes,
        text: text,
        attachments: attachments,
        onSent: onSent,
        pop: context.popModal,
      ),
      builder: (ChatForwardController c) {
        return CustomDropTarget(
          key: Key('ChatForwardView_$from'),
          onPerformDrop: c.dropFiles,
          builder: (dragging) => Stack(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ModalPopupHeader(
                      text: 'label_forward_message'.l10n,
                      subtitle: 'label_forward_subtitle'.l10n,
                    ),
                    Expanded(
                      child: SearchView(
                        key: const Key('SearchView'),
                        categories: const [
                          SearchCategory.chat,
                          SearchCategory.contact,
                          SearchCategory.user,
                        ],
                        onSelected: (r) => c.selected.value = r,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: MessageFieldView(
                        fieldKey: const Key('ForwardField'),
                        sendKey: const Key('SendForward'),
                        constraints: BoxConstraints(
                          maxHeight:
                              min(
                                MediaQuery.of(context).size.height - 10,
                                _maxHeight,
                              ) /
                              4,
                        ),
                        rounded: true,
                        controller: c.send,
                      ),
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                child: SafeAnimatedSwitcher(
                  duration: 200.milliseconds,
                  child: dragging
                      ? Container(
                          color: style.colors.onBackgroundOpacity27,
                          child: Center(
                            child: AnimatedDelayedScale(
                              duration: const Duration(milliseconds: 300),
                              beginScale: 1,
                              endScale: 1.06,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: style.colors.onBackgroundOpacity27,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: SvgIcon(SvgIcons.addBigger),
                                ),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
