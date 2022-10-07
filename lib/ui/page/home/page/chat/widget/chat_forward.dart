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

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/fit_view.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/forward/view.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

import 'swipeable_status.dart';

/// [ChatForward] visual representation.
class ChatForwardWidget extends StatefulWidget {
  const ChatForwardWidget({
    Key? key,
    required this.chat,
    required this.forwards,
    required this.note,
    required this.authorId,
    required this.me,
    this.user,
    this.getUser,
    this.animation,
    this.onHide,
    this.onDelete,
    this.onReply,
    this.onEdit,
    this.onCopy,
    this.onGallery,
    this.onForwardedTap,
    this.onFileTap,
    this.onAttachmentError,
  }) : super(key: key);

  /// Reactive value of a [Chat] this chat forward is posted in.
  final Rx<Chat?> chat;

  /// List of [ChatForward]s of this [ChatForwardWidget].
  final RxList<Rx<ChatItem>> forwards;

  /// [ChatMessage] attached to this [forwards] as note.
  final Rx<Rx<ChatItem>?> note;

  /// [UserId] of the authenticated [MyUser].
  final UserId me;

  /// [UserId] of the [user].
  final UserId authorId;

  /// Optional animation that controls a [SwipeableStatus].
  final AnimationController? animation;

  /// [User] forwarded this [forwards].
  final RxUser? user;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  /// Callback, called when a hide action of this chat forward is triggered.
  final void Function()? onHide;

  /// Callback, called when a delete action of this chat forward is triggered.
  final void Function()? onDelete;

  /// Callback, called when a reply action of this chat forward is triggered.
  final Function()? onReply;

  /// Callback, called when an edit action of this chat forward is triggered.
  final void Function()? onEdit;

  /// Callback, called when a copy action of this chat forward is triggered.
  final void Function(String text)? onCopy;

  /// Callback, called when a gallery list is required.
  ///
  /// If not specified, then only media in this [forwards] and [note] will be in
  /// a gallery.
  final List<Attachment> Function()? onGallery;

  /// Callback, called when a forwarded message is tapped.
  final Function(ChatItemId, ChatId)? onForwardedTap;

  /// Callback, called when a [FileAttachment] of this [ChatItem] is tapped.
  final void Function(ChatItem, FileAttachment)? onFileTap;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function()? onAttachmentError;

  @override
  State<ChatForwardWidget> createState() => _ChatForwardWidgetState();
}

class _ChatForwardWidgetState extends State<ChatForwardWidget> {
  /// [GlobalKey]s of [Attachment]s used to animate a [GalleryPopup] from/to
  /// corresponding [Widget].
  final List<GlobalKey> _galleryKeys = [];

  @override
  void initState() {
    _populateGlobalKeys();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Style style = Theme.of(context).extension<Style>()!;

    bool fromMe = widget.authorId == widget.me;
    bool isRead = _isRead(widget.forwards.first.value);

    Color color = widget.user?.user.value.id == widget.me
        ? const Color(0xFF63B4FF)
        : AvatarWidget.colors[(widget.user?.user.value.num.val.sum() ?? 3) %
            AvatarWidget.colors.length];

    return DefaultTextStyle(
      style: style.boldBody,
      child: Obx(() {
        return _rounded(
            context,
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
              child: ClipRRect(
                clipBehavior: fromMe ? Clip.antiAlias : Clip.none,
                borderRadius: BorderRadius.circular(15),
                child: IntrinsicWidth(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      color: fromMe
                          ? isRead
                              ? style.myUserReadMessageColor
                              : style.myUserUnreadMessageColor
                          : style.messageColor,
                      borderRadius: BorderRadius.circular(15),
                      border: fromMe
                          ? isRead
                              ? style.primaryBorder
                              : Border.all(
                                  color: const Color(0xFFDAEDFF),
                                  width: 0.5,
                                )
                          : style.secondaryBorder,
                    ),
                    child: Obx(() {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.note.value != null) ..._note(),
                          if (widget.note.value == null &&
                              !fromMe &&
                              widget.chat.value?.isGroup == true)
                            Transform.translate(
                              offset: const Offset(-36, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => router.user(widget.authorId,
                                        push: true),
                                    child: AvatarWidget.fromRxUser(
                                      widget.user,
                                      radius: 15,
                                      useLayoutBuilder: false,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      4,
                                      9,
                                      4,
                                    ),
                                    child: Text(
                                      widget.user?.user.value.name?.val ??
                                          widget.user?.user.value.num.val ??
                                          '...',
                                      style:
                                          style.boldBody.copyWith(color: color),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ...widget.forwards.mapIndexed(
                            (i, e) => ClipRRect(
                              clipBehavior: i == widget.forwards.length - 1
                                  ? Clip.antiAlias
                                  : Clip.none,
                              borderRadius: BorderRadius.only(
                                topLeft: widget.note.value == null && i == 0
                                    ? const Radius.circular(15)
                                    : Radius.zero,
                                topRight: widget.note.value == null && i == 0
                                    ? const Radius.circular(15)
                                    : Radius.zero,
                                bottomLeft: i == widget.forwards.length - 1
                                    ? const Radius.circular(15)
                                    : Radius.zero,
                                bottomRight: i == widget.forwards.length - 1
                                    ? const Radius.circular(15)
                                    : Radius.zero,
                              ),
                              child: _forwardedMessage(e),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ));
      }),
    );
  }

  /// Renders the provided [forward] as [ChatForward].
  Widget _forwardedMessage(Rx<ChatItem> forward) {
    return Obx(() {
      ChatForward msg = forward.value as ChatForward;
      ChatItem item = msg.item;

      Style style = Theme.of(context).extension<Style>()!;

      bool fromMe = widget.authorId == widget.me;
      bool isRead = _isRead(item);

      Widget? content;
      List<Widget> additional = [];

      if (item is ChatMessage) {
        if (item.attachments.isNotEmpty) {
          List<Attachment> media = item.attachments
              .where((e) =>
                  e is ImageAttachment ||
                  (e is FileAttachment && e.isVideo) ||
                  (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
              .toList();

          List<Attachment> files = item.attachments
              .where((e) =>
                  (e is FileAttachment && !e.isVideo) ||
                  (e is LocalAttachment && !e.file.isImage && !e.file.isVideo))
              .toList();

          if (media.isNotEmpty || files.isNotEmpty) {
            additional = [
              if (files.isNotEmpty)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: isRead || !fromMe ? 1 : 0.55,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    child: Column(
                      children: files
                          .map((e) => buildFileAttachment(
                                e,
                                fromMe: widget.authorId == widget.me,
                                onFileTap: (a) =>
                                    widget.onFileTap?.call(item, a),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              if (media.isNotEmpty)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: isRead || !fromMe ? 1 : 0.55,
                  child: media.length == 1
                      ? buildMediaAttachment(
                          media.first,
                          media,
                          key: _galleryKeys[0],
                          context: context,
                          onGallery: widget.onGallery,
                          onError: widget.onAttachmentError,
                          filled: false,
                        )
                      : SizedBox(
                          width: media.length * 120,
                          height: max(media.length * 60, 300),
                          child: FitView(
                            dividerColor: Colors.transparent,
                            children: media
                                .mapIndexed(
                                  (i, e) => buildMediaAttachment(
                                    e,
                                    media,
                                    key: _galleryKeys[i],
                                    context: context,
                                    onGallery: widget.onGallery,
                                    onError: widget.onAttachmentError,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
            ];
          }
        }

        if (item.text != null && item.text!.val.isNotEmpty) {
          content = Text(
            item.text!.val,
            style: style.boldBody,
          );
        }
      } else if (item is ChatCall) {
        String title = 'label_chat_call_ended'.l10n;
        String? time;
        bool fromMe = widget.me == item.authorId;
        bool isMissed = false;

        if (item.finishReason == null && item.conversationStartedAt != null) {
          title = 'label_chat_call_ongoing'.l10n;
        } else if (item.finishReason != null) {
          title = item.finishReason!.localizedString(fromMe) ?? title;
          isMissed = item.finishReason == ChatCallFinishReason.dropped ||
              item.finishReason == ChatCallFinishReason.unanswered;
          time = item.finishedAt!.val
              .difference(item.conversationStartedAt!.val)
              .localizedString();
        } else {
          title = item.authorId == widget.me
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
            Flexible(child: Text(title)),
            if (time != null) ...[
              const SizedBox(width: 9),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.boldBody,
                ),
              ),
            ],
          ],
        );
      } else if (item is ChatMemberInfo) {
        // TODO: Implement `ChatMemberInfo`.
        content = Text(item.action.toString(), style: style.boldBody);
      } else if (item is ChatForward) {
        content = Text('label_forwarded_message'.l10n, style: style.boldBody);
      } else {
        content = Text('err_unknown'.l10n, style: style.boldBody);
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: (msg.item.authorId == widget.me)
              ? isRead || !fromMe
                  ? const Color.fromRGBO(219, 234, 253, 1)
                  : const Color.fromRGBO(230, 241, 254, 1)
              : isRead || !fromMe
                  ? const Color.fromRGBO(249, 249, 249, 1)
                  : const Color.fromRGBO(255, 255, 255, 1),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: isRead || !fromMe ? 1 : 0.55,
          child: WidgetButton(
            onPressed: () => widget.onForwardedTap?.call(item.id, item.chatId),
            child: FutureBuilder<RxUser?>(
              future: widget.getUser?.call(item.authorId),
              builder: (context, snapshot) {
                Color color = snapshot.data?.user.value.id == widget.me
                    ? const Color(0xFF63B4FF)
                    : AvatarWidget.colors[
                        (snapshot.data?.user.value.num.val.sum() ?? 3) %
                            AvatarWidget.colors.length];

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(width: 2, color: color),
                          ),
                        ),
                        margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Transform.scale(
                                  scaleX: -1,
                                  child:
                                      Icon(Icons.reply, size: 17, color: color),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    snapshot.data?.user.value.name?.val ??
                                        snapshot.data?.user.value.num.val ??
                                        '...',
                                    style:
                                        style.boldBody.copyWith(color: color),
                                  ),
                                ),
                              ],
                            ),
                            if (content != null) ...[
                              const SizedBox(height: 2),
                              content,
                            ],
                            if (additional.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: msg.authorId == widget.me
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: additional,
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }

  /// Renders [widget.note] as [ChatMessage].
  List<Widget> _note() {
    ChatItem item = widget.note.value!.value;

    if (item is ChatMessage) {
      Style style = Theme.of(context).extension<Style>()!;

      List<Attachment> attachments = item.attachments.where((e) {
        return ((e is ImageAttachment) ||
            (e is FileAttachment && e.isVideo) ||
            (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
      }).toList();

      List<Attachment> files = item.attachments.where((e) {
        return ((e is FileAttachment && !e.isVideo) ||
            (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
      }).toList();

      bool fromMe = widget.authorId == widget.me;
      bool isRead = _isRead(item);

      Color color = widget.user?.user.value.id == widget.me
          ? const Color(0xFF63B4FF)
          : AvatarWidget.colors[(widget.user?.user.value.num.val.sum() ?? 3) %
              AvatarWidget.colors.length];

      return [
        if (!fromMe && widget.chat.value?.isGroup == true)
          Transform.translate(
            offset: const Offset(-36, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => router.user(widget.authorId, push: true),
                  child: AvatarWidget.fromRxUser(
                    widget.user,
                    radius: 15,
                    useLayoutBuilder: false,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    12 + 6,
                    8,
                    9,
                    files.isEmpty && attachments.isNotEmpty && item.text == null
                        ? 8
                        : files.isNotEmpty && item.text == null
                            ? 0
                            : 4,
                  ),
                  child: Text(
                    widget.user?.user.value.name?.val ??
                        widget.user?.user.value.num.val ??
                        '...',
                    style: style.boldBody.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        if (item.text != null)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isRead || !fromMe ? 1 : 0.7,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                (!fromMe && widget.chat.value?.isGroup == true) ? 0 : 10,
                9,
                files.isEmpty ? 10 : 0,
              ),
              child: Text(item.text!.val, style: style.boldBody),
            ),
          ),
        if (files.isNotEmpty)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isRead || !fromMe ? 1 : 0.55,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
              child: Column(
                children: files
                    .map((e) => buildFileAttachment(
                          e,
                          fromMe: widget.authorId == widget.me,
                          onFileTap: (a) => widget.onFileTap?.call(item, a),
                        ))
                    .toList(),
              ),
            ),
          ),
        if (attachments.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: item.text != null ||
                      item.repliesTo.isNotEmpty ||
                      (!fromMe && widget.chat.value?.isGroup == true)
                  ? Radius.zero
                  : files.isEmpty
                      ? const Radius.circular(15)
                      : Radius.zero,
              topRight: item.text != null ||
                      item.repliesTo.isNotEmpty ||
                      (!fromMe && widget.chat.value?.isGroup == true)
                  ? Radius.zero
                  : files.isEmpty
                      ? const Radius.circular(15)
                      : Radius.zero,
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isRead || !fromMe ? 1 : 0.55,
              child: attachments.length == 1
                  ? buildMediaAttachment(
                      attachments.first,
                      attachments,
                      key: _galleryKeys.last,
                      context: context,
                      onGallery: widget.onGallery,
                      onError: widget.onAttachmentError,
                      filled: false,
                    )
                  : SizedBox(
                      width: attachments.length * 120,
                      height: max(attachments.length * 60, 300),
                      child: FitView(
                        dividerColor: Colors.transparent,
                        children: attachments
                            .mapIndexed(
                              (i, e) => buildMediaAttachment(
                                e,
                                attachments,
                                key: _galleryKeys.reversed.elementAt(i),
                                context: context,
                                onGallery: widget.onGallery,
                                onError: widget.onAttachmentError,
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
          ),
      ];
    }

    return [];
  }

  /// Returns rounded rectangle of a [child] representing a message box.
  Widget _rounded(BuildContext context, Widget child) {
    if (widget.forwards.isEmpty) {
      return Container();
    }

    ChatItem? item = widget.note.value?.value;

    bool fromMe = widget.authorId == widget.me;
    bool isRead = _isRead(widget.forwards.first.value);
    bool isSent =
        widget.forwards.first.value.status.value == SendingStatus.sent;

    String? copyable;
    if (item is ChatMessage) {
      copyable = item.text?.val;
    }

    return SwipeableStatus(
      animation: widget.animation,
      asStack: !fromMe,
      isSent: isSent && fromMe,
      isDelivered: isSent &&
          fromMe &&
          widget.chat.value?.lastDelivery
                  .isBefore(widget.forwards.first.value.at) ==
              false,
      isRead: isSent && (!fromMe || isRead),
      isError: widget.forwards.first.value.status.value == SendingStatus.error,
      isSending:
          widget.forwards.first.value.status.value == SendingStatus.sending,
      swipeable: Text(
        DateFormat.Hm().format(widget.forwards.first.value.at.val.toLocal()),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!fromMe && widget.chat.value!.isGroup) const SizedBox(width: 30),
          Flexible(
            child: LayoutBuilder(builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: min(
                    550,
                    constraints.maxWidth * 0.84 +
                        (fromMe ? SwipeableStatus.width : -10),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Material(
                    type: MaterialType.transparency,
                    child: ContextMenuRegion(
                      preventContextMenu: false,
                      alignment:
                          fromMe ? Alignment.bottomRight : Alignment.bottomLeft,
                      actions: [
                        if (copyable != null)
                          ContextMenuButton(
                            key: const Key('CopyButton'),
                            label: 'btn_copy'.l10n,
                            leading: SvgLoader.asset(
                              'assets/icons/copy_small.svg',
                              width: 14.82,
                              height: 17,
                            ),
                            onPressed: () => widget.onCopy?.call(copyable!),
                          ),
                        ContextMenuButton(
                          key: const Key('ReplyButton'),
                          label: 'btn_reply'.l10n,
                          leading: SvgLoader.asset(
                            'assets/icons/reply.svg',
                            width: 18.8,
                            height: 16,
                          ),
                          onPressed: () => widget.onReply?.call(),
                        ),
                        ContextMenuButton(
                          key: const Key('ForwardButton'),
                          label: 'btn_forward'.l10n,
                          leading: SvgLoader.asset(
                            'assets/icons/forward.svg',
                            width: 18.8,
                            height: 16,
                          ),
                          onPressed: () async {
                            final List<ChatItemQuote> quotes = [];

                            for (Rx<ChatItem> item in widget.forwards) {
                              quotes.add(ChatItemQuote(
                                item: item.value,
                              ));
                            }

                            if (widget.note.value != null) {
                              quotes.add(ChatItemQuote(
                                item: widget.note.value!.value,
                              ));
                            }

                            await ChatForwardView.show(
                              context,
                              widget.chat.value!.id,
                              quotes,
                            );
                          },
                        ),
                        if (fromMe &&
                            (widget.note.value?.value.at
                                        .add(ChatController.editMessageTimeout)
                                        .isAfter(PreciseDateTime.now()) ==
                                    true ||
                                !isRead))
                          ContextMenuButton(
                            key: const Key('EditButton'),
                            label: 'btn_edit'.l10n,
                            leading: SvgLoader.asset(
                              'assets/icons/edit.svg',
                              width: 17,
                              height: 17,
                            ),
                            onPressed: () => widget.onEdit?.call(),
                          ),
                        ContextMenuButton(
                          label: 'btn_delete'.l10n,
                          leading: SvgLoader.asset(
                            'assets/icons/delete_small.svg',
                            width: 17.75,
                            height: 17,
                          ),
                          onPressed: () async {
                            bool deletable = widget.authorId == widget.me &&
                                !widget.chat.value!.isRead(
                                    widget.forwards.first.value, widget.me);

                            await ConfirmDialog.show(
                              context,
                              title: 'label_delete_message'.l10n,
                              description: deletable
                                  ? null
                                  : 'label_message_will_deleted_for_you'.l10n,
                              variants: [
                                ConfirmDialogVariant(
                                  onProceed: widget.onHide,
                                  child: Text(
                                    'label_delete_for_me'.l10n,
                                    key: const Key('HideForMe'),
                                  ),
                                ),
                                if (deletable)
                                  ConfirmDialogVariant(
                                    onProceed: widget.onDelete,
                                    child: Text(
                                      'label_delete_for_everyone'.l10n,
                                      key: const Key('DeleteForAll'),
                                    ),
                                  )
                              ],
                            );
                          },
                        ),
                      ],
                      child: child,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Populates the [_galleryKeys] from [widget.forwards] and [widget.note].
  void _populateGlobalKeys() {
    _galleryKeys.clear();

    for (Rx<ChatItem> forward in widget.forwards) {
      final ChatItem item = (forward.value as ChatForward).item;
      if (item is ChatMessage) {
        _galleryKeys.addAll(
          item.attachments
              .where((e) =>
                  e is ImageAttachment ||
                  (e is FileAttachment && e.isVideo) ||
                  (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
              .map((e) => GlobalKey())
              .toList(),
        );
      }
    }

    if (widget.note.value != null) {
      _galleryKeys.addAll(
        (widget.note.value!.value as ChatMessage)
            .attachments
            .where((e) =>
                e is ImageAttachment ||
                (e is FileAttachment && e.isVideo) ||
                (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
            .map((e) => GlobalKey())
            .toList(),
      );
    }
  }

  /// Returns indicator whether the provided [ChatItem] is read.
  bool _isRead(ChatItem item) {
    bool fromMe = widget.authorId == widget.me;
    bool isRead = false;
    if (fromMe) {
      isRead = widget.chat.value?.lastReads.firstWhereOrNull(
              (e) => e.memberId != widget.me && !e.at.isBefore(item.at)) !=
          null;
    } else {
      isRead = widget.chat.value?.lastReads
              .firstWhereOrNull((e) => e.memberId == widget.me)
              ?.at
              .isBefore(item.at) ==
          false;
    }

    return isRead;
  }
}
