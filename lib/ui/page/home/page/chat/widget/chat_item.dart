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
import 'package:url_launcher/url_launcher.dart';

import '../controller.dart' show ChatCallFinishReasonL10n, ChatController;
import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/config.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/fit_view.dart';
import '/ui/page/home/page/chat/forward/view.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/page/player/controller.dart';
import '/ui/page/player/view.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/checkbox_button.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/future_or_builder.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/fixed_timer.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'animated_offset.dart';
import 'chat_gallery.dart';
import 'context_buttons.dart';
import 'data_attachment.dart';
import 'media_attachment.dart';
import 'message_info/view.dart';
import 'message_timestamp.dart';
import 'selection_text.dart';

/// [ChatItem] visual representation.
class ChatItemWidget extends StatefulWidget {
  const ChatItemWidget({
    super.key,
    required this.item,
    required this.chat,
    required this.me,
    this.user,
    this.withName = false,
    this.withAvatar = true,
    this.appendAvatarPadding = true,
    this.selectable = true,
    this.reads = const [],
    this.getUser,
    this.getItem,
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
    this.onDownload,
    this.onDownloadAs,
    this.onSave,
    this.onSelect,
    this.onSearch,
    this.onUserPressed = _defaultOnUserPressed,
    this.onDragging,
    this.onAnimateTo,
  });

  /// Reactive value of a [ChatItem] to display.
  final Rx<ChatItem> item;

  /// Reactive value of a [Chat] this [item] is posted in.
  final Rx<Chat?> chat;

  /// [UserId] of the authenticated [MyUser].
  final UserId me;

  /// [User] posted this [item].
  final RxUser? user;

  /// Indicator whether this [ChatItemWidget] should display [UserExt.title].
  ///
  /// For example, [Chat]-groups should display messages with titles.
  final bool withName;

  /// Indicator whether this [ChatItemWidget] should display an [AvatarWidget].
  ///
  /// For example, [Chat]-groups should display messages with avatars.
  final bool withAvatar;

  /// Indicator whether this [ChatItemWidget] should append a left padding in
  /// place of [AvatarWidget] of [user].
  ///
  /// When an [withAvatar] is `true`, the padding is always applied
  /// automatically. Otherwise setting this to `true` appends the padding as if
  /// there's invisible [AvatarWidget] present.
  final bool appendAvatarPadding;

  /// Indicator whether this [ChatItemWidget] enables [selectable] in
  /// [SelectionText.rich].
  final bool selectable;

  /// [LastChatRead] to display under this [ChatItem].
  final Iterable<LastChatRead> reads;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final FutureOr<RxUser?> Function(UserId userId)? getUser;

  /// Callback, called when a reactive [ChatItem] identified by the provided
  /// [ChatItemId] is required.
  final FutureOr<Rx<ChatItem>?> Function(ChatItemId itemId)? getItem;

  /// Callback, called when a hide action of this [ChatItem] is triggered.
  final void Function()? onHide;

  /// Callback, called when a delete action of this [ChatItem] is triggered.
  final void Function()? onDelete;

  /// Callback, called when a reply action of this [ChatItem] is triggered.
  final void Function(ChatItem)? onReply;

  /// Callback, called when an edit action of this [ChatItem] is triggered.
  final void Function()? onEdit;

  /// Callback, called when a copy action of this [ChatItem] is triggered.
  final void Function(String text)? onCopy;

  /// Callback, called when a gallery list is required.
  ///
  /// If not specified, then [PlayerView] won't open when [ImageAttachment] is
  /// tapped.
  final Paginated<ChatItemId, Rx<ChatItem>> Function()? onGallery;

  /// Callback, called when a replied message of this [ChatItem] is tapped.
  final void Function(ChatItemQuote)? onRepliedTap;

  /// Callback, called when a resend action of this [ChatItem] is triggered.
  final void Function()? onResend;

  /// Callback, called when a [FileAttachment] of this [ChatItem] is tapped.
  final void Function(FileAttachment)? onFileTap;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function(ChatItem?)? onAttachmentError;

  /// Callback, called when a download action of this [ChatItem] is triggered.
  final void Function(List<Attachment>)? onDownload;

  /// Callback, called when a `download as` action of this [ChatItem] is
  /// triggered.
  final void Function(List<Attachment>)? onDownloadAs;

  /// Callback, called when a save to gallery action of this [ChatItem] is
  /// triggered.
  final void Function(List<Attachment>)? onSave;

  /// Callback, called when a select action is triggered.
  final void Function()? onSelect;

  /// Callback, called when a search action is triggered.
  final void Function()? onSearch;

  /// Callback, called whenever some [User]'s name is being pressed.
  final void Function(User) onUserPressed;

  /// Callback, called whenever this [ChatItemWidget] is being dragged.
  final void Function(bool)? onDragging;

  /// Callback, called when the provided [ChatItem] should be scrolled to.
  final void Function(ChatItem)? onAnimateTo;

  @override
  State<ChatItemWidget> createState() => _ChatItemWidgetState();

  /// Returns a visual representation of the provided media-[Attachment].
  static Widget mediaAttachment(
    BuildContext context, {
    required Attachment attachment,
    GlobalKey? key,
    ChatItem? item,
    Paginated<ChatItemId, Rx<ChatItem>> Function()? onGallery,
    Future<void> Function(ChatItem?)? onError,
    bool filled = true,
    bool cover = false,
    void Function(Post)? onReply,
    void Function(Post)? onShare,
    void Function(Post)? onScrollTo,
  }) {
    final style = Theme.of(context).style;

    final bool isLocal = attachment is LocalAttachment;

    final bool isVideo;
    if (isLocal) {
      isVideo = attachment.file.isVideo;
    } else {
      isVideo = attachment is! ImageAttachment;
    }

    final Widget child = KeyedSubtree(
      key: !isLocal ? const Key('SentImage') : null,
      child: MediaAttachment(
        key: key,
        attachment: attachment,
        width: (cover && isVideo) || filled ? double.infinity : null,
        height: filled ? double.infinity : null,
        onError: () async => await onError?.call(null),
        autoplay: !filled,
      ),
    );

    return Padding(
      padding: EdgeInsets.zero,
      child: MouseRegion(
        cursor: isLocal ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: isLocal
              ? null
              : () {
                  if (onGallery == null) {
                    // [onTap] still needs to be invoked to ensure [ContextMenu]
                    // doesn't get closed, when this is being built within it.
                    return;
                  }

                  int initial = 0;
                  if (item is ChatMessage) {
                    initial = max(0, item.attachments.indexOf(attachment));
                  }

                  PlayerView.show(
                    context,
                    gallery: PaginatedGallery(
                      paginated: onGallery(),
                      resourceId: ResourceId(chatId: item?.chatId),
                      initial: item == null
                          ? null
                          : (item.key.toString(), initial),
                      onReply: onReply,
                      onShare: onShare,
                      onScrollTo: onScrollTo,
                    ),
                  );
                },
          child: Stack(
            alignment: Alignment.center,
            children: [
              filled
                  ? Positioned.fill(child: child)
                  : Container(
                      constraints: const BoxConstraints(minWidth: 300),
                      width: double.infinity,
                      child: child,
                    ),
              ElasticAnimatedSwitcher(
                key: Key('AttachmentStatus_${attachment.id}'),
                child: !isLocal || attachment.status.value == SendingStatus.sent
                    ? Container(key: const Key('Sent'))
                    : Container(
                        constraints: filled
                            ? const BoxConstraints(
                                minWidth: 300,
                                minHeight: 300,
                              )
                            : null,
                        child: attachment.status.value == SendingStatus.sending
                            ? SizedBox(
                                width: 60,
                                height: 60,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    key: const Key('Sending'),
                                    value: attachment.progress.value,
                                    backgroundColor: style.colors.onPrimary,
                                    strokeWidth: 10,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.error,
                                key: const Key('Error'),
                                size: 48,
                                color: style.colors.danger,
                              ),
                      ),
              ),
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

  /// Opens the [User.dialog] chat.
  static void _defaultOnUserPressed(User user) =>
      router.chat(ChatId.local(user.id), push: true);
}

/// State of a [ChatItemWidget] maintaining the [GlobalKey]s for gallery and
/// machinery for a swipe gesture.
class _ChatItemWidgetState extends State<ChatItemWidget> {
  /// [GlobalKey]s of [Attachment]s used to animate a [PlayerView] from/to
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

  /// Indicator whether [Offset] during horizontal dragging.
  bool _offsetWasBigger = false;

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

  /// Indicates whether this [ChatItem] was read only partially.
  bool get _isHalfRead {
    final Chat? chat = widget.chat.value;
    if (chat == null) {
      return false;
    }

    return chat.isHalfRead(widget.item.value, widget.me);
  }

  /// Returns the [User] who posted this [ChatItem].
  User get _author => widget.item.value.author;

  /// Indicates whether this [ChatItemWidget.item] was posted by the
  /// authenticated [MyUser].
  bool get _fromMe => _author.id == widget.me;

  @override
  void initState() {
    _populateWorker();

    super.initState();
  }

  @override
  void dispose() {
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
    final style = Theme.of(context).style;

    return DefaultTextStyle(
      style: style.fonts.medium.regular.onBackground,
      child: Obx(() {
        if (widget.item.value is ChatMessage) {
          return _renderAsChatMessage(context);
        } else if (widget.item.value is ChatForward) {
          throw Exception(
            'Use `ChatForward` widget for rendering `ChatForward`s instead',
          );
        } else if (widget.item.value is ChatCall) {
          return _renderAsChatCall(context);
        } else if (widget.item.value is ChatInfo) {
          return SelectionContainer.disabled(child: _renderAsChatInfo());
        }
        throw UnimplementedError('Unknown ChatItem ${widget.item.value}');
      }),
    );
  }

  /// Renders [widget.item] as [ChatInfo].
  Widget _renderAsChatInfo() {
    final style = Theme.of(context).style;

    final ChatInfo message = widget.item.value as ChatInfo;

    final Widget content;

    // Builds a [FutureOrBuilder] returning a [User] fetched by the provided
    // [id].
    Widget userBuilder(
      UserId id,
      Widget Function(BuildContext context, RxUser? user) builder,
    ) {
      return FutureOrBuilder<RxUser?>(
        key: Key('${message.id}_5_$id'),
        futureOr: () => widget.getUser?.call(id),
        builder: (context, user) {
          if (user != null) {
            return Obx(() => builder(context, user));
          }

          return builder(context, null);
        },
      );
    }

    switch (message.action.kind) {
      case ChatInfoActionKind.created:
        final action = message.action as ChatInfoActionCreated;

        if (widget.chat.value?.isGroup == true) {
          content = userBuilder(message.author.id, (context, user) {
            if (user != null) {
              final Map<String, dynamic> args = {'author': user.title()};

              return Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'label_group_created_by1'.l10nfmt(args),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => widget.onUserPressed(user.user.value),
                    ),
                    TextSpan(
                      text: 'label_group_created_by2'.l10nfmt(args),
                      style: style.systemMessageStyle,
                    ),
                  ],
                  style: style.systemMessagePrimary,
                ),
              );
            }

            return Text(
              'label_group_created'.l10n,
              style: style.systemMessageStyle,
            );
          });
        } else if (widget.chat.value?.isMonolog == true) {
          content = Text(
            'label_monolog_created'.l10n,
            style: style.systemMessageStyle,
          );
        } else {
          if (action.directLinkSlug == null) {
            content = Text(
              'label_dialog_created'.l10n,
              style: style.systemMessageStyle,
            );
          } else {
            content = Text(
              'label_dialog_created_by_link'.l10n,
              style: style.systemMessageStyle,
            );
          }
        }
        break;

      case ChatInfoActionKind.memberAdded:
        final action = message.action as ChatInfoActionMemberAdded;

        if (action.user.id != message.author.id) {
          content = userBuilder(action.user.id, (context, rxUser) {
            final User author = widget.user?.user.value ?? message.author;
            final User user = rxUser?.user.value ?? action.user;

            final Map<String, dynamic> args = {
              'author': widget.user?.title() ?? message.author.title(),
              'user': rxUser?.title() ?? action.user.title(),
            };

            return Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'label_user_added_user1'.l10nfmt(args),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => widget.onUserPressed(author),
                  ),
                  TextSpan(
                    text: 'label_user_added_user2'.l10nfmt(args),
                    style: style.systemMessageStyle,
                  ),
                  TextSpan(
                    text: 'label_user_added_user3'.l10nfmt(args),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => widget.onUserPressed(user),
                  ),
                ],
                style: style.systemMessagePrimary,
              ),
            );
          });
        } else {
          final User user = widget.user?.user.value ?? action.user;

          final Map<String, dynamic> args = {
            'author': widget.user?.title() ?? action.user.title(),
          };

          content = Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'label_was_added1'.l10nfmt(args),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => widget.onUserPressed(user),
                ),
                TextSpan(
                  text: 'label_was_added2'.l10nfmt(args),
                  style: style.systemMessageStyle,
                ),
              ],
              style: style.systemMessagePrimary,
            ),
          );
        }
        break;

      case ChatInfoActionKind.memberRemoved:
        final action = message.action as ChatInfoActionMemberRemoved;

        if (action.user.id != message.author.id) {
          content = userBuilder(action.user.id, (context, rxUser) {
            final User author = widget.user?.user.value ?? message.author;
            final User user = rxUser?.user.value ?? action.user;

            final Map<String, dynamic> args = {
              'author': widget.user?.title() ?? message.author.title(),
              'user': rxUser?.title() ?? action.user.title(),
            };

            return Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'label_user_removed_user1'.l10nfmt(args),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => widget.onUserPressed(author),
                  ),
                  TextSpan(
                    text: 'label_user_removed_user2'.l10nfmt(args),
                    style: style.systemMessageStyle,
                  ),
                  TextSpan(
                    text: 'label_user_removed_user3'.l10nfmt(args),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => widget.onUserPressed(user),
                  ),
                ],
                style: style.systemMessagePrimary,
              ),
            );
          });
        } else {
          final User user = widget.user?.user.value ?? action.user;

          final Map<String, dynamic> args = {
            'author': widget.user?.title() ?? action.user.title(),
          };

          content = Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'label_was_removed1'.l10nfmt(args),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => widget.onUserPressed(user),
                ),
                TextSpan(
                  text: 'label_was_removed2'.l10nfmt(args),
                  style: style.systemMessageStyle,
                ),
              ],
              style: style.systemMessagePrimary,
            ),
          );
        }
        break;

      case ChatInfoActionKind.avatarUpdated:
        final action = message.action as ChatInfoActionAvatarUpdated;

        final User user = widget.user?.user.value ?? message.author;
        final Map<String, dynamic> args = {
          'author': widget.user?.title() ?? user.title(),
        };

        final String phrase1, phrase2;
        if (action.avatar == null) {
          phrase1 = 'label_avatar_removed1'.l10nfmt(args);
          phrase2 = 'label_avatar_removed2'.l10nfmt(args);
        } else {
          phrase1 = 'label_avatar_updated1'.l10nfmt(args);
          phrase2 = 'label_avatar_updated2'.l10nfmt(args);
        }

        content = Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: phrase1,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => widget.onUserPressed(user),
              ),
              TextSpan(text: phrase2, style: style.systemMessageStyle),
            ],
            style: style.systemMessagePrimary,
          ),
        );
        break;

      case ChatInfoActionKind.nameUpdated:
        final action = message.action as ChatInfoActionNameUpdated;

        final User user = widget.user?.user.value ?? message.author;
        final Map<String, dynamic> args = {
          'author': widget.user?.title() ?? user.title(),
          if (action.name != null) 'name': action.name?.val,
        };

        content = Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'label_name_updated1'.l10nfmt(args),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => widget.onUserPressed(user),
              ),
              TextSpan(
                text: 'label_name_updated2'.l10nfmt(args),
                style: style.systemMessageStyle,
              ),
            ],
            style: style.systemMessagePrimary,
          ),
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: style.systemMessageBorder,
            color: style.systemMessageColor,
          ),
          child: DefaultTextStyle(
            style: style.fonts.small.regular.onBackground,
            child: content,
          ),
        ),
      ),
    );
  }

  /// Renders [widget.item] as [ChatMessage].
  Widget _renderAsChatMessage(BuildContext context) {
    final style = Theme.of(context).style;

    final ChatMessage msg = widget.item.value as ChatMessage;

    final List<Attachment> media = msg.attachments.where((e) {
      return ((e is ImageAttachment) ||
          (e is FileAttachment && e.isVideo) ||
          (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
    }).toList();

    final List<Attachment> files = msg.attachments.where((e) {
      return ((e is FileAttachment && !e.isVideo) ||
          (e is LocalAttachment && !e.file.isImage && !e.file.isVideo));
    }).toList();

    final Color color = _fromMe
        ? style.colors.primary
        : style.colors.userColors[(widget.user?.user.value.num.val.sum() ?? 3) %
              style.colors.userColors.length];

    // Indicator whether the [_timestamp] should be displayed in a bubble above
    // the [ChatMessage] (e.g. if there's an [ImageAttachment]).
    final bool timeInBubble =
        media.isNotEmpty && files.isEmpty && _text == null;

    return _rounded(context, (menu, constraints) {
      final List<Widget> children = [
        if (!_fromMe &&
            widget.chat.value?.isGroup == true &&
            widget.withName) ...[
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
                        ..onTap = () => widget.onUserPressed(_author),
                    ),
                    selectable:
                        widget.selectable && (PlatformUtils.isDesktop || menu),
                    onChanged: (a) => _selection = a,
                    style: style.fonts.medium.regular.onBackground.copyWith(
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ] else
          SizedBox(height: msg.repliesTo.isNotEmpty || media.isEmpty ? 6 : 0),
        if (msg.repliesTo.isNotEmpty) ...[
          ...msg.repliesTo.expand((e) {
            return [
              SelectionContainer.disabled(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  margin: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  decoration: BoxDecoration(
                    color: style.colors.onBackgroundOpacity2,
                    borderRadius: style.cardRadius,
                    border: Border.fromBorderSide(
                      BorderSide(
                        color: style.colors.onBackgroundOpacity13,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _isRead || !_fromMe ? 1 : 0.55,
                    child: WidgetButton(
                      onPressed: menu
                          ? null
                          : () => widget.onRepliedTap?.call(e),
                      child: _repliedMessage(e, constraints),
                    ),
                  ),
                ),
              ),
              if (msg.repliesTo.last != e) const SizedBox(height: 6),
            ];
          }),
          const SizedBox(height: 6),
        ],
        if (media.isNotEmpty) ...[
          // TODO: Replace `ClipRRect` with rounded `DecoratedBox`s when
          //       `ImageAttachment` sizes are known.
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft:
                  msg.repliesTo.isNotEmpty ||
                      (!_fromMe &&
                          widget.chat.value?.isGroup == true &&
                          widget.withAvatar)
                  ? Radius.zero
                  : const Radius.circular(15),
              topRight:
                  msg.repliesTo.isNotEmpty ||
                      (!_fromMe &&
                          widget.chat.value?.isGroup == true &&
                          widget.withAvatar)
                  ? Radius.zero
                  : const Radius.circular(15),
              bottomLeft: _text != null
                  ? Radius.zero
                  : const Radius.circular(15),
              bottomRight: _text != null
                  ? Radius.zero
                  : const Radius.circular(15),
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _isRead || !_fromMe ? 1 : 0.55,
              child: media.length == 1
                  ? _buildAttachment(
                      media.first,
                      filled: false,
                      menu: menu,
                      cover: _text != null,
                    )
                  : SizedBox(
                      width: media.length * 120,
                      height: max(media.length * 60, 300),
                      child: FitView(
                        dividerColor: style.colors.transparent,
                        children: media
                            .mapIndexed(
                              (i, e) => _buildAttachment(e, menu: menu, i: i),
                            )
                            .toList(),
                      ),
                    ),
            ),
          ),
          SizedBox(height: files.isNotEmpty || _text != null ? 6 : 0),
        ],
        if (files.isNotEmpty) ...[
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _isRead || !_fromMe ? 1 : 0.55,
            child: SelectionContainer.disabled(
              child: Column(
                children: [
                  ...files.expand(
                    (e) => [
                      ChatItemWidget.fileAttachment(
                        e,
                        onFileTap: widget.onFileTap,
                      ),
                      if (files.last != e) const SizedBox(height: 6),
                    ],
                  ),
                  if (_text == null)
                    Opacity(opacity: 0, child: _timestamp(msg)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (_text != null || msg.attachments.isEmpty) ...[
          Row(
            children: [
              Flexible(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _isRead || !_fromMe ? 1 : 0.7,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: SelectionText.rich(
                      TextSpan(
                        children: [
                          if (_text != null) _text!,
                          if (!timeInBubble) ...[
                            const WidgetSpan(child: SizedBox(width: 4)),
                            WidgetSpan(
                              child: Opacity(
                                opacity: 0,
                                child: _timestamp(msg),
                              ),
                            ),
                          ],
                        ],
                      ),
                      key: Key('Text_${widget.item.value.id}'),
                      selectable:
                          (PlatformUtils.isDesktop || menu) &&
                          _text != null &&
                          widget.selectable,
                      onChanged: (a) => _selection = a,
                      style: style.fonts.medium.regular.onBackground,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_text != null) const SizedBox(height: 6),
        ],
      ];

      return Container(
        padding: const EdgeInsets.fromLTRB(5, 0, 2, 0),
        child: Stack(
          children: [
            IntrinsicWidth(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  color: _fromMe
                      ? _isRead
                            ? style.readMessageColor
                            : style.unreadMessageColor
                      : style.messageColor,
                  borderRadius: BorderRadius.circular(15),
                  border: _fromMe ? style.secondaryBorder : style.primaryBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            Positioned(
              right: timeInBubble ? 6 : 8,
              bottom: 4,
              child: timeInBubble
                  ? Container(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      decoration: BoxDecoration(
                        color: style.colors.onBackgroundOpacity50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _timestamp(msg, true),
                    )
                  : _timestamp(msg),
            ),
          ],
        ),
      );
    });
  }

  /// Renders the [widget.item] as a [ChatCall].
  Widget _renderAsChatCall(BuildContext context) {
    final style = Theme.of(context).style;

    final message = widget.item.value as ChatCall;

    final Color color = _fromMe
        ? style.colors.primary
        : style.colors.userColors[(widget.user?.user.value.num.val.sum() ?? 3) %
              style.colors.userColors.length];

    // Returns the contents of the [ChatCall] render along with its timestamp.
    Widget child(bool menu) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _isRead || !_fromMe ? 1 : 0.55,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_fromMe &&
                      widget.chat.value?.isGroup == true &&
                      widget.withAvatar) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                      child: SelectionText.rich(
                        TextSpan(
                          text: widget.user?.title() ?? ('dot'.l10n * 3),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => widget.onUserPressed(_author),
                        ),
                        selectable: PlatformUtils.isDesktop || menu,
                        onChanged: (a) => _selection = a,
                        style: style.fonts.medium.regular.onBackground.copyWith(
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  SelectionContainer.disabled(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: ChatCallWidget(
                                message,
                                me: widget.me,
                                getItem: widget.getItem,
                              ),
                            ),
                          ),
                          WidgetSpan(
                            child: Opacity(
                              opacity: 0,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: _timestamp(widget.item.value),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 4,
              child: _timestamp(widget.item.value),
            ),
          ],
        ),
      );
    }

    return _rounded(
      context,
      (menu, _) => Padding(
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            border: _fromMe ? style.secondaryBorder : style.primaryBorder,
            color: _fromMe
                ? _isRead
                      ? style.readMessageColor
                      : style.unreadMessageColor
                : style.messageColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: child(menu),
        ),
      ),
    );
  }

  /// Renders the provided [item] as a replied message.
  Widget _repliedMessage(ChatItemQuote item, BoxConstraints constraints) {
    final style = Theme.of(context).style;

    bool fromMe = item.author == widget.me;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessageQuote) {
      if (item.attachments.isNotEmpty) {
        int take = (constraints.maxWidth - 35) ~/ 52;
        if (take <= item.attachments.length - 1) {
          take -= 1;
        }

        take = max(take, 0);

        final List<Widget> widgets = [];

        widgets.addAll(
          item.attachments
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
                          thumbhash: image.medium.thumbhash,
                          onForbidden: () async =>
                              await widget.onAttachmentError?.call(null),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: BorderRadius.circular(10.0),
                          cancelable: true,
                        ),
                );
              })
              .take(take),
        );

        if (item.attachments.length > take) {
          final int count = (item.attachments.length - take).clamp(1, 99);

          widgets.add(
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
                    style: style.fonts.normal.regular.secondary,
                  ),
                ),
              ),
            ),
          );
        }

        additional = [Row(mainAxisSize: MainAxisSize.min, children: widgets)];
      }

      if (item.text != null && item.text!.val.isNotEmpty) {
        content = SelectionContainer.disabled(
          child: Text(
            item.text!.val,
            maxLines: 1,
            style: style.fonts.normal.regular.onBackground,
          ),
        );
      }
    } else if (item is ChatCallQuote) {
      content = ChatCallWidget(
        item.original as ChatCall?,
        me: widget.me,
        getItem: widget.getItem,
      );
    } else if (item is ChatInfoQuote) {
      // TODO: Implement `ChatInfo`.
      content = Text(
        item.action.toString(),
        style: style.fonts.big.regular.onBackground,
      );
    } else {
      content = Text(
        'err_unknown'.l10n,
        style: style.fonts.big.regular.onBackground,
      );
    }

    return FutureOrBuilder<RxUser?>(
      key: Key('${item.hashCode}_6_${item.author}'),
      futureOr: () => widget.getUser?.call(item.author),
      builder: (_, user) {
        final Color color = user?.user.value.id == widget.me
            ? style.colors.primary
            : style.colors.userColors[(user?.user.value.num.val.sum() ?? 3) %
                  style.colors.userColors.length];

        return ClipRRect(
          key: Key('Reply_${item.original?.id}'),
          borderRadius: style.cardRadius,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(width: 2, color: color)),
            ),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user?.title() ?? 'dot'.l10n * 3,
                        style: style.fonts.medium.regular.onBackground.copyWith(
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (additional.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...additional,
                ],
                if (content != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle.merge(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: content,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns rounded rectangle of a [child] representing a message box.
  Widget _rounded(
    BuildContext context,
    Widget Function(bool menu, BoxConstraints constraints) builder,
  ) {
    final style = Theme.of(context).style;

    final ChatItem item = widget.item.value;

    final List<Attachment> media = [];

    String? copyable;
    if (item is ChatMessage) {
      copyable = item.text?.val;
      media.addAll(
        item.attachments.where(
          (e) => e is ImageAttachment || (e is FileAttachment && e.isVideo),
        ),
      );
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
              key: Key('${widget.item.value.id}_1_${m.memberId}'),
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
    Widget child(bool menu, BoxConstraints constraints) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          builder(menu, constraints),
          if (avatars.isNotEmpty)
            Transform.translate(
              offset: const Offset(-12, 0),
              child: WidgetButton(
                onPressed: () =>
                    MessageInfo.show(context, widget.item.value.id),
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
                          onTap: () => widget.onUserPressed(item.author),
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
              final BoxConstraints itemConstraints = BoxConstraints(
                maxWidth: 550,
              );
              return ConstrainedBox(
                constraints: itemConstraints,
                child: Material(
                  key: Key('Message_${item.id}'),
                  type: MaterialType.transparency,
                  child: Obx(() {
                    return ContextMenuRegion(
                      preventContextMenu: false,
                      alignment: _fromMe
                          ? Alignment.bottomRight
                          : Alignment.bottomLeft,
                      actions: [
                        InformationContextMenuButton(
                          onPressed: () =>
                              MessageInfo.show(context, widget.item.value.id),
                        ),
                        if (copyable != null)
                          CopyContextMenuButton(
                            onPressed: () => widget.onCopy?.call(
                              _selection?.plainText ?? copyable!,
                            ),
                          ),
                        if (item.status.value == SendingStatus.sent) ...[
                          ReplyContextMenuButton(
                            onPressed: () =>
                                widget.onReply?.call(widget.item.value),
                          ),
                          if (item is ChatMessage)
                            ForwardContextMenuButton(
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
                                  !widget.chat.value!.isRead(
                                    widget.item.value,
                                    widget.me,
                                  )))
                            EditContextMenuButton(onPressed: widget.onEdit),
                          if (media.isNotEmpty) ...[
                            if (PlatformUtils.isDesktop)
                              DownloadContextMenuButton(
                                single: media.length == 1,
                                onPressed: () => widget.onDownload?.call(media),
                              ),
                            if (PlatformUtils.isDesktop && !PlatformUtils.isWeb)
                              DownloadAsContextMenuButton(
                                single: media.length == 1,
                                onPressed: () =>
                                    widget.onDownloadAs?.call(media),
                              ),
                            if (PlatformUtils.isMobile && !PlatformUtils.isWeb)
                              SaveContextMenuButton(
                                single: media.length == 1,
                                onPressed: () => widget.onSave?.call(media),
                              ),
                          ],
                          DeleteContextMenuButton(
                            onPressed: () async {
                              bool isMonolog = widget.chat.value!.isMonolog;
                              bool deletable =
                                  _fromMe &&
                                  !widget.chat.value!.isRead(
                                    widget.item.value,
                                    widget.me,
                                  ) &&
                                  widget.item.value is ChatMessage;

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
                                          label:
                                              'label_also_delete_for_everyone'
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
                        ],
                        if (item.status.value == SendingStatus.error) ...[
                          EditContextMenuButton(onPressed: widget.onEdit),
                          ResendContextMenuButton(onPressed: widget.onResend),
                          DeleteContextMenuButton(
                            onPressed: () async {
                              final bool? pressed = await MessagePopup.alert(
                                'label_delete_message'.l10n,
                                button: MessagePopup.deleteButton,
                              );

                              if (pressed ?? false) {
                                widget.onDelete?.call();
                              }
                            },
                          ),
                        ],
                        SearchContextMenuButton(onPressed: widget.onSearch),
                        SelectContextMenuButton(onPressed: widget.onSelect),
                      ],
                      builder: PlatformUtils.isMobile
                          ? (menu) => child(menu, itemConstraints)
                          : null,
                      child: PlatformUtils.isMobile
                          ? null
                          : child(false, itemConstraints),
                    );
                  }),
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

  /// Builds a [MessageTimestamp] of the provided [item].
  Widget _timestamp(ChatItem item, [bool inverted = false]) {
    return Obx(() {
      final bool isMonolog = widget.chat.value?.isMonolog == true;

      return KeyedSubtree(
        key: Key('MessageStatus_${item.id}'),
        child: MessageTimestamp(
          at: item.at,
          status: _fromMe ? item.status.value : null,
          read: _isRead || isMonolog,
          halfRead: _isHalfRead,
          delivered:
              widget.chat.value?.lastDelivery.isBefore(item.at) == false ||
              isMonolog,
          inverted: inverted,
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
          .where(
            (e) =>
                e is ImageAttachment ||
                (e is FileAttachment && e.isVideo) ||
                (e is LocalAttachment && (e.file.isImage || e.file.isVideo)),
          )
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
        _text = string?.parseLinks(
          _recognizers,
          router.context == null
              ? null
              : Theme.of(router.context!).style.linkStyle,
        );
      }
    } else if (msg is ChatForward) {
      throw Exception(
        'Use `ChatForward` widget for rendering `ChatForward`s instead',
      );
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
          widget.onReply?.call(widget.item.value);
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
    Attachment e, {
    int i = 0,
    bool filled = true,
    bool menu = false,
    bool cover = false,
  }) {
    return ChatItemWidget.mediaAttachment(
      context,
      attachment: e,
      item: widget.item.value,
      filled: filled,
      cover: cover,
      key: _galleryKeys[i],
      onError: widget.onAttachmentError,
      onGallery: menu ? null : widget.onGallery,
      onReply: (e) => widget.onReply?.call(e.item!),
      onShare: (e) async {
        await ChatForwardView.show(context, widget.item.value.chatId, [
          ChatItemQuoteInput(item: e.item!),
        ]);
      },
      onScrollTo: (e) => widget.onAnimateTo?.call(e.item!),
    );
  }
}

/// [ChatCall] visual representation.
class ChatCallWidget extends StatefulWidget {
  const ChatCallWidget(this.call, {super.key, this.getItem, required this.me});

  /// [UserId] of the authenticated [MyUser].
  final UserId me;

  /// [ChatCall] this widget represents.
  final ChatCall? call;

  /// Callback, called when a reactive [ChatItem] with relevant information
  /// about [call] identified by the provided [ChatItemId] is required.
  final FutureOr<Rx<ChatItem>?> Function(ChatItemId itemId)? getItem;

  @override
  State<ChatCallWidget> createState() => ChatCallWidgetState();
}

/// State of a [ChatCallWidget] maintaining the [FutureOr] retrieving the
/// [ChatCall] and [Timer] for its periodic updates.
class ChatCallWidgetState extends State<ChatCallWidget> {
  /// Reactive [ChatItem] representing the [ChatCall].
  Rx<ChatItem>? _item;

  /// [ever] reacting on the [_item] changes.
  Worker? _worker;

  /// [FixedTimer] rebuilding this widget every second, if this [ChatCall]
  /// represents an ongoing [ChatCall].
  FixedTimer? _ongoingCallTimer;

  @override
  void initState() {
    super.initState();

    if (widget.getItem != null && widget.call != null) {
      _fetchItem();
    }
  }

  @override
  void dispose() {
    _ongoingCallTimer?.cancel();
    _ongoingCallTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_item == null || _item?.value is! ChatCall) {
      return _render(context, widget.call);
    }

    return Obx(() => _render(context, _item!.value as ChatCall));
  }

  /// Builds the [ChatCall] visual representation.
  Widget _render(BuildContext context, ChatCall? call) {
    final style = Theme.of(context).style;

    final bool isOngoing =
        call?.finishReason == null && call?.conversationStartedAt != null;

    bool isMissed = false;
    String title = 'label_chat_call_ended'.l10n;
    String? time;

    if (isOngoing) {
      title = 'label_chat_call_ongoing'.l10n;
      time = call!.conversationStartedAt!.val
          .difference(DateTime.now())
          .localizedString();
    } else if (call != null && call.finishReason != null) {
      title =
          call.finishReason!.localizedString(call.author.id == widget.me) ??
          title;
      isMissed =
          call.finishReason == ChatCallFinishReason.dropped ||
          call.finishReason == ChatCallFinishReason.unanswered;

      if (call.finishedAt != null && call.conversationStartedAt != null) {
        time = call.finishedAt!.val
            .difference(call.conversationStartedAt!.val)
            .localizedString();
      }
    } else {
      title = call == null
          ? title
          : call.author.id == widget.me
          ? 'label_outgoing_call'.l10n
          : 'label_incoming_call'.l10n;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SvgIcon(
            (call?.withVideo ?? false)
                ? isMissed
                      ? SvgIcons.callVideoMissed
                      : SvgIcons.callVideo
                : isMissed
                ? SvgIcons.callAudioMissed
                : SvgIcons.callAudio,
          ),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.fonts.medium.regular.onBackground,
                ),
              ),
              if (time != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 2.5),
                  child: Text(
                    time,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style.fonts.normal.regular.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 2),
      ],
    );
  }

  /// Fetches the [_item].
  Future<void> _fetchItem() async {
    _checkForTimer(widget.call);

    final futureOrItem = widget.getItem!(widget.call!.id);
    if (futureOrItem is Rx<ChatItem>?) {
      _item = futureOrItem;
    } else {
      _item = await futureOrItem;
    }

    if (mounted) {
      setState(() {});
    }

    _worker?.dispose();

    if (_item != null) {
      _worker = ever(_item!, (e) => _checkForTimer(e as ChatCall));
    }
  }

  /// Ensures the [_ongoingCallTimer] is being up, if [ChatCall] is considered
  /// active.
  void _checkForTimer(ChatCall? call) {
    final bool isOngoing =
        call?.finishReason == null && call?.conversationStartedAt != null;

    if (isOngoing && !Config.disableInfiniteAnimations) {
      _ongoingCallTimer ??= FixedTimer.periodic(1.seconds, () {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      _ongoingCallTimer?.cancel();
      _ongoingCallTimer = null;
    }
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
    TextStyle? style,
  ]) {
    final Iterable<RegExpMatch> matches = _regex.allMatches(this);
    if (matches.isEmpty) {
      return TextSpan(text: this);
    }

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
          style: style,
          recognizer: recognizer
            ..onTap = () async {
              final Uri uri;

              if (link.isEmail) {
                uri = Uri(scheme: 'mailto', path: link);
              } else {
                uri = Uri.parse(
                  !link.startsWith('http') ? 'https://$link' : link,
                );

                final String url = uri.toString();
                final List<String> origins = [Config.origin, Config.link];

                for (var e in origins) {
                  if (url.startsWith(e)) {
                    router.push(url.replaceFirst(e, ''));
                    return;
                  }
                }
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
