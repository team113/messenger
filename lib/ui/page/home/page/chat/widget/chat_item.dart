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
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../controller.dart'
    show ChatCallFinishReasonL10n, ChatController, FileAttachmentIsVideo;
import '/api/backend/schema.dart'
    show ChatCallFinishReason, ChatMemberInfoAction;
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
import '/ui/page/home/page/chat/forward/view.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'animated_offset.dart';
import 'chat_item_reads.dart';
import 'swipeable_status.dart';
import 'video_thumbnail/video_thumbnail.dart';

/// [ChatItem] visual representation.
class ChatItemWidget extends StatefulWidget {
  const ChatItemWidget({
    Key? key,
    required this.item,
    required this.chat,
    required this.me,
    this.user,
    this.avatar = true,
    this.margin = const EdgeInsets.fromLTRB(0, 6, 0, 6),
    this.reads = const [],
    this.getUser,
    this.animation,
    this.onHide,
    this.onDelete,
    this.onReply,
    this.onEdit,
    this.onCopy,
    this.onGallery,
    this.onRepliedTap,
    this.onResend,
    this.onDrag,
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

  /// Indicator whether this [ChatItemWidget] should display an [AvatarWidget].
  final bool avatar;

  /// [EdgeInsets] being margin to apply to this [ChatItemWidget].
  final EdgeInsets margin;

  /// [LastChatRead] to display under this [ChatItem].
  final Iterable<LastChatRead> reads;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  /// Callback, called when a hide action of this [ChatItem] is triggered.
  final void Function()? onHide;

  /// Callback, called when a delete action of this [ChatItem] is triggered.
  final void Function()? onDelete;

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

  /// Callback, called when a drag of this [ChatItem] starts or ends.
  final void Function(bool)? onDrag;

  /// Callback, called when a [FileAttachment] of this [ChatItem] is tapped.
  final void Function(FileAttachment)? onFileTap;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function()? onAttachmentError;

  @override
  State<ChatItemWidget> createState() => _ChatItemWidgetState();

  /// Returns a visual representation of the provided media-[Attachment].
  static Widget mediaAttachment(
    BuildContext context,
    Attachment e,
    List<Attachment> media, {
    GlobalKey? key,
    List<Attachment> Function()? onGallery,
    Future<void> Function()? onError,
    bool filled = true,
  }) {
    final bool isLocal = e is LocalAttachment;

    final bool isVideo;
    if (isLocal) {
      isVideo = e.file.isVideo;
    } else {
      isVideo = e is FileAttachment;
    }

    final Widget attachment;
    if (isVideo) {
      attachment = Stack(
        alignment: Alignment.center,
        fit: filled ? StackFit.expand : StackFit.loose,
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
                  url: e.original.url,
                  key: key,
                  height: 300,
                  onError: onError,
                ),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x80000000),
              ),
              child:
                  const Icon(Icons.play_arrow, color: Colors.white, size: 48),
            ),
          ),
        ],
      );
    } else if (isLocal) {
      if (e.file.bytes == null) {
        attachment = const CircularProgressIndicator();
      } else {
        attachment = Image.memory(
          e.file.bytes!,
          key: key,
          fit: BoxFit.cover,
          height: 300,
        );
      }
    } else {
      attachment = KeyedSubtree(
        key: const Key('SentImage'),
        child: RetryImage(
          (e as ImageAttachment).big.url,
          key: key,
          fit: BoxFit.cover,
          width: filled ? double.infinity : null,
          height: 300,
          onForbidden: onError,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.zero,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: isLocal
            ? null
            : () {
                final List<Attachment> attachments = onGallery?.call() ?? media;

                int initial = attachments.indexOf(e);
                if (initial == -1) {
                  initial = 0;
                }

                List<GalleryItem> gallery = [];
                for (var o in attachments) {
                  String link = o.original.url;
                  GalleryItem? item;

                  if (o is FileAttachment) {
                    item = GalleryItem.video(
                      link,
                      o.filename,
                      size: o.original.size,
                      onError: () async {
                        await onError?.call();
                        item?.link = o.original.url;
                      },
                    );
                  } else if (o is ImageAttachment) {
                    item = GalleryItem.image(
                      link,
                      o.filename,
                      size: o.original.size,
                      onError: () async {
                        await onError?.call();
                        item?.link = o.original.url;
                      },
                    );
                  }

                  gallery.add(item!);
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
            filled
                ? Positioned.fill(child: attachment)
                : Container(
                    constraints: const BoxConstraints(minWidth: 300),
                    width: double.infinity,
                    child: attachment,
                  ),
            ElasticAnimatedSwitcher(
              key: Key('AttachmentStatus_${e.id}'),
              child: !isLocal
                  ? Container(key: const Key('Sent'))
                  : e.status.value == SendingStatus.sent
                      ? const Icon(
                          Icons.check_circle,
                          key: Key('Sent'),
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

  /// Returns a visual representation of the provided file-[Attachment].
  static Widget fileAttachment(
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
                    value: e.progress.value == 0 ? null : e.progress.value,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.basenameWithoutExtension(e.filename),
                            style: const TextStyle(fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          p.extension(e.filename),
                          style: const TextStyle(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'label_kb'.l10nfmt({
                        'amount': e.original.size == null
                            ? 'dot'.l10n * 3
                            : e.original.size! ~/ 1024
                      }),
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
}

/// State of a [ChatItemWidget] used to update an active call [Timer].
class _ChatItemWidgetState extends State<ChatItemWidget> {
  /// [Timer] rebuilding this widget every second if the [widget.item]
  /// represents an ongoing [ChatCall].
  Timer? _ongoingCallTimer;

  /// [GlobalKey]s of [Attachment]s used to animate a [GalleryPopup] from/to
  /// corresponding [Widget].
  List<GlobalKey> _galleryKeys = [];

  /// [Offset] to translate this [ChatItemWidget] with when swipe to reply
  /// gesture is happening.
  Offset _offset = Offset.zero;

  /// Total [Offset] applied to this [ChatItemWidget] by a swipe gesture.
  Offset _totalOffset = Offset.zero;

  /// [Duration] to animate [_offset] changes with.
  ///
  /// Used to animate [_offset] resetting when swipe to reply gesture ends.
  Duration _offsetDuration = Duration.zero;

  /// Indicator whether this [ChatItemWidget] is in an ongoing drag.
  bool _dragging = false;

  /// Indicator whether [GestureDetector] of this [ChatItemWidget] recognized a
  /// horizontal drag start.
  ///
  /// This indicator doesn't mean that the started drag will become an ongoing.
  bool _draggingStarted = false;

  /// Indicates whether this [ChatItem] was read by any [User].
  bool get _isRead {
    final Chat? chat = widget.chat.value;
    if (chat == null) {
      return false;
    }

    if (_fromMe) {
      return chat.isRead(widget.item.value, widget.me);
    } else {
      return chat.isReadBy(widget.item.value, widget.me);
    }
  }

  /// Indicates whether this [ChatItemWidget.item] was posted by the
  /// authenticated [MyUser].
  bool get _fromMe => widget.item.value.authorId == widget.me;

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
    final Style style = Theme.of(context).extension<Style>()!;
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
    final Style style = Theme.of(context).extension<Style>()!;
    final ChatMemberInfo message = widget.item.value as ChatMemberInfo;

    final Widget content;

    switch (message.action) {
      case ChatMemberInfoAction.created:
        if (widget.chat.value?.isGroup == true) {
          content = Text('label_group_created'.l10n);
        } else {
          content = Text('label_dialog_created'.l10n);
        }
        break;

      case ChatMemberInfoAction.added:
        content = Text(
          'label_was_added'
              .l10nfmt({'who': '${message.user.name ?? message.user.num}'}),
        );
        break;

      case ChatMemberInfoAction.removed:
        content = Text(
          'label_was_removed'
              .l10nfmt({'who': '${message.user.name ?? message.user.num}'}),
        );
        break;

      case ChatMemberInfoAction.artemisUnknown:
        content = Text('${message.action}');
        break;
    }

    final bool isSent = widget.item.value.status.value == SendingStatus.sent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SwipeableStatus(
        animation: widget.animation,
        translate: false,
        isSent: isSent && _fromMe,
        isDelivered: isSent &&
            _fromMe &&
            widget.chat.value?.lastDelivery.isBefore(message.at) == false,
        isRead: isSent && (!_fromMe || _isRead),
        isError: message.status.value == SendingStatus.error,
        isSending: message.status.value == SendingStatus.sending,
        swipeable: Text(DateFormat.Hm().format(message.at.val.toLocal())),
        padding: const EdgeInsets.only(bottom: 8),
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
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  /// Renders [widget.item] as [ChatMessage].
  Widget _renderAsChatMessage(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;
    final ChatMessage msg = widget.item.value as ChatMessage;

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

    Color color = _fromMe
        ? Theme.of(context).colorScheme.secondary
        : AvatarWidget.colors[(widget.user?.user.value.num.val.sum() ?? 3) %
            AvatarWidget.colors.length];

    double avatarOffset = 0;
    if ((!_fromMe && widget.chat.value?.isGroup == true && widget.avatar) &&
        msg.repliesTo.isNotEmpty) {
      for (ChatItem reply in msg.repliesTo) {
        if (reply is ChatMessage) {
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

        if (reply is ChatCall) {
          if (msg.attachments.isEmpty && text == null) {
            avatarOffset += 59 - 4;
          } else {
            avatarOffset += 55 - 4 + 8;
          }
        }

        if (reply is ChatForward) {
          if (msg.attachments.isEmpty && text == null) {
            avatarOffset += 59 - 5;
          } else {
            avatarOffset += 55 - 4 + 8;
          }
        }
      }
    }

    return _rounded(
      context,
      Container(
        padding: widget.margin.add(const EdgeInsets.fromLTRB(5, 0, 2, 0)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (msg.repliesTo.isNotEmpty)
                  ...msg.repliesTo.mapIndexed((i, e) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      decoration: BoxDecoration(
                        color: e.authorId == widget.me
                            ? _isRead || !_fromMe
                                ? const Color(0xFFDBEAFD)
                                : const Color(0xFFE6F1FE)
                            : _isRead || !_fromMe
                                ? const Color(0xFFF9F9F9)
                                : const Color(0xFFFFFFFF),
                        borderRadius: i == 0
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              )
                            : BorderRadius.zero,
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: _isRead || !_fromMe ? 1 : 0.55,
                        child: WidgetButton(
                          onPressed: () => widget.onRepliedTap?.call(e.id),
                          child: _repliedMessage(e),
                        ),
                      ),
                    );
                  }),
                if (!_fromMe &&
                    widget.chat.value?.isGroup == true &&
                    widget.avatar)
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
                        !_fromMe &&
                                widget.chat.value?.isGroup == true &&
                                widget.avatar
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
                    opacity: _isRead || !_fromMe ? 1 : 0.55,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                      child: Column(
                        children: files
                            .map(
                              (e) => ChatItemWidget.fileAttachment(
                                e,
                                fromMe: _fromMe,
                                onFileTap: widget.onFileTap,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                if (media.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: text != null ||
                              msg.repliesTo.isNotEmpty ||
                              (!_fromMe &&
                                  widget.chat.value?.isGroup == true &&
                                  widget.avatar)
                          ? Radius.zero
                          : files.isEmpty
                              ? const Radius.circular(15)
                              : Radius.zero,
                      topRight: text != null ||
                              msg.repliesTo.isNotEmpty ||
                              (!_fromMe &&
                                  widget.chat.value?.isGroup == true &&
                                  widget.avatar)
                          ? Radius.zero
                          : files.isEmpty
                              ? const Radius.circular(15)
                              : Radius.zero,
                      bottomLeft: const Radius.circular(15),
                      bottomRight: const Radius.circular(15),
                    ),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: _isRead || !_fromMe ? 1 : 0.55,
                      child: media.length == 1
                          ? ChatItemWidget.mediaAttachment(
                              context,
                              media.first,
                              media,
                              filled: false,
                              key: _galleryKeys[0],
                              onError: widget.onAttachmentError,
                              onGallery: widget.onGallery,
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
                                        key: _galleryKeys[i],
                                        onError: widget.onAttachmentError,
                                        onGallery: widget.onGallery,
                                      ),
                                    )
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
      avatarOffset: avatarOffset,
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
    bool isMissed = false;

    String title = 'label_chat_call_ended'.l10n;
    String? time;

    if (isOngoing) {
      title = 'label_chat_call_ongoing'.l10n;
      time = message.conversationStartedAt!.val
          .difference(DateTime.now())
          .localizedString();
    } else if (message.finishReason != null) {
      title = message.finishReason!.localizedString(_fromMe) ?? title;
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

    final Style style = Theme.of(context).extension<Style>()!;

    subtitle = [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
        child: message.withVideo
            ? SvgLoader.asset(
                'assets/icons/call_video${isMissed && !_fromMe ? '_red' : ''}.svg',
                height: 13,
              )
            : SvgLoader.asset(
                'assets/icons/call_audio${isMissed && !_fromMe ? '_red' : ''}.svg',
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

    return _rounded(
      context,
      Padding(
        padding: widget.margin.add(const EdgeInsets.fromLTRB(5, 1, 5, 1)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            border: _fromMe
                ? _isRead
                    ? style.secondaryBorder
                    : Border.all(color: const Color(0xFFDAEDFF), width: 0.5)
                : style.primaryBorder,
            color: _fromMe
                ? _isRead
                    ? style.readMessageColor
                    : style.unreadMessageColor
                : style.messageColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _isRead || !_fromMe ? 1 : 0.55,
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
                ),
                width: 50,
                height: 50,
                child: image == null
                    ? Icon(
                        Icons.file_copy,
                        color: fromMe ? Colors.white : const Color(0xFFDDDDDD),
                        size: 28,
                      )
                    : RetryImage(
                        image.medium.url,
                        onForbidden: widget.onAttachmentError,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
              );
            })
            .take(3)
            .toList();

        if (item.attachments.length > 3) {
          final int count = max(item.attachments.length - 3, 99);

          additional.add(
            Container(
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: fromMe
                    ? Colors.white.withOpacity(0.25)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              width: 50,
              height: 50,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${'plus'.l10n}$count',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          );
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
          Flexible(child: Text(title, style: style.boldBody)),
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
                          'dot'.l10n * 3,
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
  Widget _rounded(
    BuildContext context,
    Widget child, {
    double avatarOffset = 0,
  }) {
    ChatItem item = widget.item.value;

    String? copyable;
    if (item is ChatMessage) {
      copyable = item.text?.val;
    }

    bool isSent = item.status.value == SendingStatus.sent;

    const int maxAvatars = 5;
    final List<Widget> avatars = [];

    if (widget.chat.value?.isGroup == true) {
      final int countUserAvatars =
          widget.reads.length > maxAvatars ? maxAvatars - 1 : maxAvatars;

      for (LastChatRead m in widget.reads.take(countUserAvatars)) {
        final User? user = widget.chat.value?.members
            .firstWhereOrNull((e) => e.user.id == m.memberId)
            ?.user;

        if (user != null) {
          avatars.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FutureBuilder<RxUser?>(
                future: widget.getUser?.call(user.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return AvatarWidget.fromRxUser(snapshot.data, radius: 10);
                  }
                  return AvatarWidget.fromUser(user, radius: 10);
                },
              ),
            ),
          );
        }
      }

      if (widget.reads.length > maxAvatars) {
        avatars.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: AvatarWidget(title: 'plus'.l10n, radius: 10),
          ),
        );
      }
    }

    return SwipeableStatus(
      animation: widget.animation,
      translate: _fromMe,
      isSent: isSent && _fromMe,
      isDelivered: isSent &&
          _fromMe &&
          widget.chat.value?.lastDelivery.isBefore(item.at) == false,
      isRead: isSent && (!_fromMe || _isRead),
      isError: item.status.value == SendingStatus.error,
      isSending: item.status.value == SendingStatus.sending,
      swipeable: Text(DateFormat.Hm().format(item.at.val.toLocal())),
      padding:
          EdgeInsets.only(bottom: widget.reads.isNotEmpty == true ? 33 : 13),
      child: AnimatedOffset(
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
              // Distance [_totalOffset] should exceed in order for dragging to
              // start.
              const int delta = 10;

              if (_totalOffset.dx > delta) {
                _offset += d.delta;

                if (_offset.dx > 30 + delta &&
                    _offset.dx - d.delta.dx < 30 + delta) {
                  HapticFeedback.selectionClick();
                  widget.onReply?.call();
                }

                setState(() {});
              } else {
                _totalOffset += d.delta;
                if (_totalOffset.dx <= 0) {
                  _dragging = false;
                  widget.onDrag?.call(_dragging);
                }
              }
            }
          },
          onHorizontalDragEnd: (d) {
            if (_dragging) {
              _dragging = false;
              _draggingStarted = false;
              _offset = Offset.zero;
              _totalOffset = Offset.zero;
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
              if (_fromMe)
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
                            padding: EdgeInsets.only(bottom: 8),
                            child: Icon(Icons.access_alarm, size: 15),
                          )
                        : item.status.value == SendingStatus.error
                            ? const Padding(
                                key: Key('Error'),
                                padding: EdgeInsets.only(bottom: 8),
                                child: Icon(
                                  Icons.error_outline,
                                  size: 15,
                                  color: Colors.red,
                                ),
                              )
                            : Container(key: const Key('Sent')),
                  ),
                ),
              if (!_fromMe && widget.chat.value!.isGroup)
                Padding(
                  padding: EdgeInsets.only(top: 8 + avatarOffset),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => router.user(item.authorId, push: true),
                    child: Opacity(
                      opacity: widget.avatar ? 1 : 0,
                      child: AvatarWidget.fromRxUser(widget.user, radius: 17),
                    ),
                  ),
                ),
              Flexible(
                child: LayoutBuilder(builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: min(
                        550,
                        (constraints.maxWidth +
                                    (_fromMe ? SwipeableStatus.width : 0)) *
                                0.84 -
                            20,
                      ),
                    ),
                    child: Material(
                      key: Key('Message_${item.id}'),
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
                              label: PlatformUtils.isMobile
                                  ? 'btn_copy'.l10n
                                  : 'btn_copy_text'.l10n,
                              trailing: SvgLoader.asset(
                                'assets/icons/copy_small.svg',
                                height: 18,
                              ),
                              onPressed: () => widget.onCopy?.call(copyable!),
                            ),
                          if (item.status.value == SendingStatus.sent) ...[
                            ContextMenuButton(
                              key: const Key('ReplyButton'),
                              label: PlatformUtils.isMobile
                                  ? 'btn_reply'.l10n
                                  : 'btn_reply_message'.l10n,
                              trailing: SvgLoader.asset(
                                'assets/icons/reply.svg',
                                height: 18,
                              ),
                              onPressed: widget.onReply,
                            ),
                            if (item is ChatMessage)
                              ContextMenuButton(
                                key: const Key('ForwardButton'),
                                label: PlatformUtils.isMobile
                                    ? 'btn_forward'.l10n
                                    : 'btn_forward_message'.l10n,
                                trailing: SvgLoader.asset(
                                  'assets/icons/forward.svg',
                                  height: 18,
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
                                _fromMe &&
                                (item.at
                                        .add(ChatController.editMessageTimeout)
                                        .isAfter(PreciseDateTime.now()) ||
                                    !_isRead))
                              ContextMenuButton(
                                key: const Key('EditButton'),
                                label: 'btn_edit'.l10n,
                                trailing: SvgLoader.asset(
                                  'assets/icons/edit.svg',
                                  height: 18,
                                ),
                                onPressed: widget.onEdit,
                              ),
                            ContextMenuButton(
                              key: const Key('Delete'),
                              label: PlatformUtils.isMobile
                                  ? 'btn_delete'.l10n
                                  : 'btn_delete_message'.l10n,
                              trailing: SvgLoader.asset(
                                'assets/icons/delete_small.svg',
                                height: 18,
                              ),
                              onPressed: () async {
                                bool deletable = _fromMe &&
                                    !widget.chat.value!
                                        .isRead(widget.item.value, widget.me) &&
                                    (widget.item.value is ChatMessage);

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
                          if (item.status.value == SendingStatus.error) ...[
                            ContextMenuButton(
                              key: const Key('Resend'),
                              label: PlatformUtils.isMobile
                                  ? 'btn_resend'.l10n
                                  : 'btn_resend_message'.l10n,
                              trailing: SvgLoader.asset(
                                'assets/icons/send_small.svg',
                                width: 18.37,
                                height: 16,
                              ),
                              onPressed: widget.onResend,
                            ),
                            ContextMenuButton(
                              key: const Key('Delete'),
                              label: PlatformUtils.isMobile
                                  ? 'btn_delete'.l10n
                                  : 'btn_delete_message'.l10n,
                              trailing: SvgLoader.asset(
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
                            ContextMenuButton(
                              label: 'btn_select'.l10n,
                              trailing: const Icon(Icons.select_all),
                            ),
                          ],
                        ],
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            child,
                            if (avatars.isNotEmpty)
                              Transform.translate(
                                offset: Offset(-12, -widget.margin.bottom),
                                child: WidgetButton(
                                  onPressed: () => ChatItemReads.show(
                                    context,
                                    reads: widget.reads,
                                    getUser: widget.getUser,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: avatars,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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

    if (microseconds < 0) microseconds = -microseconds;

    var hours = microseconds ~/ Duration.microsecondsPerHour;
    microseconds = microseconds.remainder(Duration.microsecondsPerHour);

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
