import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/chat_item_quote.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/sending_status.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/widget/fit_view.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';
import 'package:messenger/ui/page/home/page/chat/forward/view.dart';
import 'package:messenger/ui/page/home/page/chat/widget/swipeable_status.dart';
import 'package:messenger/ui/page/home/page/chat/widget/video_thumbnail/video_thumbnail.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/gallery_popup.dart';
import 'package:messenger/ui/widget/animated_delayed_switcher.dart';
import 'package:messenger/ui/widget/animations.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

class PostWidget extends StatefulWidget {
  const PostWidget({
    Key? key,
    required this.item,
    this.onDelete,
    this.onFileTap,
    this.onGallery,
    this.onResend,
    this.onReply,
    this.onCopy,
    this.onEdit,
    this.getUser,
    this.me,
  }) : super(key: key);

  /// Reactive value of a [ChatItem] to display.
  final Rx<ChatItem> item;

  /// Callback, called when a delete action of this post is triggered.
  final Function()? onDelete;

  /// Callback, called when a [FileAttachment] of this [ChatItem] is tapped.
  final Function(FileAttachment)? onFileTap;

  /// Callback, called when a gallery list is required.
  ///
  /// If not specified, then only media in this [item] will be in a gallery.
  final List<Attachment> Function()? onGallery;

  /// Callback, called when a reply action of this [ChatItem] is triggered.
  final Function()? onReply;

  /// Callback, called when an edit action of this [ChatItem] is triggered.
  final Function()? onEdit;

  /// Callback, called when a copy action of this [ChatItem] is triggered.
  final Function(String text)? onCopy;

  /// Callback, called when a resend action of this [ChatItem] is triggered.
  final Function()? onResend;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  final UserId? me;

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  /// [GlobalKey]s of [Attachment]s used to animate a [GalleryPopup] from/to
  /// corresponding [Widget].
  List<GlobalKey> _galleryKeys = [];

  @override
  void initState() {
    _populateGlobalKeys(widget.item.value);
    super.initState();
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
          return _renderAsChatForward(context);
        } else {
          return Container();
        }
      }),
    );
  }

  /// Renders [widget.item] as [ChatMessage].
  Widget _renderAsChatMessage(BuildContext context) {
    var msg = widget.item.value as ChatMessage;

    String? text = msg.text?.val.replaceAll(' ', '');
    if (text?.isEmpty == true) {
      text = null;
    } else {
      text = msg.text?.val;
    }

    Style style = Theme.of(context).extension<Style>()!;

    List<Attachment> media = msg.attachments.where((e) {
      return ((e is ImageAttachment) ||
          (e is FileAttachment && e.isVideo) ||
          (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
    }).toList();

    List<Attachment> files = msg.attachments.where((e) {
      return ((e is FileAttachment && !e.isVideo) ||
          (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
    }).toList();

    return _rounded(
      context,
      Container(
        padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
        child: IntrinsicWidth(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: style.secondaryBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (text != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      10,
                      9,
                      files.isEmpty ? 10 : 0,
                    ),
                    child: SelectableText(
                      text,
                      style: style.boldBody,
                    ),
                  ),
                if (files.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    child: Column(
                      children: files.map(_fileAttachment).toList(),
                    ),
                  ),
                if (media.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: text != null
                          ? Radius.zero
                          : files.isEmpty
                              ? const Radius.circular(15)
                              : Radius.zero,
                      topRight: text != null
                          ? Radius.zero
                          : files.isEmpty
                              ? const Radius.circular(15)
                              : Radius.zero,
                      bottomLeft: const Radius.circular(15),
                      bottomRight: const Radius.circular(15),
                    ),
                    child: media.length == 1
                        ? _mediaAttachment(
                            0,
                            media.first,
                            media,
                            filled: false,
                          )
                        : SizedBox(
                            width: media.length * 250,
                            height: max(media.length * 60, 300),
                            child: FitView(
                              dividerColor: Colors.transparent,
                              children: media
                                  .mapIndexed(
                                      (i, e) => _mediaAttachment(i, e, media))
                                  .toList(),
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

  Widget _renderAsChatForward(BuildContext context) {
    ChatForward msg = widget.item.value as ChatForward;
    ChatItem item = msg.item;

    Style style = Theme.of(context).extension<Style>()!;

    return DefaultTextStyle(
      style: style.boldBody,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(),
              child: Padding(
                padding: EdgeInsets.zero,
                child: Material(
                  borderRadius: BorderRadius.circular(15),
                  type: MaterialType.transparency,
                  child: ContextMenuRegion(
                    preventContextMenu: false,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    menu: Container(),
                    alignment: Alignment.bottomLeft,
                    actions: [
                      ContextMenuButton(
                        key: const Key('ReplyButton'),
                        label: 'Reply'.l10n,
                        leading: SvgLoader.asset(
                          'assets/icons/reply.svg',
                          width: 18.8,
                          height: 16,
                        ),
                        onPressed: () => widget.onReply?.call(),
                      ),
                      ContextMenuButton(
                        key: const Key('ForwardButton'),
                        label: 'Forward'.l10n,
                        leading: SvgLoader.asset(
                          'assets/icons/forward.svg',
                          width: 18.8,
                          height: 16,
                        ),
                        onPressed: () async {},
                      ),
                      ContextMenuButton(
                        label: 'Delete'.l10n,
                        leading: SvgLoader.asset(
                          'assets/icons/delete_small.svg',
                          width: 17.75,
                          height: 17,
                        ),
                        onPressed: () async {},
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
                      child: ClipRRect(
                        clipBehavior: Clip.none,
                        borderRadius: BorderRadius.circular(15),
                        child: IntrinsicWidth(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: style.secondaryBorder,
                            ),
                            child: _forwardedMessage(item),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _forwardedMessage(ChatItem item) {
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
            if (files.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: Column(
                  children: files.map(_fileAttachment).toList(),
                ),
              ),
            if (media.isNotEmpty)
              ClipRRect(
                child: media.length == 1
                    ? _mediaAttachment(
                        0,
                        media.first,
                        media,
                        filled: false,
                      )
                    : SizedBox(
                        width: media.length * 120,
                        height: max(media.length * 60, 300),
                        child: FitView(
                          dividerColor: Colors.transparent,
                          children: media
                              .mapIndexed(
                                  (i, e) => _mediaAttachment(i, e, media))
                              .toList(),
                        ),
                      ),
              ),
          ];
        }
      }

      if (desc.isNotEmpty) {
        content = Text(
          desc.toString(),
          style: style.boldBody,
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: WidgetButton(
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
                            // const SizedBox(width: 6),
                            Transform.scale(
                              scaleX: -1,
                              child: Icon(Icons.reply, size: 17, color: color),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                snapshot.data?.user.value.name?.val ??
                                    snapshot.data?.user.value.num.val ??
                                    '...',
                                style: style.boldBody.copyWith(color: color),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  /// Returns rounded rectangle of a [child] representing a message box.
  Widget _rounded(BuildContext context, Widget child) {
    ChatItem item = widget.item.value;

    String? copyable;
    if (widget.item.value is ChatMessage) {
      copyable = (widget.item.value as ChatMessage).text?.val;
    }

    bool isSent = widget.item.value.status.value == SendingStatus.sent;

    return SwipeableStatus(
      asStack: true,
      isSent: isSent,
      isDelivered: true,
      isRead: isSent && false,
      isError: item.status.value == SendingStatus.error,
      isSending: item.status.value == SendingStatus.sending,
      swipeable:
          Text(DateFormat.Hm().format(widget.item.value.at.val.toLocal())),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
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
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.error_outline,
                            size: 15,
                            color: Colors.red,
                          ),
                        )
                      : Container(),
            ),
          ),
          Flexible(
            child: LayoutBuilder(builder: (context, constraints) {
              return ConstrainedBox(
                constraints: const BoxConstraints(
                    // maxWidth: min(550, constraints.maxWidth * 0.84 + -10),
                    ),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Material(
                    key: Key('Message_${widget.item.value.id}'),
                    type: MaterialType.transparency,
                    child: ContextMenuRegion(
                      preventContextMenu: false,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      menu: Container(),
                      alignment: Alignment.bottomLeft,
                      id: widget.item.value.id.val,
                      actions: [
                        if (widget.item.value is ChatMessage &&
                            (widget.item.value as ChatMessage)
                                .attachments
                                .isNotEmpty) ...[
                          ContextMenuButton(
                            label: 'Download all'.l10n,
                            leading: SvgLoader.asset(
                              'assets/icons/copy_small.svg',
                              width: 14.82,
                              height: 17,
                            ),
                            onPressed: () {},
                          ),
                          ContextMenuButton(
                            label: 'Download all as'.l10n,
                            leading: SvgLoader.asset(
                              'assets/icons/copy_small.svg',
                              width: 14.82,
                              height: 17,
                            ),
                            onPressed: () {},
                          ),
                        ],
                        if (copyable != null)
                          ContextMenuButton(
                            key: const Key('CopyButton'),
                            label: 'Copy'.l10n,
                            leading: SvgLoader.asset(
                              'assets/icons/copy_small.svg',
                              width: 14.82,
                              height: 17,
                            ),
                            onPressed: () {
                              widget.onCopy?.call(copyable!);
                            },
                          ),
                        if (item.status.value == SendingStatus.sent) ...[
                          ContextMenuButton(
                            key: const Key('ReplyButton'),
                            label: 'Reply'.l10n,
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
                              label: 'Forward'.l10n,
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

                                // await ChatForwardView.show(
                                //   context,
                                //   widget.chat.value!.id,
                                //   [
                                //     ChatItemQuote(
                                //       item: item,
                                //       attachments: attachments,
                                //     ),
                                //   ],
                                // );
                              },
                            ),
                          if (widget.item.value is ChatMessage)
                            ContextMenuButton(
                              key: const Key('EditButton'),
                              label: 'Edit'.l10n,
                              leading: SvgLoader.asset(
                                'assets/icons/edit.svg',
                                width: 17,
                                height: 17,
                              ),
                              onPressed: () => widget.onEdit?.call(),
                            ),
                          ContextMenuButton(
                            // key: const Key('HideForMe'),
                            // key: _deleteKey,
                            label: 'Delete'.l10n,
                            leading: SvgLoader.asset(
                              'assets/icons/delete_small.svg',
                              width: 17.75,
                              height: 17,
                            ),
                            onPressed: () async {
                              widget.onDelete?.call();
                              // await ModalPopup.show(
                              //   context: context,
                              //   child: _buildDelete2(item),
                              // );
                            },
                          ),
                        ],
                        if (item.status.value == SendingStatus.error) ...[
                          ContextMenuButton(
                            key: const Key('Resend'),
                            label: 'Resend'.l10n,
                            // leading: const Icon(Icons.send),
                            leading: SvgLoader.asset(
                              'assets/icons/send_small.svg',
                              width: 18.37,
                              height: 16,
                            ),
                            onPressed: () => widget.onResend?.call(),
                          ),
                          ContextMenuButton(
                            key: const Key('Delete'),
                            label: 'Delete'.l10n,
                            leading: SvgLoader.asset(
                              'assets/icons/delete_small.svg',
                              width: 17.75,
                              height: 17,
                            ),
                            onPressed: () async {
                              // await ModalPopup.show(
                              //   context: context,
                              //   child: _buildDelete2(item),
                              // );
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

  Widget _fileAttachment(Attachment e) {
    Widget leading = Container();
    if (e is FileAttachment) {
      switch (e.downloadStatus.value) {
        case DownloadStatus.downloading:
          leading = InkWell(
            onTap: () => widget.onFileTap?.call(e),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgLoader.asset(
                  'assets/icons/download_cancel.svg',
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

        case DownloadStatus.downloaded:
          leading = const Icon(
            Icons.file_copy,
            key: Key('Downloaded'),
            color: Color(0xFF63B4FF),
            size: 28,
          );
          break;

        case DownloadStatus.notDownloaded:
          leading = SvgLoader.asset(
            'assets/icons/download.svg',
            width: 28,
            height: 28,
          );
          break;
      }
    }

    leading = KeyedSubtree(key: const Key('Sent'), child: leading);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: WidgetButton(
        onPressed: e is FileAttachment
            ? e.isDownloading
                ? null
                : () => widget.onFileTap?.call(e)
            : null,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black.withOpacity(0.03),
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
                    // TODO: Must be cut WITH extension visible!!!!!!
                    Text(
                      e.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${e.size ~/ 1024} KB',
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

  Widget _mediaAttachment(
    int i,
    Attachment e,
    List<Attachment> media, {
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
                          key: _galleryKeys[i],
                          height: 300,
                        )
                  : VideoThumbnail.path(
                      path: '${Config.url}/files${e.original}',
                      key: _galleryKeys[i],
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
            : Image.network(
                '${Config.url}/files${(e as ImageAttachment).big}',
                key: _galleryKeys[i],
                fit: BoxFit.cover,
                height: 300,
              );

    return Padding(
      padding: EdgeInsets.zero,
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
            filled ? Positioned.fill(child: attachment) : attachment,
            if (isLocal)
              ElasticAnimatedSwitcher(
                child: e.status.value == SendingStatus.sent
                    ? const Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.green,
                      )
                    : e.status.value == SendingStatus.sending
                        ? CircularProgressIndicator(
                            value: e.progress.value,
                            backgroundColor: Colors.white,
                            strokeWidth: 10,
                          )
                        : const Icon(
                            Icons.error,
                            size: 48,
                            color: Colors.red,
                          ),
              )
          ],
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
}
