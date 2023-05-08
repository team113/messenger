// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
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

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_item_quote_input.dart';
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
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'animated_offset.dart';
import 'chat_item.dart';
import 'message_info/view.dart';
import 'selection_text.dart';
import 'swipeable_status.dart';

/// [ChatForward] visual representation.
class ChatForwardWidget extends StatefulWidget {
  const ChatForwardWidget({
    super.key,
    required this.chat,
    required this.forwards,
    required this.note,
    required this.authorId,
    required this.me,
    this.reads = const [],
    this.loadImages = true,
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
    this.onSelecting,
  });

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

  /// [LastChatRead] to display under this [ChatItem].
  final Iterable<LastChatRead> reads;

  /// Indicator whether the [ImageAttachment]s of this [ChatItem] should be
  /// fetched as soon as they are displayed, if any.
  final bool loadImages;

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

  /// Callback, called when a drag of these [forwards] starts or ends.
  final void Function(bool)? onDrag;

  /// Callback, called when a [ChatForward] is tapped.
  final void Function(ChatItemQuote)? onForwardedTap;

  /// Callback, called when a [FileAttachment] of some [ChatItem] is tapped.
  final void Function(ChatItem, FileAttachment)? onFileTap;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function()? onAttachmentError;

  /// Callback, called when a [Text] selection starts or ends.
  final void Function(bool)? onSelecting;

  @override
  State<ChatForwardWidget> createState() => _ChatForwardWidgetState();
}

/// State of a [ChatForwardWidget] maintaining the [_galleryKeys].
class _ChatForwardWidgetState extends State<ChatForwardWidget> {
  /// [GlobalKey]s of [Attachment]s used to animate a [GalleryPopup] from/to
  /// corresponding [Widget].
  final Map<ChatItemId, List<GlobalKey>> _galleryKeys = {};

  /// [Offset] to translate this [ChatForwardWidget] with when swipe to reply
  /// gesture is happening.
  final Offset _offset = Offset.zero;

  /// Total [Offset] applied to this [ChatForwardWidget] by a swipe gesture.
  final Offset _totalOffset = Offset.zero;

  /// [Duration] to animate [_offset] changes with.
  ///
  /// Used to animate [_offset] resetting when swipe to reply gesture ends.
  final Duration _offsetDuration = Duration.zero;

  /// Indicator whether this [ChatForwardWidget] is in an ongoing drag.
  final bool _dragging = false;

  /// Indicator whether [GestureDetector] of this [ChatForwardWidget] recognized
  /// a horizontal drag start.
  ///
  /// This indicator doesn't mean that the started drag will become an ongoing.
  final bool _draggingStarted = false;

  /// [SelectedContent] of a [SelectionText] within this [ChatForwardWidget].
  SelectedContent? _selection;

  /// [TapGestureRecognizer]s for tapping on the [SelectionText.rich] spans, if
  /// any.
  final List<TapGestureRecognizer> _recognizers = [];

  /// [TextSpan]s of the [ChatForwardWidget.forwards] and
  /// [ChatForwardWidget.note] to display as a text of this [ChatForwardWidget].
  final Map<ChatItemId, TextSpan> _text = {};

  /// [Worker]s updating the [_text] on the [ChatForwardWidget.forwards] and
  /// [ChatForwardWidget.note] changes.
  final List<Worker> _workers = [];

  /// Indicates whether these [ChatForwardWidget.forwards] were read by any
  /// [User].
  bool get _isRead {
    final Chat? chat = widget.chat.value;
    if (chat == null) {
      return false;
    }

    if (_fromMe) {
      return chat.isRead(widget.forwards.first.value, widget.me, chat.members);
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
    _populateWorkers();
    super.initState();
  }

  @override
  void dispose() {
    for (var w in _workers) {
      w.dispose();
    }

    for (var r in _recognizers) {
      r.dispose();
    }

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatForwardWidget oldWidget) {
    if (oldWidget.note != widget.note ||
        oldWidget.forwards != widget.forwards) {
      _populateWorkers();
    }

    super.didUpdateWidget(oldWidget);
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
        return RoundedWidget(
          note: widget.note,
          forwards: widget.forwards,
          isRead: _isRead,
          fromMe: _fromMe,
          onFileTap: widget.onFileTap,
          galleryKeys: _galleryKeys,
          onGallery: widget.onGallery,
          onAttachmentError: widget.onAttachmentError,
          loadImages: widget.loadImages,
          me: widget.me,
          onForwardedTap: widget.onForwardedTap,
          getUser: widget.getUser,
          user: widget.user,
          chat: widget.chat,
          animation: widget.animation,
          authorId: widget.authorId,
          dragging: _dragging,
          draggingStarted: _draggingStarted,
          offset: _offset,
          offsetDuration: _offsetDuration,
          totalOffset: _totalOffset,
          onCopy: widget.onCopy,
          onDelete: widget.onDelete,
          onDrag: widget.onDrag,
          onEdit: widget.onEdit,
          onHide: widget.onHide,
          onReply: widget.onReply,
          changeDraggingState: changeDraggingState,
          builder: (menu) => Padding(
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
                        if (widget.note.value != null)
                          NoteWidget(
                            note: widget.note,
                            menu: menu,
                            isRead: _isRead,
                            fromMe: _fromMe,
                            onFileTap: widget.onFileTap,
                            galleryKeys: _galleryKeys,
                            onGallery: widget.onGallery,
                            onAttachmentError: widget.onAttachmentError,
                            loadImages: widget.loadImages,
                            selection: _selection,
                            me: widget.me,
                            onSelecting: widget.onSelecting,
                            onForwardedTap: widget.onForwardedTap,
                            getUser: widget.getUser,
                            user: widget.user,
                            chat: widget.chat,
                            textChat: _text,
                          ),
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
                              child: ForwardedMessage(
                                textChat: _text,
                                forward: e,
                                menu: menu,
                                isRead: _isRead,
                                fromMe: _fromMe,
                                onFileTap: widget.onFileTap,
                                galleryKeys: _galleryKeys,
                                onGallery: widget.onGallery,
                                onAttachmentError: widget.onAttachmentError,
                                loadImages: widget.loadImages,
                                selection: _selection,
                                me: widget.me,
                                onSelecting: widget.onSelecting,
                                onForwardedTap: widget.onForwardedTap,
                                getUser: widget.getUser,
                              )),
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

  void changeDraggingState(
    bool dragging,
    bool draggingStarted,
    Offset offset,
    Duration offsetDuration,
    Offset totalOffset,
  ) {
    if (dragging) {
      dragging = false;
      draggingStarted = false;
      offset = Offset.zero;
      totalOffset = Offset.zero;
      offsetDuration = 200.milliseconds;
      widget.onDrag?.call(dragging);
      setState(() {});
    }
  }

  /// Populates the [_workers] invoking the [_populateSpans] on the
  /// [ChatForwardWidget.forwards] and [ChatForwardWidget.note] changes.
  void _populateWorkers() {
    for (var w in _workers) {
      w.dispose();
    }
    _workers.clear();

    _populateSpans();

    ChatMessageText? text;
    if (widget.note.value?.value is ChatMessage) {
      final msg = widget.note.value?.value as ChatMessage;
      text = msg.text;
    }

    _workers.add(ever(widget.note, (Rx<ChatItem>? item) {
      if (item?.value is ChatMessage) {
        final msg = item?.value as ChatMessage;
        if (text != msg.text) {
          _populateSpans();
          text = msg.text;
        }
      }
    }));

    int length = widget.forwards.length;
    _workers.add(ever(widget.forwards, (List<Rx<ChatItem>> forwards) {
      if (forwards.length != length) {
        _populateSpans();
        length = forwards.length;
      }
    }));
  }

  /// Populates the [_galleryKeys] from the [ChatForwardWidget.forwards] and
  /// [ChatForwardWidget.note].
  void _populateGlobalKeys() {
    _galleryKeys.clear();

    for (Rx<ChatItem> forward in widget.forwards) {
      final ChatItemQuote item = (forward.value as ChatForward).quote;
      if (item is ChatMessageQuote) {
        _galleryKeys[forward.value.id] = item.attachments
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

  /// Populates the [_text] with the [ChatMessage.text] of the
  /// [ChatForwardWidget.forwards] and [ChatForwardWidget.note] parsed through a
  /// [LinkParsingExtension.parseLinks] method.
  void _populateSpans() {
    for (var r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    _text.clear();

    for (Rx<ChatItem> forward in widget.forwards) {
      final ChatItemQuote item = (forward.value as ChatForward).quote;
      if (item is ChatMessageQuote) {
        final String? string = item.text?.val.trim();
        if (string?.isNotEmpty == true) {
          _text[forward.value.id] =
              string!.parseLinks(_recognizers, router.context);
        }
      }
    }

    if (widget.note.value != null) {
      final ChatMessage item = widget.note.value!.value as ChatMessage;
      final String? string = item.text?.val.trim();
      if (string?.isNotEmpty == true) {
        _text[item.id] = string!.parseLinks(_recognizers, router.context);
      }
    }
  }
}

/// Returns a visual representation of the provided [forward].
class ForwardedMessage extends StatelessWidget {
  ForwardedMessage({
    super.key,
    required this.forward,
    required this.menu,
    required this.isRead,
    required this.fromMe,
    required this.galleryKeys,
    required this.loadImages,
    required this.me,
    required this.textChat,
    this.onFileTap,
    this.onGallery,
    this.onAttachmentError,
    this.selection,
    this.onSelecting,
    this.onForwardedTap,
    this.getUser,
  });

  ///
  final Rx<ChatItem> forward;

  ///
  final bool menu;

  ///
  final bool isRead;

  ///
  final bool fromMe;

  ///
  final void Function(ChatItem, FileAttachment)? onFileTap;

  ///
  final Map<ChatItemId, List<GlobalKey<State<StatefulWidget>>>> galleryKeys;

  ///
  final List<Attachment> Function()? onGallery;

  ///
  final Future<void> Function()? onAttachmentError;

  ///
  final bool loadImages;
  SelectedContent? selection;

  ///
  final UserId me;

  ///
  final Map<ChatItemId, TextSpan> textChat;

  ///
  void Function(bool)? onSelecting;

  ///
  final void Function(ChatItemQuote)? onForwardedTap;

  ///
  final Future<RxUser?> Function(UserId)? getUser;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      ChatForward msg = forward.value as ChatForward;
      ChatItemQuote quote = msg.quote;

      Style style = Theme.of(context).extension<Style>()!;

      Widget? content;
      List<Widget> additional = [];

      if (quote is ChatMessageQuote) {
        if (quote.attachments.isNotEmpty) {
          List<Attachment> media = quote.attachments
              .where((e) =>
                  e is ImageAttachment ||
                  (e is FileAttachment && e.isVideo) ||
                  (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
              .toList();

          List<Attachment> files = quote.attachments
              .where((e) =>
                  (e is FileAttachment && !e.isVideo) ||
                  (e is LocalAttachment && !e.file.isImage && !e.file.isVideo))
              .toList();

          additional = [
            if (files.isNotEmpty)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: isRead || !fromMe ? 1 : 0.55,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                  child: Column(
                    children: files
                        .map(
                          (e) => ChatItemWidget.fileAttachment(
                            e,
                            onFileTap: (a) => onFileTap?.call(msg, a),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            if (media.isNotEmpty)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: isRead || !fromMe ? 1 : 0.55,
                child: media.length == 1
                    ? ChatItemWidget.mediaAttachment(
                        context,
                        media.first,
                        media,
                        key: galleryKeys[msg.id]?.firstOrNull,
                        onGallery: onGallery,
                        onError: onAttachmentError,
                        filled: false,
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
                                  key: galleryKeys[msg.id]?[i],
                                  onGallery: onGallery,
                                  onError: onAttachmentError,
                                  autoLoad: loadImages,
                                ),
                              )
                              .toList(),
                        ),
                      ),
              ),
          ];
        }

        final TextSpan? text = textChat[msg.id];
        if (text != null) {
          content = SelectionText.rich(
            text,
            selectable: PlatformUtils.isDesktop || menu,
            onChanged: (a) => selection = a,
            onSelecting: onSelecting,
            style: style.boldBody,
          );
        }
      } else if (quote is ChatCallQuote) {
        String title = 'label_chat_call_ended'.l10n;
        String? time;
        bool fromMe = me == quote.author;
        bool isMissed = false;

        final ChatCall? call = quote.original as ChatCall?;

        if (call?.finishReason == null && call?.conversationStartedAt != null) {
          title = 'label_chat_call_ongoing'.l10n;
        } else if (call?.finishReason != null) {
          title = call!.finishReason!.localizedString(fromMe) ?? title;
          isMissed = call.finishReason == ChatCallFinishReason.dropped ||
              call.finishReason == ChatCallFinishReason.unanswered;

          if (call.conversationStartedAt != null) {
            time = call.finishedAt!.val
                .difference(call.conversationStartedAt!.val)
                .localizedString();
          }
        } else {
          title = call?.authorId == me
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
      } else if (quote is ChatInfoQuote) {
        content = Text(quote.action.toString(), style: style.boldBody);
      } else {
        content = Text('err_unknown'.l10n, style: style.boldBody);
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: msg.quote.author == me
              ? isRead || !fromMe
                  ? const Color(0xFFDBEAFD)
                  : const Color(0xFFE6F1FE)
              : isRead || !fromMe
                  ? const Color(0xFFF9F9F9)
                  : const Color(0xFFFFFFFF),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: isRead || !fromMe ? 1 : 0.55,
          child: WidgetButton(
            onPressed: () => onForwardedTap?.call(quote),
            child: FutureBuilder<RxUser?>(
              future: getUser?.call(quote.author),
              builder: (context, snapshot) {
                Color color = snapshot.data?.user.value.id == me
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
                                crossAxisAlignment: msg.authorId == me
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
}

/// Builds a visual representation of the [ChatForwardWidget.note].
class NoteWidget extends StatelessWidget {
  /// [ChatMessage] attached to these [forwards] as a note.
  ///
  final Rx<Rx<ChatItem>?> note;

  ///
  final bool menu;

  ///
  final bool isRead;

  ///
  final bool fromMe;

  ///
  final void Function(ChatItem, FileAttachment)? onFileTap;

  ///
  final Map<ChatItemId, List<GlobalKey<State<StatefulWidget>>>> galleryKeys;

  ///
  final List<Attachment> Function()? onGallery;

  ///
  final Future<void> Function()? onAttachmentError;

  ///
  final bool loadImages;

  ///
  SelectedContent? selection;

  ///
  final UserId me;

  ///
  void Function(bool)? onSelecting;

  ///
  final void Function(ChatItemQuote)? onForwardedTap;

  ///
  final Future<RxUser?> Function(UserId)? getUser;

  /// [User] posted these [forwards].
  final RxUser? user;

  final Map<ChatItemId, TextSpan> textChat;

  /// Reactive value of a [Chat] these [forwards] are posted in.
  final Rx<Chat?> chat;

  NoteWidget({
    super.key,
    required this.note,
    required this.menu,
    required this.isRead,
    required this.fromMe,
    required this.galleryKeys,
    required this.loadImages,
    required this.me,
    required this.textChat,
    required this.chat,
    this.onFileTap,
    this.onGallery,
    this.onAttachmentError,
    this.selection,
    this.onSelecting,
    this.onForwardedTap,
    this.getUser,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final ChatItem item = note.value!.value;

    if (item is ChatMessage) {
      final Style style = Theme.of(context).extension<Style>()!;

      final TextSpan? text = textChat[item.id];

      final List<Attachment> attachments = item.attachments.where((e) {
        return ((e is ImageAttachment) ||
            (e is FileAttachment && e.isVideo) ||
            (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
      }).toList();

      final List<Attachment> files = item.attachments.where((e) {
        return ((e is FileAttachment && !e.isVideo) ||
            (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
      }).toList();

      final Color color = user?.user.value.id == me
          ? Theme.of(context).colorScheme.secondary
          : AvatarWidget.colors[(user?.user.value.num.val.sum() ?? 3) %
              AvatarWidget.colors.length];

      return Column(children: [
        if (!fromMe && chat.value?.isGroup == true)
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
            child: SelectionText(
              user?.user.value.name?.val ??
                  user?.user.value.num.val ??
                  'dot'.l10n * 3,
              selectable: PlatformUtils.isDesktop || menu,
              onChanged: (a) => selection = a,
              onSelecting: onSelecting,
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
                !fromMe && chat.value?.isGroup == true ? 0 : 10,
                9,
                files.isEmpty ? 10 : 0,
              ),
              child: SelectionText.rich(
                text,
                selectable: PlatformUtils.isDesktop || menu,
                onChanged: (a) => selection = a,
                onSelecting: onSelecting,
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
                    .map(
                      (e) => ChatItemWidget.fileAttachment(
                        e,
                        onFileTap: (a) => onFileTap?.call(item, a),
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
                      (!fromMe && chat.value?.isGroup == true)
                  ? Radius.zero
                  : files.isEmpty
                      ? const Radius.circular(15)
                      : Radius.zero,
              topRight: text != null ||
                      item.repliesTo.isNotEmpty ||
                      (!fromMe && chat.value?.isGroup == true)
                  ? Radius.zero
                  : files.isEmpty
                      ? const Radius.circular(15)
                      : Radius.zero,
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isRead || !fromMe ? 1 : 0.55,
              child: attachments.length == 1
                  ? ChatItemWidget.mediaAttachment(
                      context,
                      attachments.first,
                      attachments,
                      key: galleryKeys[item.id]?.lastOrNull,
                      onGallery: onGallery,
                      onError: onAttachmentError,
                      filled: false,
                      autoLoad: loadImages,
                    )
                  : SizedBox(
                      width: attachments.length * 120,
                      height: max(attachments.length * 60, 300),
                      child: FitView(
                        dividerColor: Colors.transparent,
                        children: attachments
                            .mapIndexed(
                              (i, e) => ChatItemWidget.mediaAttachment(
                                context,
                                e,
                                attachments,
                                key: galleryKeys[item.id]?[i],
                                onGallery: onGallery,
                                onError: onAttachmentError,
                                autoLoad: loadImages,
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
          ),
      ]);
    }

    return const SizedBox();
  }
}

/// Returns rounded rectangle of a [child] representing a message box.
class RoundedWidget extends StatefulWidget {
  RoundedWidget({
    super.key,
    required this.note,
    required this.forwards,
    required this.isRead,
    required this.fromMe,
    required this.galleryKeys,
    required this.loadImages,
    required this.chat,
    required this.authorId,
    required this.dragging,
    required this.draggingStarted,
    required this.offset,
    required this.offsetDuration,
    required this.totalOffset,
    required this.me,
    required this.builder,
    this.onFileTap,
    this.onGallery,
    this.onAttachmentError,
    this.onForwardedTap,
    this.getUser,
    this.user,
    this.animation,
    this.onCopy,
    this.onDelete,
    this.onDrag,
    this.onEdit,
    this.onHide,
    this.onReply,
    this.changeDraggingState,
  });

  /// [ChatMessage] attached to these [forwards] as a note.
  final Rx<Rx<ChatItem>?> note;

  ///
  final RxList<Rx<ChatItem>> forwards;

  ///
  final bool isRead;

  ///
  final bool fromMe;

  ///
  final void Function(ChatItem, FileAttachment)? onFileTap;

  ///
  final Map<ChatItemId, List<GlobalKey<State<StatefulWidget>>>> galleryKeys;

  ///
  final List<Attachment> Function()? onGallery;

  ///
  final Future<void> Function()? onAttachmentError;

  ///
  final bool loadImages;

  ///
  SelectedContent? selection;

  ///
  final UserId me;

  ///
  void Function(bool)? onSelecting;

  ///
  final void Function(ChatItemQuote)? onForwardedTap;

  ///
  final Future<RxUser?> Function(UserId)? getUser;

  /// [User] posted these [forwards].
  final RxUser? user;

  /// Reactive value of a [Chat] these [forwards] are posted in.

  final Rx<Chat?> chat;

  ///
  final AnimationController? animation;

  ///
  Offset offset;

  ///
  Duration offsetDuration;

  ///
  Offset totalOffset;

  ///
  bool draggingStarted;

  ///
  bool dragging;

  ///
  final void Function(bool)? onDrag;

  ///
  final void Function()? onReply;

  ///
  final UserId authorId;

  ///
  final void Function(String)? onCopy;

  ///
  final void Function()? onEdit;

  ///
  final void Function()? onHide;

  ///
  final void Function()? onDelete;

  ///
  final void Function(
    bool dragging,
    bool draggingStarted,
    Offset offset,
    Duration offsetDuration,
    Offset totalOffset,
  )? changeDraggingState;

  ///
  final Widget Function(bool) builder;

  @override
  State<RoundedWidget> createState() => RoundedWidgetState();
}

class RoundedWidgetState extends State<RoundedWidget> {
  @override
  Widget build(BuildContext context) {
    ChatItem? item = widget.note.value?.value;

    bool isSent =
        widget.forwards.first.value.status.value == SendingStatus.sent;

    String? copyable;
    if (item is ChatMessage) {
      copyable = item.text?.val;
    }

    final Iterable<LastChatRead>? reads = widget.chat.value?.lastReads.where(
      (e) =>
          !e.at.val.isBefore(widget.forwards.first.value.at.val) &&
          e.memberId != widget.authorId,
    );

    const int maxAvatars = 5;
    final List<Widget> avatars = [];

    if (widget.chat.value?.isGroup == true) {
      final int countUserAvatars =
          reads!.length > maxAvatars ? maxAvatars - 1 : maxAvatars;

      for (LastChatRead m in reads.take(countUserAvatars)) {
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

      if (reads.length > maxAvatars) {
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
      translate: widget.fromMe,
      isSent: isSent && widget.fromMe,
      isDelivered: isSent &&
          widget.fromMe &&
          widget.chat.value?.lastDelivery
                  .isBefore(widget.forwards.first.value.at) ==
              false,
      isRead: isSent && (!widget.fromMe || widget.isRead),
      isError: widget.forwards.first.value.status.value == SendingStatus.error,
      isSending:
          widget.forwards.first.value.status.value == SendingStatus.sending,
      swipeable: Text(
        DateFormat.Hm().format(widget.forwards.first.value.at.val.toLocal()),
      ),
      padding: EdgeInsets.only(bottom: avatars.isNotEmpty == true ? 33 : 13),
      child: AnimatedOffset(
        duration: widget.offsetDuration,
        offset: widget.offset,
        curve: Curves.ease,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: PlatformUtils.isDesktop
              ? null
              : (d) {
                  widget.draggingStarted = true;
                  setState(() => widget.offsetDuration = Duration.zero);
                },
          onHorizontalDragUpdate: PlatformUtils.isDesktop
              ? null
              : (d) {
                  if (widget.draggingStarted && !widget.dragging) {
                    if (widget.animation?.value == 0 &&
                        widget.offset.dx == 0 &&
                        d.delta.dx > 0) {
                      widget.dragging = true;
                      widget.onDrag?.call(widget.dragging);
                    } else {
                      widget.draggingStarted = false;
                    }
                  }

                  if (widget.dragging) {
                    // Distance [_totalOffset] should exceed in order for
                    // dragging to start.
                    const int delta = 10;

                    if (widget.totalOffset.dx > delta) {
                      widget.offset += d.delta;

                      if (widget.offset.dx > 30 + delta &&
                          widget.offset.dx - d.delta.dx < 30 + delta) {
                        HapticFeedback.selectionClick();
                        widget.onReply?.call();
                      }

                      setState(() {});
                    } else {
                      widget.totalOffset += d.delta;
                      if (widget.totalOffset.dx <= 0) {
                        widget.dragging = false;
                        widget.onDrag?.call(widget.dragging);
                      }
                    }
                  }
                },
          onHorizontalDragEnd: PlatformUtils.isDesktop
              ? null
              : (d) {
                  widget.changeDraggingState;
                },
          child: Row(
            crossAxisAlignment: widget.fromMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisAlignment:
                widget.fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!widget.fromMe && widget.chat.value!.isGroup)
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
                        constraints.maxWidth - SwipeableStatus.width,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Material(
                        type: MaterialType.transparency,
                        child: ContextMenuRegion(
                          preventContextMenu: false,
                          alignment: widget.fromMe
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
                                id: widget.forwards.first.value.id,
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
                                onPressed: () => widget.onCopy?.call(
                                    widget.selection?.plainText ?? copyable!),
                              ),
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
                                final List<ChatItemQuoteInput> quotes = [];

                                for (Rx<ChatItem> item in widget.forwards) {
                                  quotes.add(
                                    ChatItemQuoteInput(item: item.value),
                                  );
                                }

                                if (widget.note.value != null) {
                                  quotes.add(
                                    ChatItemQuoteInput(
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
                            if (widget.fromMe &&
                                widget.note.value != null &&
                                (widget.note.value!.value.at
                                        .add(ChatController.editMessageTimeout)
                                        .isAfter(PreciseDateTime.now()) ||
                                    !widget.isRead))
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
                              label: PlatformUtils.isMobile
                                  ? 'btn_delete'.l10n
                                  : 'btn_delete_message'.l10n,
                              trailing: SvgImage.asset(
                                'assets/icons/delete_small.svg',
                                height: 18,
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
                          builder: (bool menu) => Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              widget.builder(menu),
                              if (avatars.isNotEmpty)
                                Transform.translate(
                                  offset: const Offset(-12, -4),
                                  child: WidgetButton(
                                    onPressed: () => MessageInfo.show(
                                      context,
                                      id: widget.forwards.first.value.id,
                                      reads: reads ?? [],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: avatars,
                                    ),
                                  ),
                                ),
                            ],
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
    );
  }
}
