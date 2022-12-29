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

import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/sending_status.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/attachment_selector.dart';
import '/ui/page/home/page/chat/widget/video_thumbnail/video_thumbnail.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/page/home/widget/init_callback.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/message.dart';

/// View for writing and editing a [ChatMessage] or a [ChatForward].
class MessageFieldView extends StatelessWidget {
  const MessageFieldView({
    super.key,
    this.onChanged,
    this.onItemPressed,
    this.fieldKey,
    this.sendKey,
    this.canForward = false,
    this.canAttach = true,
    this.controller,
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

  /// Callback, called when a [ChatItem] being a reply or forward of this
  /// [MessageFieldView] is pressed.
  final Future<void> Function(ChatItemId id)? onItemPressed;

  /// Callback, called when the contents of this [MessageFieldView] changes.
  final void Function()? onChanged;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      init: controller ?? MessageFieldController(Get.find(), Get.find()),
      global: false,
      builder: (MessageFieldController c) {
        return Theme(
          data: Theme.of(context).copyWith(
            shadowColor: const Color(0x55000000),
            iconTheme: const IconThemeData(color: Colors.blue),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              focusColor: Colors.white,
              fillColor: Colors.white,
              hoverColor: Colors.transparent,
              filled: true,
              isDense: true,
              contentPadding: EdgeInsets.fromLTRB(
                15,
                PlatformUtils.isDesktop ? 30 : 23,
                15,
                0,
              ),
            ),
          ),
          child: SafeArea(
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
                          color: Colors.white.withOpacity(0.4),
                          child: AnimatedSize(
                            duration: 400.milliseconds,
                            curve: Curves.ease,
                            child: Obx(() {
                              return Container(
                                width: double.infinity,
                                padding: c.replied.isNotEmpty ||
                                        c.attachments.isNotEmpty
                                    ? const EdgeInsets.fromLTRB(4, 6, 4, 6)
                                    : EdgeInsets.zero,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Obx(() {
                                      if (c.editedMessage.value != null) {
                                        return ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(context)
                                                    .size
                                                    .height /
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
                                              key: Key(
                                                  '${c.editedMessage.value?.id}'),
                                              direction:
                                                  DismissDirection.horizontal,
                                              onDismissed: (_) =>
                                                  c.editedMessage.value = null,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 2,
                                                ),
                                                child: MessageFieldMessage(
                                                  c.editedMessage.value!,
                                                  c,
                                                  () => c.editedMessage.value =
                                                      null,
                                                  isEdit: true,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        return Container();
                                      }
                                    }),
                                    if (c.quotes.isNotEmpty)
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              3,
                                        ),
                                        child: Obx(() {
                                          return ReorderableListView(
                                            shrinkWrap: true,
                                            buildDefaultDragHandles:
                                                PlatformUtils.isMobile,
                                            onReorder: (int old, int to) {
                                              if (old < to) {
                                                --to;
                                              }

                                              final ChatItemQuote item =
                                                  c.quotes.removeAt(old);
                                              c.quotes.insert(to, item);

                                              HapticFeedback.lightImpact();
                                            },
                                            proxyDecorator:
                                                (child, i, animation) {
                                              return AnimatedBuilder(
                                                animation: animation,
                                                builder: (
                                                  BuildContext context,
                                                  Widget? child,
                                                ) {
                                                  final double t = Curves
                                                      .easeInOut
                                                      .transform(
                                                          animation.value);
                                                  final double elevation =
                                                      lerpDouble(0, 6, t)!;
                                                  final Color color =
                                                      Color.lerp(
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
                                                            blurRadius:
                                                                elevation,
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
                                                enabled:
                                                    !PlatformUtils.isMobile,
                                                index: c.quotes.indexOf(e),
                                                child: Dismissible(
                                                  key: Key('${e.item.id}'),
                                                  direction: DismissDirection
                                                      .horizontal,
                                                  onDismissed: (_) {
                                                    c.quotes.remove(e);
                                                    if (c.quotes.isEmpty) {
                                                      Navigator.of(context)
                                                          .pop();
                                                    }
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: 2,
                                                    ),
                                                    child: MessageFieldMessage(
                                                      e.item,
                                                      c,
                                                      () {
                                                        c.quotes.remove(e);
                                                        if (c.quotes.isEmpty) {
                                                          Navigator.of(context)
                                                              .pop();
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        }),
                                      ),
                                    if (c.replied.isNotEmpty)
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              3,
                                        ),
                                        child: ReorderableListView(
                                          shrinkWrap: true,
                                          buildDefaultDragHandles:
                                              PlatformUtils.isMobile,
                                          onReorder: (int old, int to) {
                                            if (old < to) {
                                              --to;
                                            }

                                            final ChatItem item =
                                                c.replied.removeAt(old);
                                            c.replied.insert(to, item);

                                            HapticFeedback.lightImpact();
                                          },
                                          proxyDecorator:
                                              (child, i, animation) {
                                            return AnimatedBuilder(
                                              animation: animation,
                                              builder: (
                                                BuildContext context,
                                                Widget? child,
                                              ) {
                                                final double t = Curves
                                                    .easeInOut
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
                                          children: c.replied.map((e) {
                                            return ReorderableDragStartListener(
                                              key: Key('Handle_${e.id}'),
                                              enabled: !PlatformUtils.isMobile,
                                              index: c.replied.indexOf(e),
                                              child: Dismissible(
                                                key: Key('${e.id}'),
                                                direction:
                                                    DismissDirection.horizontal,
                                                onDismissed: (_) {
                                                  c.replied.remove(e);
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 2,
                                                  ),
                                                  child: MessageFieldMessage(
                                                    e,
                                                    c,
                                                    () => c.replied.remove(e),
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
                              onPressed: canAttach ? c.pickFile : null,
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
                              onPressed: canAttach
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
                                offset:
                                    Offset(0, PlatformUtils.isMobile ? 6 : 1),
                                child: ReactiveTextField(
                                  onChanged: onChanged,
                                  key: fieldKey ?? const Key('MessageField'),
                                  state: c.field,
                                  hint: 'label_send_message_hint'.l10n,
                                  minLines: 1,
                                  maxLines: 7,
                                  filled: false,
                                  dense: true,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  style: style.boldBody.copyWith(fontSize: 17),
                                  type: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                ),
                              ),
                            ),
                          ),
                          Obx(() {
                            final Widget child;

                            if (c.forwarding.value) {
                              child = SizedBox(
                                width: 26,
                                height: 22,
                                child: SvgLoader.asset(
                                  'assets/icons/forward.svg',
                                  width: 26,
                                  height: 22,
                                ),
                              );
                            } else {
                              child = SizedBox(
                                key: sendKey ?? const Key('Send'),
                                width: 25.18,
                                height: 22.85,
                                child: SvgLoader.asset(
                                  'assets/icons/send.svg',
                                  height: 22.85,
                                ),
                              );
                            }

                            return GestureDetector(
                              onLongPress:
                                  canForward ? c.forwarding.toggle : null,
                              child: WidgetButton(
                                onPressed: c.field.submit,
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      child: AnimatedSwitcher(
                                        duration: 300.milliseconds,
                                        child: child,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
        padding: const EdgeInsets.all(10),
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
              if (!c.field.status.value.isLoading)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: Obx(() {
                      final Widget child;

                      if (c.hoveredAttachment.value == e ||
                          PlatformUtils.isMobile) {
                        child = InkWell(
                          key: const Key('RemovePickedFile'),
                          onTap: () =>
                              c.attachments.removeWhere((a) => a.value == e),
                          child: Container(
                            width: 15,
                            height: 15,
                            margin: const EdgeInsets.only(left: 8, bottom: 8),
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
                        );
                      } else {
                        child = const SizedBox();
                      }

                      return AnimatedSwitcher(
                        duration: 200.milliseconds,
                        child: child,
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
}
