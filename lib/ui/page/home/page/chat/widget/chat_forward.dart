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
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/my_user.dart';
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
import 'animated_transform.dart';
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
    this.onDrag,
    this.onForwardedTap,
    this.onFileTap,
    this.onAttachmentError,
  }) : super(key: key);

  /// Reactive value of a [Chat] these [forwards] are posted in.
  final Rx<Chat?> chat;

  /// [ChatForward]s to display.
  final RxList<Rx<ChatItem>> forwards;

  /// [ChatMessage] attached to these [forwards] as a note.
  final Rx<Rx<ChatItem>?> note;

  /// [UserId] of the authenticated [MyUser].
  final UserId me;

  /// [UserId] of the [user] who posted these [forwards].
  final UserId authorId;

  /// Optional animation controlling a [SwipeableStatus].
  final AnimationController? animation;

  /// [User] posted these [forwards].
  final RxUser? user;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  /// Callback, called when a hide action of these [forwards] is triggered.
  final void Function()? onHide;

  /// Callback, called when a delete action of these [forwards] is triggered.
  final void Function()? onDelete;

  /// Callback, called when a reply action of these [forwards] is triggered.
  final void Function()? onReply;

  /// Callback, called when an edit action of these [forwards] is triggered.
  final void Function()? onEdit;

  /// Callback, called when a copy action of these [forwards] is triggered.
  final void Function(String text)? onCopy;

  /// Callback, called when a gallery list is required.
  ///
  /// If not specified, then only media of these [forwards] and [note] will be
  /// in a gallery.
  final List<Attachment> Function()? onGallery;

  /// Callback, called when the dragging state of this [ChatForwardWidget]
  /// is changed.
  final void Function(bool)? onDrag;

  /// Callback, called when a [ChatForward] is tapped.
  final void Function(ChatItemId, ChatId)? onForwardedTap;

  /// Callback, called when a [FileAttachment] of some [ChatItem] is tapped.
  final void Function(ChatItem, FileAttachment)? onFileTap;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function()? onAttachmentError;

  @override
  State<ChatForwardWidget> createState() => _ChatForwardWidgetState();
}

/// State of a [ChatForwardWidget] maintaining the [_galleryKeys].
class _ChatForwardWidgetState extends State<ChatForwardWidget> {
  /// [GlobalKey]s of [Attachment]s used to animate a [GalleryPopup] from/to
  /// corresponding [Widget].
  final Map<ChatItemId, List<GlobalKey>> _galleryKeys = {};

  /// [Offset] of this [ChatForwardWidget];
  Offset _offset = Offset.zero;

  /// [Duration] of the offset animation.
  Duration _offsetDuration = Duration.zero;

  /// Indicator whether this [ChatForwardWidget] is being dragged.
  bool _dragging = false;

  /// Indicator whether dragging of this [ChatForwardWidget] is started.
  bool _draggingStarted = false;

  /// Indicates whether these [ChatForwardWidget.forwards] were read by any
  /// [User].
  bool get _isRead {
    final Chat? chat = widget.chat.value;
    if (chat == null) {
      return false;
    }

    if (_fromMe) {
      return chat.isRead(widget.forwards.first.value, widget.me);
    } else {
      return chat.isReadBy(widget.forwards.first.value, widget.me);
    }
  }

  /// Indicates whether these [ChatForwardWidget.forwards] were forwarded by the
  /// authenticated [MyUser].
  bool get _fromMe => widget.authorId == widget.me;

  @override
  void initState() {
    assert(widget.forwards.isNotEmpty);

    _populateGlobalKeys();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Style style = Theme.of(context).extension<Style>()!;

    Color color = widget.user?.user.value.id == widget.me
        ? Theme.of(context).colorScheme.secondary
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
              clipBehavior: _fromMe ? Clip.antiAlias : Clip.none,
              borderRadius: BorderRadius.circular(15),
              child: IntrinsicWidth(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: _fromMe
                        ? _isRead
                            ? style.readMessageColor
                            : style.unreadMessageColor
                        : style.messageColor,
                    borderRadius: BorderRadius.circular(15),
                    border: _fromMe
                        ? _isRead
                            ? style.secondaryBorder
                            : Border.all(
                                color: const Color(0xFFDAEDFF),
                                width: 0.5,
                              )
                        : style.primaryBorder,
                  ),
                  child: Obx(() {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.note.value != null) ..._note(),
                        if (widget.note.value == null &&
                            !_fromMe &&
                            widget.chat.value?.isGroup == true)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 9, 4),
                            child: Text(
                              widget.user?.user.value.name?.val ??
                                  widget.user?.user.value.num.val ??
                                  'dot'.l10n * 3,
                              style: style.boldBody.copyWith(color: color),
                            ),
                          ),
                        ...widget.forwards.mapIndexed(
                          (i, e) => ClipRRect(
                            clipBehavior: i == widget.forwards.length - 1
                                ? Clip.antiAlias
                                : Clip.none,
                            borderRadius: BorderRadius.only(
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
          ),
        );
      }),
    );
  }

  /// Returns a visual representation of the provided [forward].
  Widget _forwardedMessage(Rx<ChatItem> forward) {
    return Obx(() {
      ChatForward msg = forward.value as ChatForward;
      ChatItem item = msg.item;

      Style style = Theme.of(context).extension<Style>()!;

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

          additional = [
            if (files.isNotEmpty)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _isRead || !_fromMe ? 1 : 0.55,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                  child: Column(
                    children: files
                        .map(
                          (e) => ChatItemWidget.fileAttachment(
                            e,
                            fromMe: widget.authorId == widget.me,
                            onFileTap: (a) => widget.onFileTap?.call(item, a),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            if (media.isNotEmpty)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _isRead || !_fromMe ? 1 : 0.55,
                child: media.length == 1
                    ? ChatItemWidget.mediaAttachment(
                        media.first,
                        media,
                        key: _galleryKeys[item.id]?.firstOrNull,
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
                                (i, e) => ChatItemWidget.mediaAttachment(
                                  e,
                                  media,
                                  key: _galleryKeys[item.id]?[i],
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

          if (item.conversationStartedAt != null) {
            time = item.finishedAt!.val
                .difference(item.conversationStartedAt!.val)
                .localizedString();
          }
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
        content = Text(item.action.toString(), style: style.boldBody);
      } else if (item is ChatForward) {
        content = Text('label_forwarded_message'.l10n, style: style.boldBody);
      } else {
        content = Text('err_unknown'.l10n, style: style.boldBody);
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: msg.item.authorId == widget.me
              ? _isRead || !_fromMe
                  ? const Color(0xFFDBEAFD)
                  : const Color(0xFFE6F1FE)
              : _isRead || !_fromMe
                  ? const Color(0xFFF9F9F9)
                  : const Color(0xFFFFFFFF),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _isRead || !_fromMe ? 1 : 0.55,
          child: WidgetButton(
            onPressed: () => widget.onForwardedTap?.call(item.id, item.chatId),
            child: FutureBuilder<RxUser?>(
              future: widget.getUser?.call(item.authorId),
              builder: (context, snapshot) {
                Color color = snapshot.data?.user.value.id == widget.me
                    ? Theme.of(context).colorScheme.secondary
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
                                        'dot'.l10n * 3,
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

  /// Builds a visual representation of the [ChatForwardWidget.note].
  List<Widget> _note() {
    ChatItem item = widget.note.value!.value;

    if (item is ChatMessage) {
      Style style = Theme.of(context).extension<Style>()!;

      String? text = item.text?.val.trim();
      if (text?.isEmpty == true) {
        text = null;
      } else {
        text = item.text?.val;
      }

      List<Attachment> attachments = item.attachments.where((e) {
        return ((e is ImageAttachment) ||
            (e is FileAttachment && e.isVideo) ||
            (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
      }).toList();

      List<Attachment> files = item.attachments.where((e) {
        return ((e is FileAttachment && !e.isVideo) ||
            (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
      }).toList();

      Color color = widget.user?.user.value.id == widget.me
          ? Theme.of(context).colorScheme.secondary
          : AvatarWidget.colors[(widget.user?.user.value.num.val.sum() ?? 3) %
              AvatarWidget.colors.length];

      return [
        if (!_fromMe && widget.chat.value?.isGroup == true)
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              item.attachments.isEmpty && text == null ? 4 : 8,
              9,
              files.isEmpty && attachments.isNotEmpty && text == null
                  ? 8
                  : files.isNotEmpty && text == null
                      ? 0
                      : 4,
            ),
            child: Text(
              widget.user?.user.value.name?.val ??
                  widget.user?.user.value.num.val ??
                  'dot'.l10n * 3,
              style: style.boldBody.copyWith(color: color),
            ),
          ),
        if (text != null)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _isRead || !_fromMe ? 1 : 0.7,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                !_fromMe && widget.chat.value?.isGroup == true ? 0 : 10,
                9,
                files.isEmpty ? 10 : 0,
              ),
              child: Text(text, style: style.boldBody),
            ),
          ),
        if (files.isNotEmpty)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _isRead || !_fromMe ? 1 : 0.55,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
              child: Column(
                children: files
                    .map(
                      (e) => ChatItemWidget.fileAttachment(
                        e,
                        fromMe: widget.authorId == widget.me,
                        onFileTap: (a) => widget.onFileTap?.call(item, a),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        if (attachments.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: text != null ||
                      item.repliesTo.isNotEmpty ||
                      (!_fromMe && widget.chat.value?.isGroup == true)
                  ? Radius.zero
                  : files.isEmpty
                      ? const Radius.circular(15)
                      : Radius.zero,
              topRight: text != null ||
                      item.repliesTo.isNotEmpty ||
                      (!_fromMe && widget.chat.value?.isGroup == true)
                  ? Radius.zero
                  : files.isEmpty
                      ? const Radius.circular(15)
                      : Radius.zero,
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _isRead || !_fromMe ? 1 : 0.55,
              child: attachments.length == 1
                  ? ChatItemWidget.mediaAttachment(
                      attachments.first,
                      attachments,
                      key: _galleryKeys[item.id]?.lastOrNull,
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
                              (i, e) => ChatItemWidget.mediaAttachment(
                                e,
                                attachments,
                                key: _galleryKeys[item.id]?[i],
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
    ChatItem? item = widget.note.value?.value;

    bool isSent =
        widget.forwards.first.value.status.value == SendingStatus.sent;

    String? copyable;
    if (item is ChatMessage) {
      copyable = item.text?.val;
    }

    return SwipeableStatus(
      animation: widget.animation,
      asStack: !_fromMe,
      isSent: isSent && _fromMe,
      isDelivered: isSent &&
          _fromMe &&
          widget.chat.value?.lastDelivery
                  .isBefore(widget.forwards.first.value.at) ==
              false,
      isRead: isSent && (!_fromMe || _isRead),
      isError: widget.forwards.first.value.status.value == SendingStatus.error,
      isSending:
          widget.forwards.first.value.status.value == SendingStatus.sending,
      swipeable: Text(
        DateFormat.Hm().format(widget.forwards.first.value.at.val.toLocal()),
      ),
      child: AnimatedTransform(
        duration: _offsetDuration,
        offset: _offset,
        curve: Curves.ease,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (d) {
            _draggingStarted = true;
            setState(() => _offsetDuration = Duration.zero);
          },
          onHorizontalDragUpdate: (d) {
            if (_draggingStarted && !_dragging) {
              if (widget.animation?.value == 0 &&
                  _offset.dx == 0 &&
                  d.delta.dx > 0) {
                _dragging = true;
                widget.onDrag?.call(_dragging);
              } else {
                _draggingStarted = false;
              }
            }

            if (_dragging) {
              _offset += d.delta;
              if (_offset.dx > 30 && _offset.dx - d.delta.dx < 30) {
                HapticFeedback.selectionClick();
                widget.onReply?.call();
              }

              setState(() {});
            }
          },
          onHorizontalDragEnd: (d) {
            if (_dragging) {
              _dragging = false;
              _draggingStarted = false;
              _offset = Offset.zero;
              _offsetDuration = 200.milliseconds;
              widget.onDrag?.call(_dragging);
              setState(() {});
            }
          },
          child: Row(
            crossAxisAlignment:
                _fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisAlignment:
                _fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!_fromMe && widget.chat.value!.isGroup)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => router.user(widget.authorId, push: true),
                    child: AvatarWidget.fromRxUser(
                      widget.user,
                      radius: 15,
                    ),
                  ),
                ),
              Flexible(
                child: LayoutBuilder(builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: min(
                        550,
                        constraints.maxWidth * 0.84 +
                            (_fromMe ? SwipeableStatus.width : -10),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Material(
                        type: MaterialType.transparency,
                        child: ContextMenuRegion(
                          preventContextMenu: false,
                          alignment: _fromMe
                              ? Alignment.bottomRight
                              : Alignment.bottomLeft,
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
                              onPressed: widget.onReply,
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
                                  quotes.add(ChatItemQuote(item: item.value));
                                }

                                if (widget.note.value != null) {
                                  quotes.add(
                                    ChatItemQuote(
                                      item: widget.note.value!.value,
                                    ),
                                  );
                                }

                                await ChatForwardView.show(
                                  context,
                                  widget.chat.value!.id,
                                  quotes,
                                );
                              },
                            ),
                            if (_fromMe &&
                                widget.note.value != null &&
                                (widget.note.value!.value.at
                                        .add(ChatController.editMessageTimeout)
                                        .isAfter(PreciseDateTime.now()) ||
                                    !_isRead))
                              ContextMenuButton(
                                key: const Key('EditButton'),
                                label: 'btn_edit'.l10n,
                                leading: SvgLoader.asset(
                                  'assets/icons/edit.svg',
                                  width: 17,
                                  height: 17,
                                ),
                                onPressed: widget.onEdit,
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
                                      widget.forwards.first.value,
                                      widget.me,
                                    );

                                await ConfirmDialog.show(
                                  context,
                                  title: 'label_delete_message'.l10n,
                                  description: deletable
                                      ? null
                                      : 'label_message_will_deleted_for_you'
                                          .l10n,
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
        ),
      ),
    );
  }

  /// Populates the [_galleryKeys] from the [ChatForwardWidget.forwards] and
  /// [ChatForwardWidget.note].
  void _populateGlobalKeys() {
    _galleryKeys.clear();

    for (Rx<ChatItem> forward in widget.forwards) {
      final ChatItem item = (forward.value as ChatForward).item;
      if (item is ChatMessage) {
        _galleryKeys[item.id] = item.attachments
            .where((e) =>
                e is ImageAttachment ||
                (e is FileAttachment && e.isVideo) ||
                (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
            .map((e) => GlobalKey())
            .toList();
      }
    }

    if (widget.note.value != null) {
      final ChatMessage item = (widget.note.value!.value as ChatMessage);
      _galleryKeys[item.id] = item.attachments
          .where((e) =>
              e is ImageAttachment ||
              (e is FileAttachment && e.isVideo) ||
              (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
          .map((e) => GlobalKey())
          .toList();
    }
  }
}
