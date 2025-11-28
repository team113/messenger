// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import '/domain/model/user.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/fit_view.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/forward/view.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/checkbox_button.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/future_or_builder.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'animated_offset.dart';
import 'chat_item.dart';
import 'context_buttons.dart';
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
    this.withAvatar = true,
    this.appendAvatarPadding = false,
    this.selectable = true,
    this.withName = true,
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
    this.onDragging,
    this.onAnimateTo,
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

  /// Indicator whether this [ChatForwardWidget] should display [UserExt.title].
  ///
  /// For example, [Chat]-groups should display messages with titles.
  final bool withName;

  /// Indicator whether this [ChatForwardWidget] should display an
  /// [AvatarWidget].
  ///
  /// For example, [Chat]-groups should display messages with avatars.
  final bool withAvatar;

  /// Indicator whether this [ChatForwardWidget] should append a left padding in
  /// place of [AvatarWidget] of [user].
  ///
  /// When an [withAvatar] is `true`, the padding is always applied
  /// automatically. Otherwise setting this to `true` appends the padding as if
  /// there's invisible [AvatarWidget] present.
  final bool appendAvatarPadding;

  /// Indicator whether this [ChatForwardWidget] enables [selectable] in
  /// [SelectionText.rich].
  final bool selectable;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final FutureOr<RxUser?> Function(UserId userId)? getUser;

  /// Callback, called when a hide action of these [forwards] is triggered.
  final void Function()? onHide;

  /// Callback, called when a delete action of these [forwards] is triggered.
  final void Function()? onDelete;

  /// Callback, called when a reply action of these [forwards] is triggered.
  final void Function(ChatItem?)? onReply;

  /// Callback, called when an edit action of these [forwards] is triggered.
  final void Function()? onEdit;

  /// Callback, called when a copy action of these [forwards] is triggered.
  final void Function(String text)? onCopy;

  /// Callback, called when a gallery list is required.
  ///
  /// If not specified, then [PlayerView] won't open when [ImageAttachment] is
  /// tapped.
  final Paginated<ChatItemId, Rx<ChatItem>> Function(ChatItem item)? onGallery;

  /// Callback, called when a [ChatForward] is tapped.
  final void Function(ChatForward)? onForwardedTap;

  /// Callback, called when a [FileAttachment] of some [ChatItem] is tapped.
  final void Function(ChatItem, FileAttachment)? onFileTap;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function(ChatItem?)? onAttachmentError;

  /// Callback, called when a select action is triggered.
  final void Function()? onSelect;

  /// Callback, called whenever this [ChatForwardWidget] is being dragged.
  final void Function(bool)? onDragging;

  /// Callback, called when the provided [ChatItem] should be scrolled to.
  final void Function(ChatItem)? onAnimateTo;

  @override
  State<ChatForwardWidget> createState() => _ChatForwardWidgetState();
}

/// State of a [ChatForwardWidget] maintaining the [_galleryKeys].
class _ChatForwardWidgetState extends State<ChatForwardWidget> {
  /// [GlobalKey]s of [Attachment]s used to animate a [PlayerView] from/to
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

  /// Indicator whether [Offset] during horizontal dragging.
  bool _offsetWasBigger = false;

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
    (widget.note.value?.value.at ?? widget.forwards.last.value.at).val
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
                          widget.note.value == null &&
                          widget.withName) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 9, 0),
                          child: SelectionText.rich(
                            TextSpan(
                              text: widget.user?.title() ?? 'dot'.l10n * 3,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () =>
                                    router.user(widget.authorId, push: true),
                            ),
                            selectable:
                                widget.selectable &&
                                (PlatformUtils.isDesktop || menu),
                            onChanged: (a) => _selection = a,
                            style: style.fonts.medium.regular.onBackground
                                .copyWith(color: color),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 9, 0),
                        child: SelectionText(
                          'label_forwarded_messages'.l10nfmt({
                            'count': widget.forwards.length,
                          }),
                          selectable:
                              widget.selectable &&
                              (PlatformUtils.isDesktop || menu),
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
                              status: _fromMe
                                  ? widget.forwards.first.value.status.value
                                  : null,
                              read: _isRead,
                              halfRead: _isHalfRead,
                              delivered:
                                  widget.chat.value?.lastDelivery.isBefore(
                                    _at,
                                  ) ==
                                  false,
                            ),
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
            .where(
              (e) =>
                  e is ImageAttachment ||
                  (e is FileAttachment && e.isVideo) ||
                  (e is LocalAttachment && (e.file.isImage || e.file.isVideo)),
            )
            .toList();

        final List<Attachment> files = quote.attachments
            .where(
              (e) =>
                  (e is FileAttachment && !e.isVideo) ||
                  (e is LocalAttachment && !e.file.isImage && !e.file.isVideo),
            )
            .toList();

        timeInBubble = text == null && media.isNotEmpty && files.isEmpty;

        content = [
          FutureOrBuilder<RxUser?>(
            key: Key('${quote.hashCode}_3_${quote.author}'),
            futureOr: () => widget.getUser?.call(quote.author),
            builder: (context, user) {
              final Color color = user?.user.value.id == widget.me
                  ? style.colors.primary
                  : style.colors.userColors[(user?.user.value.num.val.sum() ??
                            3) %
                        style.colors.userColors.length];

              return WidgetButton(
                onPressed: () => router.user(quote.author, push: true),
                child: Row(
                  children: [
                    SizedBox(width: 6),
                    AvatarWidget.fromRxUser(
                      user,
                      radius: AvatarRadius.big,
                      badge: false,
                      constraints: BoxConstraints(
                        maxWidth: AvatarRadius.big.toDouble(),
                        maxHeight: AvatarRadius.big.toDouble(),
                      ),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 9),
                        child: SelectionText(
                          user?.title() ?? 'dot'.l10n * 3,
                          selectable:
                              widget.selectable &&
                              (PlatformUtils.isDesktop || menu),
                          onChanged: (a) => _selection = a,
                          style: style.fonts.medium.regular.onBackground
                              .copyWith(color: color),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: quote.attachments.isNotEmpty ? 6 : 3),
          if (media.isNotEmpty) ...[
            media.length == 1
                ? _buildAttachment(
                    media.first,
                    msg,
                    menu: menu,
                    filled: false,
                    cover: quote.text != null,
                  )
                : SizedBox(
                    width: media.length * 120,
                    height: max(media.length * 60, 300),
                    child: FitView(
                      dividerColor: style.colors.transparent,
                      children: media
                          .mapIndexed(
                            (i, e) =>
                                _buildAttachment(e, msg, i: i, menu: menu),
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
                      selectable:
                          widget.selectable &&
                          (PlatformUtils.isDesktop || menu),
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
          isMissed =
              call.finishReason == ChatCallFinishReason.dropped ||
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
          ),
        ];
      } else if (quote is ChatInfoQuote) {
        content = [
          Text(
            quote.action.toString(),
            style: style.fonts.medium.regular.onBackground,
          ),
        ];
      } else {
        content = [
          Text(
            'err_unknown'.l10n,
            style: style.fonts.medium.regular.onBackground,
          ),
        ];
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: style.colors.onBackgroundOpacity2,
          borderRadius: style.cardRadius,
          border: Border.all(
            color: style.colors.onBackgroundOpacity20,
            width: 0.5,
          ),
        ),
        margin: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _isRead || !_fromMe ? 1 : 0.55,
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
                    ? Container(
                        padding: const EdgeInsets.only(left: 4, right: 4),
                        decoration: BoxDecoration(
                          color: style.colors.onBackgroundOpacity27,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: MessageTimestamp(
                          at: quote.at,
                          date: true,
                          fontSize:
                              style.fonts.smaller.regular.onBackground.fontSize,
                          inverted: true,
                        ),
                      )
                    : MessageTimestamp(
                        at: quote.at,
                        date: true,
                        fontSize:
                            style.fonts.smaller.regular.onBackground.fontSize,
                      ),
              ),
            ],
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

      final List<Attachment> files = item.attachments.where((e) {
        return ((e is FileAttachment && !e.isVideo) ||
            (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
      }).toList();

      final Color color = widget.user?.user.value.id == widget.me
          ? style.colors.primary
          : style.colors.userColors[(widget.user?.user.value.num.val.sum() ??
                    3) %
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
                        text: widget.user?.title() ?? 'dot'.l10n * 3,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () =>
                              router.user(widget.authorId, push: true),
                      ),
                      selectable:
                          widget.selectable &&
                          (PlatformUtils.isDesktop || menu),
                      onChanged: (a) => _selection = a,
                      style: style.fonts.medium.regular.onBackground.copyWith(
                        color: color,
                      ),
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
                  ? _buildAttachment(
                      media.first,
                      item,
                      menu: menu,
                      filled: false,
                      cover: text != null,
                    )
                  : SizedBox(
                      width: media.length * 120,
                      height: max(media.length * 60, 300),
                      child: FitView(
                        dividerColor: style.colors.transparent,
                        children: media
                            .mapIndexed(
                              (i, e) =>
                                  _buildAttachment(e, item, i: i, menu: menu),
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
                        selectable:
                            widget.selectable &&
                            (PlatformUtils.isDesktop || menu),
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
    final ChatItem? note = widget.note.value?.value;
    String? copyable = _text.values
        .where((e) => e.text != null)
        .firstOrNull
        ?.text;

    if (note is ChatMessage) {
      copyable = note.text?.val;
    }

    const int maxAvatars = 5;
    final List<Widget> avatars = [];
    const AvatarRadius avatarRadius = AvatarRadius.medium;

    if (widget.chat.value?.isGroup == true) {
      final int countUserAvatars = widget.reads.length > maxAvatars
          ? maxAvatars - 1
          : maxAvatars;

      for (LastChatRead m in widget.reads.take(countUserAvatars)) {
        final User? user = widget.chat.value?.members
            .firstWhereOrNull((e) => e.user.id == m.memberId)
            ?.user;

        avatars.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: FutureOrBuilder<RxUser?>(
              key: Key('${note?.id}_4_${m.memberId}'),
              futureOr: () => widget.getUser?.call(m.memberId),
              builder: (context, member) {
                return Tooltip(
                  message: member?.title() ?? user?.title() ?? ('dot'.l10n * 3),
                  verticalOffset: 15,
                  padding: const EdgeInsets.fromLTRB(7, 3, 7, 3),
                  decoration: BoxDecoration(
                    color: style.colors.secondaryOpacity40,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: member != null
                      ? AvatarWidget.fromRxUser(
                          member,
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
                onPressed: () =>
                    MessageInfo.show(context, widget.forwards.first.value.id),
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

    final row = Row(
      crossAxisAlignment: _fromMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisAlignment: _fromMe
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: 150.milliseconds,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              axisAlignment: 0,
              child: ScaleTransition(
                scale: animation,
                alignment: Alignment.center,
                child: AnimatedSwitcher.defaultTransitionBuilder(
                  child,
                  animation,
                ),
              ),
            );
          },
          child: !_fromMe && widget.chat.value?.isGroup == true
              ? Padding(
                  key: Key('${widget.withAvatar}${widget.appendAvatarPadding}'),
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  child: widget.withAvatar
                      ? InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => router.user(widget.authorId, push: true),
                          child: AvatarWidget.fromRxUser(
                            widget.user,
                            radius: avatarRadius,
                          ),
                        )
                      : widget.appendAvatarPadding
                      ? SizedBox(width: avatarRadius.toDouble() * 2)
                      : const SizedBox(key: Key('1')),
                )
              : _fromMe
              ? widget.appendAvatarPadding
                    ? SizedBox(width: avatarRadius.toDouble() * 2)
                    : const SizedBox(key: Key('3'))
              : const SizedBox(key: Key('4')),
        ),
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 550),
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
                        InformationContextMenuButton(
                          onPressed: () => MessageInfo.show(
                            context,
                            widget.forwards.first.value.id,
                          ),
                        ),
                        if (copyable != null)
                          CopyContextMenuButton(
                            onPressed: () => widget.onCopy?.call(
                              _selection?.plainText ?? copyable!,
                            ),
                          ),
                        ReplyContextMenuButton(
                          onPressed: () => widget.onReply?.call(null),
                        ),
                        ForwardContextMenuButton(
                          onPressed: () async {
                            final List<ChatItemQuoteInput> quotes = [];

                            for (Rx<ChatItem> item in widget.forwards) {
                              quotes.add(ChatItemQuoteInput(item: item.value));
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
                                !widget.chat.value!.isRead(
                                  widget.note.value!.value,
                                  widget.me,
                                )))
                          EditContextMenuButton(onPressed: widget.onEdit),
                        DeleteContextMenuButton(
                          onPressed: () async {
                            bool isMonolog = widget.chat.value!.isMonolog;
                            bool deletable =
                                widget.authorId == widget.me &&
                                !widget.chat.value!.isRead(
                                  widget.forwards.first.value,
                                  widget.me,
                                );

                            bool deleteForAll = false;

                            final bool? pressed = await MessagePopup.alert(
                              'label_delete_message'.l10n,
                              description: [
                                if (!deletable && !isMonolog)
                                  TextSpan(
                                    text: 'label_message_will_deleted_for_you'
                                        .l10n,
                                  ),
                              ],
                              additional: [
                                if (deletable && !isMonolog)
                                  StatefulBuilder(
                                    builder: (context, setState) {
                                      return RowCheckboxButton(
                                        key: const Key('DeleteForAll'),
                                        label: 'label_also_delete_for_everyone'
                                            .l10n,
                                        value: deleteForAll,
                                        onPressed: (e) =>
                                            setState(() => deleteForAll = e),
                                      );
                                    },
                                  ),
                              ],
                              button: MessagePopup.deleteButton,
                            );

                            if (pressed ?? false) {
                              if (deletable && (isMonolog || deleteForAll)) {
                                widget.onDelete?.call();
                              } else if (!isMonolog) {
                                widget.onHide?.call();
                              }
                            }
                          },
                        ),
                        SelectContextMenuButton(onPressed: widget.onSelect),
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
            },
          ),
        ),
        if (_fromMe ||
            (widget.chat.value?.isGroup == false && !widget.selectable))
          AnimatedSize(duration: 150.milliseconds, child: SizedBox(width: 0))
        else
          AnimatedSize(
            duration: 150.milliseconds,
            child: SizedBox(width: avatarRadius.toDouble() * 2),
          ),
      ],
    );

    return AnimatedOffset(
      duration: _offsetDuration,
      offset: _offset,
      curve: Curves.ease,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerPanZoomStart: PlatformUtils.isDesktop
            ? (d) => _handleDraggingStart()
            : null,
        onPointerPanZoomUpdate: PlatformUtils.isDesktop
            ? (d) => _handleDraggingUpdate(d.panDelta)
            : null,
        onPointerPanZoomEnd: PlatformUtils.isDesktop
            ? (d) => _handleDraggingEnd()
            : null,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: PlatformUtils.isDesktop
              ? null
              : (d) => _handleDraggingStart(),
          onHorizontalDragUpdate: PlatformUtils.isDesktop
              ? null
              : (d) => _handleDraggingUpdate(d.delta),
          onHorizontalDragEnd: PlatformUtils.isDesktop
              ? null
              : (d) => _handleDraggingEnd(),
          child: row,
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

    _workers.add(
      ever(widget.note, (Rx<ChatItem>? item) {
        if (item?.value is ChatMessage) {
          final msg = item?.value as ChatMessage;
          if (text != msg.text) {
            _populateSpans();
            text = msg.text;
          }
        }
      }),
    );

    int length = widget.forwards.length;
    _workers.add(
      ever(widget.forwards, (List<Rx<ChatItem>> forwards) {
        if (forwards.length != length) {
          _populateSpans();
          length = forwards.length;
        }
      }),
    );
  }

  /// Populates the [_galleryKeys] from the [ChatForwardWidget.forwards] and
  /// [ChatForwardWidget.note].
  void _populateGlobalKeys() {
    _galleryKeys.clear();

    for (Rx<ChatItem> forward in widget.forwards) {
      final ChatItemQuote item = (forward.value as ChatForward).quote;
      if (item is ChatMessageQuote) {
        _galleryKeys[forward.value.id] = item.attachments
            .where(
              (e) =>
                  e is ImageAttachment ||
                  (e is FileAttachment && e.isVideo) ||
                  (e is LocalAttachment && (e.file.isImage || e.file.isVideo)),
            )
            .map((e) => GlobalKey())
            .toList();
      }
    }

    if (widget.note.value != null) {
      final ChatMessage item = (widget.note.value!.value as ChatMessage);
      _galleryKeys[item.id] = item.attachments
          .where(
            (e) =>
                e is ImageAttachment ||
                (e is FileAttachment && e.isVideo) ||
                (e is LocalAttachment && (e.file.isImage || e.file.isVideo)),
          )
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
            router.context == null
                ? null
                : Theme.of(router.context!).style.linkStyle,
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
          router.context == null
              ? null
              : Theme.of(router.context!).style.linkStyle,
        );
      }
    }
  }

  /// Sets the [_draggingStarted] to be `true`.
  void _handleDraggingStart() {
    _draggingStarted = true;
    setState(() => _offsetDuration = Duration.zero);
  }

  /// Updates the [_offset] and dragging related fields by the provided
  /// [offset].
  void _handleDraggingUpdate(Offset offset) {
    if (_draggingStarted && !_dragging) {
      if (_offset.dx == 0 && offset.dx > 0) {
        _dragging = true;
      } else {
        _draggingStarted = false;
      }
    }

    if (_dragging) {
      // Distance [_totalOffset] should exceed in order for
      // dragging to start.
      const int delta = 50;

      if (_totalOffset.dx > delta) {
        widget.onDragging?.call(true);

        _offset += Offset(offset.dx, 0);

        final bool isBigger = _offset.dx > 30 + delta;

        if (isBigger &&
            ((_offset.dx - offset.dx < 30 + delta) ||
                (!_offsetWasBigger && isBigger))) {
          PlatformUtils.haptic(kind: HapticKind.light);
          widget.onReply?.call(null);
        }

        _offsetWasBigger = isBigger;

        setState(() {});
      } else {
        _totalOffset += Offset(offset.dx, 0);
        if (_totalOffset.dx <= 0) {
          _dragging = false;
        }
      }
    }
  }

  /// Resets the dragging related fields to its original states.
  void _handleDraggingEnd() {
    if (_dragging) {
      _dragging = false;
      _draggingStarted = false;
      _offset = Offset.zero;
      _totalOffset = Offset.zero;
      _offsetDuration = 200.milliseconds;
      _offsetWasBigger = false;
      widget.onDragging?.call(false);
      setState(() {});
    }
  }

  /// Builds a [ChatItemWidget.mediaAttachment].
  Widget _buildAttachment(
    Attachment e,
    ChatItem item, {
    int i = 0,
    bool filled = true,
    bool cover = false,
    bool menu = false,
  }) {
    return ChatItemWidget.mediaAttachment(
      context,
      attachment: e,
      item: item,
      filled: filled,
      cover: cover,
      key: _galleryKeys[item.id]?.elementAtOrNull(i),
      onGallery: menu
          ? null
          : widget.onGallery == null
          ? null
          : () => widget.onGallery!.call(item),
      onError: widget.onAttachmentError,
      onReply: (e) {
        widget.onReply?.call(item);
      },
      onShare: (e) async {
        await ChatForwardView.show(context, item.chatId, [
          ChatItemQuoteInput(item: e.item!),
        ]);
      },
      onScrollTo: (e) {
        widget.onAnimateTo?.call(e.item!);
      },
    );
  }
}
