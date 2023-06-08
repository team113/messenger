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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/call/widget/conditional_backdrop.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/hovered_ink.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller.dart'
    show ChatCallFinishReasonL10n, ChatController, GalleryAttachment;
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
import 'conditional_intrinsic.dart';
import 'data_attachment.dart';
import 'embossed_text.dart';
import 'media_attachment.dart';
import 'message_info/view.dart';
import 'message_timestamp.dart';
import 'selection_text.dart';
import 'swipeable_status.dart';

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
    this.onPin,
    this.paid = false,
    this.pinned = false,
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
  final List<GalleryAttachment> Function()? onGallery;

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

  final void Function()? onPin;
  final bool pinned;

  final bool paid;

  @override
  State<ChatItemWidget> createState() => _ChatItemWidgetState();

  /// Returns a visual representation of the provided media-[Attachment].
  static Widget mediaAttachment(
    BuildContext context,
    Attachment e,
    Iterable<GalleryAttachment> media, {
    GlobalKey? key,
    Iterable<GalleryAttachment> Function()? onGallery,
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
                  final Iterable<GalleryAttachment> attachments =
                      onGallery?.call() ?? media;

                  int initial = attachments.indexed
                      .firstWhere((a) => a.$2.attachment == e)
                      .$1;
                  if (initial == -1) {
                    initial = 0;
                  }

                  List<GalleryItem> gallery = [];
                  for (var o in attachments) {
                    final StorageFile file = o.attachment.original;
                    GalleryItem? item;

                    if (o.attachment is FileAttachment) {
                      item = GalleryItem.video(
                        file.url,
                        o.attachment.filename,
                        size: file.size,
                        checksum: file.checksum,
                        onError: o.onForbidden,
                      );
                    } else if (o.attachment is ImageAttachment) {
                      item = GalleryItem.image(
                        file.url,
                        o.attachment.filename,
                        size: file.size,
                        checksum: file.checksum,
                        onError: o.onForbidden,
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
                child: !isLocal || e.status.value == SendingStatus.sent
                    ? Container(key: const Key('Sent'))
                    : Container(
                        constraints: filled
                            ? const BoxConstraints(
                                minWidth: 300,
                                minHeight: 300,
                              )
                            : null,
                        child: e.status.value == SendingStatus.sending
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
      onPressed: (e) {
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

  final bool _expandedReply = false;

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

  /// Returns the [UserId] of [User] posted this [ChatItem].
  UserId get _author => widget.item.value.authorId;

  /// Indicates whether this [ChatItemWidget.item] was posted by the
  /// authenticated [MyUser].
  bool get _fromMe => _author == widget.me;

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
    final Style style = Theme.of(context).extension<Style>()!;

    final ChatInfo message = widget.item.value as ChatInfo;

    final Widget content;

    // Builds a [FutureBuilder] returning a [User] fetched by the provided [id].
    Widget userBuilder(
      UserId id,
      Widget Function(BuildContext context, User? user) builder,
    ) {
      return FutureBuilder(
        future: widget.getUser?.call(id),
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            return Obx(() => builder(context, snapshot.data!.user.value));
          }

          return builder(context, null);
        },
      );
    }

    switch (message.action.kind) {
      case ChatInfoActionKind.created:
        final action = message.action as ChatInfoActionCreated;

        if (widget.chat.value?.isGroup == true) {
          content = userBuilder(message.authorId, (context, user) {
            if (user != null) {
              final Map<String, dynamic> args = {
                'author': user.name?.val ?? user.num.val,
              };

              return Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'label_group_created_by1'.l10nfmt(args),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => router.user(user.id, push: true),
                    ),
                    TextSpan(
                      text: 'label_group_created_by2'.l10nfmt(args),
                      style: style.systemMessageStyle.copyWith(
                        color: style.colors.secondary,
                      ),
                    ),
                  ],
                  style: style.systemMessageStyle.copyWith(
                    color: style.colors.primary,
                  ),
                ),
              );
            }

            return Text('label_group_created'.l10n);
          });
        } else if (widget.chat.value?.isMonolog == true) {
          content = Text('label_monolog_created'.l10n);
        } else {
          if (action.directLinkSlug == null) {
            content = Text('label_dialog_created'.l10n);
          } else {
            content = Text('label_dialog_created_by_link'.l10n);
          }
        }
        break;

      case ChatInfoActionKind.memberAdded:
        final action = message.action as ChatInfoActionMemberAdded;

        if (action.user.id != message.authorId) {
          content = userBuilder(action.user.id, (context, user) {
            final User author = widget.user?.user.value ?? message.author;
            user ??= action.user;

            final Map<String, dynamic> args = {
              'author': author.name?.val ?? author.num.val,
              'user': user.name?.val ?? user.num.val,
            };

            return Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'label_user_added_user1'.l10nfmt(args),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => router.user(author.id, push: true),
                  ),
                  TextSpan(
                    text: 'label_user_added_user2'.l10nfmt(args),
                    style: style.systemMessageStyle.copyWith(
                      color: style.colors.secondary,
                    ),
                  ),
                  TextSpan(
                    text: 'label_user_added_user3'.l10nfmt(args),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => router.user(user!.id, push: true),
                  ),
                ],
                style: style.systemMessageStyle.copyWith(
                  color: style.colors.primary,
                ),
              ),
            );
          });
        } else {
          final Map<String, dynamic> args = {
            'author': action.user.name?.val ?? action.user.num.val,
          };

          content = Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'label_was_added1'.l10nfmt(args),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => router.user(action.user.id, push: true),
                ),
                TextSpan(
                  text: 'label_was_added2'.l10nfmt(args),
                  style: style.systemMessageStyle.copyWith(
                    color: style.colors.secondary,
                  ),
                ),
              ],
              style: style.systemMessageStyle.copyWith(
                color: style.colors.primary,
              ),
            ),
          );
        }
        break;

      case ChatInfoActionKind.memberRemoved:
        final action = message.action as ChatInfoActionMemberRemoved;

        if (action.user.id != message.authorId) {
          content = userBuilder(action.user.id, (context, user) {
            final User author = widget.user?.user.value ?? message.author;
            user ??= action.user;

            final Map<String, dynamic> args = {
              'author': author.name?.val ?? author.num.val,
              'user': user.name?.val ?? user.num.val,
            };

            return Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'label_user_removed_user1'.l10nfmt(args),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => router.user(author.id, push: true),
                  ),
                  TextSpan(
                    text: 'label_user_removed_user2'.l10nfmt(args),
                    style: style.systemMessageStyle.copyWith(
                      color: style.colors.secondary,
                    ),
                  ),
                  TextSpan(
                    text: 'label_user_removed_user3'.l10nfmt(args),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => router.user(user!.id, push: true),
                  ),
                ],
                style: style.systemMessageStyle.copyWith(
                  color: style.colors.primary,
                ),
              ),
            );
          });
        } else {
          final Map<String, dynamic> args = {
            'author': action.user.name?.val ?? action.user.num.val,
          };

          content = Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'label_was_removed1'.l10nfmt(args),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => router.user(action.user.id, push: true),
                ),
                TextSpan(
                  text: 'label_was_removed2'.l10nfmt(args),
                  style: style.systemMessageStyle.copyWith(
                    color: style.colors.secondary,
                  ),
                ),
              ],
              style: style.systemMessageStyle.copyWith(
                color: style.colors.primary,
              ),
            ),
          );
        }
        break;

      case ChatInfoActionKind.avatarUpdated:
        final action = message.action as ChatInfoActionAvatarUpdated;

        final User user = widget.user?.user.value ?? message.author;
        final Map<String, dynamic> args = {
          'author': user.name?.val ?? user.num.val,
        };

        final String phrase1, phrase2;
        if (action.avatar == null) {
          phrase1 = 'label_avatar_removed1';
          phrase2 = 'label_avatar_removed2';
        } else {
          phrase1 = 'label_avatar_updated1';
          phrase2 = 'label_avatar_updated2';
        }

        content = Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: phrase1.l10nfmt(args),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => router.user(user.id, push: true),
              ),
              TextSpan(
                text: phrase2.l10nfmt(args),
                style: style.systemMessageStyle.copyWith(
                  color: style.colors.secondary,
                ),
              ),
            ],
            style:
                style.systemMessageStyle.copyWith(color: style.colors.primary),
          ),
        );
        break;

      case ChatInfoActionKind.nameUpdated:
        final action = message.action as ChatInfoActionNameUpdated;

        final User user = widget.user?.user.value ?? message.author;
        final Map<String, dynamic> args = {
          'author': user.name?.val ?? user.num.val,
          if (action.name != null) 'name': action.name?.val,
        };

        final String phrase1, phrase2;
        if (action.name == null) {
          phrase1 = 'label_name_removed1';
          phrase2 = 'label_name_removed2';
        } else {
          phrase1 = 'label_name_updated1';
          phrase2 = 'label_name_updated2';
        }

        content = Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: phrase1.l10nfmt(args),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => router.user(user.id, push: true),
              ),
              TextSpan(
                text: phrase2.l10nfmt(args),
                style: style.systemMessageStyle.copyWith(
                  color: style.colors.secondary,
                ),
              ),
            ],
            style: style.systemMessageStyle.copyWith(
              color: style.colors.primary,
            ),
          ),
        );
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
        swipeable: Text(message.at.val.toLocal().hm),
        padding: const EdgeInsets.only(bottom: 6.5),
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

    final List<Attachment> media = msg.attachments.where((e) {
      return ((e is ImageAttachment) ||
          (e is FileAttachment && e.isVideo) ||
          (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
    }).toList();

    final Iterable<GalleryAttachment> galleries =
        media.map((e) => GalleryAttachment(e, widget.onAttachmentError));

    final List<Attachment> files = msg.attachments.where((e) {
      return ((e is FileAttachment && !e.isVideo) ||
          (e is LocalAttachment && !e.file.isImage && !e.file.isVideo));
    }).toList();

    final bool avatar = widget.avatar || msg.donate != null;

    final Color color = _fromMe
        ? style.colors.primary
        : style.colors.userColors[(widget.user?.user.value.num.val.sum() ?? 3) %
            style.colors.userColors.length];

    // Indicator whether the [_timestamp] should be displayed in a bubble above
    // the [ChatMessage] (e.g. if there's an [ImageAttachment]).
    final bool timeInBubble =
        media.isNotEmpty && files.isEmpty && _text == null;

    final bool timestamp =
        (widget.timestamp || msg.donate != null || widget.paid) &&
            (_text != null); // || msg.donate != null);

    return _rounded(
      context,
      // constrained: msg.donate == null,
      (menu, constraints) {
        final List<Widget> children = [
          if (msg.donate == null) ...[
            if (msg.donate != null) const SizedBox(height: 3),
            if (!_fromMe && widget.chat.value?.isGroup == true && avatar) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 9, 0),
                          child: SelectionText.rich(
                            TextSpan(
                              text: widget.user?.user.value.name?.val ??
                                  widget.user?.user.value.num.val ??
                                  'dot'.l10n * 3,
                              recognizer: TapGestureRecognizer()
                                ..onTap =
                                    () => router.user(_author, push: true),
                            ),
                            selectable: PlatformUtils.isDesktop || menu,
                            onSelecting: widget.onSelecting,
                            onChanged: (a) => _selection = a,
                            style: style.boldBody.copyWith(color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ] else
              SizedBox(
                height: msg.repliesTo.isNotEmpty || media.isEmpty ? 6 : 0,
              ),
          ] else ...[
            _donate(
              context,
              donate: msg.donate!,
              timestamp: _text == null,
              header: !_fromMe && widget.chat.value?.isGroup == true && avatar
                  ? [
                      Row(
                        children: [
                          Flexible(
                            child: Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 0, 9, 0),
                                  child: EmbossedText(
                                    widget.user?.user.value.name?.val ??
                                        widget.user?.user.value.num.val ??
                                        'dot'.l10n * 3,
                                    // recognizer: TapGestureRecognizer()
                                    //   ..onTap = () =>
                                    //       router.user(_author, push: true),
                                    style: style.boldBody.copyWith(
                                      color: const Color(0xFFFFFE8A),
                                      // color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 4),
                    ]
                  : [],
              footer: !_fromMe && widget.chat.value?.isGroup == true && avatar
                  ? [
                      const SizedBox(height: 16),
                    ]
                  : [],
            ),
            if ((msg.repliesTo.isNotEmpty || msg.attachments.isNotEmpty))
              const SizedBox(height: 1),
            if ((msg.repliesTo.isEmpty && msg.attachments.isEmpty) &&
                _text != null)
              const SizedBox(height: 6),
          ],

          // if (msg.donate != null)
          //   Padding(
          //     padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          //     child: Align(
          //       alignment:
          //           _fromMe ? Alignment.centerRight : Alignment.centerLeft,
          //       child: _donate(context, donate: msg.donate!),
          //     ),
          //   ),

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
                        onPressed:
                            menu ? null : () => widget.onRepliedTap?.call(e),
                        child: _repliedMessage(e, constraints),
                      ),
                    ),
                  ),
                ),
                if (msg.repliesTo.last != e) const SizedBox(height: 6),
              ];
            }),
            SizedBox(
              height: _text != null || msg.attachments.isNotEmpty ? 6 : 0,
            ),
          ],
          if (media.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: msg.repliesTo.isNotEmpty ||
                        (!_fromMe &&
                            widget.chat.value?.isGroup == true &&
                            avatar)
                    ? Radius.zero
                    : const Radius.circular(15),
                topRight: msg.repliesTo.isNotEmpty ||
                        (!_fromMe &&
                            widget.chat.value?.isGroup == true &&
                            avatar)
                    ? Radius.zero
                    : const Radius.circular(15),
                bottomLeft:
                    _text != null ? Radius.zero : const Radius.circular(15),
                bottomRight:
                    _text != null ? Radius.zero : const Radius.circular(15),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _isRead || !_fromMe ? 1 : 0.55,
                child: media.length == 1
                    ? ChatItemWidget.mediaAttachment(
                        context,
                        media.first,
                        galleries,
                        filled: false,
                        key: _galleryKeys[0],
                        onError: widget.onAttachmentError,
                        onGallery: widget.onGallery,
                        autoLoad: widget.loadImages,
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
                                  key: _galleryKeys[i],
                                  onError: widget.onAttachmentError,
                                  onGallery: widget.onGallery,
                                  autoLoad: widget.loadImages,
                                ),
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
                    if (_text == null && !timeInBubble)
                      Opacity(opacity: 0, child: _timestamp(msg)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (_text != null || (timestamp && msg.attachments.isEmpty)) ...[
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
                            // else
                            //   TextSpan(
                            //     text: 'Sent a gift',
                            //     style: style.boldBody.copyWith(
                            //       color: style.colors.secondary,
                            //     ),
                            //   ),
                            if (timestamp && !timeInBubble) ...[
                              const WidgetSpan(child: SizedBox(width: 4)),
                              WidgetSpan(
                                child:
                                    Opacity(opacity: 0, child: _timestamp(msg)),
                              )
                            ],
                          ],
                        ),
                        key: Key('Text_${widget.item.value.id}'),
                        selectable:
                            (PlatformUtils.isDesktop || menu) && _text != null,
                        onSelecting: widget.onSelecting,
                        onChanged: (a) => _selection = a,
                        style: style.boldBody,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_text != null) const SizedBox(height: 6),
          ],
        ];

        final message = Stack(
          children: [
            ConditionalIntrinsicWidth(
              condition: msg.donate == null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  color: _fromMe
                      ? _isRead
                          ? style.readMessageColor
                          : style.unreadMessageColor
                      : style.messageColor,
                  borderRadius: BorderRadius.circular(15).copyWith(
                      // topLeft: Radius.zero,
                      ),
                  border: _fromMe
                      ? _isRead
                          ? style.secondaryBorder
                          : Border.all(
                              color: style.readMessageColor,
                              width: 0.5,
                            )
                      : style.primaryBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            if (timestamp)
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
                          child: _timestamp(msg, true),
                        ),
                      )
                    : _timestamp(msg),
              )
          ],
        );

        // Widget? donate;

        // if (msg.donate != null) {
        //   donate = Align(
        //     alignment: _fromMe ? Alignment.centerRight : Alignment.centerLeft,
        //     child: donate(msg.donate),
        //   );
        // }

        return Container(
          padding: widget.margin.add(const EdgeInsets.fromLTRB(5, 0, 2, 0)),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment:
                    _fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // if (donate != null) donate,
                  // const SizedBox(height: 1),
                  // if (donate != null) Opacity(opacity: 0, child: donate),
                  message,
                ],
              ),

              // if (donate != null)
              //   Transform.translate(offset: const Offset(0, 3), child: donate),
            ],
          ),
        );
      },
    );
  }

  Widget _donate(
    BuildContext context, {
    required int donate,
    List<Widget> header = const [],
    List<Widget> footer = const [],
    bool timestamp = false,
  }) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Container(
      // width: 300,
      // constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8).copyWith(
            // bottomLeft: Radius.zero,
            // bottomRight: Radius.zero,
            ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFF8B),
            Color(0xFFFFFC82),
            Color(0xFFFFF68A),
            Color(0xFFE1AB18),
            // Colors.green,
            // Colors.green.darken(0.1),
          ],
          stops: [0, 0.32, 0.68, 1],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            // begin: Alignment.topCenter,
            // end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFF8B),
              Color(0xFFFFFC82),
              Color(0xFFFFF68A),
              Color(0xFFE1AB18),
              // Colors.green,
              // Colors.green.darken(0.1),
            ],
            stops: [0, 0.32, 0.68, 1],
          ),
        ),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                ...header,
                Row(
                  children: [
                    // if (_text == null) ...[
                    //   const SizedBox(width: 16),
                    //   Opacity(
                    //     opacity: 0,
                    //     child: Transform.translate(
                    //       offset: const Offset(0, 8),
                    //       child: _timestamp(msg, false, !_fromMe),
                    //     ),
                    //   ),
                    // ],
                    // const SizedBox(width: 6),

                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EmbossedText(
                              '$donate',
                              style: style.boldBody.copyWith(
                                fontSize: 32,
                                color: const Color(0xFFFFFE8A),
                              ),
                            ),
                            EmbossedText(
                              '¤',
                              style: style.boldBody.copyWith(
                                fontSize: 32,
                                fontFamily: 'Gapopa',
                                color: const Color(0xFFFFFE8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded(
                    //   child: SelectionText.rich(
                    //     TextSpan(
                    //       children: [
                    //         TextSpan(
                    //           text: '$donate',
                    //           style: style.boldBody.copyWith(
                    //             // color: const Color(0xFFFFF63D),
                    //             color: const Color(0xFFFFFE8A),
                    //             shadows: const [
                    //               // box-shadow: -8px -8px 16px 0px #FFF63DE5 inset;
                    //               // box-shadow: 8px -8px 16px 0px #C6A82933 inset;
                    //               // box-shadow: -1px -1px 2px 0px #C6A82980;
                    //               // box-shadow: 1px 1px 2px 0px #FFF63D4D;
                    //               Shadow(
                    //                 offset: Offset(-8, -8),
                    //                 blurRadius: 16,
                    //                 color: Color(0xE5FFF63D),
                    //               ),
                    //               Shadow(
                    //                 offset: Offset(8, -8),
                    //                 blurRadius: 16,
                    //                 color: Color(0x33C6A829),
                    //               ),
                    //               Shadow(
                    //                 offset: Offset(-1, -1),
                    //                 blurRadius: 2,
                    //                 color: Color(0x80C6A829),
                    //               ),
                    //               Shadow(
                    //                 offset: Offset(1, 1),
                    //                 blurRadius: 2,
                    //                 color: Color(0x4DFFF63D),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //         TextSpan(
                    //           text: '¤',
                    //           style: style.boldBody.copyWith(
                    //             fontFamily: 'Gapopa',
                    //             color: const Color(0xFFA98010),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //     textAlign: TextAlign.center,
                    //   ),
                    // ),
                  ],
                ),
                ...footer,
                const SizedBox(height: 2),
                const SizedBox(height: 6),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 4),
              child: timestamp
                  ? _timestamp(widget.item.value, false, true)
                  : EmbossedText(
                      'Gift',
                      style: style.systemMessageStyle.copyWith(
                        // color: const Color(0xFFA98010),
                        color: const Color(0xFFFFFE8A),
                        fontSize: 11,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders the [widget.item] as a [ChatCall].
  Widget _renderAsChatCall(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

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

    final Color color = _fromMe
        ? style.colors.primary
        : style.colors.userColors[(widget.user?.user.value.num.val.sum() ?? 3) %
            style.colors.userColors.length];

    final Widget call = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: message.withVideo
                ? SvgImage.asset(
                    'assets/icons/call_video3${isMissed && !_fromMe ? '_red' : isOngoing ? '_blue' : ''}.svg',
                    height: 11,
                  )
                : SvgImage.asset(
                    'assets/icons/call_audio4${isMissed && !_fromMe ? '_red' : isOngoing ? '_blue' : ''}.svg',
                    height: 12,
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
                    style: style.boldBody,
                  ),
                ),
                if (time != null) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2.5),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Text(
                          time,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ).fixedDigits(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );

    // Returns the contents of the [ChatCall] render along with its timestamp.
    Widget child(bool menu) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _isRead || !_fromMe ? 1 : 0.55,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_fromMe &&
                      widget.chat.value?.isGroup == true &&
                      widget.avatar) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                      child: SelectionText.rich(
                        TextSpan(
                          text: widget.user?.user.value.name?.val ??
                              widget.user?.user.value.num.val ??
                              'dot'.l10n * 3,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => router.user(_author, push: true),
                        ),
                        selectable: PlatformUtils.isDesktop || menu,
                        onSelecting: widget.onSelecting,
                        onChanged: (a) => _selection = a,
                        style: style.boldBody.copyWith(color: color),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  SelectionContainer.disabled(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(child: call),
                          if (widget.timestamp)
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
            if (widget.timestamp)
              Positioned(
                right: 8,
                bottom: 4,
                child: _timestamp(widget.item.value),
              )
          ],
        ),
      );
    }

    return _rounded(
      context,
      (menu, __) => Padding(
        padding: widget.margin.add(const EdgeInsets.fromLTRB(5, 1, 5, 1)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            border: _fromMe
                ? _isRead
                    ? style.secondaryBorder
                    : Border.all(
                        color: style.colors.backgroundAuxiliaryLighter,
                        width: 0.5,
                      )
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
            child: child(menu),
          ),
        ),
      ),
    );
  }

  /// Renders the provided [item] as a replied message.
  Widget _repliedMessage(ChatItemQuote item, BoxConstraints constraints) {
    Style style = Theme.of(context).extension<Style>()!;
    bool fromMe = item.author == widget.me;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessageQuote) {
      if (item.attachments.isNotEmpty) {
        int take = (constraints.maxWidth - 35) ~/ 52;
        if (take <= item.attachments.length - 1) {
          take -= 1;
        }

        final List<Widget> widgets = [];

        widgets.addAll(item.attachments.map((a) {
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
        }).take(take));

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
                    style:
                        TextStyle(fontSize: 15, color: style.colors.secondary),
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
          child: Text(item.text!.val, maxLines: 1, style: style.boldBody),
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

        return ClipRRect(
          borderRadius: style.cardRadius,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(width: 2, color: color)),
            ),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            snapshot.data?.user.value.name?.val ??
                                snapshot.data?.user.value.num.val ??
                                'dot'.l10n * 3,
                            style: style.boldBody.copyWith(color: color),
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
    Widget Function(bool menu, BoxConstraints constraints) builder, {
    bool constrained = true,
  }) {
    final Style style = Theme.of(context).extension<Style>()!;

    final ChatItem item = widget.item.value;

    String? copyable;
    if (item is ChatMessage) {
      copyable = item.text?.val;
    }

    final Iterable<LastChatRead>? reads = widget.chat.value?.lastReads.where(
      (e) =>
          !e.at.val.isBefore(widget.item.value.at.val) && e.memberId != _author,
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

        avatars.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: FutureBuilder<RxUser?>(
              future: widget.getUser?.call(m.memberId),
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
    Widget child(bool menu, BoxConstraints constraints) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          builder(menu, constraints),
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

    final bool avatar =
        widget.avatar; // || (item is ChatMessage && item.donate != null);

    return SwipeableStatus(
      animation: widget.animation,
      translate: _fromMe,
      status: _fromMe,
      isSent: isSent,
      isDelivered:
          isSent && widget.chat.value?.lastDelivery.isBefore(item.at) == false,
      isRead: isSent && _isRead,
      isError: item.status.value == SendingStatus.error,
      isSending: item.status.value == SendingStatus.sending,
      swipeable: Text(item.at.val.toLocal().hm),
      padding: EdgeInsets.only(
        bottom: (avatars.isNotEmpty ? 28 : 7) + widget.margin.bottom,
      ),
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
                  padding: const EdgeInsets.only(top: 8),
                  child: avatar
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
                  final BoxConstraints itemConstraints = BoxConstraints(
                    maxWidth: min(
                      550,
                      constraints.maxWidth - SwipeableStatus.width,
                    ),
                  );

                  return ConstrainedBox(
                    constraints: constrained
                        ? itemConstraints
                        : const BoxConstraints.tightForFinite(),
                    child: Material(
                      key: Key('Message_${item.id}'),
                      type: MaterialType.transparency,
                      child: ContextMenuRegion(
                        id: item.id.val,
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
                            if (widget.onReply != null)
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
                                    !_isRead ||
                                    widget.chat.value?.isMonolog == true))
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
                              key: widget.pinned
                                  ? const Key('Pin')
                                  : const Key('Unpin'),
                              label: widget.pinned
                                  ? PlatformUtils.isMobile
                                      ? 'btn_unpin'.l10n
                                      : 'btn_unpin_message'.l10n
                                  : PlatformUtils.isMobile
                                      ? 'btn_pin'.l10n
                                      : 'btn_pin_message'.l10n,
                              trailing: SvgImage.asset(
                                'assets/icons/send_small.svg',
                                width: 18.37,
                                height: 16,
                              ),
                              onPressed: widget.onPin,
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
                        builder: PlatformUtils.isMobile
                            ? (menu) => child(menu, itemConstraints)
                            : null,
                        child: PlatformUtils.isMobile
                            ? null
                            : child(false, itemConstraints),
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
  Widget _timestamp(ChatItem item,
      [bool inverted = false, bool donation = false]) {
    return Obx(() {
      final bool isMonolog = widget.chat.value?.isMonolog == true;

      return KeyedSubtree(
        key: Key('MessageStatus_${item.id}'),
        child: MessageTimestamp(
          at: widget.timestamp ? item.at : null,
          status: widget.timestamp && _fromMe && !isMonolog
              ? item.status.value
              : null,
          read: _isRead || isMonolog,
          delivered:
              widget.chat.value?.lastDelivery.isBefore(item.at) == false ||
                  isMonolog,
          price: widget.paid && !_fromMe ? 123 : null,
          donation: donation,
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

      String? string = msg.text?.val.trim();

      if (msg.donate != null) {
        final index = msg.text?.val.lastIndexOf('?donate=');
        if (index != null && index != -1) {
          string = msg.text!.val.substring(0, index);
        }
      }

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

class FoldedWidget extends StatelessWidget {
  const FoldedWidget({
    super.key,
    this.color,
    this.folded = true,
    this.radius = 10,
    required this.child,
  });

  final Color? color;
  final Widget child;
  final bool folded;

  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      // clipBehavior: Clip.none,
      clipper: folded ? FoldedClipper(radius) : null,
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          child,
          if (folded)
            Container(
              width: radius,
              height: radius,
              decoration: BoxDecoration(
                // color: Color(0xFF72B060)
                // color: Color(0xFF8383ff),
                // color: Color(0xFFfff7ea),
                // color: Color(0xFF8383ff),
                color: Theme.of(context)
                    .extension<Style>()!
                    .cardHoveredBorder
                    .top
                    .color
                    .darken(0.1),
                borderRadius:
                    const BorderRadius.only(bottomLeft: Radius.circular(4)),
                boxShadow: const [
                  CustomBoxShadow(
                    color: Color(0xFFC0C0C0),
                    blurStyle: BlurStyle.outer,
                    blurRadius: 4,
                  ),
                ],
              ),
              // child: Align(
              //   alignment: Alignment.bottomLeft,
              //   child: Padding(
              //     padding: const EdgeInsets.only(bottom: 1, left: 1),
              //     child: Text(
              //       '¤',
              //       style:
              //           Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
              //                 height: 0.8,
              //                 fontFamily: 'Gapopa',
              //                 fontWeight: FontWeight.w300,
              //                 fontSize: 9,
              //               ),
              //     ),
              //   ),
              // ),
            ),
        ],
      ),
    );
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
