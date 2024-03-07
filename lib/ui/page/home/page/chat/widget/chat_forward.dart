// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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
import '/ui/page/call/widget/conditional_backdrop.dart';
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
import 'chat_gallery.dart';
import 'chat_item.dart';
import 'message_info/view.dart';
import 'message_timestamp.dart';
import 'selection_text.dart';

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
    this.user,
    this.getUser,
    this.onHide,
    this.onDelete,
    this.onReply,
    this.onEdit,
    this.onCopy,
    this.onGallery,
    this.onForwardedTap,
    this.onFileTap,
    this.onAttachmentError,
    this.onSelect,
  });

  /// Reactive value of a [Chat] these [forwards] are posted in.
  final Rx<Chat?> chat;

  /// [ChatForward]s to display.
  final RxList<Rx<ChatItem>> forwards;

  /// [ChatMessage] attached to these [forwards] as a note.
  final Rx<Rx<ChatItem>?> note;

  /// [UserId] of the [user] who posted these [forwards].
  final UserId authorId;

  /// [UserId] of the authenticated [MyUser].
  final UserId me;

  /// [LastChatRead] to display under this [ChatItem].
  final Iterable<LastChatRead> reads;

  /// [User] posted these [forwards].
  final RxUser? user;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final FutureOr<RxUser?> Function(UserId userId)? getUser;

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
  final List<GalleryAttachment> Function()? onGallery;

  /// Callback, called when a [ChatForward] is tapped.
  final void Function(ChatForward)? onForwardedTap;

  /// Callback, called when a [FileAttachment] of some [ChatItem] is tapped.
  final void Function(ChatItem, FileAttachment)? onFileTap;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function()? onAttachmentError;

  /// Callback, called when a select action is triggered.
  final void Function()? onSelect;

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
  Offset _offset = Offset.zero;

  /// Total [Offset] applied to this [ChatForwardWidget] by a swipe gesture.
  Offset _totalOffset = Offset.zero;

  /// [Duration] to animate [_offset] changes with.
  ///
  /// Used to animate [_offset] resetting when swipe to reply gesture ends.
  Duration _offsetDuration = Duration.zero;

  /// Indicator whether this [ChatForwardWidget] is in an ongoing drag.
  bool _dragging = false;

  /// Indicator whether [GestureDetector] of this [ChatForwardWidget] recognized
  /// a horizontal drag start.
  ///
  /// This indicator doesn't mean that the started drag will become an ongoing.
  bool _draggingStarted = false;

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

  /// Indicates whether this [ChatItem] was read only partially.
  bool get _isHalfRead {
    final Chat? chat = widget.chat.value;
    if (chat == null) {
      return false;
    }

    return chat.isHalfRead(widget.forwards.first.value, widget.me);
  }

  /// Indicates whether these [ChatForwardWidget.forwards] were forwarded by the
  /// authenticated [MyUser].
  bool get _fromMe => widget.authorId == widget.me;

  /// Returns a [PreciseDateTime] when this [ChatForwardWidget] is posted.
  PreciseDateTime get _at => PreciseDateTime(
        (widget.note.value?.value.at ?? widget.forwards.last.value.at)
            .val
            .toLocal(),
      );

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
    final style = Theme.of(context).style;

    final Color color = widget.user?.user.value.id == widget.me
        ? style.colors.primary
        : style.colors.userColors[(widget.user?.user.value.num.val.sum() ?? 3) %
            style.colors.userColors.length];

    return DefaultTextStyle(
      style: style.fonts.medium.regular.onBackground,
      child: Obx(() {
        return _rounded(
          context,
          (menu) => Padding(
            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
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
                              color: style.colors.backgroundAuxiliaryLighter,
                              width: 0.5,
                            )
                      : style.primaryBorder,
                ),
                child: Obx(() {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.note.value != null) _note(menu),
                      if (!_fromMe &&
                          widget.chat.value?.isGroup == true &&
                          widget.note.value == null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 9, 0),
                          child: SelectionText.rich(
                            TextSpan(
                              text: widget.user?.title ?? 'dot'.l10n * 3,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () =>
                                    router.user(widget.authorId, push: true),
                            ),
                            selectable: PlatformUtils.isDesktop || menu,
                            onChanged: (a) => _selection = a,
                            style: style.fonts.medium.regular.onBackground
                                .copyWith(color: color),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 9, 0),
                        child: Text(
                          'label_forwarded_messages'.l10nfmt({
                            'count': widget.forwards.length,
                          }),
                          style: style.fonts.small.regular.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...widget.forwards.map((e) => _forwardedMessage(e, menu)),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          children: [
                            const Spacer(),
                            MessageTimestamp(
                              key: Key(
                                'MessageStatus_${widget.note.value?.value.id ?? widget.forwards.firstOrNull?.value.id}',
                              ),
                              at: _at,
                              status: SendingStatus.sent,
                              read: _isRead,
                              halfRead: _isHalfRead,
                              delivered: widget.chat.value?.lastDelivery
                                      .isBefore(_at) ==
                                  false,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Returns a visual representation of the provided [forward].
  Widget _forwardedMessage(Rx<ChatItem> forward, bool menu) {
    return Obx(() {
      final ChatForward msg = forward.value as ChatForward;
      final ChatItemQuote quote = msg.quote;

      final style = Theme.of(context).style;

      List<Widget> content = [];

      bool timeInBubble = false;

      if (quote is ChatMessageQuote) {
        final TextSpan? text = _text[msg.id];

        final List<Attachment> media = quote.attachments
            .where((e) =>
                e is ImageAttachment ||
                (e is FileAttachment && e.isVideo) ||
                (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
            .toList();

        final Iterable<GalleryAttachment> galleries = media.map(
          (e) => GalleryAttachment(e, widget.onAttachmentError),
        );

        final List<Attachment> files = quote.attachments
            .where((e) =>
                (e is FileAttachment && !e.isVideo) ||
                (e is LocalAttachment && !e.file.isImage && !e.file.isVideo))
            .toList();

        timeInBubble = text == null && media.isNotEmpty && files.isEmpty;

        final FutureOr<RxUser?>? user = widget.getUser?.call(quote.author);

        content = [
          FutureBuilder<RxUser?>(
              future: user is Future<RxUser?> ? user : null,
              builder: (context, snapshot) {
                final RxUser? data =
                    snapshot.data ?? (user is RxUser? ? user : null);

                final Color color = data?.user.value.id == widget.me
                    ? style.colors.primary
                    : style.colors.userColors[
                        (data?.user.value.num.val.sum() ?? 3) %
                            style.colors.userColors.length];

                return Row(
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 9),
                        child: SelectionText.rich(
                          TextSpan(
                            text: data?.title ?? 'dot'.l10n * 3,
                            recognizer: TapGestureRecognizer()
                              ..onTap =
                                  () => router.user(quote.author, push: true),
                          ),
                          selectable: PlatformUtils.isDesktop || menu,
                          onChanged: (a) => _selection = a,
                          style: style.fonts.medium.regular.onBackground
                              .copyWith(color: color),
                        ),
                      ),
                    ),
                  ],
                );
              }),
          SizedBox(height: quote.attachments.isNotEmpty ? 6 : 3),
          if (media.isNotEmpty) ...[
            media.length == 1
                ? ChatItemWidget.mediaAttachment(
                    context,
                    media.first,
                    galleries,
                    key: _galleryKeys[msg.id]?.firstOrNull,
                    onGallery: widget.onGallery,
                    onError: widget.onAttachmentError,
                    filled: false,
                  )
                : SizedBox(
                    width: media.length * 120,
                    height: max(media.length * 60, 300),
                    child: FitView(
                      dividerColor: style.colors.transparent,
                      children: media
                          .mapIndexed(
                            (i, e) => ChatItemWidget.mediaAttachment(
                              context,
                              e,
                              galleries,
                              key: _galleryKeys[msg.id]?[i],
                              onGallery: widget.onGallery,
                              onError: widget.onAttachmentError,
                            ),
                          )
                          .toList(),
                    ),
                  ),
            SizedBox(height: files.isNotEmpty || text != null ? 6 : 0),
          ],
          if (files.isNotEmpty) ...[
            SelectionContainer.disabled(
              child: Column(
                children: [
                  ...files.expand(
                    (e) => [
                      ChatItemWidget.fileAttachment(
                        e,
                        onFileTap: (a) => widget.onFileTap?.call(msg, a),
                      ),
                      if (files.last != e) const SizedBox(height: 6),
                    ],
                  ),
                  if (text == null && !timeInBubble)
                    Opacity(
                      opacity: 0,
                      child: MessageTimestamp(
                        at: quote.at,
                        date: true,
                        fontSize:
                            style.fonts.smaller.regular.onBackground.fontSize,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (text != null || quote.attachments.isEmpty) ...[
            Row(
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: SelectionText.rich(
                      TextSpan(
                        children: [
                          if (text != null) text,
                          // TODO: Use transparent [MessageTimestamp]:
                          //       https://github.com/flutter/flutter/issues/124787
                          const WidgetSpan(child: SizedBox(width: 95)),
                        ],
                      ),
                      selectable: PlatformUtils.isDesktop || menu,
                      onChanged: (a) => _selection = a,
                      style: style.fonts.medium.regular.onBackground,
                    ),
                  ),
                ),
              ],
            ),
            if (text != null) const SizedBox(height: 8),
          ],
        ];
      } else if (quote is ChatCallQuote) {
        String title = 'label_chat_call_ended'.l10n;
        String? time;
        bool fromMe = widget.me == quote.author;
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
          title = call?.author.id == widget.me
              ? 'label_outgoing_call'.l10n
              : 'label_incoming_call'.l10n;
        }

        content = [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
                child: SvgIcon(
                  call?.withVideo == true
                      ? isMissed && !fromMe
                          ? SvgIcons.callVideoMissed
                          : SvgIcons.callVideo
                      : isMissed && !fromMe
                          ? SvgIcons.callAudioMissed
                          : SvgIcons.callAudio,
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
                    style: style.fonts.medium.regular.onBackground,
                  ),
                ),
              ],
            ],
          )
        ];
      } else if (quote is ChatInfoQuote) {
        content = [
          Text(
            quote.action.toString(),
            style: style.fonts.medium.regular.onBackground,
          )
        ];
      } else {
        content = [
          Text(
            'err_unknown'.l10n,
            style: style.fonts.medium.regular.onBackground,
          )
        ];
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: style.colors.onBackgroundOpacity2,
          borderRadius: style.cardRadius,
          border:
              Border.all(color: style.colors.onBackgroundOpacity20, width: 0.5),
        ),
        margin: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _isRead || !_fromMe ? 1 : 0.55,
          child: WidgetButton(
            onPressed: menu ? null : () => widget.onForwardedTap?.call(msg),
            child: Stack(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                        child: IntrinsicWidth(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: content,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: timeInBubble ? 6 : 8,
                  bottom: 4,
                  child: timeInBubble
                      ? ConditionalBackdropFilter(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.only(left: 4, right: 4),
                            decoration: BoxDecoration(
                              color: style.colors.onBackgroundOpacity27,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: MessageTimestamp(
                              at: quote.at,
                              date: true,
                              fontSize: style
                                  .fonts.smaller.regular.onBackground.fontSize,
                              inverted: true,
                            ),
                          ),
                        )
                      : MessageTimestamp(
                          at: quote.at,
                          date: true,
                          fontSize:
                              style.fonts.smaller.regular.onBackground.fontSize,
                        ),
                )
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Builds a visual representation of the [ChatForwardWidget.note].
  Widget _note(bool menu) {
    final ChatItem item = widget.note.value!.value;

    if (item is ChatMessage) {
      final style = Theme.of(context).style;

      final TextSpan? text = _text[item.id];

      final List<Attachment> media = item.attachments.where((e) {
        return ((e is ImageAttachment) ||
            (e is FileAttachment && e.isVideo) ||
            (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
      }).toList();

      final Iterable<GalleryAttachment> galleries = media.map(
        (e) => GalleryAttachment(e, widget.onAttachmentError),
      );

      final List<Attachment> files = item.attachments.where((e) {
        return ((e is FileAttachment && !e.isVideo) ||
            (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
      }).toList();

      final Color color = widget.user?.user.value.id == widget.me
          ? style.colors.primary
          : style.colors.userColors[
              (widget.user?.user.value.num.val.sum() ?? 3) %
                  style.colors.userColors.length];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_fromMe && widget.chat.value?.isGroup == true) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 9, 0),
                    child: SelectionText.rich(
                      TextSpan(
                        text: widget.user?.title ?? 'dot'.l10n * 3,
                        recognizer: TapGestureRecognizer()
                          ..onTap =
                              () => router.user(widget.authorId, push: true),
                      ),
                      selectable: PlatformUtils.isDesktop || menu,
                      onChanged: (a) => _selection = a,
                      style: style.fonts.medium.regular.onBackground
                          .copyWith(color: color),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ] else
            SizedBox(height: media.isEmpty ? 6 : 0),
          if (media.isNotEmpty) ...[
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _isRead || !_fromMe ? 1 : 0.55,
              child: media.length == 1
                  ? ChatItemWidget.mediaAttachment(
                      context,
                      media.first,
                      galleries,
                      key: _galleryKeys[item.id]?.lastOrNull,
                      onGallery: widget.onGallery,
                      onError: widget.onAttachmentError,
                      filled: false,
                    )
                  : SizedBox(
                      width: media.length * 120,
                      height: max(media.length * 60, 300),
                      child: FitView(
                        dividerColor: style.colors.transparent,
                        children: media
                            .mapIndexed(
                              (i, e) => ChatItemWidget.mediaAttachment(
                                context,
                                e,
                                galleries,
                                key: _galleryKeys[item.id]?[i],
                                onGallery: widget.onGallery,
                                onError: widget.onAttachmentError,
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
            SizedBox(height: files.isNotEmpty || text != null ? 6 : 0),
          ],
          if (files.isNotEmpty) ...[
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _isRead || !_fromMe ? 1 : 0.55,
              child: Column(
                children: files
                    .expand(
                      (e) => [
                        ChatItemWidget.fileAttachment(
                          e,
                          onFileTap: (a) => widget.onFileTap?.call(item, a),
                        ),
                        if (files.last != e) const SizedBox(height: 6),
                      ],
                    )
                    .toList(),
              ),
            ),
            if (text != null) const SizedBox(height: 6),
          ],
          if (text != null) ...[
            Row(
              children: [
                Flexible(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _isRead || !_fromMe ? 1 : 0.7,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 9, 0),
                      child: SelectionText.rich(
                        text,
                        selectable: PlatformUtils.isDesktop || menu,
                        onChanged: (a) => _selection = a,
                        style: style.fonts.medium.regular.onBackground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    return const SizedBox();
  }

  /// Returns rounded rectangle of a [child] representing a message box.
  Widget _rounded(BuildContext context, Widget Function(bool) builder) {
    final style = Theme.of(context).style;

    final ChatItem? item = widget.note.value?.value;

    String? copyable;
    if (item is ChatMessage) {
      copyable = item.text?.val;
    }

    final Iterable<LastChatRead>? reads = widget.chat.value?.lastReads.where(
      (e) => e.at.val.isAfter(_at.val) && e.memberId != widget.authorId,
    );

    const int maxAvatars = 5;
    final List<Widget> avatars = [];
    const AvatarRadius avatarRadius = AvatarRadius.medium;

    if (widget.chat.value?.isGroup == true) {
      final int countUserAvatars =
          widget.reads.length > maxAvatars ? maxAvatars - 1 : maxAvatars;

      for (LastChatRead m in widget.reads.take(countUserAvatars)) {
        final User? user = widget.chat.value?.members
            .firstWhereOrNull((e) => e.user.id == m.memberId)
            ?.user;

        final FutureOr<RxUser?>? member = widget.getUser?.call(m.memberId);

        avatars.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: FutureBuilder<RxUser?>(
              future: member is Future<RxUser?> ? member : null,
              builder: (context, snapshot) {
                final RxUser? data =
                    snapshot.data ?? (member is RxUser? ? member : null);

                return Tooltip(
                  message: data?.title ?? user?.title,
                  verticalOffset: 15,
                  padding: const EdgeInsets.fromLTRB(7, 3, 7, 3),
                  decoration: BoxDecoration(
                    color: style.colors.secondaryOpacity40,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: data != null
                      ? AvatarWidget.fromRxUser(
                          data,
                          radius: AvatarRadius.smaller,
                        )
                      : AvatarWidget.fromUser(
                          user,
                          radius: AvatarRadius.smaller,
                        ),
                );
              },
            ),
          ),
        );
      }

      if (widget.reads.length > maxAvatars) {
        avatars.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: AvatarWidget(
              title: 'plus'.l10n,
              radius: AvatarRadius.smaller,
            ),
          ),
        );
      }
    }

    // Builds the provided [builder] and the [avatars], if any.
    Widget child(bool menu, constraints) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          builder(menu),
          if (avatars.isNotEmpty)
            Transform.translate(
              offset: const Offset(-12, 0),
              child: WidgetButton(
                onPressed: () => MessageInfo.show(
                  context,
                  id: widget.forwards.first.value.id,
                  reads: reads ?? [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: avatars,
                ),
              ),
            ),
        ],
      );
    }

    return AnimatedOffset(
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
                  if (_offset.dx == 0 && d.delta.dx > 0) {
                    _dragging = true;
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
                    radius: avatarRadius,
                  ),
                ),
              ),
            Flexible(
              child: LayoutBuilder(builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: min(
                      550,
                      constraints.maxWidth - avatarRadius.toDouble() * 2,
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
                          ContextMenuButton(
                            label: PlatformUtils.isMobile
                                ? 'btn_info'.l10n
                                : 'btn_message_info'.l10n,
                            trailing: const SvgIcon(SvgIcons.info),
                            inverted: const SvgIcon(SvgIcons.infoWhite),
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
                              trailing: const SvgIcon(SvgIcons.copy19),
                              inverted: const SvgIcon(SvgIcons.copy19White),
                              onPressed: () => widget.onCopy
                                  ?.call(_selection?.plainText ?? copyable!),
                            ),
                          ContextMenuButton(
                            key: const Key('ReplyButton'),
                            label: PlatformUtils.isMobile
                                ? 'btn_reply'.l10n
                                : 'btn_reply_message'.l10n,
                            trailing: const SvgIcon(SvgIcons.reply),
                            inverted: const SvgIcon(SvgIcons.replyWhite),
                            onPressed: widget.onReply,
                          ),
                          ContextMenuButton(
                            key: const Key('ForwardButton'),
                            label: PlatformUtils.isMobile
                                ? 'btn_forward'.l10n
                                : 'btn_forward_message'.l10n,
                            trailing: const SvgIcon(SvgIcons.forwardSmall),
                            inverted: const SvgIcon(SvgIcons.forwardSmallWhite),
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
                          if (_fromMe &&
                              widget.note.value != null &&
                              (_at
                                      .add(ChatController.editMessageTimeout)
                                      .isAfter(PreciseDateTime.now()) ||
                                  !_isRead))
                            ContextMenuButton(
                              key: const Key('EditButton'),
                              label: 'btn_edit'.l10n,
                              trailing: const SvgIcon(SvgIcons.edit),
                              inverted: const SvgIcon(SvgIcons.editWhite),
                              onPressed: widget.onEdit,
                            ),
                          ContextMenuButton(
                            label: PlatformUtils.isMobile
                                ? 'btn_delete'.l10n
                                : 'btn_delete_message'.l10n,
                            trailing: const SvgIcon(SvgIcons.delete19),
                            inverted: const SvgIcon(SvgIcons.delete19White),
                            onPressed: () async {
                              bool isMonolog = widget.chat.value!.isMonolog;
                              bool deletable = widget.authorId == widget.me &&
                                  !widget.chat.value!.isRead(
                                    widget.forwards.first.value,
                                    widget.me,
                                  );

                              await ConfirmDialog.show(
                                context,
                                title: 'label_delete_message'.l10n,
                                description: deletable || isMonolog
                                    ? null
                                    : 'label_message_will_deleted_for_you'.l10n,
                                variants: [
                                  if (!deletable || !isMonolog)
                                    ConfirmDialogVariant(
                                      key: const Key('HideForMe'),
                                      onProceed: widget.onHide,
                                      label: 'label_delete_for_me'.l10n,
                                    ),
                                  if (deletable)
                                    ConfirmDialogVariant(
                                      key: const Key('DeleteForAll'),
                                      onProceed: widget.onDelete,
                                      label: 'label_delete_for_everyone'.l10n,
                                    )
                                ],
                              );
                            },
                          ),
                          ContextMenuButton(
                            label: 'btn_select_messages'.l10n,
                            trailing: const SvgIcon(SvgIcons.select),
                            inverted: const SvgIcon(SvgIcons.selectWhite),
                            onPressed: widget.onSelect,
                          ),
                        ],
                        builder: PlatformUtils.isMobile
                            ? (menu) => child(menu, constraints)
                            : null,
                        child: PlatformUtils.isMobile
                            ? null
                            : child(false, constraints),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
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
          _text[forward.value.id] = string!.parseLinks(
            _recognizers,
            Theme.of(router.context!).style.linkStyle,
          );
        }
      }
    }

    if (widget.note.value != null) {
      final ChatMessage item = widget.note.value!.value as ChatMessage;
      final String? string = item.text?.val.trim();
      if (string?.isNotEmpty == true) {
        _text[item.id] = string!.parseLinks(
          _recognizers,
          Theme.of(router.context!).style.linkStyle,
        );
      }
    }
  }
}
