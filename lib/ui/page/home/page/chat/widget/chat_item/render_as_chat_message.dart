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

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/fit_view.dart';
import '/ui/page/home/page/chat/controller.dart' show FileAttachmentIsVideo;
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import '../message_timestamp.dart';
import '../selection_text.dart';
import 'chat_item.dart';

/// [Widget] which renders [item] as [ChatMessage].
class RenderAsChatMessage extends StatelessWidget {
  const RenderAsChatMessage({
    super.key,
    required this.chat,
    required this.item,
    required this.fromMe,
    required this.isRead,
    required this.avatar,
    required this.rounded,
    required this.repliedMessage,
    required this.timestamp,
    required this.timestampWidget,
    required this.galleryKeys,
    required this.loadImages,
    required this.margin,
    this.me,
    this.rxUser,
    this.text,
    this.avatarOffset,
    this.onRepliedTap,
    this.onSelecting,
    this.onAttachmentError,
    this.onGallery,
    this.onFileTap,
     this.onChanged,
  });

  /// Reactive value of a [Chat] this [item] is posted in.
  final Rx<Chat?> chat;

  /// Reactive value of a [ChatItem] to display.
  final Rx<ChatItem> item;

  /// [User] posted this [item].
  final RxUser? rxUser;

  /// Indicator whether this [ChatItemWidget.item] was posted by the
  /// authenticated [MyUser].
  final bool fromMe;

  /// Indicator whether this [ChatItem] was read by any [User].
  final bool isRead;

  /// Indicator whether this [ChatItemWidget] should display an [AvatarWidget].
  final bool avatar;

  /// [TextSpan] of the [ChatItemWidget.item] to display as a text of the
  /// [ChatItemWidget].
  final TextSpan? text;

  /// [UserId] of the authenticated [MyUser].
  final UserId? me;

  /// [Offset] for the avatar of the [ChatItemWidget.item].
  final double? avatarOffset;

  /// Indicator whether a [ChatItem.at] should be displayed within the
  /// [ChatItemWidget].
  final bool timestamp;

  /// [GlobalKey]s of [Attachment]s used to animate a [GalleryPopup] from/to
  /// corresponding [Widget].
  final List<GlobalKey<State<StatefulWidget>>> galleryKeys;

  /// Indicator whether the [ImageAttachment]s of this [ChatItem] should be
  /// fetched as soon as they are displayed, if any.
  final bool loadImages;

  /// [EdgeInsets] being margin to apply to this [ChatItemWidget].
  final EdgeInsets margin;

  /// Returns rounded rectangle of a child representing a message box.
  final Widget Function(
    BuildContext context,
    Widget Function(bool) builder, {
    double avatarOffset,
  }) rounded;

  /// Renders the provided [item] as a replied message.
  final Widget Function(ChatItemQuote item, {bool timestamp}) repliedMessage;

  /// Builds a [MessageTimestamp] of the provided [item].
  final Widget Function(ChatItem item) timestampWidget;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function()? onAttachmentError;

  /// Callback, called when a replied message of this [ChatItem] is tapped.
  final void Function(ChatItemQuote)? onRepliedTap;

  /// Callback, called when the [SelectionText] changes.
  final void Function(SelectedContent?)? onChanged;

  /// Callback, called when a [Text] selection starts or ends.
  final void Function(bool)? onSelecting;

  /// Callback, called when a [FileAttachment] of this [ChatItem] is tapped.
  final void Function(FileAttachment)? onFileTap;

  /// Callback, called when a gallery list is required.
  final List<Attachment> Function()? onGallery;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;
    final ChatMessage msg = item.value as ChatMessage;

    List<Attachment> media = msg.attachments.where((e) {
      return ((e is ImageAttachment) ||
          (e is FileAttachment && e.isVideo) ||
          (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
    }).toList();

    List<Attachment> files = msg.attachments.where((e) {
      return ((e is FileAttachment && !e.isVideo) ||
          (e is LocalAttachment && !e.file.isImage && !e.file.isVideo));
    }).toList();

    Color color = fromMe
        ? Theme.of(context).colorScheme.secondary
        : AvatarWidget.colors[(rxUser?.user.value.num.val.sum() ?? 3) %
            AvatarWidget.colors.length];

    double avatarOffset = 0;
    if ((!fromMe && chat.value?.isGroup == true && avatar) &&
        msg.repliesTo.isNotEmpty) {
      for (ChatItemQuote reply in msg.repliesTo) {
        if (reply is ChatMessageQuote) {
          if (reply.text != null && reply.attachments.isNotEmpty) {
            avatarOffset += 54 + 54 + 4;
          } else if (reply.text == null && reply.attachments.isNotEmpty) {
            avatarOffset += 90;
          } else if (reply.text != null) {
            if (msg.attachments.isEmpty && text == null) {
              avatarOffset += 59 - 5;
            } else {
              avatarOffset += 55 - 4 + 8;
            }
          }
        }

        if (reply is ChatCallQuote) {
          if (msg.attachments.isEmpty && text == null) {
            avatarOffset += 59 - 4;
          } else {
            avatarOffset += 55 - 4 + 8;
          }
        }

        if (reply is ChatInfoQuote) {
          if (msg.attachments.isEmpty && text == null) {
            avatarOffset += 59 - 5;
          } else {
            avatarOffset += 55 - 4 + 8;
          }
        }
      }
    }

    // Indicator whether the [_timestamp] should be displayed in a bubble above
    // the [ChatMessage] (e.g. if there's an [ImageAttachment]).
    final bool timeInBubble = media.isNotEmpty;

    return rounded(
      context,
      (menu) {
        final List<Widget> children = [
          if (msg.repliesTo.isNotEmpty)
            ...msg.repliesTo.mapIndexed((i, e) {
              return SelectionContainer.disabled(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: e.author == me
                        ? isRead || !fromMe
                            ? const Color(0xFFDBEAFD)
                            : const Color(0xFFE6F1FE)
                        : isRead || !fromMe
                            ? const Color(0xFFF9F9F9)
                            : const Color(0xFFFFFFFF),
                    borderRadius: i == 0
                        ? BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft:
                                msg.repliesTo.length == 1 && text == null
                                    ? const Radius.circular(15)
                                    : Radius.zero,
                            bottomRight:
                                msg.repliesTo.length == 1 && text == null
                                    ? const Radius.circular(15)
                                    : Radius.zero,
                          )
                        : i == msg.repliesTo.length - 1 && text == null
                            ? const BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              )
                            : BorderRadius.zero,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: isRead || !fromMe ? 1 : 0.55,
                    child: WidgetButton(
                      onPressed: menu ? null : () => onRepliedTap?.call(e),
                      child: repliedMessage(
                        e,
                        timestamp: timestamp &&
                            i == msg.repliesTo.length - 1 &&
                            text == null &&
                            msg.attachments.isEmpty,
                      ),
                    ),
                  ),
                ),
              );
            }),
          if (!fromMe && chat.value?.isGroup == true && avatar)
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                msg.attachments.isEmpty && text == null ? 4 : 8,
                9,
                files.isEmpty && media.isNotEmpty && text == null
                    ? 8
                    : files.isNotEmpty && text == null
                        ? 0
                        : 4,
              ),
              child: SelectionText(
                rxUser?.user.value.name?.val ??
                    rxUser?.user.value.num.val ??
                    'dot'.l10n * 3,
                selectable: PlatformUtils.isDesktop || menu,
                onSelecting: onSelecting,
                onChanged: onChanged,
                // onChanged: (a) => selection = a,
                style: style.boldBody.copyWith(color: color),
              ),
            ),
          if (text != null)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isRead || !fromMe ? 1 : 0.7,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  !fromMe && chat.value?.isGroup == true && avatar ? 0 : 10,
                  9,
                  files.isEmpty ? 10 : 0,
                ),
                child: SelectionText.rich(
                  key: Key('Text_${item.value.id}'),
                  TextSpan(
                    children: [
                      text!,
                      if (timestamp && files.isEmpty && !timeInBubble)
                        WidgetSpan(
                          child:
                              Opacity(opacity: 0, child: timestampWidget(msg)),
                        ),
                    ],
                  ),
                  selectable: PlatformUtils.isDesktop || menu,
                  onSelecting: onSelecting,
                  onChanged: onChanged,
                  // onChanged: (a) => selection = a,
                  style: style.boldBody,
                ),
              ),
            ),
          if (files.isNotEmpty)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isRead || !fromMe ? 1 : 0.55,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: SelectionContainer.disabled(
                  child: Column(
                    children: [
                      ...files.mapIndexed(
                        (i, e) => ChatItemWidget.fileAttachment(
                          e,
                          onFileTap: onFileTap,
                        ),
                      ),
                      if (timestamp && !timeInBubble)
                        Opacity(opacity: 0, child: timestampWidget(msg)),
                    ],
                  ),
                ),
              ),
            ),
          if (media.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: text != null ||
                        msg.repliesTo.isNotEmpty ||
                        (!fromMe && chat.value?.isGroup == true && avatar)
                    ? Radius.zero
                    : files.isEmpty
                        ? const Radius.circular(15)
                        : Radius.zero,
                topRight: text != null ||
                        msg.repliesTo.isNotEmpty ||
                        (!fromMe && chat.value?.isGroup == true && avatar)
                    ? Radius.zero
                    : files.isEmpty
                        ? const Radius.circular(15)
                        : Radius.zero,
                bottomLeft: const Radius.circular(15),
                bottomRight: const Radius.circular(15),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: isRead || !fromMe ? 1 : 0.55,
                child: media.length == 1
                    ? ChatItemWidget.mediaAttachment(
                        context,
                        media.first,
                        media,
                        filled: false,
                        key: galleryKeys[0],
                        onError: onAttachmentError,
                        onGallery: onGallery,
                        autoLoad: loadImages,
                      )
                    : SizedBox(
                        width: media.length * 120,
                        height: max(media.length * 60, 300),
                        child: FitView(
                          dividerColor: Colors.transparent,
                          children: media
                              .mapIndexed(
                                (i, e) => ChatItemWidget.mediaAttachment(
                                  context,
                                  e,
                                  media,
                                  key: galleryKeys[i],
                                  onError: onAttachmentError,
                                  onGallery: onGallery,
                                  autoLoad: loadImages,
                                ),
                              )
                              .toList(),
                        ),
                      ),
              ),
            ),
        ];

        return Container(
          padding: margin.add(const EdgeInsets.fromLTRB(5, 0, 2, 0)),
          child: Stack(
            children: [
              IntrinsicWidth(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: fromMe
                        ? isRead
                            ? style.readMessageColor
                            : style.unreadMessageColor
                        : style.messageColor,
                    borderRadius: BorderRadius.circular(15),
                    border: fromMe
                        ? isRead
                            ? style.secondaryBorder
                            : Border.all(
                                color: const Color(0xFFDAEDFF), width: 0.5)
                        : style.primaryBorder,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              if (timestamp)
                Positioned(
                  right: timeInBubble ? 6 : 8,
                  bottom: 4,
                  child: timeInBubble
                      ? Container(
                          padding: const EdgeInsets.only(left: 4, right: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: timestampWidget(msg),
                        )
                      : timestampWidget(msg),
                )
            ],
          ),
        );
      },
      avatarOffset: avatarOffset,
    );
  }
}
