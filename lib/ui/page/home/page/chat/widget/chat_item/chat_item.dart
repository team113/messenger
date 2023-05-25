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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/domain/model/file.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/forward/view.dart';
import '/ui/page/home/page/chat/controller.dart'
    show ChatCallFinishReasonL10n, ChatController, FileAttachmentIsVideo;
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
import '/ui/page/home/page/chat/widget/animated_offset.dart';
import '/ui/page/home/page/chat/widget/data_attachment.dart';
import '/ui/page/home/page/chat/widget/media_attachment.dart';
import '/ui/page/home/page/chat/widget/message_info/view.dart';
import '/ui/page/home/page/chat/widget/message_timestamp.dart';
import '/ui/page/home/page/chat/widget/selection_text.dart';
import '/ui/page/home/page/chat/widget/swipeable_status.dart';
import '/util/platform_utils.dart';
import 'render_as_chat_call.dart';
import 'render_as_chat_info.dart';
import 'render_as_chat_message.dart';

/// [ChatItem] visual representation.
class ChatItemWidget extends StatefulWidget {
  const ChatItemWidget({
    super.key,
    required this.item,
    required this.chat,
    required this.me,
    this.user,
    this.avatar = true,
    this.margin = const EdgeInsets.fromLTRB(0, 6, 0, 6),
    this.reads = const [],
    this.loadImages = true,
    this.animation,
    this.timestamp = true,
    this.getUser,
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
    this.onSelecting,
  });

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

  /// Indicator whether the [ImageAttachment]s of this [ChatItem] should be
  /// fetched as soon as they are displayed, if any.
  final bool loadImages;

  /// Optional animation that controls a [SwipeableStatus].
  final AnimationController? animation;

  /// Indicator whether a [ChatItem.at] should be displayed within this
  /// [ChatItemWidget].
  final bool timestamp;

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

  /// Callback, called when a gallery list is required.
  ///
  /// If not specified, then only media in this [item] will be in a gallery.
  final List<Attachment> Function()? onGallery;

  /// Callback, called when a replied message of this [ChatItem] is tapped.
  final void Function(ChatItemQuote)? onRepliedTap;

  /// Callback, called when a resend action of this [ChatItem] is triggered.
  final void Function()? onResend;

  /// Callback, called when a drag of this [ChatItem] starts or ends.
  final void Function(bool)? onDrag;

  /// Callback, called when a [FileAttachment] of this [ChatItem] is tapped.
  final void Function(FileAttachment)? onFileTap;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function()? onAttachmentError;

  /// Callback, called when a [Text] selection starts or ends.
  final void Function(bool)? onSelecting;

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
    bool autoLoad = true,
  }) {
    final Style style = Theme.of(context).extension<Style>()!;

    final bool isLocal = e is LocalAttachment;

    final bool isVideo;
    if (isLocal) {
      isVideo = e.file.isVideo;
    } else {
      isVideo = e is FileAttachment;
    }

    Widget attachment;
    if (isVideo) {
      attachment = Stack(
        alignment: Alignment.center,
        fit: filled ? StackFit.expand : StackFit.loose,
        children: [
          MediaAttachment(
            key: key,
            attachment: e,
            height: 300,
            autoLoad: autoLoad,
            onError: onError,
          ),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.colors.onBackgroundOpacity50,
              ),
              child: Icon(
                Icons.play_arrow,
                color: style.colors.onPrimary,
                size: 48,
              ),
            ),
          ),
        ],
      );
    } else {
      attachment = MediaAttachment(
        key: key,
        attachment: e,
        height: 300,
        width: filled ? double.infinity : null,
        fit: BoxFit.cover,
        autoLoad: autoLoad,
        onError: onError,
      );

      if (!isLocal) {
        attachment = KeyedSubtree(
          key: const Key('SentImage'),
          child: attachment,
        );
      }
    }

    return Padding(
      padding: EdgeInsets.zero,
      child: MouseRegion(
        cursor: isLocal ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: isLocal
              ? null
              : () {
                  final List<Attachment> attachments =
                      onGallery?.call() ?? media;

                  int initial = attachments.indexOf(e);
                  if (initial == -1) {
                    initial = 0;
                  }

                  List<GalleryItem> gallery = [];
                  for (var o in attachments) {
                    StorageFile file = o.original;
                    GalleryItem? item;

                    if (o is FileAttachment) {
                      item = GalleryItem.video(
                        file.url,
                        o.filename,
                        size: file.size,
                        checksum: file.checksum,
                        onError: () async {
                          await onError?.call();
                          item?.link = o.original.url;
                        },
                      );
                    } else if (o is ImageAttachment) {
                      item = GalleryItem.image(
                        file.url,
                        o.filename,
                        size: file.size,
                        checksum: file.checksum,
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
                    : Container(
                        constraints: filled
                            ? const BoxConstraints(
                                minWidth: 300, minHeight: 300)
                            : null,
                        child: e.status.value == SendingStatus.sent
                            ? Icon(
                                Icons.check_circle,
                                key: const Key('Sent'),
                                size: 48,
                                color: style.colors.acceptAuxiliaryColor,
                              )
                            : e.status.value == SendingStatus.sending
                                ? SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        key: const Key('Sending'),
                                        value: e.progress.value,
                                        backgroundColor: style.colors.onPrimary,
                                        strokeWidth: 10,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.error,
                                    key: const Key('Error'),
                                    size: 48,
                                    color: style.colors.dangerColor,
                                  ),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Returns a visual representation of the provided file-[Attachment].
  static Widget fileAttachment(
    Attachment e, {
    void Function(FileAttachment)? onFileTap,
  }) {
    return DataAttachment(
      e,
      onPressed: () {
        if (e is FileAttachment) {
          onFileTap?.call(e);
        }
      },
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

  /// [SelectedContent] of a [SelectionText] within this [ChatItemWidget].
  SelectedContent? _selection;

  /// [TapGestureRecognizer]s for tapping on the [SelectionText.rich] spans, if
  /// any.
  final List<TapGestureRecognizer> _recognizers = [];

  /// [TextSpan] of the [ChatItemWidget.item] to display as a text of this
  /// [ChatItemWidget].
  TextSpan? _text;

  /// [Worker] reacting on the [ChatItemWidget.item] changes updating the
  /// [_text] and [_galleryKeys].
  Worker? _worker;

  /// Indicates whether this [ChatItem] was read by any [User].
  bool get _isRead {
    final Chat? chat = widget.chat.value;
    if (chat == null) {
      return false;
    }

    if (_fromMe) {
      return chat.isRead(widget.item.value, widget.me, chat.members);
    } else {
      return chat.isReadBy(widget.item.value, widget.me);
    }
  }

  /// Indicates whether this [ChatItemWidget.item] was posted by the
  /// authenticated [MyUser].
  bool get _fromMe => widget.item.value.authorId == widget.me;

  @override
  void initState() {
    _populateWorker();
    super.initState();
  }

  @override
  void dispose() {
    _ongoingCallTimer?.cancel();
    _ongoingCallTimer = null;

    _worker?.dispose();
    for (var r in _recognizers) {
      r.dispose();
    }

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatItemWidget oldWidget) {
    if (oldWidget.item != widget.item) {
      _populateWorker();
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
          return RenderAsChatMessage(
            chat: widget.chat,
            item: widget.item,
            rxUser: widget.user,
            fromMe: _fromMe,
            isRead: _isRead,
            avatar: widget.avatar,
            text: _text,
            me: widget.me,
            onRepliedTap: widget.onRepliedTap,
            avatarOffset: 0,
            timestamp: widget.timestamp,
            onSelecting: widget.onSelecting,
            galleryKeys: _galleryKeys,
            onAttachmentError: widget.onAttachmentError,
            onGallery: widget.onGallery,
            loadImages: widget.loadImages,
            onFileTap: widget.onFileTap,
            margin: widget.margin,
            onChanged: (a) => _selection = a,
            rounded: _rounded,
            repliedMessage: _repliedMessage,
            timestampWidget: _timestamp,
          );
        } else if (widget.item.value is ChatForward) {
          throw Exception(
            'Use `ChatForward` widget for rendering `ChatForward`s instead',
          );
        } else if (widget.item.value is ChatCall) {
          return SelectionContainer.disabled(
              child: RenderAsChatCall(
            item: widget.item,
            fromMe: _fromMe,
            isRead: _isRead,
            chat: widget.chat,
            avatar: widget.avatar,
            me: widget.me,
            rxUser: widget.user,
            timestamp: widget.timestamp,
            margin: widget.margin,
            timestampWidget: _timestamp,
            rounded: _rounded,
            startCallTimer: () => startCallTimer(_ongoingCallTimer),
          ));
        } else if (widget.item.value is ChatInfo) {
          return SelectionContainer.disabled(
              child: RenderAsChatInfo(
            chat: widget.chat,
            item: widget.item,
            rxUser: widget.user,
            animation: widget.animation,
            fromMe: _fromMe,
            isRead: _isRead,
            getUser: widget.getUser,
          ));
        }
        throw UnimplementedError('Unknown ChatItem ${widget.item.value}');
      }),
    );
  }

  /// Renders the provided [item] as a replied message.
  Widget _repliedMessage(ChatItemQuote item, {bool timestamp = false}) {
    Style style = Theme.of(context).extension<Style>()!;
    bool fromMe = item.author == widget.me;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessageQuote) {
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
                      ? style.colors.onPrimaryOpacity25
                      : style.colors.onBackgroundOpacity2,
                  borderRadius: BorderRadius.circular(10),
                ),
                width: 50,
                height: 50,
                child: image == null
                    ? Icon(
                        Icons.file_copy,
                        color: fromMe
                            ? style.colors.onPrimary
                            : style.colors.secondaryHighlightDarkest,
                        size: 28,
                      )
                    : RetryImage(
                        image.medium.url,
                        checksum: image.medium.checksum,
                        onForbidden: widget.onAttachmentError,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.circular(10.0),
                        cancelable: true,
                        autoLoad: widget.loadImages,
                      ),
              );
            })
            .take(3)
            .toList();

        if (item.attachments.length > 3) {
          final int count = (item.attachments.length - 3).clamp(1, 99);

          additional.add(
            Container(
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: fromMe
                    ? style.colors.onPrimaryOpacity25
                    : style.colors.onBackgroundOpacity2,
                borderRadius: BorderRadius.circular(10),
              ),
              width: 50,
              height: 50,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${'plus'.l10n}$count',
                    style:
                        TextStyle(fontSize: 15, color: style.colors.secondary),
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
    } else if (item is ChatCallQuote) {
      String title = 'label_chat_call_ended'.l10n;
      String? time;
      bool fromMe = widget.me == item.author;
      bool isMissed = false;

      final ChatCall? call = item.original as ChatCall?;

      if (call?.finishReason == null && call?.conversationStartedAt != null) {
        title = 'label_chat_call_ongoing'.l10n;
      } else if (call?.finishReason != null) {
        title = call!.finishReason!.localizedString(fromMe) ?? title;
        isMissed = call.finishReason == ChatCallFinishReason.dropped ||
            call.finishReason == ChatCallFinishReason.unanswered;

        if (call.finishedAt != null && call.conversationStartedAt != null) {
          time = call.finishedAt!.val
              .difference(call.conversationStartedAt!.val)
              .localizedString();
        }
      } else {
        title = item.author == widget.me
            ? 'label_outgoing_call'.l10n
            : 'label_incoming_call'.l10n;
      }

      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
            child: call?.withVideo == true
                ? SvgImage.asset(
                    'assets/icons/call_video${isMissed && !fromMe ? '_red' : ''}.svg',
                    height: 13,
                  )
                : SvgImage.asset(
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
    } else if (item is ChatInfoQuote) {
      // TODO: Implement `ChatInfo`.
      content = Text(item.action.toString(), style: style.boldBody);
    } else {
      content = Text('err_unknown'.l10n, style: style.boldBody);
    }

    return FutureBuilder<RxUser?>(
      future: widget.getUser?.call(item.author),
      builder: (context, snapshot) {
        final Color color = snapshot.data?.user.value.id == widget.me
            ? style.colors.primary
            : style.colors.userColors[
                (snapshot.data?.user.value.num.val.sum() ?? 3) %
                    style.colors.userColors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                children: [
                  Container(
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: additional,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (timestamp)
                    Opacity(opacity: 0, child: _timestamp(widget.item.value)),
                ],
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
    Widget Function(bool menu) builder, {
    double avatarOffset = 0,
  }) {
    final Style style = Theme.of(context).extension<Style>()!;

    ChatItem item = widget.item.value;

    String? copyable;
    if (item is ChatMessage) {
      copyable = item.text?.val;
    }

    final Iterable<LastChatRead>? reads = widget.chat.value?.lastReads.where(
      (e) =>
          !e.at.val.isBefore(widget.item.value.at.val) &&
          e.memberId != widget.item.value.authorId,
    );

    final bool isSent = item.status.value == SendingStatus.sent;

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

    // Builds the provided [builder] and the [avatars], if any.
    Widget child(bool menu) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          builder(menu),
          if (avatars.isNotEmpty)
            Transform.translate(
              offset: Offset(-12, -widget.margin.bottom),
              child: WidgetButton(
                onPressed: () => MessageInfo.show(
                  context,
                  reads: reads ?? [],
                  id: widget.item.value.id,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: avatars,
                  ),
                ),
              ),
            ),
        ],
      );
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
      padding: EdgeInsets.only(bottom: avatars.isNotEmpty ? 33 : 13),
      child: AnimatedOffset(
        duration: _offsetDuration,
        offset: _offset,
        curve: Curves.ease,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: PlatformUtils.isDesktop
              ? null
              : (d) {
                  _draggingStarted = true;
                  setState(() => _offsetDuration = Duration.zero);
                },
          onHorizontalDragUpdate: PlatformUtils.isDesktop
              ? null
              : (d) {
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
                    // Distance [_totalOffset] should exceed in order for
                    // dragging to start.
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
          onHorizontalDragEnd: PlatformUtils.isDesktop
              ? null
              : (d) {
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
              if (_fromMe && !widget.timestamp)
                Padding(
                  key: Key('MessageStatus_${item.id}'),
                  padding: const EdgeInsets.only(top: 16),
                  child: Obx(() {
                    return AnimatedDelayedSwitcher(
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
                              ? Padding(
                                  key: const Key('Error'),
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 15,
                                    color: style.colors.dangerColor,
                                  ),
                                )
                              : Container(key: const Key('Sent')),
                    );
                  }),
                ),
              if (!_fromMe && widget.chat.value!.isGroup)
                Padding(
                  padding: EdgeInsets.only(top: 8 + avatarOffset),
                  child: widget.avatar
                      ? InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => router.user(item.authorId, push: true),
                          child:
                              AvatarWidget.fromRxUser(widget.user, radius: 17),
                        )
                      : const SizedBox(width: 34),
                ),
              Flexible(
                child: LayoutBuilder(builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: min(
                        550,
                        constraints.maxWidth - SwipeableStatus.width,
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
                          ContextMenuButton(
                            label: PlatformUtils.isMobile
                                ? 'btn_info'.l10n
                                : 'btn_message_info'.l10n,
                            trailing: const Icon(Icons.info_outline),
                            onPressed: () => MessageInfo.show(
                              context,
                              id: widget.item.value.id,
                              reads: reads ?? [],
                            ),
                          ),
                          if (copyable != null)
                            ContextMenuButton(
                              key: const Key('CopyButton'),
                              label: PlatformUtils.isMobile
                                  ? 'btn_copy'.l10n
                                  : 'btn_copy_text'.l10n,
                              trailing: SvgImage.asset(
                                'assets/icons/copy_small.svg',
                                height: 18,
                              ),
                              onPressed: () => widget.onCopy
                                  ?.call(_selection?.plainText ?? copyable!),
                            ),
                          if (item.status.value == SendingStatus.sent) ...[
                            ContextMenuButton(
                              key: const Key('ReplyButton'),
                              label: PlatformUtils.isMobile
                                  ? 'btn_reply'.l10n
                                  : 'btn_reply_message'.l10n,
                              trailing: SvgImage.asset(
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
                                trailing: SvgImage.asset(
                                  'assets/icons/forward.svg',
                                  height: 18,
                                ),
                                onPressed: () async {
                                  await ChatForwardView.show(
                                    context,
                                    widget.chat.value!.id,
                                    [ChatItemQuoteInput(item: item)],
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
                                trailing: SvgImage.asset(
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
                              trailing: SvgImage.asset(
                                'assets/icons/delete_small.svg',
                                height: 18,
                              ),
                              onPressed: () async {
                                bool isMonolog = widget.chat.value!.isMonolog;
                                bool deletable = _fromMe &&
                                    !widget.chat.value!
                                        .isRead(widget.item.value, widget.me) &&
                                    (widget.item.value is ChatMessage);

                                await ConfirmDialog.show(
                                  context,
                                  title: 'label_delete_message'.l10n,
                                  description: deletable || isMonolog
                                      ? null
                                      : 'label_message_will_deleted_for_you'
                                          .l10n,
                                  variants: [
                                    if (!deletable || !isMonolog)
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
                              trailing: SvgImage.asset(
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
                              trailing: SvgImage.asset(
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
                        builder: PlatformUtils.isMobile ? child : null,
                        child: PlatformUtils.isMobile ? null : child(false),
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

  /// Builds a [MessageTimestamp] of the provided [item].
  Widget _timestamp(ChatItem item) {
    return Obx(() {
      final bool isMonolog = widget.chat.value?.isMonolog == true;

      return KeyedSubtree(
        key: Key('MessageStatus_${item.id}'),
        child: MessageTimestamp(
          at: item.at,
          status: _fromMe ? item.status.value : null,
          read: _isRead || isMonolog,
          delivered:
              widget.chat.value?.lastDelivery.isBefore(item.at) == false ||
                  isMonolog,
        ),
      );
    });
  }

  /// Populates the [_worker] invoking the [_populateSpans] and
  /// [_populateGlobalKeys] on the [ChatItemWidget.item] changes.
  void _populateWorker() {
    _worker?.dispose();
    _populateGlobalKeys(widget.item.value);
    _populateSpans(widget.item.value);

    ChatMessageText? text;
    int attachments = 0;

    if (widget.item.value is ChatMessage) {
      final msg = widget.item.value as ChatMessage;
      attachments = msg.attachments.length;
      text = msg.text;
    }

    _worker = ever(widget.item, (ChatItem item) {
      if (item is ChatMessage) {
        if (item.attachments.length != attachments) {
          _populateGlobalKeys(item);
          attachments = item.attachments.length;
        }

        if (text != item.text) {
          _populateSpans(item);
          text = item.text;
        }
      }
    });
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

  /// Populates the [_text] with the [ChatMessage.text] of the provided [item]
  /// parsed through a [LinkParsingExtension.parseLinks] method.
  void _populateSpans(ChatItem msg) {
    if (msg is ChatMessage) {
      for (var r in _recognizers) {
        r.dispose();
      }
      _recognizers.clear();

      final String? string = msg.text?.val.trim();
      if (string?.isEmpty == true) {
        _text = null;
      } else {
        _text = string?.parseLinks(_recognizers, router.context);
      }
    } else if (msg is ChatForward) {
      throw Exception(
        'Use `ChatForward` widget for rendering `ChatForward`s instead',
      );
    }
  }

  /// Starts the [ongoingCallTimer].
  void startCallTimer(Timer? ongoingCallTimer) {
    var message = widget.item.value as ChatCall;

    bool isOngoing =
        message.finishReason == null && message.conversationStartedAt != null;

    if (isOngoing) {
      ongoingCallTimer ??= Timer.periodic(1.seconds, (_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      ongoingCallTimer?.cancel();
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

/// Extension adding an ability to parse links and e-mails from a [String].
extension LinkParsingExtension on String {
  /// [RegExp] detecting links and e-mails in a [parseLinks] method.
  static final RegExp _regex = RegExp(
    r'([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)|((([a-z]+:\/\/)?(www\.)?([a-zA-Z0-9_-]+\.)+[a-zA-Z]{2,})((\/\S*)?[^,\u0027")}\].:;?!`\s])?)',
  );

  /// Returns [TextSpan]s containing plain text along with links and e-mails
  /// detected and parsed.
  ///
  /// [recognizers] are [TapGestureRecognizer]s constructed, so ensure to
  /// dispose them properly.
  TextSpan parseLinks(
    List<TapGestureRecognizer> recognizers, [
    BuildContext? context,
  ]) {
    final Iterable<RegExpMatch> matches = _regex.allMatches(this);
    if (matches.isEmpty) {
      return TextSpan(text: this);
    }

    final Style? style = context?.theme.extension<Style>()!;

    String text = this;
    final List<TextSpan> spans = [];
    final List<String> links = [];

    for (RegExpMatch match in matches) {
      links.add(text.substring(match.start, match.end));
    }

    for (int i = 0; i < links.length; i++) {
      final String link = links[i];

      final int index = text.indexOf(link);
      final List<String> parts = [
        text.substring(0, index),
        text.substring(index + link.length),
      ];

      if (parts[0].isNotEmpty) {
        spans.add(TextSpan(text: parts[0]));
      }

      final TapGestureRecognizer recognizer = TapGestureRecognizer();
      recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: link,
          style: style?.linkStyle,
          recognizer: recognizer
            ..onTap = () async {
              final Uri uri;

              if (link.isEmail) {
                uri = Uri(scheme: 'mailto', path: link);
              } else {
                uri = Uri.parse(
                  !link.startsWith('http') ? 'https://$link' : link,
                );
              }

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
        ),
      );

      if (parts[1].isNotEmpty) {
        if (i == links.length - 1) {
          spans.add(TextSpan(text: parts[1]));
        } else {
          text = parts[1];
        }
      }
    }

    return TextSpan(children: spans);
  }
}

/// Extension adding a fixed-length digits [Text] transformer.
extension FixedDigitsExtension on Text {
  /// [RegExp] detecting numbers.
  static final RegExp _regex = RegExp(r'\d');

  /// Returns a [Text] guaranteed to have fixed width of digits in it.
  Widget fixedDigits() {
    Text copyWith(String string) {
      return Text(
        string,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaleFactor: textScaleFactor,
        maxLines: maxLines,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }

    return Stack(
      children: [
        Opacity(opacity: 0, child: copyWith(data!.replaceAll(_regex, '0'))),
        copyWith(data!),
      ],
    );
  }
}
