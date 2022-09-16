import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/api/backend/schema.dart' show ChatCallFinishReason;
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_call.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/chat_item_quote.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/sending_status.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/widget/fit_view.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';
import 'package:messenger/ui/page/home/page/chat/forward/view.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/gallery_popup.dart';
import 'package:messenger/ui/widget/animations.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import 'animated_transform.dart';
import 'swipeable_status.dart';
import 'video_thumbnail/video_thumbnail.dart';

class ChatForwardWidget extends StatefulWidget {
  const ChatForwardWidget({
    Key? key,
    required this.id,
    required this.chat,
    required this.forwards,
    required this.note,
    required this.authorId,
    required this.me,
    this.user,
    this.getUser,
    this.animation,
    this.onReply,
    this.onGallery,
    this.onRepliedTap,
    this.onDrag,
    this.onForwardedTap,
  }) : super(key: key);

  /// Reactive value of a [Chat] this [item] is posted in.
  final Rx<Chat?> chat;

  final RxList<Rx<ChatItem>> forwards;
  final Rx<Rx<ChatItem>?> note;

  final String id;
  final UserId authorId;
  final UserId me;

  /// Optional animation that controls a [SwipeableStatus].
  final AnimationController? animation;

  /// [User] posted this [item].
  final RxUser? user;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  /// Callback, called when a reply action of this [ChatItem] is triggered.
  final Function()? onReply;

  /// Callback, called when a gallery list is required.
  ///
  /// If not specified, then only media in this [item] will be in a gallery.
  final List<Attachment> Function()? onGallery;

  /// Callback, called when a replied message of this [ChatItem] is tapped.
  final Function(ChatItemId)? onRepliedTap;

  final Function(bool)? onDrag;

  /// Callback, called when a forwarded message of this [ChatItem] is tapped.
  final Function(ChatItemId, ChatId)? onForwardedTap;

  @override
  State<ChatForwardWidget> createState() => _ChatForwardWidgetState();
}

class _ChatForwardWidgetState extends State<ChatForwardWidget> {
  /// [GlobalKey]s of [Attachment]s used to animate a [GalleryPopup] from/to
  /// corresponding [Widget].
  List<GlobalKey> _galleryKeys = [];
  List<GlobalKey> _noteKeys = [];

  final GlobalKey _deleteKey = GlobalKey();

  @override
  void initState() {
    _populateGlobalKeys();
    super.initState();
  }

  Offset _offset = Offset.zero;
  Duration _offsetDuration = Duration.zero;
  bool _dragging = false;
  bool _draggingStarted = false;
  bool _draggingFeedback = false;

  @override
  Widget build(BuildContext context) {
    Style style = Theme.of(context).extension<Style>()!;

    bool fromMe = widget.authorId == widget.me;
    bool isRead = _isRead(widget.forwards.first.value);

    Color color = widget.user?.user.value.id == widget.me
        ? const Color(0xFF63B4FF)
        : AvatarWidget.colors[(widget.user?.user.value.num.val.sum() ?? 3) %
            AvatarWidget.colors.length];

    bool isSent =
        widget.forwards.first.value.status.value == SendingStatus.sent;

    double avatarOffset = 0;

    return DefaultTextStyle(
      style: style.boldBody,
      child: SwipeableStatus(
        animation: widget.animation,
        asStack: !fromMe,
        isSent: isSent && fromMe,
        isDelivered: isSent &&
            fromMe &&
            widget.chat.value?.lastDelivery
                    .isBefore(widget.forwards.first.value.at) ==
                false,
        isRead: isSent && (!fromMe || isRead),
        isError:
            widget.forwards.first.value.status.value == SendingStatus.error,
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
              if (_draggingStarted) {
                if (widget.animation?.value == 0 &&
                    _offset.dx == 0 &&
                    d.delta.dx > 0) {
                  _dragging = true;
                  widget.onDrag?.call(_dragging);
                }
                _draggingStarted = false;
              }

              if (_dragging) {
                _offset += d.delta;
                if (_offset.dx > 30) {
                  if (!_draggingFeedback) {
                    _draggingFeedback = true;
                    HapticFeedback.selectionClick();
                    widget.onReply?.call();
                  }
                } else {
                  _draggingFeedback = false;
                }

                setState(() {});
              }
            },
            onHorizontalDragEnd: _dragging
                ? (d) {
                    if (_offset.dx > 30) {
                      // widget.onReply?.call();
                    }

                    _dragging = false;
                    _draggingFeedback = false;
                    _offset = Offset.zero;
                    _offsetDuration = 200.milliseconds;
                    widget.onDrag?.call(_dragging);
                    setState(() {});
                  }
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:
                  fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!fromMe && widget.chat.value!.isGroup)
                  const SizedBox(width: 30),
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
                          key: Key('Message_${widget.id}'),
                          type: MaterialType.transparency,
                          child: ContextMenuRegion(
                            preventContextMenu: false,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            menu: Container(),
                            alignment: fromMe
                                ? Alignment.bottomRight
                                : Alignment.bottomLeft,
                            id: widget.id,
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
                                onPressed: () async {
                                  final List<ChatItemQuote> quotes = [];

                                  for (Rx<ChatItem> item in widget.forwards) {
                                    List<AttachmentId> attachments = [];
                                    if (item.value is ChatForward) {
                                      ChatItem nested =
                                          (item.value as ChatForward).item;
                                      if (nested is ChatMessage) {
                                        attachments = nested.attachments
                                            .map((a) => a.id)
                                            .toList();
                                      }
                                    }

                                    quotes.add(ChatItemQuote(
                                      item: item.value,
                                      attachments: attachments,
                                    ));
                                  }

                                  if (widget.note.value != null) {
                                    List<AttachmentId> attachments = [];
                                    ChatItem item = widget.note.value!.value;
                                    if (item is ChatMessage) {
                                      attachments = item.attachments
                                          .map((a) => a.id)
                                          .toList();
                                    }

                                    quotes.add(ChatItemQuote(
                                      item: item,
                                      attachments: attachments,
                                    ));
                                  }

                                  await ChatForwardView.show(
                                    context,
                                    widget.chat.value!.id,
                                    quotes,
                                  );
                                },
                              ),
                              ContextMenuButton(
                                // key: _deleteKey,
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
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
                              child: ClipRRect(
                                clipBehavior:
                                    fromMe ? Clip.antiAlias : Clip.none,
                                borderRadius: BorderRadius.circular(15),
                                child: IntrinsicWidth(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    decoration: BoxDecoration(
                                      color: fromMe
                                          ? isRead
                                              ? const Color.fromRGBO(
                                                  210,
                                                  227,
                                                  249,
                                                  1,
                                                )
                                              : const Color.fromARGB(
                                                  255,
                                                  244,
                                                  249,
                                                  255,
                                                )
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      border: fromMe
                                          ? isRead
                                              ? style.primaryBorder
                                              : Border.all(
                                                  color:
                                                      const Color(0xFFDAEDFF),
                                                  width: 0.5,
                                                )
                                          : style.secondaryBorder,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ...widget.forwards.mapIndexed(
                                          (i, e) => ClipRRect(
                                            clipBehavior: i == 0
                                                ? Clip.antiAlias
                                                : Clip.none,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(15),
                                              topRight: Radius.circular(15),
                                            ),
                                            child: _forwardedMessage(e),
                                          ),
                                        ),
                                        if (widget.note.value == null &&
                                            !fromMe &&
                                            widget.chat.value?.isGroup == true)
                                          Transform.translate(
                                            offset: const Offset(-36, 0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Transform.translate(
                                                  offset: const Offset(0, -2),
                                                  child: InkWell(
                                                    customBorder:
                                                        const CircleBorder(),
                                                    onTap: () => router.user(
                                                        widget.authorId,
                                                        push: true),
                                                    child:
                                                        AvatarWidget.fromRxUser(
                                                      widget.user,
                                                      radius: 15,
                                                      useLayoutBuilder: false,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                    12 + 6,
                                                    4,
                                                    9,
                                                    4,
                                                  ),
                                                  child: Text(
                                                    widget.user?.user.value.name
                                                            ?.val ??
                                                        widget.user?.user.value
                                                            .num.val ??
                                                        '...',
                                                    style: style.boldBody
                                                        .copyWith(color: color),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (widget.note.value != null)
                                          ..._note(),
                                      ],
                                    ),
                                  ),
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
          ),
        ),
      ),
    );
  }

  /// Renders [widget.item] as [ChatForward].
  Widget _forwardedMessage(Rx<ChatItem> forward) {
    ChatForward msg = forward.value as ChatForward;
    ChatItem item = msg.item;

    Style style = Theme.of(context).extension<Style>()!;

    bool fromMe = widget.authorId == widget.me;
    bool isRead = _isRead(item);

    Widget? content;
    List<Widget> additional = [];

    bool isFirst = widget.forwards.indexOf(forward) == 0;

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
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: isRead
                    ? 1
                    : fromMe
                        ? 0.55
                        : 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                  child: Column(
                    children:
                        files.map((e) => _buildFileAttachment(e)).toList(),
                  ),
                ),
              ),
            if (media.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.zero,
                  topRight: Radius.zero,
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: isRead
                      ? 1
                      : fromMe
                          ? 0.55
                          : 1,
                  child: media.length == 1
                      ? _buildMediaAttachment(
                          0,
                          media.first,
                          media,
                          _galleryKeys[0],
                          filled: false,
                        )
                      : SizedBox(
                          width: media.length * 120,
                          height: max(media.length * 60, 300),
                          child: FitView(
                            dividerColor: Colors.transparent,
                            children: media
                                .mapIndexed(
                                  (i, e) => _buildMediaAttachment(
                                    i,
                                    e,
                                    media,
                                    _galleryKeys[i],
                                  ),
                                )
                                .toList(),
                          ),
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
            ? isRead
                ? const Color.fromRGBO(219, 234, 253, 1)
                : const Color.fromRGBO(230, 241, 254, 1)
            : isRead
                ? const Color.fromRGBO(249, 249, 249, 1)
                : const Color.fromRGBO(255, 255, 255, 1),
        // borderRadius: BorderRadius.only(
        //   topLeft: const Radius.circular(15),
        //   topRight: const Radius.circular(15),
        //   bottomLeft: !fromMe && widget.chat.value?.isGroup == true
        //       ? Radius.zero
        //       : const Radius.circular(15),
        //   bottomRight: !fromMe && widget.chat.value?.isGroup == true
        //       ? Radius.zero
        //       : const Radius.circular(15),
        // ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: isRead
            ? 1
            : fromMe
                ? 0.55
                : 1,
        child: WidgetButton(
          onPressed: () => widget.onForwardedTap?.call(item.id, item.chatId),
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
                          if (snapshot.data?.user.value != null)
                            Row(
                              children: [
                                // const SizedBox(width: 6),
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
  }

  List<Widget> _note() {
    Rx<ChatItem> e = widget.note.value!;
    ChatItem item = e.value;

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
        if (item.repliesTo != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              color: (item.repliesTo!.authorId == widget.me)
                  ? isRead
                      ? const Color.fromRGBO(219, 234, 253, 1)
                      : const Color.fromRGBO(230, 241, 254, 1)
                  : isRead
                      ? const Color.fromRGBO(249, 249, 249, 1)
                      : const Color.fromRGBO(255, 255, 255, 1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: isRead
                    ? 1
                    : fromMe
                        ? 0.55
                        : 1,
                child: WidgetButton(
                  onPressed: () =>
                      widget.onRepliedTap?.call(item.repliesTo!.id),
                  child: _repliedMessage(item.repliesTo!),
                ),
              ),
            ),
          ),
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
            opacity: isRead
                ? 1
                : fromMe
                    ? 0.55
                    : 1,
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
            opacity: isRead
                ? 1
                : fromMe
                    ? 0.55
                    : 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
              child: Column(
                children: files.map((e) => _buildFileAttachment(e)).toList(),
              ),
            ),
          ),
        if (attachments.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: item.text != null ||
                      item.repliesTo != null ||
                      (!fromMe && widget.chat.value?.isGroup == true)
                  ? Radius.zero
                  : files.isEmpty
                      ? const Radius.circular(15)
                      : Radius.zero,
              topRight: item.text != null ||
                      item.repliesTo != null ||
                      (!fromMe && widget.chat.value?.isGroup == true)
                  ? Radius.zero
                  : files.isEmpty
                      ? const Radius.circular(15)
                      : Radius.zero,
              bottomLeft: const Radius.circular(15),
              bottomRight: const Radius.circular(15),
              // bottomLeft: files.isEmpty
              //     ? const Radius.circular(15)
              //     : Radius.zero,
              // bottomRight: files.isEmpty
              //     ? const Radius.circular(15)
              //     : Radius.zero,
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isRead
                  ? 1
                  : fromMe
                      ? 0.55
                      : 1,
              child: attachments.length == 1
                  ? _buildMediaAttachment(
                      0,
                      attachments.first,
                      attachments,
                      _noteKeys[0],
                      filled: false,
                    )
                  : SizedBox(
                      width: attachments.length * 120,
                      height: max(attachments.length * 60, 300),
                      child: FitView(
                        dividerColor: Colors.transparent,
                        children: attachments
                            .mapIndexed(
                              (i, e) => _buildMediaAttachment(
                                i,
                                e,
                                attachments,
                                _noteKeys[i],
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

  Widget _buildFileAttachment(Attachment e) {
    bool fromMe = widget.authorId == widget.me;
    Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: WidgetButton(
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
              const SizedBox(width: 10),
              Icon(
                Icons.file_copy,
                color: fromMe ? Colors.white : const Color(0xFFDDDDDD),
                size: 28,
              ),
              const SizedBox(width: 10),
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
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaAttachment(
    int i,
    Attachment e,
    List<Attachment> media,
    GlobalKey key, {
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
                  : VideoThumbnail.path(
                      path: '${Config.url}/files${e.original}',
                      key: key,
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
                    key: key,
                    fit: BoxFit.cover,
                    height: 300,
                  )
            : Image.network(
                '${Config.url}/files${(e as ImageAttachment).big}',
                key: key,
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

  /// Renders [item] as a replied message.
  Widget _repliedMessage(ChatItem item) {
    Style style = Theme.of(context).extension<Style>()!;
    bool fromMe = item.authorId == widget.me;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessage) {
      var desc = StringBuffer();

      if (item.text != null) {
        desc.write(item.text!.val);
        // if (item.attachments.isNotEmpty) {
        //   desc.write(
        //       ' [${item.attachments.length} ${'label_attachments'.l10n}]');
        // }
      } else if (item.attachments.isNotEmpty) {
        // desc.write('${item.attachments.length} ${'label_attachments'.l10n}]');
      }

      if (item.attachments.isNotEmpty) {
        // TODO: IF MORE THAN 3, WRITE "+201" AS THE LAST ONE
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
                              '${Config.url}/files${image.medium}'),
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

      if (desc.isNotEmpty) {
        content = Text(
          desc.toString(),
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
      content = Text('Forwarded message', style: style.boldBody);
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
                    Builder(
                      builder: (context) {
                        String? name;

                        if (snapshot.data != null) {
                          return Obx(() {
                            return Text(
                              snapshot.data!.user.value.name?.val ??
                                  snapshot.data!.user.value.num.val,
                              style: style.boldBody.copyWith(color: color),
                            );
                          });
                        }

                        return Text(
                          name ?? '...',
                          style: style.boldBody
                              .copyWith(color: const Color(0xFF63B4FF)),
                        );
                      },
                    ),
                    if (content != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle.merge(maxLines: 1, child: content),
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

  /// Populates the [_galleryKeys] from the provided [ChatMessage.attachments].
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
      _noteKeys.clear();
      _noteKeys.addAll(
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
