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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/widget/fit_view.dart';
import 'package:messenger/ui/page/home/page/chat/widget/animated_transform.dart';
import 'package:messenger/ui/widget/animated_delayed_switcher.dart';
import 'package:messenger/ui/widget/context_menu/mobile.dart';
import 'package:messenger/ui/widget/context_menu/overlay.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/platform_utils.dart';

import '../../../../../../domain/model/precise_date_time/precise_date_time.dart';
import '../controller.dart'
    show ChatCallFinishReasonL10n, ChatController, FileAttachmentIsVideo;
import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/config.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
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
    this.onJoinCall,
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
  }) : super(key: key);

  /// Reactive value of a [ChatItem] to display.
  final Rx<ChatItem> item;

  /// Reactive value of a [Chat] this [item] is posted in.
  final Rx<Chat?> chat;

  /// [UserId] of the authenticated [MyUser].
  final UserId me;

  /// [User] posted this [item].
  final RxUser? user;

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

  /// Callback, called when a resend action of this [ChatItem] is triggered.
  final Function()? onResend;

  final Function(bool)? onDrag;

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

  final GlobalKey _deleteKey = GlobalKey();

  @override
  void initState() {
    if (widget.item.value is ChatMessage) {
      var msg = widget.item.value as ChatMessage;
      _populateGlobalKeys(msg);
    }

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
    Style style = Theme.of(context).extension<Style>()!;
    return DefaultTextStyle(
      style: style.boldBody,
      child: Obx(() {
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
      }),
    );
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
    return _rounded(context, Text('label_forwarded_message'.l10n));
  }

  /// Renders [widget.item] as [ChatMessage].
  Widget _renderAsChatMessage(BuildContext context) {
    var msg = widget.item.value as ChatMessage;

    bool ignoreFirstRmb = msg.text?.val.isNotEmpty ?? false;
    Style style = Theme.of(context).extension<Style>()!;

    List<Attachment> attachments = msg.attachments;
    bool fromMe = widget.item.value.authorId == widget.me;
    bool isRead = _isRead();

    return _rounded(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
        child: Column(
          crossAxisAlignment:
              fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // if (msg.repliesTo != null)
            //   AnimatedContainer(
            //     duration: const Duration(milliseconds: 500),
            //     decoration: BoxDecoration(
            //       color: fromMe
            //           ? isRead
            //               ? const Color(0xFFD7ECFF)
            //               : const Color(0xFFE6F1FE)
            //           : Colors.white,
            //       borderRadius: BorderRadius.circular(15),
            //     ),
            //     child: ClipRRect(
            //       borderRadius: BorderRadius.circular(15),
            //       child: AnimatedOpacity(
            //         duration: const Duration(milliseconds: 500),
            //         opacity: isRead
            //             ? 1
            //             : fromMe
            //                 ? 0.55
            //                 : 1,
            //         child: WidgetButton(
            //           onPressed: () =>
            //               widget.onRepliedTap?.call(msg.repliesTo!.id),
            //           child: _repliedMessage(msg.repliesTo!),
            //         ),
            //       ),
            //     ),
            //   ),

            // if (msg.repliesTo != null)
            //   AnimatedContainer(
            //     duration: const Duration(milliseconds: 500),
            //     decoration: BoxDecoration(
            //       color: fromMe
            //           ? isRead
            //               ? const Color(0xFFD7ECFF)
            //               : const Color(0xFFE6F1FE)
            //           : Colors.white,
            //       borderRadius: BorderRadius.circular(15),
            //     ),
            //     child: ClipRRect(
            //       borderRadius: BorderRadius.circular(15),
            //       child: AnimatedOpacity(
            //         duration: const Duration(milliseconds: 500),
            //         opacity: isRead
            //             ? 1
            //             : fromMe
            //                 ? 0.55
            //                 : 1,
            //         child: WidgetButton(
            //           onPressed: () =>
            //               widget.onRepliedTap?.call(msg.repliesTo!.id),
            //           child: _repliedMessage(msg.repliesTo!),
            //         ),
            //       ),
            //     ),
            //   ),
            // if (msg.repliesTo != null &&
            //     (msg.text != null || msg.attachments.isNotEmpty))
            //   const SizedBox(height: 0),
            // if (msg.text != null)
            //   AnimatedContainer(
            //     duration: const Duration(milliseconds: 500),
            //     decoration: BoxDecoration(
            //       color: fromMe
            //           ? isRead
            //               ? const Color(0xFFD7ECFF)
            //               : const Color(0xFFE6F1FE)
            //           : Colors.white,
            //       borderRadius: BorderRadius.circular(15),
            //     ),
            //     child: ClipRRect(
            //       borderRadius: BorderRadius.circular(15),
            //       child: AnimatedOpacity(
            //         duration: const Duration(milliseconds: 500),
            //         opacity: isRead
            //             ? 1
            //             : fromMe
            //                 ? 0.55
            //                 : 1,
            //         child: Padding(
            //           padding: const EdgeInsets.all(8.0),
            //           child: GestureDetector(
            //             behavior: HitTestBehavior.deferToChild,
            //             onHorizontalDragUpdate:
            //                 PlatformUtils.isDesktop ? (d) {} : null,
            //             onHorizontalDragEnd:
            //                 PlatformUtils.isDesktop ? (d) {} : null,
            //             child: SelectableText(msg.text!.val,
            //                 style: style.boldBody),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // if (msg.text != null && msg.attachments.isNotEmpty)
            //   const SizedBox(height: 0),
            // if (attachments.isNotEmpty)
            //   AnimatedContainer(
            //     duration: const Duration(milliseconds: 500),
            //     decoration: BoxDecoration(
            //       color: fromMe
            //           ? isRead
            //               ? const Color(0xFFD7ECFF)
            //               : const Color(0xFFE6F1FE)
            //           : Colors.white,
            //       borderRadius: BorderRadius.circular(15),
            //     ),
            //     child: ClipRRect(
            //       borderRadius: BorderRadius.circular(15),
            //       child: AnimatedOpacity(
            //         duration: const Duration(milliseconds: 500),
            //         opacity: isRead
            //             ? 1
            //             : fromMe
            //                 ? 0.55
            //                 : 1,
            //         child: attachments.length == 1
            //             ? _buildAttachment(
            //                 0,
            //                 attachments.first,
            //                 attachments,
            //                 filled: false,
            //               )
            //             : SizedBox(
            //                 width: attachments.length * 120,
            //                 height: max(attachments.length * 60, 300),
            //                 child: FitView(
            //                   dividerColor: Colors.transparent,
            //                   children: attachments
            //                       .mapIndexed((i, e) =>
            //                           _buildAttachment(i, e, attachments))
            //                       .toList(),
            //                 ),
            //               ),
            //       ),
            //     ),
            //   ),

            IntrinsicWidth(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    CustomBoxShadow(
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.2),
                      blurStyle: BlurStyle.outer,
                      offset: const Offset(0, 0.5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (msg.repliesTo != null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        decoration: BoxDecoration(
                          color: fromMe
                              ? isRead
                                  ? const Color(0xFFEDF6FF)
                                  : const Color(0xFFE6F1FE)
                              : const Color(0xFFDFDFDF),
                          // borderRadius: BorderRadius.circular(15),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: ClipRRect(
                          // borderRadius: BorderRadius.circular(15),
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
                                  widget.onRepliedTap?.call(msg.repliesTo!.id),
                              child: _repliedMessage(msg.repliesTo!),
                            ),
                          ),
                        ),
                      ),
                    if (msg.repliesTo != null &&
                        (msg.text != null || msg.attachments.isNotEmpty))
                      const SizedBox(height: 0),
                    if (msg.text != null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        decoration: BoxDecoration(
                          color: fromMe
                              ? isRead
                                  ? const Color(0xFFD7ECFF)
                                  : const Color(0xFFE6F1FE)
                              : Colors.white,
                          // borderRadius: BorderRadius.circular(15),
                          borderRadius: BorderRadius.only(
                            topLeft: msg.repliesTo != null
                                ? Radius.zero
                                : const Radius.circular(15),
                            topRight: msg.repliesTo != null
                                ? Radius.zero
                                : const Radius.circular(15),
                            bottomLeft: msg.attachments.isNotEmpty
                                ? Radius.zero
                                : const Radius.circular(15),
                            bottomRight: msg.attachments.isNotEmpty
                                ? Radius.zero
                                : const Radius.circular(15),
                          ),
                        ),
                        child: ClipRRect(
                          // borderRadius: BorderRadius.circular(15),
                          borderRadius: BorderRadius.only(
                            topLeft: msg.repliesTo != null
                                ? Radius.zero
                                : const Radius.circular(15),
                            topRight: msg.repliesTo != null
                                ? Radius.zero
                                : const Radius.circular(15),
                            bottomLeft: msg.attachments.isNotEmpty
                                ? Radius.zero
                                : const Radius.circular(15),
                            bottomRight: msg.attachments.isNotEmpty
                                ? Radius.zero
                                : const Radius.circular(15),
                          ),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: isRead
                                ? 1
                                : fromMe
                                    ? 0.55
                                    : 1,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 9, 10),
                              child: GestureDetector(
                                behavior: HitTestBehavior.deferToChild,
                                onHorizontalDragUpdate:
                                    PlatformUtils.isDesktop ? (d) {} : null,
                                onHorizontalDragEnd:
                                    PlatformUtils.isDesktop ? (d) {} : null,
                                child: Obx(() {
                                  return IgnorePointer(
                                    ignoring: ContextMenuOverlay.of(context)
                                            .id
                                            .value !=
                                        widget.item.value.id.val,
                                    child: SelectableText(
                                      msg.text!.val,
                                      style: style.boldBody,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (msg.text != null && msg.attachments.isNotEmpty)
                      const SizedBox(height: 0),
                    if (attachments.isNotEmpty)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        decoration: BoxDecoration(
                          color: fromMe
                              ? isRead
                                  ? const Color(0xFFD7ECFF)
                                  : const Color(0xFFE6F1FE)
                              : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: msg.text != null || msg.repliesTo != null
                                ? Radius.zero
                                : const Radius.circular(15),
                            topRight: msg.text != null || msg.repliesTo != null
                                ? Radius.zero
                                : const Radius.circular(15),
                            bottomLeft: const Radius.circular(15),
                            bottomRight: const Radius.circular(15),
                          ),
                          // borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: msg.text != null || msg.repliesTo != null
                                ? Radius.zero
                                : const Radius.circular(15),
                            topRight: msg.text != null || msg.repliesTo != null
                                ? Radius.zero
                                : const Radius.circular(15),
                            bottomLeft: const Radius.circular(15),
                            bottomRight: const Radius.circular(15),
                          ),
                          // borderRadius: BorderRadius.circular(15),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: isRead
                                ? 1
                                : fromMe
                                    ? 0.55
                                    : 1,
                            child: attachments.length == 1
                                ? _buildAttachment(
                                    0,
                                    attachments.first,
                                    attachments,
                                    filled: false,
                                  )
                                : SizedBox(
                                    width: attachments.length * 120,
                                    height: max(attachments.length * 60, 300),
                                    child: FitView(
                                      dividerColor: Colors.transparent,
                                      children: attachments
                                          .mapIndexed((i, e) =>
                                              _buildAttachment(
                                                  i, e, attachments))
                                          .toList(),
                                    ),
                                  ),
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
      padding: EdgeInsets.zero,
      ignoreFirstRmb: ignoreFirstRmb,
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

    Style style = Theme.of(context).extension<Style>()!;

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

    bool isRead = _isRead();

    return _rounded(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            boxShadow: [
              CustomBoxShadow(
                blurRadius: 2,
                color: Colors.black.withOpacity(0.2),
                blurStyle: BlurStyle.outer,
                offset: const Offset(0, 0.5),
              ),
            ],
            color: fromMe
                ? isRead
                    ? const Color(0xFFD7ECFF)
                    : const Color(0xFFE6F1FE)
                : Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isRead
                  ? 1
                  : fromMe
                      ? 0.55
                      : 1,
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

  /// Renders [item] as a replied message.
  Widget _repliedMessage(ChatItem item) {
    Style style = Theme.of(context).extension<Style>()!;

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
        additional = item.attachments.map((a) {
          ImageAttachment? image;

          if (a is ImageAttachment) {
            image = a;
          }

          return Container(
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE7E7E7),
              borderRadius: BorderRadius.circular(4),
              image: image == null
                  ? null
                  : DecorationImage(
                      image: NetworkImage('${Config.url}/files${image.small}'),
                    ),
            ),
            width: 30,
            height: 30,
            child:
                image == null ? const Icon(Icons.attach_file, size: 16) : null,
          );
        }).toList();
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

    Color color = AvatarWidget.colors[
        (widget.user?.user.value.num.val.sum() ?? 3) %
            AvatarWidget.colors.length];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 12),
        // Padding(
        //   padding: const EdgeInsets.only(top: 0),
        //   child: SvgLoader.asset(
        //     'assets/icons/forward.svg',
        //     height: 13,
        //     width: 13,
        //   ),
        // ),
        // const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 2,
                color: color,
                // color: Color(0xFF63B4FF),
              ),
            ),
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

                  if (widget.user?.user.value != null) {
                    return Obx(() {
                      Color color = AvatarWidget.colors[
                          widget.user!.user.value.num.val.sum() %
                              AvatarWidget.colors.length];

                      return Text(
                        widget.user!.user.value.name?.val ??
                            widget.user!.user.value.num.val,
                        style: style.boldBody.copyWith(color: color),
                      );
                    });
                  }

                  return Text(
                    name ?? '...',
                    style:
                        style.boldBody.copyWith(color: const Color(0xFF63B4FF)),
                  );
                },
              ),
              if (content != null) ...[
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  maxLines: 1,
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
      ],
    );
  }

  bool _isRead() {
    bool fromMe = widget.item.value.authorId == widget.me;
    bool isRead = false;
    if (fromMe) {
      isRead = widget.chat.value?.lastReads.firstWhereOrNull((e) =>
              e.memberId != widget.me &&
              !e.at.isBefore(widget.item.value.at)) !=
          null;
    } else {
      isRead = widget.chat.value?.lastReads
              .firstWhereOrNull((e) => e.memberId == widget.me)
              ?.at
              .isBefore(widget.item.value.at) ==
          false;
    }

    return isRead;
  }

  Offset _offset = Offset.zero;
  Duration _offsetDuration = Duration.zero;
  bool _dragging = false;
  bool _draggingStarted = false;
  bool _draggingFeedback = false;

  /// Returns rounded rectangle of a [child] representing a message box.
  Widget _rounded(
    BuildContext context,
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(8),
    bool ignoreFirstRmb = false,
  }) {
    ChatItem item = widget.item.value;

    String? copyable;
    if (widget.item.value is ChatMessage) {
      copyable = (widget.item.value as ChatMessage).text?.val;
    }

    bool fromMe = widget.item.value.authorId == widget.me;
    bool isRead = _isRead();
    bool isSent = widget.item.value.status.value == SendingStatus.sent;

    return SwipeableStatus(
      animation: widget.animation,
      asStack: !fromMe,
      isSent: isSent && fromMe,
      isDelivered: isSent &&
          fromMe &&
          widget.chat.value?.lastDelivery.isBefore(widget.item.value.at) ==
              false,
      isRead: isSent && (!fromMe || isRead),
      isError: widget.item.value.status.value == SendingStatus.error,
      isSending: widget.item.value.status.value == SendingStatus.sending,
      swipeable:
          Text(DateFormat.Hm().format(widget.item.value.at.val.toLocal())),
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
              if (fromMe)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: AnimatedDelayedSwitcher(
                    delay:
                        widget.item.value.status.value == SendingStatus.sending
                            ? const Duration(seconds: 2)
                            : Duration.zero,
                    child: widget.item.value.status.value ==
                            SendingStatus.sending
                        ? const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.access_alarm, size: 15),
                          )
                        : widget.item.value.status.value == SendingStatus.error
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
              if (!fromMe && widget.chat.value!.isGroup)
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 4),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () =>
                        router.user(widget.item.value.authorId, push: true),
                    child: AvatarWidget.fromRxUser(widget.user, radius: 18),
                  ),
                ),
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
                      // padding: const EdgeInsets.all(5),
                      // padding: padding == EdgeInsets.zero
                      //     ? EdgeInsets.zero
                      //     : const EdgeInsets.all(5),
                      child: Material(
                        key: Key('Message_${widget.item.value.id}'),
                        type: MaterialType.transparency,
                        // borderRadius: BorderRadius.circular(15),
                        child: ContextMenuRegion(
                          preventContextMenu: false,
                          usePointerDown: ignoreFirstRmb,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          menu: Container(),
                          alignment: fromMe
                              ? Alignment.bottomRight
                              : Alignment.bottomLeft,
                          id: widget.item.value.id.val,
                          // menu: ContextMenu(
                          actions: [
                            if (copyable != null)
                              ContextMenuButton(
                                key: const Key('CopyButton'),
                                label: 'Copy'.l10n,
                                // leading: const Icon(Icons.copy),
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
                                // leading: const Icon(Icons.reply),
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
                                // leading: const Icon(Icons.reply_all),
                                leading: SvgLoader.asset(
                                  'assets/icons/forward.svg',
                                  width: 18.8,
                                  height: 16,
                                ),
                                onPressed: () {},
                              ),
                              if (widget.item.value is ChatMessage &&
                                  fromMe &&
                                  (widget.item.value.at
                                          .add(
                                              ChatController.editMessageTimeout)
                                          .isAfter(PreciseDateTime.now()) ||
                                      !isRead))
                                ContextMenuButton(
                                  key: const Key('EditButton'),
                                  label: 'Edit'.l10n,
                                  // leading: const Icon(Icons.edit),
                                  leading: SvgLoader.asset(
                                    'assets/icons/edit.svg',
                                    width: 17,
                                    height: 17,
                                  ),
                                  onPressed: () => widget.onEdit?.call(),
                                ),
                              // ContextMenuButton(
                              //   key: const Key('SelectButton'),
                              //   label: 'Select'.l10n,
                              //   // leading: const Icon(Icons.check_circle),
                              //   leading: SvgLoader.asset(
                              //     'assets/icons/select.svg',
                              //     width: 17,
                              //     height: 17,
                              //   ),
                              //   onPressed: () {},
                              // ),
                              ContextMenuButton(
                                // key: const Key('HideForMe'),
                                key: _deleteKey,
                                label: 'Delete'.l10n,
                                // leading: const Icon(Icons.delete),
                                leading: SvgLoader.asset(
                                  'assets/icons/delete_small.svg',
                                  width: 17.75,
                                  height: 17,
                                ),
                                onPressed: () async {
                                  await ModalPopup.show(
                                    context: context,
                                    child: _buildDelete2(item),
                                  );
                                  // showDialog(
                                  //   // barrierColor: Colors.transparent,
                                  //   barrierColor: Colors.black.withOpacity(0.1),
                                  //   context: context,
                                  //   builder: (context) {
                                  // return _buildDelete(item, onRemove: (d) {
                                  //   Navigator.of(router.context!).pop();
                                  // });
                                  //   },
                                  // );

                                  // OverlayEntry? entry;

                                  // entry = OverlayEntry(builder: (context) {
                                  //   return _buildDelete(
                                  //     item,
                                  //     onRemove: (bool? value) {
                                  //       entry?.remove();
                                  //     },
                                  //   );
                                  // });

                                  // Overlay.of(context, rootOverlay: true)
                                  //     ?.insert(entry);

                                  // bool deletable =
                                  //     widget.item.value.authorId == widget.me &&
                                  //         !widget.chat.value!.isRead(
                                  //             widget.item.value, widget.me) &&
                                  //         (widget.item.value is ChatMessage ||
                                  //             widget.item.value is ChatForward);

                                  // if (await MessagePopup.alert(
                                  //         'Are you sure you want to delete this message?') ==
                                  //     true) {
                                  //   widget.onHide?.call();
                                  // }
                                },
                              ),
                              // ContextMenuButton(
                              //   key: const Key('HideForMe'),
                              //   label: 'label_hide_for_me'.l10n,
                              //   leading: const Icon(Icons.delete),
                              //   onPressed: () => widget.onHide?.call(),
                              // ),
                              // if (widget.item.value.authorId == widget.me &&
                              //     !widget.chat.value!
                              //         .isRead(widget.item.value, widget.me) &&
                              //     (widget.item.value is ChatMessage ||
                              //         widget.item.value is ChatForward))
                              //   ContextMenuButton(
                              //     key: const Key('DeleteForAll'),
                              //     label: 'label_delete_for_all'.l10n,
                              //     leading: const Icon(Icons.delete_forever),
                              //     onPressed: () => widget.onDelete?.call(),
                              //   ),
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
                                  await ModalPopup.show(
                                    context: context,
                                    child: _buildDelete2(item),
                                  );
                                  // bool deletable =
                                  //     widget.item.value.authorId == widget.me &&
                                  //         !widget.chat.value!.isRead(
                                  //             widget.item.value, widget.me) &&
                                  //         (widget.item.value is ChatMessage ||
                                  //             widget.item.value is ChatForward);

                                  // if (await MessagePopup.alert(
                                  //         'Are you sure you want to delete this message?') ==
                                  //     true) {
                                  //   widget.onDelete?.call();
                                  // }
                                },
                              ),
                            ],
                          ],
                          // ),
                          child: child,
                          // child: AnimatedContainer(
                          //   duration: const Duration(milliseconds: 500),
                          //   // padding: padding,
                          //   decoration: BoxDecoration(
                          //     color: fromMe
                          //         ? isRead
                          //             ? const Color(0xFFD7ECFF)
                          //             : const Color(0xFFE6F1FE)
                          //         : Colors.white,
                          //     borderRadius: BorderRadius.circular(15),
                          //   ),
                          //   child: ClipRRect(
                          //     borderRadius: BorderRadius.circular(15),
                          //     child: AnimatedOpacity(
                          //       duration: const Duration(milliseconds: 500),
                          //       opacity: isRead
                          //           ? 1
                          //           : fromMe
                          //               ? 0.55
                          //               : 1,
                          //       child: child,
                          //     ),
                          //   ),
                          // ),
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

  Widget _buildAttachment(
    int i,
    Attachment e,
    List<Attachment> attachments, {
    bool filled = true,
  }) {
    if (e is ImageAttachment ||
        (e is FileAttachment && e.isVideo) ||
        (e is LocalAttachment && (e.file.isImage || e.file.isVideo))) {
      return _buildMedia(i, e, attachments, filled: filled);
    }

    return _buildFile(e, filled: filled);
  }

  Widget _buildFile(Attachment e, {bool filled = true}) {
    Style style = Theme.of(context).extension<Style>()!;
    bool isLocal = e is LocalAttachment;

    // return Container(
    //   padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
    //   width: 100,
    //   height: 100,
    //   decoration: BoxDecoration(
    //     color: Colors.grey,
    //     borderRadius: BorderRadius.circular(10),
    //   ),
    // );

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD8D8D8),
        // borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              e.filename,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
              // TODO: Cut the file in way for the extension to be displayed.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              '${e.size ~/ 1024} KB',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF888888),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
      child: InkWell(
        onTap: () => throw UnimplementedError(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 2, 10, 0),
              child: isLocal
                  ? ElasticAnimatedSwitcher(
                      child: e.status.value == SendingStatus.sent
                          ? const Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Colors.green,
                            )
                          : e.status.value == SendingStatus.sending
                              ? SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    value: e.progress.value,
                                  ),
                                )
                              : const Icon(
                                  Icons.error_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                    )
                  : const Icon(
                      Icons.attach_file,
                      size: 18,
                      color: Colors.blue,
                    ),
            ),
            Flexible(
              child: Text(
                e.filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.boldBody,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                '${e.size ~/ 1024} KB',
                style: Theme.of(context).textTheme.subtitle2,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(
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
      // padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
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
                    gallery.add(GalleryItem.video(link));
                  } else if (o is ImageAttachment) {
                    gallery.add(GalleryItem.image(link));
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
  void _populateGlobalKeys(ChatMessage msg) {
    _galleryKeys = msg.attachments
        // .where((e) =>
        //     e is ImageAttachment ||
        //     (e is FileAttachment && e.isVideo) ||
        //     (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
        .map((e) => GlobalKey())
        .toList();
  }

  Widget _buildDelete(ChatItem item, {void Function(bool?)? onRemove}) {
    return LayoutBuilder(builder: (context, constraints) {
      Offset offset =
          Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
      final keyContext = _deleteKey.currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox?;
        offset = box?.localToGlobal(Offset.zero) ?? offset;
        offset = Offset(
          offset.dx + (box?.size.width ?? 0) / 2,
          offset.dy,
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: offset.dx - 260 / 2,
            bottom: MediaQuery.of(context).size.height - offset.dy,
            child: Container(
              child: ContextMenuActions(
                backdrop: true,
                width: 250,
                actions: [
                  ContextMenuButton(
                    key: const Key('Delete1'),
                    label: 'Delete for me'.l10n,
                    leading: SvgLoader.asset(
                      'assets/icons/delete_small.svg',
                      width: 17.75,
                      height: 17,
                    ),
                    onPressed: () {
                      widget.onHide?.call();
                      Navigator.of(context).pop();
                      onRemove?.call(null);
                    },
                  ),
                  ContextMenuButton(
                    key: const Key('Delete2'),
                    label: 'Delete for everyone'.l10n,
                    leading: SvgLoader.asset(
                      'assets/icons/delete_small.svg',
                      width: 17.75,
                      height: 17,
                    ),
                    onPressed: () {
                      widget.onDelete?.call();
                      Navigator.of(context).pop();
                      onRemove?.call(null);
                    },
                  ),
                  ContextMenuButton(
                    key: const Key('Cancel'),
                    label: 'Cancel'.l10n,
                    leading: SvgLoader.asset(
                      'assets/icons/delete_small.svg',
                      width: 17.75,
                      height: 17,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // onRemove?.call(null);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  DeleteOptions? _deleteOptions = DeleteOptions.me;

  Widget _buildDelete2(ChatItem item) {
    ThemeData theme = Theme.of(context);
    Style style = theme.extension<Style>()!;
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    bool deletable = widget.item.value.authorId == widget.me &&
        !widget.chat.value!.isRead(widget.item.value, widget.me) &&
        (widget.item.value is ChatMessage || widget.item.value is ChatForward);

    return StatefulBuilder(builder: (context, setState) {
      return ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Delete the message?'.l10n,
              style: thin?.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(height: 25),
          if (deletable) ...[
            _button(
              context,
              text: 'Delete for me',
              deleteOptions: DeleteOptions.me,
              setState: setState,
            ),
            const SizedBox(height: 10),
            _button(
              context,
              text: 'Delete for everyone',
              deleteOptions: DeleteOptions.everyone,
              setState: setState,
            ),
          ] else ...[
            Center(
              child: Text(
                'The message will be deleted only for you.',
                style: thin?.copyWith(fontSize: 18),
              ),
            ),
          ],
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: OutlinedRoundedButton(
                  maxWidth: null,
                  title: Text(
                    'Proceed'.l10n,
                    style: thin?.copyWith(color: Colors.white),
                  ),
                  onPressed: () {
                    switch (_deleteOptions) {
                      case DeleteOptions.me:
                        widget.onHide?.call();
                        break;

                      case DeleteOptions.everyone:
                        widget.onHide?.call();
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
                  title: Text('Cancel'.l10n, style: thin),
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

  Widget _button(
    BuildContext context, {
    required String text,
    DeleteOptions deleteOptions = DeleteOptions.everyone,
    required StateSetter setState,
  }) {
    ThemeData theme = Theme.of(context);
    Style style = theme.extension<Style>()!;
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    return Material(
      type: MaterialType.card,
      borderRadius: style.cardRadius,
      child: InkWell(
        onTap: () => setState(() => _deleteOptions = deleteOptions),
        borderRadius: style.cardRadius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(text, style: thin?.copyWith(fontSize: 18)),
              ),
              IgnorePointer(
                child: Radio<DeleteOptions>(
                  value: deleteOptions,
                  groupValue: _deleteOptions,
                  onChanged: (DeleteOptions? value) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum DeleteOptions { me, everyone }

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
