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

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/widget/fit_view.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/page/chat/widget/data_attachment.dart';
import 'package:messenger/ui/page/home/page/chat/widget/media_attachment.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/l10n/l10n.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/call/widget/animated_delayed_scale.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/page/chat/widget/custom_drop_target.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for forwarding the provided [quotes] into the selected [Chat]s.
///
/// Intended to be displayed with the [show] method.
class WelcomeMessageView extends StatelessWidget {
  const WelcomeMessageView({
    super.key,
    this.text,
    this.attachments = const [],
  });

  /// Initial [String] to put in the send field.
  final String? text;

  /// Initial [Attachment]s to attach to the provided [quotes].
  final List<Attachment> attachments;

  /// Displays a [ChatForwardView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    String? text,
    List<Attachment> attachments = const [],
  }) {
    return ModalPopup.show(
      context: context,
      desktopConstraints:
          const BoxConstraints(maxWidth: double.infinity, maxHeight: 800),
      mobilePadding: const EdgeInsets.all(0),
      desktopPadding: const EdgeInsets.all(0),
      child: WelcomeMessageView(
        key: const Key('ChatForwardView'),
        attachments: attachments,
        text: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    Widget info({
      required Widget child,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: style.systemMessageBorder,
              color: style.systemMessageColor,
            ),
            child: DefaultTextStyle(
              style: style.systemMessageStyle,
              child: child,
            ),
          ),
        ),
      );
    }

    Widget message({
      String text = '123',
      List<Attachment> attachments = const [],
      PreciseDateTime? at,
    }) {
      List<Attachment> media = attachments.where((e) {
        return ((e is ImageAttachment) ||
            (e is FileAttachment && e.isVideo) ||
            (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
      }).toList();

      List<Attachment> files = attachments.where((e) {
        return ((e is FileAttachment && !e.isVideo) ||
            (e is LocalAttachment && !e.file.isImage && !e.file.isVideo));
      }).toList();

      final bool timeInBubble = attachments.isNotEmpty;

      Widget? timeline;
      if (at != null) {
        timeline = SelectionContainer.disabled(
          child: Text(
            '${'label_date_ymd'.l10nfmt({
                  'year': at.val.year.toString().padLeft(4, '0'),
                  'month': at.val.month.toString().padLeft(2, '0'),
                  'day': at.val.day.toString().padLeft(2, '0'),
                })}, 10:04',
            style: style.systemMessageStyle.copyWith(fontSize: 11),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.fromLTRB(5 * 2, 6, 5 * 2, 6),
        child: Stack(
          children: [
            IntrinsicWidth(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  color: style.readMessageColor,
                  borderRadius: BorderRadius.circular(15),
                  border: style.secondaryBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: text),
                              if (timeline != null)
                                WidgetSpan(
                                  child: Opacity(opacity: 0, child: timeline),
                                ),
                            ],
                          ),
                          style: style.boldBody,
                        ),
                      ),
                    if (files.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                        child: Column(
                          children: files
                              .map(
                                (e) => ChatItemWidget.fileAttachment(e),
                              )
                              .toList(),
                        ),
                      ),
                    if (media.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: text.isNotEmpty || files.isNotEmpty
                              ? Radius.zero
                              : files.isEmpty
                                  ? const Radius.circular(15)
                                  : Radius.zero,
                          topRight: text.isNotEmpty || files.isNotEmpty
                              ? Radius.zero
                              : files.isEmpty
                                  ? const Radius.circular(15)
                                  : Radius.zero,
                          bottomLeft: const Radius.circular(15),
                          bottomRight: const Radius.circular(15),
                        ),
                        child: media.length == 1
                            ? ChatItemWidget.mediaAttachment(
                                context,
                                media.first,
                                media,
                                filled: false,
                              )
                            : SizedBox(
                                width: media.length * 120,
                                height: max(media.length * 60, 300),
                                child: FitView(
                                  dividerColor: Colors.transparent,
                                  children: media
                                      .mapIndexed(
                                        (i, e) =>
                                            ChatItemWidget.mediaAttachment(
                                          context,
                                          e,
                                          media,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                      ),
                    // if (at != null)
                    //   Align(
                    //     alignment: Alignment.bottomRight,
                    //     child: Padding(
                    //       padding: EdgeInsets.only(
                    //         top: media.isNotEmpty || files.isNotEmpty ? 4 : 0,
                    //         right: 8,
                    //         bottom: 4,
                    //       ),
                    //       child: Text(
                    //         'label_date_ymd'.l10nfmt({
                    //           'year': at.val.year.toString().padLeft(4, '0'),
                    //           'month': at.val.month.toString().padLeft(2, '0'),
                    //           'day': at.val.day.toString().padLeft(2, '0'),
                    //         }),
                    //         style: style.systemMessageStyle,
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            ),
            if (timeline != null)
              Positioned(
                right: timeInBubble ? 4 : 8,
                bottom: 4,
                child: timeInBubble
                    ? Container(
                        padding: const EdgeInsets.only(left: 4, right: 4),
                        decoration: BoxDecoration(
                          // color: Colors.white.withOpacity(0.9),
                          color: style.readMessageColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: timeline,
                      )
                    : timeline,
              )
          ],
        ),
      );
    }

    return GetBuilder(
      init: WelcomeMessageController(
        Get.find(),
        Get.find(),
        Get.find(),
        text: text,
        attachments: attachments,
        pop: () => Navigator.of(context).pop(true),
      ),
      builder: (WelcomeMessageController c) {
        final TextStyle? thin = Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: Colors.black);

        final Widget editOrDelete = info(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WidgetButton(
                onPressed: () {
                  c.send.editing.value = true;

                  c.send.field.unchecked = c.message.value?.text?.val ?? '';

                  c.send.attachments.value = c.message.value?.attachments
                          .map(
                            (e) => MapEntry(
                              GlobalKey(),
                              e,
                            ),
                          )
                          .toList() ??
                      [];
                },
                child: Text(
                  'btn_edit'.l10n,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                'space_or_space'.l10n,
                style: const TextStyle(color: Colors.black, fontSize: 11),
              ),
              WidgetButton(
                key: const Key('DeleteAvatar'),
                onPressed: () => c.message.value = null,
                child: Text(
                  'btn_delete'.l10n.toLowerCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );

        // return Obx(() {
        return CustomDropTarget(
          key: const Key('WelcomeMessageView'),
          onDragDone: c.dropFiles,
          onDragEntered: (_) => c.isDraggingFiles.value = true,
          onDragExited: (_) => c.isDraggingFiles.value = false,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  ModalPopupHeader(
                    header: Center(
                      child: Text(
                        'label_welcome_message'.l10n,
                        style: thin?.copyWith(fontSize: 18),
                      ),
                    ),
                  ),
                  Padding(
                    padding: ModalPopup.padding(context),
                    child: Text(
                      'label_welcome_message_description'.l10n,
                      style: thin,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Flexible(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              bottomRight: style.cardRadius.bottomRight,
                              bottomLeft: style.cardRadius.bottomLeft,
                            ),
                            child: Container(
                              color: Colors.transparent,
                              child: c.background.value == null
                                  ? Container(
                                      child: SvgImage.asset(
                                        'assets/images/background_light.svg',
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.memory(
                                      c.background.value!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: SingleChildScrollView(
                                child: Obx(() {
                                  if (c.message.value == null) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                      ),
                                      height: 60 * 3,
                                      child: info(
                                        child: const Text(
                                          'Здесь будет Ваше приветственное сообщение',
                                        ),
                                      ),
                                    );
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16,
                                      top: 16,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          IgnorePointer(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16,
                                              ),
                                              child: message(
                                                text: c.message.value?.text
                                                        ?.val ??
                                                    '',
                                                attachments: c.message.value
                                                        ?.attachments ??
                                                    [],
                                                at: c.message.value?.at,
                                              ),
                                            ),
                                          ),
                                          // const SizedBox(height: 5),
                                          // editOrDelete,
                                        ],
                                      ),
                                      // Row(
                                      // //   mainAxisSize: MainAxisSize.min,
                                      // //   children: [
                                      // //     // const SizedBox(width: 10),
                                      // //     Column(
                                      // //       mainAxisSize: MainAxisSize.min,
                                      // //       children: [
                                      // //         // WidgetButton(
                                      // //         //   onPressed: () {
                                      // //         //     c.send.editing.value = true;

                                      // //         //     c.send.field.unchecked = c
                                      // //         //             .message
                                      // //         //             .value
                                      // //         //             ?.text
                                      // //         //             ?.val ??
                                      // //         //         '';

                                      // //         //     c.send.attachments.value = c
                                      // //         //             .message
                                      // //         //             .value
                                      // //         //             ?.attachments
                                      // //         //             .map(
                                      // //         //               (e) => MapEntry(
                                      // //         //                 GlobalKey(),
                                      // //         //                 e,
                                      // //         //               ),
                                      // //         //             )
                                      // //         //             .toList() ??
                                      // //         //         [];
                                      // //         //   },
                                      // //         //   child: SvgImage.asset(
                                      // //         //     'assets/icons/edit_message.svg',
                                      // //         //     height: 24,
                                      // //         //     width: 24,
                                      // //         //   ),
                                      // //         // ),
                                      // //         // const SizedBox(height: 16),
                                      // //         // WidgetButton(
                                      // //         //   onPressed: () {
                                      // //         //     c.message.value = null;
                                      // //         //   },
                                      // //         //   child: SvgImage.asset(
                                      // //         //     'assets/icons/delete_message.svg',
                                      // //         //     height: 26.16,
                                      // //         //     width: 25,
                                      // //         //   ),
                                      // //         // ),
                                      // //       ],
                                      // //     ),
                                      // //     Flexible(
                                      // //       child: IgnorePointer(
                                      // //         child: message(
                                      // //           text: c.message.value?.text
                                      // //                   ?.val ??
                                      // //               '',
                                      // //           attachments: c.message.value
                                      // //                   ?.attachments ??
                                      // //               [],
                                      // //           at: c.message.value?.at,
                                      // //         ),
                                      // //       ),
                                      // //     ),
                                      // //   ],
                                      // // ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                              child: MessageFieldView(
                                fieldKey: const Key('ForwardField'),
                                sendKey: const Key('SendForward'),
                                constraints: const BoxConstraints(),
                                controller: c.send,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // IgnorePointer(
              //   child: AnimatedSwitcher(
              //     duration: 200.milliseconds,
              //     child: c.isDraggingFiles.value
              //         ? Container(
              //             color: const Color(0x40000000),
              //             child: Center(
              //               child: AnimatedDelayedScale(
              //                 duration: const Duration(milliseconds: 300),
              //                 beginScale: 1,
              //                 endScale: 1.06,
              //                 child: ConditionalBackdropFilter(
              //                   borderRadius: BorderRadius.circular(16),
              //                   child: Container(
              //                     decoration: BoxDecoration(
              //                       borderRadius: BorderRadius.circular(16),
              //                       color: const Color(0x40000000),
              //                     ),
              //                     child: const Padding(
              //                       padding: EdgeInsets.all(16),
              //                       child: Icon(
              //                         Icons.add_rounded,
              //                         size: 50,
              //                         color: Colors.white,
              //                       ),
              //                     ),
              //                   ),
              //                 ),
              //               ),
              //             ),
              //           )
              //         : null,
              //   ),
              // ),
            ],
          ),
        );
        // });
      },
    );
  }
}
