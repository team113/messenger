// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/sending_status.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/page/home/widget/init_callback.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import '../attachment_selector.dart';
import '../video_thumbnail/video_thumbnail.dart';
import 'controller.dart';

/// View of the [MessageFieldView] widget.
class MessageFieldView extends StatelessWidget {
  const MessageFieldView({
    Key? key,
    this.keepTyping,
    this.onReorder,
    this.onChatItemTap,
    this.messageFieldKey,
    this.messageSendButtonKey,
    this.updateDraft,
    this.enabledForwarding = false,
    this.canAttachFile = true,
    this.onSend,
    required this.textFieldState,
    required this.controller,
  }) : super(key: key);

  /// [Key] of message field.
  final Key? messageFieldKey;

  /// [Key] of message send button.
  final Key? messageSendButtonKey;

  /// Callback, called when the [controller.quotes] or the
  /// [controller.repliedMessages] were reordered.
  final void Function(int old, int to)? onReorder;

  /// State of a send message field.
  final TextFieldState textFieldState;

  /// Indicator whether forwarding message is enabled or not.
  final bool enabledForwarding;

  /// Indicator whether can attach files to message or not.
  final bool canAttachFile;

  /// [MessageFieldController] controller.
  final MessageFieldController controller;

  /// Callback, animated to the [ChatMessage] with the provided [ChatItemId].
  final Future<void> Function(ChatItemId id)? onChatItemTap;

  /// Callback, called when send message button was tapped.
  final void Function()? onSend;

  /// Callback, called when user typing in message field.
  final void Function()? keepTyping;

  /// Callback, called when need to update draft message.
  final void Function()? updateDraft;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    Widget sendButton() => WidgetButton(
          onPressed: onSend?.call,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: SizedBox(
                  key: messageSendButtonKey ?? const Key('Send'),
                  width: 25.18,
                  height: 22.85,
                  child: SvgLoader.asset(
                    'assets/icons/send.svg',
                    height: 22.85,
                  ),
                ),
              ),
            ),
          ),
        );

    return GetBuilder<MessageFieldController>(
      init: controller,
      global: false,
      builder: (c) => SafeArea(
        child: Container(
          key: const Key('SendField'),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  bool grab = false;
                  if (c.attachments.isNotEmpty) {
                    grab = (125 + 2) * c.attachments.length >
                        constraints.maxWidth - 16;
                  }

                  return ConditionalBackdropFilter(
                    condition: style.cardBlur > 0,
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    borderRadius: BorderRadius.only(
                      topLeft: style.cardRadius.topLeft,
                      topRight: style.cardRadius.topRight,
                    ),
                    child: Container(
                      color: const Color(0xFFFFFFFF).withOpacity(0.4),
                      child: AnimatedSize(
                        duration: 400.milliseconds,
                        curve: Curves.ease,
                        child: Obx(() {
                          return Container(
                            width: double.infinity,
                            padding: c.repliedMessages.isNotEmpty ||
                                    c.attachments.isNotEmpty
                                ? const EdgeInsets.fromLTRB(4, 6, 4, 6)
                                : EdgeInsets.zero,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (c.editedMessage.value != null)
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height /
                                              3,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        4,
                                        4,
                                        4,
                                        4,
                                      ),
                                      child: Dismissible(
                                        key:
                                            Key('${c.editedMessage.value?.id}'),
                                        direction: DismissDirection.horizontal,
                                        onDismissed: (_) =>
                                            c.editedMessage.value = null,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          child: buildEditedMessage(
                                            context,
                                            c,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (c.quotes.isNotEmpty)
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height /
                                              3,
                                    ),
                                    child: Obx(() {
                                      return ReorderableListView(
                                        shrinkWrap: true,
                                        buildDefaultDragHandles:
                                            PlatformUtils.isMobile,
                                        onReorder: (int from, int to) {
                                          onReorder?.call(from, to);
                                        },
                                        proxyDecorator: (child, i, animation) {
                                          return AnimatedBuilder(
                                            animation: animation,
                                            builder: (
                                              BuildContext context,
                                              Widget? child,
                                            ) {
                                              final double t = Curves.easeInOut
                                                  .transform(animation.value);
                                              final double elevation =
                                                  lerpDouble(0, 6, t)!;
                                              final Color color = Color.lerp(
                                                const Color(0x00000000),
                                                const Color(0x33000000),
                                                t,
                                              )!;

                                              return InitCallback(
                                                callback: HapticFeedback
                                                    .selectionClick,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    boxShadow: [
                                                      CustomBoxShadow(
                                                        color: color,
                                                        blurRadius: elevation,
                                                      ),
                                                    ],
                                                  ),
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: child,
                                          );
                                        },
                                        reverse: true,
                                        padding: const EdgeInsets.fromLTRB(
                                          1,
                                          0,
                                          1,
                                          0,
                                        ),
                                        children: c.quotes.map((e) {
                                          return ReorderableDragStartListener(
                                            key: Key('Handle_${e.item.id}'),
                                            enabled: !PlatformUtils.isMobile,
                                            index: c.quotes.indexOf(e),
                                            child: Dismissible(
                                              key: Key('${e.item.id}'),
                                              direction:
                                                  DismissDirection.horizontal,
                                              onDismissed: (_) {
                                                c.quotes.remove(e);
                                                if (c.quotes.isEmpty) {
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 2,
                                                ),
                                                child: buildForwardedMessage(
                                                  context,
                                                  e.item,
                                                  c,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    }),
                                  ),
                                if (c.repliedMessages.isNotEmpty)
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height /
                                              3,
                                    ),
                                    child: ReorderableListView(
                                      shrinkWrap: true,
                                      buildDefaultDragHandles:
                                          PlatformUtils.isMobile,
                                      onReorder: (from, to) {
                                        onReorder?.call(from, to);
                                      },
                                      proxyDecorator: (child, i, animation) {
                                        return AnimatedBuilder(
                                          animation: animation,
                                          builder: (
                                            BuildContext context,
                                            Widget? child,
                                          ) {
                                            final double t = Curves.easeInOut
                                                .transform(animation.value);
                                            final double elevation =
                                                lerpDouble(0, 6, t)!;
                                            final Color color = Color.lerp(
                                              const Color(0x00000000),
                                              const Color(0x33000000),
                                              t,
                                            )!;

                                            return InitCallback(
                                              callback:
                                                  HapticFeedback.selectionClick,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  boxShadow: [
                                                    CustomBoxShadow(
                                                      color: color,
                                                      blurRadius: elevation,
                                                    ),
                                                  ],
                                                ),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: child,
                                        );
                                      },
                                      reverse: true,
                                      padding: const EdgeInsets.fromLTRB(
                                        1,
                                        0,
                                        1,
                                        0,
                                      ),
                                      children: c.repliedMessages.map((e) {
                                        return ReorderableDragStartListener(
                                          key: Key('Handle_${e.id}'),
                                          enabled: !PlatformUtils.isMobile,
                                          index: c.repliedMessages.indexOf(e),
                                          child: Dismissible(
                                            key: Key('${e.id}'),
                                            direction:
                                                DismissDirection.horizontal,
                                            onDismissed: (_) {
                                              c.repliedMessages.remove(e);
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 2,
                                              ),
                                              child: repliedMessage(
                                                context,
                                                e,
                                                c,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                if (c.attachments.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: MouseRegion(
                                      cursor: grab
                                          ? SystemMouseCursors.grab
                                          : MouseCursor.defer,
                                      opaque: false,
                                      child: ScrollConfiguration(
                                        behavior: CustomScrollBehavior(),
                                        child: SingleChildScrollView(
                                          clipBehavior: Clip.none,
                                          physics: grab
                                              ? null
                                              : const NeverScrollableScrollPhysics(),
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: c.attachments
                                                .map(
                                                  (e) => buildAttachment(
                                                    context,
                                                    e.value,
                                                    e.key,
                                                    c,
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                }),
                Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  decoration: BoxDecoration(color: style.cardColor),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!PlatformUtils.isMobile || PlatformUtils.isWeb)
                        WidgetButton(
                          onPressed: canAttachFile ? c.pickFile : null,
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: SvgLoader.asset(
                                  'assets/icons/attach.svg',
                                  height: 22,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        WidgetButton(
                          onPressed: canAttachFile
                              ? () => AttachmentSourceSelector.show(
                                    context,
                                    onPickFile: c.pickFile,
                                    onTakePhoto: c.pickImageFromCamera,
                                    onPickMedia: c.pickMedia,
                                    onTakeVideo: c.pickVideoFromCamera,
                                  )
                              : null,
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: SvgLoader.asset(
                                  'assets/icons/attach.svg',
                                  height: 22,
                                ),
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
                              onChanged: keepTyping,
                              key: messageFieldKey ?? const Key('MessageField'),
                              state: textFieldState,
                              hint: 'label_send_message_hint'.l10n,
                              minLines: 1,
                              maxLines: 7,
                              filled: false,
                              dense: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              style: style.boldBody.copyWith(fontSize: 17),
                              type: TextInputType.multiline,
                              textInputAction: TextInputAction.send,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onLongPress: c.forwarding.toggle,
                        child: enabledForwarding
                            ? Obx(
                                () => AnimatedSwitcher(
                                  duration: 300.milliseconds,
                                  child: c.forwarding.value == true
                                      ? WidgetButton(
                                          onPressed: () {
                                            onSend?.call();
                                          },
                                          child: SizedBox(
                                            width: 56,
                                            height: 56,
                                            child: Center(
                                              child: AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 150,
                                                ),
                                                child: SizedBox(
                                                  width: 26,
                                                  height: 22,
                                                  child: SvgLoader.asset(
                                                    'assets/icons/forward.svg',
                                                    width: 26,
                                                    height: 22,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : sendButton(),
                                ),
                              )
                            : sendButton(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns a visual representation of the provided [Attachment].
  Widget buildAttachment(
    BuildContext context,
    Attachment e,
    GlobalKey key,
    MessageFieldController c,
  ) {
    bool isImage =
        (e is ImageAttachment || (e is LocalAttachment && e.file.isImage));
    bool isVideo = (e is FileAttachment && e.isVideo) ||
        (e is LocalAttachment && e.file.isVideo);

    const double size = 125;

    // Builds the visual representation of the provided [Attachment] itself.
    Widget content() {
      if (isImage || isVideo) {
        Widget child;

        if (isImage) {
          if (e is LocalAttachment) {
            if (e.file.bytes == null) {
              if (e.file.path == null) {
                child = const Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                if (e.file.isSvg) {
                  child = SvgLoader.file(
                    File(e.file.path!),
                    width: size,
                    height: size,
                  );
                } else {
                  child = Image.file(
                    File(e.file.path!),
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                  );
                }
              }
            } else {
              if (e.file.isSvg) {
                child = SvgLoader.bytes(
                  e.file.bytes!,
                  width: size,
                  height: size,
                );
              } else {
                child = Image.memory(
                  e.file.bytes!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                );
              }
            }
          } else {
            child = RetryImage(
              e.original.url,
              fit: BoxFit.cover,
              width: size,
              height: size,
            );
          }
        } else {
          if (e is LocalAttachment) {
            if (e.file.bytes == null) {
              child = const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              child = VideoThumbnail.bytes(bytes: e.file.bytes!);
            }
          } else {
            child = VideoThumbnail.url(url: e.original.url);
          }
        }

        List<Attachment> attachmentsList = c.attachments
            .where((e) {
              Attachment a = e.value;
              return a is ImageAttachment ||
                  (a is FileAttachment && a.isVideo) ||
                  (a is LocalAttachment && (a.file.isImage || a.file.isVideo));
            })
            .map((e) => e.value)
            .toList();

        return WidgetButton(
          key: key,
          onPressed: () {
            int index = c.attachments.indexOf(e);
            if (index != -1) {
              GalleryPopup.show(
                context: context,
                gallery: GalleryPopup(
                  initial: c.attachments.indexOf(e),
                  initialKey: key,
                  onTrashPressed: (int i) {
                    Attachment a = attachmentsList[i];
                    c.attachments.removeWhere((o) => o.value == a);
                  },
                  children: attachmentsList.map((o) {
                    if (o is ImageAttachment ||
                        (o is LocalAttachment && o.file.isImage)) {
                      return GalleryItem.image(
                        e.original.url,
                        o.filename,
                        size: o.original.size,
                      );
                    }
                    return GalleryItem.video(
                      e.original.url,
                      o.filename,
                      size: o.original.size,
                    );
                  }).toList(),
                ),
              );
            }
          },
          child: isVideo
              ? IgnorePointer(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      child,
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x80000000),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                )
              : child,
        );
      }

      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      p.basenameWithoutExtension(e.filename),
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    p.extension(e.filename),
                    style: const TextStyle(fontSize: 13),
                  )
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                'label_kb'.l10nfmt({
                  'amount': e.original.size == null
                      ? 'dot'.l10n * 3
                      : e.original.size! ~/ 1024
                }),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Builds the [content] along with manipulation buttons and statuses.
    Widget attachment() {
      final Style style = Theme.of(context).extension<Style>()!;
      return MouseRegion(
        key: Key('Attachment_${e.id}'),
        opaque: false,
        onEnter: (_) => c.hoveredAttachment.value = e,
        onExit: (_) => c.hoveredAttachment.value = null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFF5F5F5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: content(),
              ),
              Center(
                child: SizedBox.square(
                  dimension: 30,
                  child: ElasticAnimatedSwitcher(
                    child: e is LocalAttachment
                        ? e.status.value == SendingStatus.error
                            ? Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                              )
                            : const SizedBox()
                        : const SizedBox(),
                  ),
                ),
              ),
              if (!textFieldState.status.value.isLoading)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: Obx(() {
                      return AnimatedSwitcher(
                        duration: 200.milliseconds,
                        child: (c.hoveredAttachment.value == e ||
                                PlatformUtils.isMobile)
                            ? InkWell(
                                key: const Key('RemovePickedFile'),
                                onTap: () => c.attachments
                                    .removeWhere((a) => a.value == e),
                                child: Container(
                                  width: 15,
                                  height: 15,
                                  margin:
                                      const EdgeInsets.only(left: 8, bottom: 8),
                                  child: Container(
                                    key: const Key('Close'),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: style.cardColor,
                                    ),
                                    child: Center(
                                      child: SvgLoader.asset(
                                        'assets/icons/close_primary.svg',
                                        width: 7,
                                        height: 7,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Dismissible(
      key: Key(e.id.val),
      direction: DismissDirection.up,
      onDismissed: (_) => c.attachments.removeWhere((a) => a.value == e),
      child: attachment(),
    );
  }

  /// Builds a visual representation of the provided [item] being replied.
  Widget repliedMessage(
    BuildContext context,
    ChatItem item,
    MessageFieldController c,
  ) {
    final Style style = Theme.of(context).extension<Style>()!;
    final bool fromMe = item.authorId == c.me;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessage) {
      if (item.attachments.isNotEmpty) {
        additional = item.attachments.map((a) {
          ImageAttachment? image;

          if (a is ImageAttachment) {
            image = a;
          }

          return Container(
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: fromMe
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(4),
              image: image == null
                  ? null
                  : DecorationImage(image: NetworkImage(image.small.url)),
            ),
            width: 30,
            height: 30,
            child: image == null
                ? Icon(
                    Icons.file_copy,
                    color: fromMe ? Colors.white : const Color(0xFFDDDDDD),
                    size: 16,
                  )
                : null,
          );
        }).toList();
      }

      if (item.text != null && item.text!.val.isNotEmpty) {
        content = Text(
          item.text!.val.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.boldBody,
        );
      }
    } else if (item is ChatCall) {
      String title = 'label_chat_call_ended'.l10n;
      String? time;
      bool fromMe = c.me == item.authorId;
      bool isMissed = false;

      if (item.finishReason == null && item.conversationStartedAt != null) {
        title = 'label_chat_call_ongoing'.l10n;
      } else if (item.finishReason != null) {
        title = item.finishReason!.localizedString(fromMe) ?? title;
        isMissed = item.finishReason == ChatCallFinishReason.dropped ||
            item.finishReason == ChatCallFinishReason.unanswered;

        if (item.finishedAt != null && item.conversationStartedAt != null) {
          time = item.conversationStartedAt!.val
              .difference(item.finishedAt!.val)
              .localizedString();
        }
      } else {
        title = item.authorId == c.me
            ? 'label_outgoing_call'.l10n
            : 'label_incoming_call'.l10n;
      }

      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
            child: item.withVideo
                ? SvgLoader.asset(
                    'assets/icons/call_video${isMissed && !fromMe ? '_red' : ''}.svg',
                    height: 13,
                  )
                : SvgLoader.asset(
                    'assets/icons/call_audio${isMissed && !fromMe ? '_red' : ''}.svg',
                    height: 15,
                  ),
          ),
          Flexible(child: Text(title, style: style.boldBody)),
          if (time != null) ...[
            const SizedBox(width: 9),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.boldBody.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      );
    } else if (item is ChatForward) {
      // TODO: Implement `ChatForward`.
      content = Text('label_forwarded_message'.l10n, style: style.boldBody);
    } else if (item is ChatMemberInfo) {
      // TODO: Implement `ChatMemberInfo`.
      content = Text(item.action.toString(), style: style.boldBody);
    } else {
      content = Text('err_unknown'.l10n, style: style.boldBody);
    }

    return MouseRegion(
      opaque: false,
      onEnter: (d) => c.hoveredReply.value = item,
      onExit: (d) => c.hoveredReply.value = null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<RxUser?>(
                  future: c.getUser(item.authorId),
                  builder: (context, snapshot) {
                    Color color = snapshot.data?.user.value.id == c.me
                        ? Theme.of(context).colorScheme.secondary
                        : AvatarWidget.colors[
                            (snapshot.data?.user.value.num.val.sum() ?? 3) %
                                AvatarWidget.colors.length];

                    return Container(
                      key: Key('Reply_${c.repliedMessages.indexOf(item)}'),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(width: 2, color: color),
                        ),
                      ),
                      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              String? name;

                              if (snapshot.hasData) {
                                name = snapshot.data?.user.value.name?.val;
                                if (snapshot.data?.user.value != null) {
                                  return Obx(() {
                                    return Text(
                                      snapshot.data!.user.value.name?.val ??
                                          snapshot.data!.user.value.num.val,
                                      style:
                                          style.boldBody.copyWith(color: color),
                                    );
                                  });
                                }
                              }

                              return Text(
                                name ?? ('dot'.l10n * 3),
                                style: style.boldBody.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              );
                            },
                          ),
                          if (content != null) ...[
                            const SizedBox(height: 2),
                            DefaultTextStyle.merge(maxLines: 1, child: content),
                          ],
                          if (additional.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(children: additional),
                          ],
                        ],
                      ),
                    );
                  }),
            ),
            AnimatedSwitcher(
              duration: 200.milliseconds,
              child: c.hoveredReply.value == item || PlatformUtils.isMobile
                  ? WidgetButton(
                      key: const Key('CancelReplyButton'),
                      onPressed: () {
                        c.repliedMessages.remove(item);
                      },
                      child: Container(
                        width: 15,
                        height: 15,
                        margin: const EdgeInsets.only(right: 4, top: 4),
                        child: Container(
                          key: const Key('Close'),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: style.cardColor,
                          ),
                          child: Center(
                            child: SvgLoader.asset(
                              'assets/icons/close_primary.svg',
                              width: 7,
                              height: 7,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a visual representation of a [controller.repliedMessages].
  Widget buildForwardedMessage(
    BuildContext context,
    ChatItem item,
    MessageFieldController c,
  ) {
    Style style = Theme.of(context).extension<Style>()!;
    bool fromMe = item.authorId == c.me;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessage) {
      var desc = StringBuffer();

      if (item.text != null) {
        desc.write(item.text!.val);
      }

      if (item.attachments.isNotEmpty) {
        additional = item.attachments.map((a) {
          ImageAttachment? image;

          if (a is ImageAttachment) {
            image = a;
          }

          return Container(
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: fromMe
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(4),
              image: image == null
                  ? null
                  : DecorationImage(image: NetworkImage(image.original.url)),
            ),
            width: 30,
            height: 30,
            child: image == null
                ? Icon(
                    Icons.file_copy,
                    color: fromMe ? Colors.white : const Color(0xFFDDDDDD),
                    size: 16,
                  )
                : null,
          );
        }).toList();
      }

      if (desc.isNotEmpty) {
        content = Text(
          desc.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.boldBody,
        );
      }
    } else if (item is ChatCall) {
      String title = 'label_chat_call_ended'.l10n;
      String? time;
      bool fromMe = c.me == item.authorId;
      bool isMissed = false;

      if (item.finishReason == null && item.conversationStartedAt != null) {
        title = 'label_chat_call_ongoing'.l10n;
      } else if (item.finishReason != null) {
        title = item.finishReason!.localizedString(fromMe) ?? title;
        isMissed = item.finishReason == ChatCallFinishReason.dropped ||
            item.finishReason == ChatCallFinishReason.unanswered;
        time = item.conversationStartedAt!.val
            .difference(item.finishedAt!.val)
            .localizedString();
      } else {
        title = item.authorId == c.me
            ? 'label_outgoing_call'.l10n
            : 'label_incoming_call'.l10n;
      }

      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
            child: item.withVideo
                ? SvgLoader.asset(
                    'assets/icons/call_video${isMissed && !fromMe ? '_red' : ''}.svg',
                    height: 13,
                  )
                : SvgLoader.asset(
                    'assets/icons/call_audio${isMissed && !fromMe ? '_red' : ''}.svg',
                    height: 15,
                  ),
          ),
          Flexible(child: Text(title, style: style.boldBody)),
          if (time != null) ...[
            const SizedBox(width: 9),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.boldBody
                    .copyWith(color: const Color(0xFF888888), fontSize: 13),
              ),
            ),
          ],
        ],
      );
    } else if (item is ChatForward) {
      // TODO: Implement `ChatForward`.
      content = Text('label_forwarded_message'.l10n, style: style.boldBody);
    } else if (item is ChatMemberInfo) {
      // TODO: Implement `ChatMemberInfo`.
      content = Text(item.action.toString(), style: style.boldBody);
    } else {
      content = Text('err_unknown'.l10n, style: style.boldBody);
    }

    return MouseRegion(
      opaque: false,
      onEnter: (d) => c.hoveredReply.value = item,
      onExit: (d) => c.hoveredReply.value = null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<RxUser?>(
                  future: c.getUser(item.authorId),
                  builder: (context, snapshot) {
                    Color color = snapshot.data?.user.value.id == c.me
                        ? const Color(0xFF63B4FF)
                        : AvatarWidget.colors[
                            (snapshot.data?.user.value.num.val.sum() ?? 3) %
                                AvatarWidget.colors.length];

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            width: 2,
                            color: color,
                          ),
                        ),
                      ),
                      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<RxUser?>(
                            future: c.getUser(item.authorId),
                            builder: (context, snapshot) {
                              String? name;
                              if (snapshot.hasData) {
                                name = snapshot.data?.user.value.name?.val;
                                if (snapshot.data?.user.value != null) {
                                  return Obx(() {
                                    Color color =
                                        snapshot.data?.user.value.id == c.me
                                            ? const Color(0xFF63B4FF)
                                            : AvatarWidget.colors[snapshot
                                                    .data!.user.value.num.val
                                                    .sum() %
                                                AvatarWidget.colors.length];

                                    return Text(
                                        snapshot.data!.user.value.name?.val ??
                                            snapshot.data!.user.value.num.val,
                                        style: style.boldBody
                                            .copyWith(color: color));
                                  });
                                }
                              }

                              return Text(
                                name ?? '...',
                                style: style.boldBody
                                    .copyWith(color: const Color(0xFF63B4FF)),
                              );
                            },
                          ),
                          if (content != null) ...[
                            const SizedBox(height: 2),
                            DefaultTextStyle.merge(
                              maxLines: 1,
                              child: content,
                            ),
                          ],
                          if (additional.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(children: additional),
                          ],
                        ],
                      ),
                    );
                  }),
            ),
            AnimatedSwitcher(
              duration: 200.milliseconds,
              child: c.hoveredReply.value == item || PlatformUtils.isMobile
                  ? WidgetButton(
                      key: const Key('CancelReplyButton'),
                      onPressed: () {
                        c.quotes.removeWhere((e) => e.item == item);
                      },
                      child: Container(
                        width: 15,
                        height: 15,
                        margin: const EdgeInsets.only(right: 4, top: 4),
                        child: Container(
                          key: const Key('Close'),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: style.cardColor,
                          ),
                          child: Center(
                            child: SvgLoader.asset(
                              'assets/icons/close_primary.svg',
                              width: 7,
                              height: 7,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a visual representation of a [controller.editedMessage].
  Widget buildEditedMessage(BuildContext context, MessageFieldController c) {
    final Style style = Theme.of(context).extension<Style>()!;
    final bool fromMe = c.editedMessage.value?.authorId == c.me;

    if (c.editedMessage.value != null) {
      if (c.editedMessage.value is ChatMessage) {
        Widget? content;
        List<Widget> additional = [];

        final ChatMessage item = c.editedMessage.value as ChatMessage;

        var desc = StringBuffer();
        if (item.text != null) {
          desc.write(item.text!.val);
        }

        if (item.attachments.isNotEmpty) {
          additional = item.attachments.map((a) {
            ImageAttachment? image;

            if (a is ImageAttachment) {
              image = a;
            }

            return Container(
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: fromMe
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(4),
                image: image == null
                    ? null
                    : DecorationImage(image: NetworkImage(image.small.url)),
              ),
              width: 30,
              height: 30,
              child: image == null
                  ? Icon(
                      Icons.file_copy,
                      color: fromMe ? Colors.white : const Color(0xFFDDDDDD),
                      size: 16,
                    )
                  : null,
            );
          }).toList();
        }

        if (item.text != null) {
          content = Text(
            item.text!.val,
            style: style.boldBody,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        return WidgetButton(
          onPressed: () => onChatItemTap?.call(item.id),
          child: MouseRegion(
            opaque: false,
            onEnter: (d) => c.hoveredReply.value = item,
            onExit: (d) => c.hoveredReply.value = null,
            child: Container(
              margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 12),
                        SvgLoader.asset(
                          'assets/icons/edit.svg',
                          width: 17,
                          height: 17,
                        ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  width: 2,
                                  color: Color(0xFF63B4FF),
                                ),
                              ),
                            ),
                            margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            padding: const EdgeInsets.only(left: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'label_edit'.l10n,
                                  style: style.boldBody.copyWith(
                                    color: const Color(0xFF63B4FF),
                                  ),
                                ),
                                if (content != null) ...[
                                  const SizedBox(height: 2),
                                  DefaultTextStyle.merge(
                                    maxLines: 1,
                                    child: content,
                                  ),
                                ],
                                if (additional.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(children: additional),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(() {
                    return AnimatedSwitcher(
                      duration: 200.milliseconds,
                      child: c.hoveredReply.value == item ||
                              PlatformUtils.isMobile
                          ? WidgetButton(
                              key: const Key('CancelEditButton'),
                              onPressed: () => c.editedMessage.value = null,
                              child: Container(
                                width: 15,
                                height: 15,
                                margin: const EdgeInsets.only(right: 4, top: 4),
                                child: Container(
                                  key: const Key('Close'),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: style.cardColor,
                                  ),
                                  child: Center(
                                    child: SvgLoader.asset(
                                      'assets/icons/close_primary.svg',
                                      width: 7,
                                      height: 7,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox(),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }
}
