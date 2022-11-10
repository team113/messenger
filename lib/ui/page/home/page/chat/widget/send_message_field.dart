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
import '/ui/page/home/page/chat/controller.dart';
import '/domain/model/user.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import '/util/obs/obs.dart';
import 'init_callback.dart';
import 'video_thumbnail/video_thumbnail.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/sending_status.dart';
import '/domain/repository/user.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/component/attachment_selector.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';

class SendMessageField extends StatelessWidget {
  SendMessageField({
    Key? key,
    this.onPickImageFromCamera,
    this.onVideoImageFromCamera,
    this.onPickMedia,
    this.onPickFile,
    this.keepTyping,
    this.forwarding,
    this.onSend,
    this.repliedMessages,
    this.attachments,
    this.onReorder,
    this.quotes,
    this.editedMessage,
    this.animateTo,
    this.messageFieldKey,
    this.messageSendButtonKey,
    this.me,
    required this.textFieldState,
  }) : super(key: key);

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService = Get.find();

  /// [Key] of message field.
  final Key? messageFieldKey;

  /// [Key] of message send button.
  final Key? messageSendButtonKey;

  /// [ChatItemQuote]s to be forwarded.
  final RxList<ChatItemQuote>? quotes;

  /// [ChatItem] being quoted to reply onto.
  final RxList<ChatItem>? repliedMessages;

  /// Callback, called when an item is reordered.
  final void Function(int old, int to)? onReorder;

  /// [Attachment]s to be attached to a message.
  final RxObsList<MapEntry<GlobalKey, Attachment>>? attachments;

  /// State of a send message field.
  final TextFieldState textFieldState;

  /// Indicator whether forwarding mode is enabled.
  final RxBool? forwarding;

  /// Users [UserId].
  final UserId? me;

  /// [ChatItem] being edited.
  final Rx<ChatItem?>? editedMessage;

  /// [Attachment] being hovered.
  final Rx<Attachment?> hoveredAttachment = Rx(null);

  /// Replied [ChatItem] being hovered.
  final Rx<ChatItem?> hoveredReply = Rx(null);

  /// Callback, called when called pick image from camera.
  final void Function()? onPickImageFromCamera;

  /// Callback, called when need animate to some [ChatMessage].
  final Future<void> Function(
    ChatItemId id, {
    bool offsetBasedOnBottom,
    double offset,
  })? animateTo;

  /// Callback, called when called pick video from camera.
  final void Function()? onVideoImageFromCamera;

  /// Callback, called when called pick media.
  final void Function()? onPickMedia;

  /// Callback, called when called pick file.
  final void Function()? onPickFile;

  /// Callback, called when user typing in message field.
  final void Function()? keepTyping;

  /// Callback, called when message was send.
  final void Function()? onSend;

  @override
  Widget build(BuildContext context) {
    Style style = Theme.of(context).extension<Style>()!;

    Widget sendButton() => WidgetButton(
          onPressed: onSend,
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

    return SafeArea(
      child: Container(
        key: const Key('SendField'),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(builder: (context, constraints) {
                bool grab = false;
                if (attachments != null) {
                  grab = (125 + 2) * attachments!.length >
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
                          padding: (repliedMessages != null &&
                                      repliedMessages!.isNotEmpty) ||
                                  (attachments != null &&
                                      attachments!.isNotEmpty)
                              ? const EdgeInsets.fromLTRB(4, 6, 4, 6)
                              : EdgeInsets.zero,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (editedMessage?.value != null)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height / 3,
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(4, 4, 4, 4),
                                    child: Dismissible(
                                      key: Key('${editedMessage?.value?.id}'),
                                      direction: DismissDirection.horizontal,
                                      onDismissed: (_) =>
                                          editedMessage?.value = null,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: editedMessageWidget(context),
                                      ),
                                    ),
                                  ),
                                ),
                              if (quotes != null && quotes!.isNotEmpty)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height / 3,
                                  ),
                                  child: ReorderableListView(
                                    shrinkWrap: true,
                                    buildDefaultDragHandles:
                                        PlatformUtils.isMobile,
                                    onReorder: (int old, int to) {
                                      if (old < to) {
                                        --to;
                                      }

                                      final ChatItemQuote item =
                                          quotes!.removeAt(old);
                                      quotes!.insert(to, item);

                                      HapticFeedback.lightImpact();
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
                                    padding:
                                        const EdgeInsets.fromLTRB(1, 0, 1, 0),
                                    children: quotes!.map((e) {
                                      return ReorderableDragStartListener(
                                        key: Key('Handle_${e.item.id}'),
                                        enabled: !PlatformUtils.isMobile,
                                        index: quotes!.indexOf(e),
                                        child: Dismissible(
                                          key: Key('${e.item.id}'),
                                          direction:
                                              DismissDirection.horizontal,
                                          onDismissed: (_) {
                                            quotes!.remove(e);
                                            if (quotes!.isEmpty) {
                                              Navigator.of(context).pop();
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
                                            child: buildForwardedMessage(
                                              context,
                                              e.item,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              if (repliedMessages != null &&
                                  repliedMessages!.isNotEmpty)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height / 3,
                                  ),
                                  child: ReorderableListView(
                                    shrinkWrap: true,
                                    buildDefaultDragHandles:
                                        PlatformUtils.isMobile,
                                    onReorder: (i, a) {
                                      onReorder?.call(i, a);
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
                                    children: repliedMessages!.map((e) {
                                      return ReorderableDragStartListener(
                                        key: Key('Handle_${e.id}'),
                                        enabled: !PlatformUtils.isMobile,
                                        index: repliedMessages!.indexOf(e),
                                        child: Dismissible(
                                          key: Key('${e.id}'),
                                          direction:
                                              DismissDirection.horizontal,
                                          onDismissed: (_) {
                                            repliedMessages!.remove(e);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
                                            child: repliedMessage(context, e),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              if (attachments != null &&
                                  attachments!.isNotEmpty) ...[
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
                                          children: attachments!
                                              .map(
                                                (e) => buildAttachment(
                                                  context,
                                                  e.value,
                                                  e.key,
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
                        onPressed: onPickFile,
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
                        onPressed: () => AttachmentSourceSelector.show(
                          context,
                          onPickFile: onPickFile,
                          onPickImageFromCamera: onPickImageFromCamera,
                          onPickMedia: onPickMedia,
                          onVideoImageFromCamera: onVideoImageFromCamera,
                        ),
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
                      onLongPress: () {
                        forwarding?.toggle();
                        // setState(() {});
                      },
                      child: forwarding != null
                          ? Obx(() => AnimatedSwitcher(
                                duration: 300.milliseconds,
                                child: forwarding?.value == true
                                    ? WidgetButton(
                                        onPressed: onSend,
                                        child: SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: Center(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 150),
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
                              ))
                          : sendButton(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns a visual representation of the provided [Attachment].
  Widget buildAttachment(BuildContext context, Attachment e, GlobalKey key) {
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
            child = Image.network(
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

        List<Attachment> attachmentsList = attachments!
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
            int index = attachments!.indexOf(e);
            if (index != -1) {
              GalleryPopup.show(
                context: context,
                gallery: GalleryPopup(
                  initial: attachments!.indexOf(e),
                  initialKey: key,
                  onTrashPressed: (int i) {
                    Attachment a = attachmentsList[i];
                    attachments!.removeWhere((o) => o.value == a);
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
    Widget attachmentWidget() {
      Style style = Theme.of(context).extension<Style>()!;
      return MouseRegion(
        key: Key('Attachment_${e.id}'),
        opaque: false,
        onEnter: (_) => hoveredAttachment.value = e,
        onExit: (_) => hoveredAttachment.value = null,
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
                        child: (hoveredAttachment.value == e ||
                                PlatformUtils.isMobile)
                            ? InkWell(
                                key: const Key('RemovePickedFile'),
                                onTap: () => attachments!
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
      onDismissed: (_) => attachments!.removeWhere((a) => a.value == e),
      child: attachmentWidget(),
    );
  }

  /// Builds a visual representation of the provided [item] being replied.
  Widget repliedMessage(BuildContext context, ChatItem item) {
    Style style = Theme.of(context).extension<Style>()!;
    bool fromMe = item.authorId == me;

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
      bool fromMe = me == item.authorId;
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
        title = item.authorId == me
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
      onEnter: (d) => hoveredReply.value = item,
      onExit: (d) => hoveredReply.value = null,
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
                  future: _userService.get(item.authorId),
                  builder: (context, snapshot) {
                    Color color = snapshot.data?.user.value.id == me
                        ? Theme.of(context).colorScheme.secondary
                        : AvatarWidget.colors[
                            (snapshot.data?.user.value.num.val.sum() ?? 3) %
                                AvatarWidget.colors.length];

                    return Container(
                      key: Key('Reply_${repliedMessages!.indexOf(item)}'),
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
              child: hoveredReply.value == item || PlatformUtils.isMobile
                  ? WidgetButton(
                      key: const Key('CancelReplyButton'),
                      onPressed: () {
                        repliedMessages!.remove(item);
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

  /// Builds a visual representation of a [ChatController.repliedMessages].
  Widget buildForwardedMessage(
    BuildContext context,
    ChatItem item,
  ) {
    Style style = Theme.of(context).extension<Style>()!;
    bool fromMe = item.authorId == me;

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
      bool fromMe = me == item.authorId;
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
        title = item.authorId == me
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
      onEnter: (d) => hoveredReply.value = item,
      onExit: (d) => hoveredReply.value = null,
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
                  future: _userService.get(item.authorId),
                  builder: (context, snapshot) {
                    Color color = snapshot.data?.user.value.id == me
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
                            future: _userService.get(item.authorId),
                            builder: (context, snapshot) {
                              String? name;
                              if (snapshot.hasData) {
                                name = snapshot.data?.user.value.name?.val;
                                if (snapshot.data?.user.value != null) {
                                  return Obx(() {
                                    Color color =
                                        snapshot.data?.user.value.id == me
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
              child: hoveredReply.value == item || PlatformUtils.isMobile
                  ? WidgetButton(
                      key: const Key('CancelReplyButton'),
                      onPressed: () {
                        quotes!.removeWhere((e) => e.item == item);
                        if (quotes!.isEmpty) {
                          Navigator.of(context).pop();
                        }
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

  /// Builds a visual representation of a [ChatController.editedMessage].
  Widget editedMessageWidget(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;
    final bool fromMe = editedMessage?.value?.authorId == me;

    if (editedMessage?.value != null) {
      if (editedMessage?.value is ChatMessage) {
        Widget? content;
        List<Widget> additional = [];

        final ChatMessage item = editedMessage?.value as ChatMessage;

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
          onPressed: () => animateTo?.call(item.id, offsetBasedOnBottom: true),
          child: MouseRegion(
            opaque: false,
            onEnter: (d) => hoveredReply.value = item,
            onExit: (d) => hoveredReply.value = null,
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
                      child: hoveredReply.value == item ||
                              PlatformUtils.isMobile
                          ? WidgetButton(
                              key: const Key('CancelEditButton'),
                              onPressed: () => editedMessage?.value = null,
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
