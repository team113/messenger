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
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/sending_status.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/attachment_selector.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/page/chat/widget/media_attachment.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/page/home/widget/init_callback.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

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
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide.none,
    );
    final Style style = Theme.of(context).extension<Style>()!;

    return Theme.of(context).copyWith(
      shadowColor: style.onBackgroundOpacity67,
      iconTheme: IconThemeData(color: style.secondaryHighlight),
      inputDecorationTheme: InputDecorationTheme(
        border: border,
        errorBorder: border,
        enabledBorder: border,
        focusedBorder: border,
        disabledBorder: border,
        focusedErrorBorder: border,
        focusColor: style.onPrimary,
        fillColor: style.onPrimary,
        hoverColor: style.transparent,
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
                    color: style.onBackgroundOpacity88,
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
                  children: [_buildHeader(c, context), _buildField(c, context)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Returns a visual representation of the message attachments, replies,
  /// quotes and edited message.
  Widget _buildHeader(MessageFieldController c, BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return LayoutBuilder(builder: (context, constraints) {
      return Obx(() {
        final bool grab = c.attachments.isNotEmpty
            ? (125 + 2) * c.attachments.length > constraints.maxWidth - 16
            : false;

        Widget? previews;

        if (c.edited.value != null) {
          previews = SingleChildScrollView(
            controller: c.scrollController,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Dismissible(
                key: Key('${c.edited.value?.id}'),
                direction: DismissDirection.horizontal,
                onDismissed: (_) => c.edited.value = null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: WidgetButton(
                    onPressed: () => onItemPressed?.call(c.edited.value!.id),
                    child: _buildPreview(
                      context,
                      c.edited.value!,
                      c,
                      onClose: () => c.edited.value = null,
                    ),
                  ),
                ),
              ),
            ),
          );
        } else if (c.quotes.isNotEmpty) {
          previews = ReorderableListView(
            scrollController: c.scrollController,
            shrinkWrap: true,
            buildDefaultDragHandles: PlatformUtils.isMobile,
            onReorder: (int old, int to) {
              if (old < to) {
                --to;
              }

              c.quotes.insert(to, c.quotes.removeAt(old));

              HapticFeedback.lightImpact();
            },
            proxyDecorator: (child, _, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (_, child) {
                  final double t = Curves.easeInOut.transform(animation.value);
                  final double elevation = lerpDouble(0, 6, t)!;
                  final Color color = Color.lerp(
                    const Color(0x00000000),
                    const Color(0x33000000),
                    t,
                  )!;

                  return InitCallback(
                    callback: HapticFeedback.selectionClick,
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
            padding: const EdgeInsets.symmetric(horizontal: 1),
            children: c.quotes.map((e) {
              return ReorderableDragStartListener(
                key: Key('Handle_${e.item.id}'),
                enabled: !PlatformUtils.isMobile,
                index: c.quotes.indexOf(e),
                child: Dismissible(
                  key: Key('${e.item.id}'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) {
                    c.quotes.remove(e);
                    if (c.quotes.isEmpty) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                    ),
                    child: _buildPreview(
                      context,
                      e.item,
                      c,
                      onClose: () {
                        c.quotes.remove(e);
                        if (c.quotes.isEmpty) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        } else if (c.replied.isNotEmpty) {
          previews = ReorderableListView(
            scrollController: c.scrollController,
            shrinkWrap: true,
            buildDefaultDragHandles: PlatformUtils.isMobile,
            onReorder: (int old, int to) {
              if (old < to) {
                --to;
              }

              c.replied.insert(to, c.replied.removeAt(old));

              HapticFeedback.lightImpact();
            },
            proxyDecorator: (child, _, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (_, child) {
                  final double t = Curves.easeInOut.transform(animation.value);
                  final double elevation = lerpDouble(0, 6, t)!;
                  final Color color = Color.lerp(
                    style.transparent,
                    style.onBackgroundOpacity81,
                    t,
                  )!;

                  return InitCallback(
                    callback: HapticFeedback.selectionClick,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          CustomBoxShadow(color: color, blurRadius: elevation),
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
            padding: const EdgeInsets.symmetric(horizontal: 1),
            children: c.replied.map((e) {
              return ReorderableDragStartListener(
                key: Key('Handle_${e.id}'),
                enabled: !PlatformUtils.isMobile,
                index: c.replied.indexOf(e),
                child: Dismissible(
                  key: Key('${e.id}'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) => c.replied.remove(e),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: WidgetButton(
                      onPressed: () => onItemPressed?.call(e.id),
                      child: _buildPreview(
                        context,
                        e,
                        c,
                        onClose: () => c.replied.remove(e),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }

        return ConditionalBackdropFilter(
          condition: style.cardBlur > 0,
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          borderRadius: BorderRadius.only(
            topLeft: style.cardRadius.topLeft,
            topRight: style.cardRadius.topRight,
          ),
          child: Container(
            color: style.onPrimaryOpacity60,
            child: AnimatedSize(
              duration: 400.milliseconds,
              curve: Curves.ease,
              child: Container(
                width: double.infinity,
                padding: c.replied.isNotEmpty || c.attachments.isNotEmpty
                    ? const EdgeInsets.fromLTRB(4, 6, 4, 6)
                    : EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (previews != null)
                      ConstrainedBox(
                        constraints: this.constraints ??
                            BoxConstraints(
                              maxHeight: max(
                                100,
                                MediaQuery.of(context).size.height / 3.4,
                              ),
                            ),
                        child: Scrollbar(
                          controller: c.scrollController,
                          child: previews,
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
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: c.attachments
                                    .map((e) => _buildAttachment(context, e, c))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        );
      });
    });
  }

  /// Builds a visual representation of the send field itself along with its
  /// buttons.
  Widget _buildField(MessageFieldController c, BuildContext context) {
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
                    ? c.pickFile
                    : () async {
                        c.field.focus.unfocus();
                        await AttachmentSourceSelector.show(
                          context,
                          onPickFile: c.pickFile,
                          onTakePhoto: c.pickImageFromCamera,
                          onPickMedia: c.pickMedia,
                          onTakeVideo: c.pickVideoFromCamera,
                        );
                      }
                : null,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: SvgLoader.asset(
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
                  state: c.field,
                  hint: 'label_send_message_hint'.l10n,
                  minLines: 1,
                  maxLines: 7,
                  filled: false,
                  dense: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  style: style.boldBody.copyWith(fontSize: 17),
                  fillColor: style.onPrimary,
                  type: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
          ),
          Obx(() {
            return GestureDetector(
              onLongPress: canForward ? c.forwarding.toggle : null,
              child: WidgetButton(
                onPressed: c.field.submit,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: 300.milliseconds,
                      child: c.forwarding.value
                          ? SvgLoader.asset(
                              'assets/icons/forward.svg',
                              width: 26,
                              height: 22,
                            )
                          : SvgLoader.asset(
                              key: sendKey ?? const Key('Send'),
                              'assets/icons/send.svg',
                              height: 22.85,
                              width: 25.18,
                            ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Returns a visual representation of the provided [Attachment].
  Widget _buildAttachment(
    BuildContext context,
    MapEntry<GlobalKey, Attachment> entry,
    MessageFieldController c,
  ) {
    final Attachment e = entry.value;
    final GlobalKey key = entry.key;

    final bool isImage =
        (e is ImageAttachment || (e is LocalAttachment && e.file.isImage));
    final bool isVideo = (e is FileAttachment && e.isVideo) ||
        (e is LocalAttachment && e.file.isVideo);

    const double size = 125;

    // Builds the visual representation of the provided [Attachment] itself.
    Widget content() {
      final Style style = Theme.of(context).extension<Style>()!;

      if (isImage || isVideo) {
        final Widget child = MediaAttachment(
          attachment: e,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );

        final List<Attachment> attachments = c.attachments
            .where((e) {
              final Attachment a = e.value;
              return a is ImageAttachment ||
                  (a is FileAttachment && a.isVideo) ||
                  (a is LocalAttachment && (a.file.isImage || a.file.isVideo));
            })
            .map((e) => e.value)
            .toList();

        return WidgetButton(
          key: key,
          onPressed: e is LocalAttachment
              ? null
              : () {
                  final int index =
                      c.attachments.indexWhere((m) => m.value == e);
                  if (index != -1) {
                    GalleryPopup.show(
                      context: context,
                      gallery: GalleryPopup(
                        initial: index,
                        initialKey: key,
                        onTrashPressed: (int i) {
                          c.attachments
                              .removeWhere((o) => o.value == attachments[i]);
                        },
                        children: attachments.map((o) {
                          if (o is ImageAttachment ||
                              (o is LocalAttachment && o.file.isImage)) {
                            return GalleryItem.image(
                              o.original.url,
                              o.filename,
                              size: o.original.size,
                              checksum: o.original.checksum,
                            );
                          }
                          return GalleryItem.video(
                            o.original.url,
                            o.filename,
                            size: o.original.size,
                            checksum: o.original.checksum,
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: style.onBackgroundOpacity50,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: style.onPrimary,
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
                style: TextStyle(fontSize: 13, color: style.primary),
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
            color: style.primaryHighlight,
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
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: style.onPrimary,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.error,
                                    color: style.dangerColor,
                                  ),
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
                              alignment: Alignment.center,
                              child: SvgLoader.asset(
                                'assets/icons/close_primary.svg',
                                width: 7,
                                height: 7,
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

  /// Returns a visual representation of the provided [item] as a preview.
  Widget _buildPreview(
    BuildContext context,
    ChatItem item,
    MessageFieldController c, {
    void Function()? onClose,
  }) {
    final Style style = Theme.of(context).extension<Style>()!;
    final bool fromMe = item.authorId == c.me;

    Widget? content;
    final List<Widget> additional = [];

    if (item is ChatMessage) {
      if (item.attachments.isNotEmpty) {
        additional.addAll(
          item.attachments.map((a) {
            final ImageAttachment? image = a is ImageAttachment ? a : null;

            return Container(
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: fromMe
                    ? style.onPrimaryOpacity75
                    : style.onBackgroundOpacity98,
                borderRadius: BorderRadius.circular(4),
              ),
              width: 30,
              height: 30,
              child: image == null
                  ? Icon(
                      Icons.file_copy,
                      color: fromMe
                          ? style.onPrimary
                          : style.primaryHighlightDarkest,
                      size: 16,
                    )
                  : RetryImage(
                      image.small.url,
                      checksum: image.small.checksum,
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(4),
                    ),
            );
          }).toList(),
        );
      }

      if (item.text != null && item.text!.val.isNotEmpty) {
        content = Text(
          item.text!.val,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.boldBody,
        );
      }
    } else if (item is ChatCall) {
      String title = 'label_chat_call_ended'.l10n;
      String? time;
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
                  color: style.primary,
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
    } else if (item is ChatInfo) {
      // TODO: Implement `ChatInfo`.
      content = Text(item.action.toString(), style: style.boldBody);
    } else {
      content = Text('err_unknown'.l10n, style: style.boldBody);
    }

    final Widget expanded;

    if (c.edited.value != null) {
      expanded = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 12),
          SvgLoader.asset('assets/icons/edit.svg', width: 17, height: 17),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(width: 2, color: style.secondary),
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
                    style: style.boldBody.copyWith(color: style.secondary),
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
            ),
          ),
        ],
      );
    } else {
      expanded = FutureBuilder<RxUser?>(
        future: c.getUser(item.authorId),
        builder: (context, snapshot) {
          AvatarWidget avatarWidget = AvatarWidget();
          final Color? color = snapshot.data?.user.value.id == c.me
              ? style.secondary
              : avatarWidget.colors[
                  (snapshot.data?.user.value.num.val.sum() ?? 3) %
                      avatarWidget.colors.length];

          return Container(
            key: Key('Reply_${c.replied.indexOf(item)}'),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(width: 2, color: color!)),
            ),
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                snapshot.data != null
                    ? Obx(() {
                        return Text(
                          snapshot.data!.user.value.name?.val ??
                              snapshot.data!.user.value.num.val,
                          style: style.boldBody.copyWith(color: color),
                        );
                      })
                    : Text(
                        'dot'.l10n * 3,
                        style: style.boldBody.copyWith(color: style.secondary),
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
        },
      );
    }

    return MouseRegion(
      opaque: false,
      onEnter: (d) => c.hoveredReply.value = item,
      onExit: (d) => c.hoveredReply.value = null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        decoration: BoxDecoration(
          color: style.primaryHighlight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: expanded),
            Obx(() {
              final Widget child;

              if (c.hoveredReply.value == item || PlatformUtils.isMobile) {
                child = WidgetButton(
                  key: const Key('CancelReplyButton'),
                  onPressed: onClose,
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
                      alignment: Alignment.center,
                      child: SvgLoader.asset(
                        'assets/icons/close_primary.svg',
                        width: 7,
                        height: 7,
                      ),
                    ),
                  ),
                );
              } else {
                child = const SizedBox();
              }

              return AnimatedSwitcher(duration: 200.milliseconds, child: child);
            }),
          ],
        ),
      ),
    );
  }
}
