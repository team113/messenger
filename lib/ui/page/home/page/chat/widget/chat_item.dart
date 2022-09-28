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
import '/ui/page/home/page/chat/forward/view.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
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
    this.onForwardedTap,
    this.onResend,
    this.onFileTap,
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
  final Function()? onHide;

  /// Callback, called when a delete action of this [ChatItem] is triggered.
  final Function()? onDelete;

  /// Callback, called when join call button is pressed.
  final Function()? onJoinCall;

  /// Callback, called when a reply action of this [ChatItem] is triggered.
  final Function()? onReply;

  /// Callback, called when an edit action of this [ChatItem] is triggered.
  final Function()? onEdit;

  /// Callback, called when a copy action of this [ChatItem] is triggered.
  final Function(String text)? onCopy;

  /// Optional animation that controls a [SwipeableStatus].
  final AnimationController? animation;

  /// Callback, called when a gallery list is required.
  ///
  /// If not specified, then only media in this [item] will be in a gallery.
  final List<Attachment> Function()? onGallery;

  /// Callback, called when a replied message of this [ChatItem] is tapped.
  final Function(ChatItemId)? onRepliedTap;

  /// Callback, called when a forwarded message of this [ChatItem] is tapped.
  final Function(ChatItemId, ChatId)? onForwardedTap;

  /// Callback, called when a resend action of this [ChatItem] is triggered.
  final Function()? onResend;

  /// Callback, called when a [FileAttachment] of this [ChatItem] is tapped.
  final Function(FileAttachment)? onFileTap;

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

  /// [DeleteOption] of [ChatItem] this [ChatItemWidget] represents.
  DeleteOption? _deleteOption = DeleteOption.me;

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
    return Obx(() {
      if (widget.item.value is ChatMessage) {
        return _renderAsChatMessage(context);
      } else if (widget.item.value is ChatForward) {
        return _renderAsChatForward(context);
      } else if (widget.item.value is ChatCall) {
        return _renderAsChatCall(context);
      } else if (widget.item.value is ChatMemberInfo) {
        return _renderAsChatMemberInfo();
      }
      throw UnimplementedError('Unknown ChatItem ${widget.item.value}');
    });
  }

  /// Renders [widget.item] as [ChatMemberInfo].
  Widget _renderAsChatMemberInfo() {
    var message = widget.item.value as ChatMemberInfo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(child: Text('${message.action}')),
    );
  }

  /// Renders [widget.item] as [ChatForward].
  Widget _renderAsChatForward(BuildContext context) {
    ChatForward msg = widget.item.value as ChatForward;
    ChatItem item = msg.item;

    Style style = Theme.of(context).extension<Style>()!;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessage) {
      var desc = StringBuffer();

      if (item.text != null) {
        desc.write(item.text!.val);
      }

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
            ...media.mapIndexed((i, e) => _mediaAttachment(i, e, media)),
            if (media.isNotEmpty && files.isNotEmpty) const SizedBox(height: 6),
            ...files.map(_fileAttachment),
          ];
        }
      }

      if (desc.isNotEmpty) {
        content = Text(
          desc.toString(),
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

    return _rounded(
      context,
      InkWell(
        onTap: () => widget.onForwardedTap?.call(msg.item.id, msg.item.chatId),
        child: FutureBuilder<RxUser?>(
          key: Key('FutureBuilder_${item.id}'),
          future: widget.getUser?.call(item.authorId),
          builder: (context, snapshot) {
            Color color = snapshot.data?.user.value.id == widget.me
                ? const Color(0xFF63B4FF)
                : AvatarWidget.colors[
                    (snapshot.data?.user.value.num.val.sum() ?? 3) %
                        AvatarWidget.colors.length];

            return Row(
              key: Key('Row_${item.id}'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 12),
                Icon(Icons.reply, size: 26, color: color),
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
                        if (snapshot.data?.user.value != null)
                          Text(
                            snapshot.data?.user.value.name?.val ??
                                snapshot.data?.user.value.num.val ??
                                '...',
                            style: style.boldBody.copyWith(color: color),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Renders [widget.item] as [ChatMessage].
  Widget _renderAsChatMessage(BuildContext context) {
    var msg = widget.item.value as ChatMessage;

    List<Attachment> media = msg.attachments
        .where((e) =>
            e is ImageAttachment ||
            (e is FileAttachment && e.isVideo) ||
            (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
        .toList();

    List<Attachment> files = msg.attachments
        .where((e) =>
            (e is FileAttachment && !e.isVideo) ||
            (e is LocalAttachment && !e.file.isImage && !e.file.isVideo))
        .toList();

    return _rounded(
      context,
      Column(
        key: const Key('ChatMessage'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.repliesTo != null) ...[
            InkWell(
              onTap: () => widget.onRepliedTap?.call(msg.repliesTo!.id),
              child: _repliedMessage(msg.repliesTo!),
            ),
            if (msg.text != null) const SizedBox(height: 5),
          ],
          if (msg.text != null) Text(msg.text!.val),
          if (msg.text != null && msg.attachments.isNotEmpty)
            const SizedBox(height: 5),
          if (media.isNotEmpty)
            Column(
              crossAxisAlignment: msg.authorId == widget.me
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: media
                  .mapIndexed((i, e) => _mediaAttachment(i, e, media))
                  .toList(),
            ),
          if (media.isNotEmpty && files.isNotEmpty) const SizedBox(height: 6),
          ...files.map(_fileAttachment),
        ],
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
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 13),
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
      Row(mainAxisSize: MainAxisSize.min, children: subtitle),
    );
  }

  /// Renders the provided [item] as a replied message.
  Widget _repliedMessage(ChatItem item) {
    Style style = Theme.of(context).extension<Style>()!;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessage) {
      var desc = StringBuffer();

      if (item.text != null) {
        desc.write(item.text!.val);
      }

      if (item.attachments.isNotEmpty) {
        additional = item.attachments.map((a) {
          ImageAttachment? image = a is ImageAttachment ? a : null;
          return Container(
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE7E7E7),
              borderRadius: BorderRadius.circular(8),
              image: image == null
                  ? null
                  : DecorationImage(
                      image: NetworkImage('${Config.url}/files${image.medium}'),
                      fit: BoxFit.cover,
                    ),
            ),
            width: 50,
            height: 50,
            child: image == null ? const Icon(Icons.file_copy, size: 16) : null,
          );
        }).toList();
      }

      if (desc.isNotEmpty) {
        content = Text(
          desc.toString(),
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
      // TODO: Implement `ChatForward`.
      content = Text('label_forwarded_message'.l10n, style: style.boldBody);
    } else {
      content = Text('err_unknown'.l10n, style: style.boldBody);
    }

    return FutureBuilder<RxUser?>(
      key: Key('FutureBuilder_${item.id}'),
      future: widget.getUser?.call(item.authorId),
      builder: (context, snapshot) {
        Color color = snapshot.data?.user.value.id == widget.me
            ? const Color(0xFF63B4FF)
            : AvatarWidget.colors[
                (snapshot.data?.user.value.num.val.sum() ?? 3) %
                    AvatarWidget.colors.length];

        return Row(
          key: Key('Row_${item.id}'),
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
                    if (snapshot.data?.user.value != null)
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
                      )
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

  /// Returns visual representation of the provided media-[Attachment].
  Widget _mediaAttachment(int i, Attachment e, List<Attachment> media) {
    bool isLocal = e is LocalAttachment;

    bool isVideo;
    if (isLocal) {
      isVideo = e.file.isVideo;
    } else {
      isVideo = e is FileAttachment;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: isLocal
            ? null
            : () {
                List<Attachment> attachments =
                    widget.onGallery?.call() ?? media;

                int initial = attachments.indexOf(e);
                if (initial == -1) {
                  initial = 0;
                }

                List<GalleryItem> gallery = [];
                for (var o in attachments) {
                  var link = '${Config.url}/files${o.original}';
                  if (o is FileAttachment) {
                    gallery.add(GalleryItem.video(link, o.filename));
                  } else if (o is ImageAttachment) {
                    gallery.add(GalleryItem.image(link, o.filename));
                  }
                }

                GalleryPopup.show(
                  context: context,
                  gallery: GalleryPopup(
                    children: gallery,
                    initial: initial,
                    initialKey: _galleryKeys[i],
                  ),
                );
              },
        child: Stack(
          alignment: Alignment.center,
          children: [
            isVideo
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      isLocal
                          ? e.file.bytes == null
                              ? const CircularProgressIndicator()
                              : VideoThumbnail.bytes(
                                  key: _galleryKeys[i],
                                  bytes: e.file.bytes!,
                                  height: 300,
                                )
                          : VideoThumbnail.path(
                              key: _galleryKeys[i],
                              path: '${Config.url}/files${e.original}',
                              height: 300,
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
                            key: _galleryKeys[i],
                            fit: BoxFit.cover,
                            height: 300,
                          )
                    : Container(
                        key: const Key('SentImage'),
                        child: Image.network(
                          '${Config.url}/files${e.original}',
                          key: _galleryKeys[i],
                          fit: BoxFit.cover,
                          height: 300,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 300.0,
                            height: 300.0,
                            child: Center(
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                          ),
                        ),
                      ),
            ElasticAnimatedSwitcher(
              key: Key('AttachmentStatus_${e.id}'),
              child:
                  !isLocal || (isLocal && e.status.value == SendingStatus.sent)
                      ? Container(key: const Key('Sent'))
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
  Widget _fileAttachment(Attachment e) {
    bool isFile = e is FileAttachment;
    Widget leading;

    if (isFile) {
      switch (e.downloadStatus.value) {
        case DownloadStatus.inProgress:
          leading = InkWell(
            onTap: () => widget.onFileTap?.call(e),
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    key: const Key('Downloading'),
                    value: e.progress.value,
                  ),
                ),
                const Icon(
                  Icons.clear,
                  key: Key('CancelDownloading'),
                  size: 20,
                ),
              ],
            ),
          );
          break;

        case DownloadStatus.isFinished:
          leading = const Icon(
            Icons.attach_file,
            key: Key('Downloaded'),
            size: 18,
            color: Colors.blue,
          );
          break;

        case DownloadStatus.notStarted:
          leading = const Icon(
            Icons.download,
            key: Key('Download'),
            size: 18,
            color: Colors.blue,
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
    } else {
      leading = Container();
    }

    return Padding(
      key: Key('File_${e.id}'),
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
      child: InkWell(
        onTap: isFile
            ? e.isDownloading
                ? null
                : () => widget.onFileTap?.call(e)
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              key: Key('AttachmentStatus_${e.id}'),
              padding: const EdgeInsets.fromLTRB(5, 2, 10, 0),
              child: ElasticAnimatedSwitcher(child: leading),
            ),
            Flexible(
              child: Text(
                e.filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                '${e.size ~/ 1024} KB',
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 13,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns rounded rectangle of a [child] representing a message box.
  Widget _rounded(BuildContext context, Widget child) {
    ChatItem item = widget.item.value;
    bool fromMe = item.authorId == widget.me;

    String? copyable;
    if (item is ChatMessage) {
      copyable = item.text?.val;
    }

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
        crossAxisAlignment:
            fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisAlignment:
            fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (fromMe)
            Padding(
              key: Key('MessageStatus_${item.id}'),
              padding: const EdgeInsets.only(bottom: 16),
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
              padding: const EdgeInsets.only(top: 9),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => router.user(item.authorId, push: true),
                child: AvatarWidget.fromUser(
                  widget.user?.user.value ??
                      widget.chat.value!.getUser(item.authorId),
                  radius: 15,
                ),
              ),
            ),
          Flexible(
            key: Key('Message_${item.id}'),
            child: LayoutBuilder(builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: min(
                    550,
                    constraints.maxWidth * 0.84 +
                        (fromMe ? SwipeableStatus.width : 0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: isRead
                        ? 1
                        : fromMe
                            ? 0.65
                            : 0.8,
                    child: Material(
                      elevation: 6,
                      shadowColor: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(15),
                      child: ContextMenuRegion(
                        preventContextMenu: false,
                        alignment: fromMe
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
                          if (item.status.value == SendingStatus.sent) ...[
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
                            if (item is ChatMessage || item is ChatForward)
                              ContextMenuButton(
                                key: const Key('ForwardButton'),
                                label: 'btn_forward'.l10n,
                                leading: SvgLoader.asset(
                                  'assets/icons/forward.svg',
                                  width: 18.8,
                                  height: 16,
                                ),
                                onPressed: () async {
                                  List<AttachmentId> attachments = [];
                                  if (item is ChatMessage) {
                                    attachments = item.attachments
                                        .map((a) => a.id)
                                        .toList();
                                  } else if (item is ChatForward) {
                                    ChatItem nested = item.item;
                                    if (nested is ChatMessage) {
                                      attachments = nested.attachments
                                          .map((a) => a.id)
                                          .toList();
                                    }
                                  }

                                  await ChatForwardView.show(
                                    context,
                                    widget.chat.value!.id,
                                    [
                                      ChatItemQuote(
                                        item: item,
                                        attachments: attachments,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            if (widget.item.value is ChatMessage &&
                                fromMe &&
                                (widget.item.value.at
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
                                onPressed: () => widget.onEdit?.call(),
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
                                await ModalPopup.show(
                                  context: context,
                                  child: _buildDelete(item),
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
                              onPressed: () => widget.onResend?.call(),
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
                                await ModalPopup.show(
                                  context: context,
                                  child: _buildDelete(item),
                                );
                              },
                            ),
                          ],
                        ],
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: fromMe
                                ? const Color(0xFFDCE9FD)
                                : const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: DefaultTextStyle.merge(
                            style: const TextStyle(fontSize: 16),
                            child: child,
                          ),
                        ),
                      ),
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
      final ChatItem item = msg.item;
      if (item is ChatMessage) {
        _galleryKeys = item.attachments
            .where((e) =>
                e is ImageAttachment ||
                (e is FileAttachment && e.isVideo) ||
                (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
            .map((e) => GlobalKey())
            .toList();
      }
    }
  }

  /// Returns deletion confirmation modal.
  Widget _buildDelete(ChatItem item) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    bool deletable = widget.item.value.authorId == widget.me &&
        !widget.chat.value!.isRead(widget.item.value, widget.me) &&
        (widget.item.value is ChatMessage || widget.item.value is ChatForward);

    return StatefulBuilder(builder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Text(
              'label_delete_message'.l10n,
              style: thin?.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(height: 25),
          if (deletable) ...[
            _button(
              key: const Key('HideForMe'),
              context,
              text: 'label_delete_for_me'.l10n,
              deleteOption: DeleteOption.me,
              setState: setState,
            ),
            const SizedBox(height: 10),
            _button(
              key: const Key('DeleteForAll'),
              context,
              text: 'label_delete_for_everyone'.l10n,
              deleteOption: DeleteOption.everyone,
              setState: setState,
            ),
          ] else
            Center(
              child: Text(
                'label_message_will_deleted_for_you'.l10n,
                style: thin?.copyWith(fontSize: 18),
              ),
            ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: OutlinedRoundedButton(
                  key: const Key('Proceed'),
                  maxWidth: null,
                  title: Text(
                    'btn_proceed'.l10n,
                    style: thin?.copyWith(color: Colors.white),
                  ),
                  onPressed: () {
                    switch (_deleteOption) {
                      case DeleteOption.me:
                        widget.onHide?.call();
                        break;

                      case DeleteOption.everyone:
                        widget.onDelete?.call();
                        break;

                      default:
                        break;
                    }

                    Navigator.of(context).pop();
                  },
                  color: const Color(0xFF63B4FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedRoundedButton(
                  maxWidth: null,
                  title: Text('btn_cancel'.l10n, style: thin),
                  onPressed: () => Navigator.of(context).pop(true),
                  color: const Color(0xFFEEEEEE),
                ),
              )
            ],
          ),
          const SizedBox(height: 25),
        ],
      );
    });
  }

  /// Returns radio button represented the provided [DeleteOption].
  Widget _button(
    BuildContext context, {
    Key? key,
    required String text,
    DeleteOption deleteOption = DeleteOption.everyone,
    required StateSetter setState,
  }) {
    ThemeData theme = Theme.of(context);
    Style style = theme.extension<Style>()!;
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    return Material(
      key: key,
      type: MaterialType.card,
      borderRadius: style.cardRadius,
      child: InkWell(
        onTap: () => setState(() => _deleteOption = deleteOption),
        borderRadius: style.cardRadius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(text, style: thin?.copyWith(fontSize: 18)),
              ),
              IgnorePointer(
                child: Radio<DeleteOption>(
                  value: deleteOption,
                  groupValue: _deleteOption,
                  onChanged: (DeleteOption? value) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Delete option of an [ChatItem] deletion.
enum DeleteOption {
  /// Delete only for me.
  me,

  /// Delete for all chat-members.
  everyone,
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
