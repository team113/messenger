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

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller.dart'
    show ChatCallFinishReasonL10n, ChatController, FileAttachmentIsVideo;
import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/config.dart';
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
import '/ui/page/home/page/chat/forward/view.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/page/home/widget/init_callback.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import 'swipeable_status.dart';
import 'video_thumbnail/video_thumbnail.dart';

/// [ChatItem] visual representation.
class ChatItemWidget extends StatefulWidget {
  const ChatItemWidget({
    Key? key,
    required this.chat,
    required this.item,
    required this.me,
    this.user,
    this.getUser,
    this.onJoinCall,
    this.animation,
    this.onHide,
    this.onDelete,
    this.onReply,
    this.onEdit,
    this.onCopy,
    this.onGallery,
    this.onRepliedTap,
    this.onResend,
    this.onFileTap,
    this.onAttachmentError,
  }) : super(key: key);

  /// Reactive value of a [ChatItem] to display.
  final Rx<ChatItem> item;

  /// Reactive value of a [Chat] this [item] is posted in.
  final Rx<Chat?> chat;

  /// [UserId] of the authenticated [MyUser].
  final UserId me;

  /// [User] posted this [item].
  final RxUser? user;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  /// Callback, called when a hide action of this [ChatItem] is triggered.
  final void Function()? onHide;

  /// Callback, called when a delete action of this [ChatItem] is triggered.
  final void Function()? onDelete;

  /// Callback, called when join call button is pressed.
  final void Function()? onJoinCall;

  /// Callback, called when a reply action of this [ChatItem] is triggered.
  final void Function()? onReply;

  /// Callback, called when an edit action of this [ChatItem] is triggered.
  final void Function()? onEdit;

  /// Callback, called when a copy action of this [ChatItem] is triggered.
  final void Function(String text)? onCopy;

  /// Optional animation that controls a [SwipeableStatus].
  final AnimationController? animation;

  /// Callback, called when a gallery list is required.
  ///
  /// If not specified, then only media in this [item] will be in a gallery.
  final List<Attachment> Function()? onGallery;

  /// Callback, called when a replied message of this [ChatItem] is tapped.
  final void Function(ChatItemId)? onRepliedTap;

  /// Callback, called when a resend action of this [ChatItem] is triggered.
  final void Function()? onResend;

  /// Callback, called when a [FileAttachment] of this [ChatItem] is tapped.
  final void Function(FileAttachment)? onFileTap;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function()? onAttachmentError;

  @override
  State<ChatItemWidget> createState() => _ChatItemWidgetState();
}

/// State of a [ChatItemWidget] used to update an active call [Timer].
class _ChatItemWidgetState extends State<ChatItemWidget> {
  /// [Timer] rebuilding this widget every second if the [widget.item]
  /// represents an ongoing [ChatCall].
  Timer? _ongoingCallTimer;

  /// [GlobalKey]s of [Attachment]s used to animate a [GalleryPopup] from/to
  /// corresponding [Widget].
  List<GlobalKey> _galleryKeys = [];

  @override
  void initState() {
    _populateGlobalKeys(widget.item.value);
    super.initState();
  }

  @override
  void dispose() {
    _ongoingCallTimer?.cancel();
    _ongoingCallTimer = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatItemWidget oldWidget) {
    if (oldWidget.item != widget.item) {
      if (widget.item.value is ChatMessage) {
        var msg = widget.item.value as ChatMessage;

        bool needsUpdate = true;
        if (oldWidget.item is ChatMessage) {
          needsUpdate = msg.attachments.length !=
              (oldWidget.item as ChatMessage).attachments.length;
        }

        if (needsUpdate) {
          _populateGlobalKeys(msg);
        }
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    Style style = Theme.of(context).extension<Style>()!;
    return DefaultTextStyle(
      style: style.boldBody,
      child: Obx(() {
        if (widget.item.value is ChatMessage) {
          return _renderAsChatMessage(context);
        } else if (widget.item.value is ChatForward) {
          throw Exception(
            'Use `ChatForward` widget for rendering `ChatForward`s instead',
          );
        } else if (widget.item.value is ChatCall) {
          return _renderAsChatCall(context);
        } else if (widget.item.value is ChatMemberInfo) {
          return _renderAsChatMemberInfo();
        }
        throw UnimplementedError('Unknown ChatItem ${widget.item.value}');
      }),
    );
  }

  /// Renders [widget.item] as [ChatMemberInfo].
  Widget _renderAsChatMemberInfo() {
    var message = widget.item.value as ChatMemberInfo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(child: Text('${message.action}')),
    );
  }

  /// Renders [widget.item] as [ChatMessage].
  Widget _renderAsChatMessage(BuildContext context) {
    Style style = Theme.of(context).extension<Style>()!;
    var msg = widget.item.value as ChatMessage;

    String? text = msg.text?.val.trim();
    if (text?.isEmpty == true) {
      text = null;
    } else {
      text = msg.text?.val;
    }

    List<Attachment> media = msg.attachments.where((e) {
      return ((e is ImageAttachment) ||
          (e is FileAttachment && e.isVideo) ||
          (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
    }).toList();

    List<Attachment> files = msg.attachments.where((e) {
      return ((e is FileAttachment && !e.isVideo) ||
          (e is LocalAttachment && !e.file.isImage && !e.file.isVideo));
    }).toList();

    bool fromMe = msg.authorId == widget.me;
    bool isRead = _isRead();

    Color color = widget.user?.user.value.id == widget.me
        ? const Color(0xFF63B4FF)
        : AvatarWidget.colors[(widget.user?.user.value.num.val.sum() ?? 3) %
            AvatarWidget.colors.length];

    return _rounded(
      context,
      Container(
        padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (msg.repliesTo.isNotEmpty)
                  ...msg.repliesTo.mapIndexed((i, e) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      decoration: BoxDecoration(
                        color: e.authorId == widget.me
                            ? isRead || !fromMe
                                ? const Color.fromRGBO(219, 234, 253, 1)
                                : const Color.fromRGBO(230, 241, 254, 1)
                            : isRead || !fromMe
                                ? const Color.fromRGBO(249, 249, 249, 1)
                                : const Color.fromRGBO(255, 255, 255, 1),
                        borderRadius: i == 0
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              )
                            : BorderRadius.zero,
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: isRead || !fromMe ? 1 : 0.55,
                        child: WidgetButton(
                          onPressed: () => widget.onRepliedTap?.call(e.id),
                          child: _repliedMessage(e),
                        ),
                      ),
                    );
                  }),
                if (!fromMe && widget.chat.value?.isGroup == true)
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
                    child: Text(
                      widget.user?.user.value.name?.val ??
                          widget.user?.user.value.num.val ??
                          '...',
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
                        (!fromMe && widget.chat.value?.isGroup == true)
                            ? 0
                            : 10,
                        9,
                        files.isEmpty ? 10 : 0,
                      ),
                      child: Text(
                        text,
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
                      child: Column(
                        children: files
                            .map((e) => buildFileAttachment(
                                  e,
                                  fromMe:
                                      widget.item.value.authorId == widget.me,
                                  onFileTap: widget.onFileTap,
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                if (media.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: text != null ||
                              msg.repliesTo.isNotEmpty ||
                              (!fromMe && widget.chat.value?.isGroup == true)
                          ? Radius.zero
                          : files.isEmpty
                              ? const Radius.circular(15)
                              : Radius.zero,
                      topRight: text != null ||
                              msg.repliesTo.isNotEmpty ||
                              (!fromMe && widget.chat.value?.isGroup == true)
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
                          ? buildMediaAttachment(
                              media.first,
                              media,
                              filled: false,
                              key: _galleryKeys[0],
                              context: context,
                              onError: widget.onAttachmentError,
                              onGallery: widget.onGallery,
                            )
                          : SizedBox(
                              width: media.length * 120,
                              height: max(media.length * 60, 300),
                              child: FitView(
                                dividerColor: Colors.transparent,
                                children: media
                                    .mapIndexed((i, e) => buildMediaAttachment(
                                          e,
                                          media,
                                          key: _galleryKeys[i],
                                          context: context,
                                          onError: widget.onAttachmentError,
                                          onGallery: widget.onGallery,
                                        ))
                                    .toList(),
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Renders the [widget.item] as a [ChatCall].
  Widget _renderAsChatCall(BuildContext context) {
    var message = widget.item.value as ChatCall;
    bool isOngoing =
        message.finishReason == null && message.conversationStartedAt != null;

    if (isOngoing) {
      _ongoingCallTimer ??= Timer.periodic(1.seconds, (_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      _ongoingCallTimer?.cancel();
    }

    List<Widget>? subtitle;
    bool fromMe = widget.me == message.authorId;
    bool isMissed = false;

    String title = 'label_chat_call_ended'.l10n;
    String? time;

    if (isOngoing) {
      title = 'label_chat_call_ongoing'.l10n;
      time = message.conversationStartedAt!.val
          .difference(DateTime.now())
          .localizedString();
    } else if (message.finishReason != null) {
      title = message.finishReason!.localizedString(fromMe) ?? title;
      isMissed = (message.finishReason == ChatCallFinishReason.dropped) ||
          (message.finishReason == ChatCallFinishReason.unanswered);

      if (message.finishedAt != null && message.conversationStartedAt != null) {
        time = message.finishedAt!.val
            .difference(message.conversationStartedAt!.val)
            .localizedString();
      }
    } else {
      title = message.authorId == widget.me
          ? 'label_outgoing_call'.l10n
          : 'label_incoming_call'.l10n;
    }

    Style style = Theme.of(context).extension<Style>()!;

    subtitle = [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
        child: message.withVideo
            ? SvgLoader.asset(
                'assets/icons/call_video${isMissed && !fromMe ? '_red' : ''}.svg',
                height: 13,
              )
            : SvgLoader.asset(
                'assets/icons/call_audio${isMissed && !fromMe ? '_red' : ''}.svg',
                height: 15,
              ),
      ),
      Flexible(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style.boldBody,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(width: 9),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.subtitle2,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 8),
    ];

    bool isRead = _isRead();

    return _rounded(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            border: fromMe
                ? isRead
                    ? style.primaryBorder
                    : Border.all(color: const Color(0xFFDAEDFF), width: 0.5)
                : style.secondaryBorder,
            color: fromMe
                ? isRead
                    ? style.myUserReadMessageColor
                    : style.myUserUnreadMessageColor
                : style.messageColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isRead || !fromMe ? 1 : 0.55,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: subtitle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Renders the provided [item] as a replied message.
  Widget _repliedMessage(ChatItem item) {
    Style style = Theme.of(context).extension<Style>()!;
    bool fromMe = item.authorId == widget.me;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessage) {
      if (item.attachments.isNotEmpty) {
        additional = item.attachments
            .map((a) {
              ImageAttachment? image;

              if (a is ImageAttachment) {
                image = a;
              }

              return Container(
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: fromMe
                      ? Colors.white.withOpacity(0.25)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                  image: image == null
                      ? null
                      : DecorationImage(
                          image: NetworkImage(
                            '${Config.files}${image.medium.relativeRef}',
                          ),
                          onError: (_, __) => widget.onAttachmentError?.call(),
                          fit: BoxFit.cover,
                        ),
                ),
                width: 50,
                height: 50,
                child: image == null
                    ? Icon(
                        Icons.file_copy,
                        color: fromMe ? Colors.white : const Color(0xFFDDDDDD),
                        size: 28,
                      )
                    : null,
              );
            })
            .take(3)
            .toList();

        if (item.attachments.length > 3) {
          additional.add(Container(
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: fromMe
                  ? Colors.white.withOpacity(0.40)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            width: 50,
            height: 50,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '+${item.attachments.length - 3}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
            ),
          ));
        }
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
      bool fromMe = widget.me == item.authorId;
      bool isMissed = false;

      if (item.finishReason == null && item.conversationStartedAt != null) {
        title = 'label_chat_call_ongoing'.l10n;
      } else if (item.finishReason != null) {
        title = item.finishReason!.localizedString(fromMe) ?? title;
        isMissed = item.finishReason == ChatCallFinishReason.dropped ||
            item.finishReason == ChatCallFinishReason.unanswered;

        if (item.finishedAt != null && item.conversationStartedAt != null) {
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
      // TODO: Implement `ChatMemberInfo`.
      content = Text(item.action.toString(), style: style.boldBody);
    } else if (item is ChatForward) {
      // TODO: Implement `ChatForward`.
      content = Text('label_forwarded_message'.l10n, style: style.boldBody);
    } else {
      content = Text('err_unknown'.l10n, style: style.boldBody);
    }

    return FutureBuilder<RxUser?>(
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
                  border: Border(left: BorderSide(width: 2, color: color)),
                ),
                margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.data?.user.value.name?.val ??
                          snapshot.data?.user.value.num.val ??
                          '...',
                      style: style.boldBody.copyWith(color: color),
                    ),
                    if (content != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle.merge(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: content,
                      ),
                    ],
                    if (additional.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(mainAxisSize: MainAxisSize.min, children: additional),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Returns rounded rectangle of a [child] representing a message box.
  Widget _rounded(BuildContext context, Widget child) {
    ChatItem item = widget.item.value;

    String? copyable;
    if (item is ChatMessage) {
      copyable = item.text?.val;
    }

    bool fromMe = item.authorId == widget.me;
    bool isRead = _isRead();
    bool isSent = item.status.value == SendingStatus.sent;

    return SwipeableStatus(
      animation: widget.animation,
      asStack: !fromMe,
      isSent: isSent && fromMe,
      isDelivered: isSent &&
          fromMe &&
          widget.chat.value?.lastDelivery.isBefore(item.at) == false,
      isRead: isSent && (!fromMe || isRead),
      isError: item.status.value == SendingStatus.error,
      isSending: item.status.value == SendingStatus.sending,
      swipeable: Text(DateFormat.Hm().format(item.at.val.toLocal())),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (fromMe)
            Padding(
              key: Key('MessageStatus_${item.id}'),
              padding: const EdgeInsets.only(top: 16),
              child: AnimatedDelayedSwitcher(
                delay: item.status.value == SendingStatus.sending
                    ? const Duration(seconds: 2)
                    : Duration.zero,
                child: item.status.value == SendingStatus.sending
                    ? const Padding(
                        key: Key('Sending'),
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.access_alarm, size: 15),
                      )
                    : item.status.value == SendingStatus.error
                        ? const Padding(
                            key: Key('Error'),
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.error_outline,
                              size: 15,
                              color: Colors.red,
                            ),
                          )
                        : Container(key: const Key('Sent')),
              ),
            ),
          if (!fromMe && widget.chat.value!.isGroup)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => router.user(item.authorId, push: true),
                child: AvatarWidget.fromRxUser(widget.user, radius: 15),
              ),
            ),
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
                    key: Key('Message_${item.id}'),
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
                        if (item.status.value == SendingStatus.sent) ...[
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
                          if (item is ChatMessage)
                            ContextMenuButton(
                              key: const Key('ForwardButton'),
                              label: 'btn_forward'.l10n,
                              leading: SvgLoader.asset(
                                'assets/icons/forward.svg',
                                width: 18.8,
                                height: 16,
                              ),
                              onPressed: () async {
                                await ChatForwardView.show(
                                  context,
                                  widget.chat.value!.id,
                                  [ChatItemQuote(item: item)],
                                );
                              },
                            ),
                          if (item is ChatMessage &&
                              fromMe &&
                              (item.at
                                      .add(ChatController.editMessageTimeout)
                                      .isAfter(PreciseDateTime.now()) ||
                                  !isRead))
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
                            key: const Key('Delete'),
                            label: 'btn_delete'.l10n,
                            leading: SvgLoader.asset(
                              'assets/icons/delete_small.svg',
                              width: 17.75,
                              height: 17,
                            ),
                            onPressed: () async {
                              bool deletable = widget.item.value.authorId ==
                                      widget.me &&
                                  !widget.chat.value!
                                      .isRead(widget.item.value, widget.me) &&
                                  (widget.item.value is ChatMessage);

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
                        if (item.status.value == SendingStatus.error) ...[
                          ContextMenuButton(
                            key: const Key('Resend'),
                            label: 'btn_resend_message'.l10n,
                            leading: SvgLoader.asset(
                              'assets/icons/send_small.svg',
                              width: 18.37,
                              height: 16,
                            ),
                            onPressed: widget.onResend,
                          ),
                          ContextMenuButton(
                            key: const Key('Delete'),
                            label: 'btn_delete'.l10n,
                            leading: SvgLoader.asset(
                              'assets/icons/delete_small.svg',
                              width: 17.75,
                              height: 17,
                            ),
                            onPressed: () async {
                              await ConfirmDialog.show(
                                context,
                                title: 'label_delete_message'.l10n,
                                variants: [
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

  /// Returns indicator whether [ChatItemWidget.item] is read.
  bool _isRead() {
    bool fromMe = widget.item.value.authorId == widget.me;
    bool isRead = false;
    if (fromMe) {
      isRead = widget.chat.value?.lastReads.firstWhereOrNull((e) =>
              e.memberId != widget.me &&
              !e.at.isBefore(widget.item.value.at)) !=
          null;
    } else {
      isRead = widget.chat.value?.lastReads
              .firstWhereOrNull((e) => e.memberId == widget.me)
              ?.at
              .isBefore(widget.item.value.at) ==
          false;
    }

    return isRead;
  }

  /// Populates the [_galleryKeys] from the provided [ChatMessage.attachments].
  void _populateGlobalKeys(ChatItem msg) {
    if (msg is ChatMessage) {
      _galleryKeys = msg.attachments
          .where((e) =>
              e is ImageAttachment ||
              (e is FileAttachment && e.isVideo) ||
              (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
          .map((e) => GlobalKey())
          .toList();
    } else if (msg is ChatForward) {
      throw Exception(
        'Use `ChatForward` widget for rendering `ChatForward`s instead',
      );
    }
  }
}

/// Returns visual representation of the provided media-[Attachment].
Widget buildMediaAttachment(
  Attachment e,
  List<Attachment> media, {
  required GlobalKey key,
  required BuildContext context,
  List<Attachment> Function()? onGallery,
  Future<void> Function()? onError,
  bool filled = true,
}) {
  bool isLocal = e is LocalAttachment;

  bool isVideo;
  if (isLocal) {
    isVideo = e.file.isVideo;
  } else {
    isVideo = e is FileAttachment;
  }

  var attachment = isVideo
      ? Stack(
          alignment: Alignment.center,
          children: [
            isLocal
                ? e.file.bytes == null
                    ? const CircularProgressIndicator()
                    : VideoThumbnail.bytes(
                        bytes: e.file.bytes!,
                        key: key,
                        height: 300,
                      )
                : VideoThumbnail.url(
                    url: '${Config.files}${e.original.relativeRef}',
                    key: key,
                    height: 300,
                    onError: onError,
                  ),
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
        )
      : isLocal
          ? e.file.bytes == null
              ? const CircularProgressIndicator()
              : Image.memory(
                  e.file.bytes!,
                  key: key,
                  fit: BoxFit.cover,
                  height: 300,
                )
          : Container(
              key: const Key('SentImage'),
              child: Image.network(
                '${Config.files}${(e as ImageAttachment).big.relativeRef}',
                key: key,
                fit: BoxFit.cover,
                height: 300,
                errorBuilder: (_, __, ___) {
                  return InitCallback(
                    callback: () => onError?.call(),
                    child: const SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                },
              ),
            );

  return Padding(
    padding: EdgeInsets.zero,
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: isLocal
          ? null
          : () {
              List<Attachment> attachments = onGallery?.call() ?? media;

              int initial = attachments.indexOf(e);
              if (initial == -1) {
                initial = 0;
              }

              List<GalleryItem> gallery = [];
              for (var o in attachments) {
                String link = '${Config.files}${o.original.relativeRef}';
                if (o is FileAttachment) {
                  gallery.add(GalleryItem.video(link, o.filename));
                } else if (o is ImageAttachment) {
                  GalleryItem? item;

                  item = GalleryItem.image(
                    link,
                    o.filename,
                    onError: () async {
                      await onError?.call();
                      item?.link = '${Config.files}${o.original.relativeRef}';
                    },
                  );

                  gallery.add(item);
                }
              }

              GalleryPopup.show(
                context: context,
                gallery: GalleryPopup(
                  children: gallery,
                  initial: initial,
                  initialKey: key,
                ),
              );
            },
      child: Stack(
        alignment: Alignment.center,
        children: [
          filled ? Positioned.fill(child: attachment) : attachment,
          if (isLocal)
            ElasticAnimatedSwitcher(
              key: Key('AttachmentStatus_${e.id}'),
              child: e.status.value == SendingStatus.sent
                  ? const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green,
                    )
                  : e.status.value == SendingStatus.sending
                      ? CircularProgressIndicator(
                          key: const Key('Sending'),
                          value: e.progress.value,
                          backgroundColor: Colors.white,
                          strokeWidth: 10,
                        )
                      : const Icon(
                          Icons.error,
                          key: Key('Error'),
                          size: 48,
                          color: Colors.red,
                        ),
            )
        ],
      ),
    ),
  );
}

/// Returns visual representation of the provided file-[Attachment].
Widget buildFileAttachment(
  Attachment e, {
  required bool fromMe,
  void Function(FileAttachment)? onFileTap,
}) {
  Widget leading = Container();
  if (e is FileAttachment) {
    switch (e.downloadStatus.value) {
      case DownloadStatus.inProgress:
        leading = InkWell(
          onTap: () => onFileTap?.call(e),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgLoader.asset(
                'assets/icons/download_cancel.svg',
                key: const Key('CancelDownloading'),
                width: 28,
                height: 28,
              ),
              SizedBox.square(
                dimension: 26.3,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  key: const Key('Downloading'),
                  value: e.progress.value,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
        break;

      case DownloadStatus.isFinished:
        leading = const Icon(
          Icons.file_copy,
          key: Key('Downloaded'),
          color: Color(0xFF63B4FF),
          size: 28,
        );
        break;

      case DownloadStatus.notStarted:
        leading = SvgLoader.asset(
          'assets/icons/download.svg',
          key: const Key('Download'),
          width: 28,
          height: 28,
        );
        break;
    }

    leading = KeyedSubtree(key: const Key('Sent'), child: leading);
  } else if (e is LocalAttachment) {
    switch (e.status.value) {
      case SendingStatus.sending:
        leading = SizedBox.square(
          key: const Key('Sending'),
          dimension: 18,
          child: CircularProgressIndicator(
            value: e.progress.value,
            backgroundColor: Colors.white,
            strokeWidth: 5,
          ),
        );
        break;

      case SendingStatus.sent:
        leading = const Icon(
          Icons.check_circle,
          key: Key('Sent'),
          size: 18,
          color: Colors.green,
        );
        break;

      case SendingStatus.error:
        leading = const Icon(
          Icons.error_outline,
          key: Key('Error'),
          size: 18,
          color: Colors.red,
        );
        break;
    }
  }

  leading = AnimatedSwitcher(
    key: Key('AttachmentStatus_${e.id}'),
    duration: 250.milliseconds,
    child: leading,
  );

  return Padding(
    key: Key('File_${e.id}'),
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
    child: WidgetButton(
      onPressed: e is FileAttachment ? () => onFileTap?.call(e) : null,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: fromMe
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.03),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            const SizedBox(width: 8),
            leading,
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TODO: Cut with extension visible.
                  Text(
                    e.filename,
                    style: const TextStyle(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    e.original.size == null
                        ? '... KB'
                        : '${e.original.size! ~/ 1024} KB',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    ),
  );
}

/// Extension adding a string representation of a [Duration] in
/// `HH h, MM m, SS s` format.
extension LocalizedDurationExtension on Duration {
  /// Returns a string representation of this [Duration] in `HH:MM:SS` format.
  ///
  /// `HH` part is omitted if this [Duration] is less than an one hour.
  String hhMmSs() {
    var microseconds = inMicroseconds;

    var hours = microseconds ~/ Duration.microsecondsPerHour;
    microseconds = microseconds.remainder(Duration.microsecondsPerHour);
    var hoursPadding = hours < 10 ? '0' : '';

    if (microseconds < 0) microseconds = -microseconds;

    var minutes = microseconds ~/ Duration.microsecondsPerMinute;
    microseconds = microseconds.remainder(Duration.microsecondsPerMinute);
    var minutesPadding = minutes < 10 ? '0' : '';

    var seconds = microseconds ~/ Duration.microsecondsPerSecond;
    microseconds = microseconds.remainder(Duration.microsecondsPerSecond);
    var secondsPadding = seconds < 10 ? '0' : '';

    if (hours == 0) {
      return '$minutesPadding$minutes:$secondsPadding$seconds';
    }

    return '$hoursPadding$hours:$minutesPadding$minutes:$secondsPadding$seconds';
  }

  /// Returns localized string representing this [Duration] in
  /// `HH h, MM m, SS s` format.
  ///
  /// `MM` part is omitted if this [Duration] is less than an one minute.
  /// `HH` part is omitted if this [Duration] is less than an one hour.
  String localizedString() {
    var microseconds = inMicroseconds;

    var hours = microseconds ~/ Duration.microsecondsPerHour;
    microseconds = microseconds.remainder(Duration.microsecondsPerHour);

    if (microseconds < 0) microseconds = -microseconds;

    var minutes = microseconds ~/ Duration.microsecondsPerMinute;
    microseconds = microseconds.remainder(Duration.microsecondsPerMinute);

    var seconds = microseconds ~/ Duration.microsecondsPerSecond;
    microseconds = microseconds.remainder(Duration.microsecondsPerSecond);

    String result = '$seconds ${'label_duration_second_short'.l10n}';

    if (minutes != 0) {
      result = '$minutes ${'label_duration_minute_short'.l10n} $result';
    }

    if (hours != 0) {
      result = '$hours ${'label_duration_hour_short'.l10n} $result';
    }

    return result;
  }
}
